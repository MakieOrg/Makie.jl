# =============================================================================
# Overlay Rendering — draws LavaRenderObjects via Lava graphics pipeline
# =============================================================================

function render_overlays!(screen, bq, target; scenes=nothing)
    render_overlays_gfx!(screen, bq, target; scenes)
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
# Draw a single LavaRenderObject inside the active render pass
# =============================================================================

function draw_lava_renderobject!(screen, bq::Mantle.BatchQueue, robj::LavaRenderObject, viewport, color_format, default_vp, default_sc)
    batch = bq.active_batch
    cmd = batch.cmd_buf

    if viewport !== nothing
        vx, vy, vw, vh = viewport
        dvp = VK.Viewport(vx, vy, vw, vh, 0f0, 1f0)
        VK.cmd_set_viewport(cmd, [dvp])
        # Compute scissor rect — must clamp to non-negative (Vulkan requirement)
        sc_x = Int32(floor(vx))
        sc_y = vh < 0 ? Int32(floor(vy + vh)) : Int32(floor(vy))
        sc_w = Int32(ceil(abs(vw)))
        sc_h = Int32(ceil(abs(vh)))
        # Clamp negative offsets: shrink extent by the overflow amount
        if sc_x < Int32(0)
            sc_w = max(Int32(0), sc_w + sc_x)
            sc_x = Int32(0)
        end
        if sc_y < Int32(0)
            sc_h = max(Int32(0), sc_h + sc_y)
            sc_y = Int32(0)
        end
        dsc = VK.Rect2D(
            VK.Offset2D(sc_x, sc_y),
            VK.Extent2D(UInt32(sc_w), UInt32(sc_h)))
        VK.cmd_set_scissor(cmd, [dsc])
    else
        VK.cmd_set_viewport(cmd, [default_vp])
        VK.cmd_set_scissor(cmd, [default_sc])
    end

    args = build_args(robj)
    tt = gfx_type_tuple(args)
    ds_layout = robj.bindings !== nothing ? robj.bindings.layout : nothing
    vert_shader, compiled = Mantle.ensure_compiled_with_shader!(robj.pipeline,
        robj.pipeline.vertex, robj.pipeline.fragment, tt, tt;
        color_format=color_format, descriptor_set_layout=ds_layout)

    if robj.bindings !== nothing
        VK.cmd_bind_descriptor_sets(cmd,
            VK.PIPELINE_BIND_POINT_GRAPHICS,
            compiled.pipeline_layout, UInt32(0),
            [robj.bindings.set], UInt32[])
        Mantle.pin!(batch, robj.bindings)
    end

    push_data = Mantle.pack_gfx_args(bq, args, vert_shader.push_info)

    if haskey(robj.buffers, :indices)
        ib = robj.buffers[:indices]
        Mantle.vk_draw_indexed_in_pass!(bq, compiled, length(ib);
            push_data=push_data, indices_buffer=ib.buf[].buffer)
    else
        Mantle.vk_draw_in_pass!(bq, compiled, robj.vertex_count;
            push_data=push_data, instances=robj.instances)
    end

    Mantle.pin!(batch, compiled)
    for (_, buf) in robj.buffers
        Mantle.pin!(batch, buf)
    end
end

# =============================================================================
# Main render pass — collect and draw all LavaRenderObjects
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
    robjs = Tuple{LavaRenderObject, NTuple{4, Float32}}[]

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
                robj isa LavaRenderObject && robj.visible && push!(robjs, (robj, vp_rect))
                return nothing
            end
        end
    end
    return robjs
end

"""
    render_overlays_gfx!(screen, target; scenes=nothing)

Render overlay plots (scatter, lines, text, mesh) via the Lava graphics pipeline
directly onto `target` (a `WindowTarget` or `OffscreenTarget`).

When `scenes` is provided, only plots from those scenes are rendered (used for
uncovered overlay rendering). Otherwise, uses the current screen state's scene.
"""
function render_overlays_gfx!(screen, bq, target; scenes=nothing)
    state = screen.state
    robjs = collect_overlay_robjs(state; scenes)

    isempty(robjs) && return

    # Render directly to target using the provided BatchQueue

    if target isa Mantle.WindowTarget
        win = target.window
        w, h = Mantle.size(win)
        view = win.views[win.current_image_idx + 1]
        image = win.images[win.current_image_idx + 1]
    else
        fb = target.fb
        w, h = fb.width, fb.height
        view = fb.color_view
        image = fb.color_image
    end

    extent = VK.Extent2D(UInt32(w), UInt32(h))
    # No clear — overlays are alpha-blended on top of existing content
    Mantle.vk_begin_pass!(bq, view, image, extent; clear_color=nothing)

    batch = bq.active_batch
    cmd = batch.cmd_buf
    vp = VK.Viewport(0f0, Float32(h), Float32(w), -Float32(h), 0f0, 1f0)
    VK.cmd_set_viewport(cmd, [vp])
    sc = VK.Rect2D(VK.Offset2D(0, 0), extent)
    VK.cmd_set_scissor(cmd, [sc])

    fmt = target isa Mantle.WindowTarget ? target.window.format : target.fb.color_format
    for (robj, robj_vp) in robjs
        draw_lava_renderobject!(screen, bq, robj, robj_vp, fmt, vp, sc)
    end

    Mantle.vk_end_pass!(bq)
end
