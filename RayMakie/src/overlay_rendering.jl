# =============================================================================
# Overlay Rendering — draws RenderObjects via Lava graphics pipeline
# =============================================================================

# `e` is the EMITTER of the closed command buffer the overlays go into — a
# frame's one-shot in the render loop, an overlay one-shot in `colorbuffer` —
# not a queue. It used to take the queue and draw into whatever batch the queue
# had open; a queue holds nothing open any more (Mantle, step 7), so the caller
# opens the buffer and this writes into it.
function render_overlays!(screen, target, color_eltype; scenes=nothing)
    render_overlays_gfx!(screen, target, color_eltype; scenes)
end

# =============================================================================
# Sub-scene backgrounds (GPU fill)
# =============================================================================

function render_subscene_backgrounds!(postprocess, root_scene)
    root_h, root_w = size(postprocess)
    for child in root_scene.children
        bg = to_value(child.backgroundcolor)
        bg_rgba = RGBA{Float32}(bg)
        (bg_rgba.r ≈ 1f0 && bg_rgba.g ≈ 1f0 && bg_rgba.b ≈ 1f0) && continue
        bg_rgba.alpha < 0.01f0 && continue
        vp = child.viewport[]
        x0 = max(1, round(Int, vp.origin[1]) + 1)
        x1 = min(root_w, round(Int, vp.origin[1] + vp.widths[1]))
        y_top = root_h - round(Int, vp.origin[2] + vp.widths[2]) + 1
        y_bot = root_h - round(Int, vp.origin[2])
        y0 = max(1, y_top); y1 = min(root_h, y_bot)
        bg_fill = RGBA{Float32}(bg_rgba.r * bg_rgba.alpha, bg_rgba.g * bg_rgba.alpha, bg_rgba.b * bg_rgba.alpha, 1f0)
        bg_rgba.alpha ≈ 1f0 && (view(postprocess, y0:y1, x0:x1) .= Ref(bg_fill))
    end
end

# =============================================================================
# Draw a single RenderObject inside the active render pass
# =============================================================================

function draw_renderobject!(screen, p, robj::RenderObject, viewport, color_eltype, default_vp)
    # `Mantle.viewport!` takes plain numbers and derives the scissor — including
    # the clamping a flipped viewport needs. That arithmetic used to live here,
    # spelled in `VK.Viewport`/`VK.Rect2D`, which is how a renderer ended up
    # owning a driver's rectangle rules.
    Mantle.viewport!(p, (viewport === nothing ? default_vp : viewport)...)

    # `todevice`: a screen keeps the BACKEND its user named, and every verb below
    # wants the device.
    dev = Mantle.todevice(screen.config.device)
    args = map(a -> Mantle.resolve(dev, a), build_args(robj))
    # `Mantle.compile_draw` and not the Vulkan extension's
    # `ensure_compiled_with_shader!`: it takes the RESOLVED arguments and each
    # backend bakes their device form its own way, which is why there is no
    # `push_info` to pack against here any more. `pack_gfx_args` and the
    # descriptor-set layout went with it.
    compiled = Mantle.compile_draw(dev, robj.pipeline, (color_eltype,), nothing, args, args)

    robj.bindings === nothing || Mantle.bindings!(p, compiled, robj.bindings)

    if haskey(robj.buffers, :indices)
        ib = robj.buffers[:indices]
        Mantle.draw!(p, compiled, args, length(ib); indices = Mantle.resolve(dev, ib))
    else
        Mantle.draw!(p, compiled, args, robj.vertex_count; instances = robj.instances)
    end
    # No `pin!`. What the draw reads is reachable from `robj`, which outlives the
    # frame; `Mantle.hold!` is for the case where it is not, and this is not that
    # case. `pin!` was the Vulkan backend deciding a lifetime, which is the thing
    # `docs/mantle-owns-it.md` 2.2 moved into core.
    return nothing
end

# =============================================================================
# Main render pass — collect and draw all RenderObjects
# =============================================================================

"""
    collect_overlay_robjs(state; scenes = nothing)

Every raster render object the overlay pass would draw for `state`, each paired
with the viewport rect it belongs in.

Shared with `colorbuffer`, which has to know whether there is anything to draw
*before* it commits to the slow path (blit to a BGRA framebuffer, render, read
back, convert). Asking one function both times is what stops "are there
overlays?" and "which overlays?" from being different questions — they used to
be, and the first one was answered by `overlay_only`, which is a property of the
scene's CAMERA. So a 3D scene holding `lines!`, `scatter!` or `text!` built their
render objects and then nobody drew them, which is also why an `Axis3` came out
with no spines, ticks or labels.
"""
function collect_overlay_robjs(state::RayMakieState; scenes = nothing)
    robjs = Tuple{RenderObject, NTuple{4, Float32}}[]

    overlay_scenes = if scenes !== nothing
        scenes
    elseif state.overlay_only
        collect_overlay_scenes(state.makie_scene)
    else
        [state.makie_scene]
    end

    root_w, root_h = size(state.makie_scene)
    for rscene in overlay_scenes
        vp = Makie.viewport(rscene)[]
        vp_y = Float32(root_h - vp.origin[2])
        vp_rect = (Float32(vp.origin[1]), vp_y, Float32(vp.widths[1]), -Float32(vp.widths[2]))
        for p in rscene.plots
            Makie.for_each_atomic_plot(p) do ap
                haskey(ap, :trace_renderobject) || return nothing
                ap.visible[] || return nothing
                # A render object that exists but will not resolve is a BROKEN
                # plot, not an absent one. This was `catch; return nothing`, which
                # made a plot that fails to build indistinguishable from one that
                # simply draws nothing. `maxlog` because this runs every frame.
                robj = try
                    ap[:trace_renderobject][]
                catch e
                    @error("RayMakie: an overlay render object failed to resolve; \
                            this plot will not be drawn",
                           plot = typeof(ap), exception = (e, catch_backtrace()), maxlog = 1)
                    return nothing
                end
                robj isa RenderObject && robj.visible && push!(robjs, (robj, vp_rect))
                return nothing
            end
        end
    end
    return robjs
end

"""
    require_drawable(backend, pipeline)

Throw unless `backend` can run every stage this pipeline declares.

Asked before the pass opens rather than discovered from a shader compile, which
is what `supports_geometry_stage` exists for. It THROWS, and that is the point: an
overlay that cannot be drawn is not a degraded image, it is a WRONG one — no axis
grid, no ticks, no labels, no scatter, no lines — and a renderer that drops it and
reports success produces something nobody reading the picture can tell is
incomplete.

There was a skip-with-a-warning here. It is gone on purpose. The fix is
`Mantle.lower_geometry_to_mesh`, which everything else is already in place for.
"""
function require_drawable(backend, p::Mantle.GraphicsPipeline)
    if p.geometry !== nothing && !Mantle.supports_geometry_stage(backend)
        error("""
            $(nameof(typeof(backend))) has no geometry stage and this overlay needs one,
            so it CANNOT be drawn — and it must not be silently dropped.

              vertex stage    $(Mantle.stagefunction(p.vertex))
              geometry stage  $(Mantle.stagefunction(p.geometry))

            Apple removed the geometry stage; the replacement is the mesh pipeline,
            which this backend has. Metal emits AIR mesh programs, a mesh stage has
            the compute builtins and threadgroup memory, KernelInterface's portable
            mesh vocabulary lowers onto it, and `Mantle.MeshPipeline` compiles and
            draws. The only missing piece is the translation.

            IMPLEMENT `Mantle.lower_geometry_to_mesh` and build this pipeline through
            it. The design is decided and written out at the top of
            Mantle/src/graphics/lowering.jl. Do not reintroduce a skip.""")
    end
    if p.tess_control !== nothing && !Mantle.supports_tessellation(backend)
        error("$(nameof(typeof(backend))) has no tessellation, and this overlay " *
              "declares one: $(Mantle.stagefunction(p.vertex)).")
    end
    return nothing
end

"""
    render_overlays_gfx!(screen, e, target; scenes=nothing)

Render overlay plots (scatter, lines, text, mesh) through Mantle's graphics
pipeline directly onto `target` (a `WindowTarget` or `OffscreenTarget`), into the closed
command buffer `e` emits into.

When `scenes` is provided, only plots from those scenes are rendered (used for
uncovered overlay rendering). Otherwise, uses the current screen state's scene.
"""
function render_overlays_gfx!(screen, target, color_eltype; scenes=nothing)
    state = screen.state
    robjs = collect_overlay_robjs(state; scenes)
    isempty(robjs) && return

    # Every pipeline checked BEFORE the pass opens, so one this backend cannot run
    # is a named error rather than a half-composited frame or a missing overlay.
    backend = screen.config.device
    for rv in robjs
        require_drawable(backend, rv[1].pipeline)
    end

    # `target_extent`, not four lines of field access per target kind. Reaching
    # into `win.views[win.current_image_idx + 1]` and `fb.color_view` was this
    # package knowing a driver's swapchain bookkeeping; `Mantle.pass!` resolves
    # the attachment from the target and there is nothing left to branch on.
    w, h = Mantle.target_extent(target)

    # Y-flipped: a negative height puts clip-space +Y at the top, matching
    # Makie's pixel convention. `viewport!` derives the scissor from exactly this.
    default_vp = (0f0, Float32(h), Float32(w), -Float32(h))

    # No clear — overlays are alpha-blended on top of what is already there.
    Mantle.pass!(screen.config.device, target) do p
        Mantle.viewport!(p, default_vp...)
        for (robj, robj_vp) in robjs
            draw_renderobject!(screen, p, robj, robj_vp, color_eltype, default_vp)
        end
    end
    return nothing
end
