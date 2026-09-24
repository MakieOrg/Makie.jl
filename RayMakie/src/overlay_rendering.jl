# =============================================================================
# Overlay Rendering — draws RenderObjects via Lava graphics pipeline
# =============================================================================

# DELETED: `render_overlays!` / `render_overlays_gfx!`, which opened a
# `Mantle.pass!` and recorded every overlay into it, per frame. A frame is a
# GRAPH now — see `frame_plan!` — so the overlays are declared beside the blit
# instead of recorded after it, and the two submissions became one.

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

function declare_overlay_draw!(p, robj::RenderObject, cell, viewport, default_vp)
    # DECLARED, not recorded. `Mantle.draw!` on a `PassHandle` pushes a `DrawCall`
    # onto the graph's pass and the plan compiles it once; the hand-recorded
    # version called `Mantle.compile_draw` here, every frame, for every object.
    #
    # `cell` is a `Mantle.DrawBinding`, and it is why this plan survives a zoom.
    # `projectionview` and `model` are ARGUMENTS — plain `Mat4f` values in the
    # tuple — a tick count is a VERTEX COUNT, and a relaid-out plot gets a new
    # index buffer. All four change when the limits do and none of them is a plot
    # appearing or disappearing, so all four are rebound rather than baked; see
    # `rebind_overlay_args!`.
    #
    # The SAME list on both stages, which is what a Makie render object is: the
    # fragment stage reads the colormap its vertex stage indexed. One push
    # constant range, two stages declaring the same layout over it.
    Mantle.draw!(p, robj.pipeline, cell;
                 frag_args = Mantle.drawargs(cell),
                 viewport = viewport === nothing ? default_vp : viewport)
    # No `pin!` and no `hold!`. What the draw reads is reachable from `robj`,
    # which outlives the plan; the plan holds what it names for as long as it
    # lives, which is core's job and not this package's.
    return nothing
end

# =============================================================================
# Main render pass — collect and draw all RenderObjects
# =============================================================================

"""
    collect_overlay_robjs(state, root_scene; scenes = nothing)

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
function collect_overlay_robjs(state::RayMakieState, root_scene::Makie.Scene; scenes = nothing)
    robjs = Tuple{RenderObject, NTuple{4, Float32}}[]

    overlay_scenes = if scenes !== nothing
        scenes
    elseif state.overlay_only
        collect_overlay_scenes(state.makie_scene)
    else
        [state.makie_scene]
    end

    # The ROOT's height, because that is the space `vp.origin` is measured in —
    # a scene's viewport is placed in the figure, not in itself — and the flip
    # below turns a y-up origin into a y-down one.
    #
    # This read `size(state.makie_scene)`, which is the same scene as the root
    # for an overlay-only state and therefore right for every 2D figure. For a
    # TRACED state it is the sub-scene: an `LScene` 368 units tall in a 400-unit
    # figure flipped against 368 and drew every decoration 32 units too high, so
    # the axis box, its ticks and its labels sat above the surface they belong
    # to while the traced image itself was in the right place. Mixing a
    # sub-scene's height with a root-space origin, which is the same mistake as
    # sizing a film in units and blitting it into pixels.
    root_h = size(root_scene)[2]
    for rscene in overlay_scenes
        vp = Makie.viewport(rscene)[]
        vp_y = Float32(root_h - vp.origin[2])
        vp_rect = (Float32(vp.origin[1]), vp_y, Float32(vp.widths[1]), -Float32(vp.widths[2]))
        for p in rscene.plots
            Makie.for_each_atomic_plot(p) do ap
                # `:raster_renderobject` first: a plot that can go both ways
                # writes the raster one there and leaves `:trace_renderobject`
                # `nothing`. Plots that are only ever overlays still use the
                # older name.
                slot = haskey(ap, :raster_renderobject) ? :raster_renderobject :
                       haskey(ap, :trace_renderobject)  ? :trace_renderobject  : nothing
                slot === nothing && return nothing
                ap.visible[] || return nothing
                # A render object that exists but will not resolve is a BROKEN
                # plot, not an absent one. This was `catch; return nothing`, which
                # made a plot that fails to build indistinguishable from one that
                # simply draws nothing. `maxlog` because this runs every frame.
                robj = try
                    ap[slot][]
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

Asked before the pass opens rather than discovered from a shader compile. It
THROWS, and that is the point: an overlay that cannot be drawn is not a degraded
image, it is a WRONG one — no axis grid, no ticks, no labels, no scatter, no
lines — and a renderer that drops it and reports success produces something nobody
reading the picture can tell is incomplete. There was a skip-with-a-warning here
and it is gone on purpose.

A geometry stage needs EITHER a backend that has one or a backend that has a mesh
pipeline, because `Mantle.compile_draw` lowers a geometry pipeline onto a mesh one
where the stage does not exist. That is why this asks two questions and not one,
and why nothing above here branches on which of the two ran.
"""
function require_drawable(backend, p::Mantle.GraphicsPipeline)
    if p.geometry !== nothing && !Mantle.supports_geometry_stage(backend) &&
            !Mantle.supports_mesh_pipeline(backend)
        error("""
            $(nameof(typeof(backend))) has neither a geometry stage nor a mesh
            pipeline, and this overlay declares a geometry stage, so it CANNOT be
            drawn — and it must not be silently dropped.

              vertex stage    $(Mantle.stagefunction(p.vertex))
              geometry stage  $(Mantle.stagefunction(p.geometry))

            A backend with a mesh pipeline runs this through
            `Mantle.lower_geometry_to_mesh`, which is what Metal does. One with
            neither has to grow one of the two.""")
    end
    if p.tess_control !== nothing && !Mantle.supports_tessellation(backend)
        error("$(nameof(typeof(backend))) has no tessellation, and this overlay " *
              "declares one: $(Mantle.stagefunction(p.vertex)).")
    end
    return nothing
end

function require_drawable(backend, p::Mantle.MeshPipeline)
    Mantle.supports_mesh_pipeline(backend) || error("""
        $(nameof(typeof(backend))) has no mesh pipeline, and this overlay IS one —
        its geometry is written by a stage rather than read from a buffer, so
        there is nothing to fall back to.

          mesh stage  $(Mantle.stagefunction(p.mesh))

        A plot drawn this way has no vertex-stream form to lower onto; the
        backend has to grow the stage.""")
    return nothing
end

"""
    frame_draws!(p, screen, source, cells, robjs, w, h)

Declare a whole composited frame onto one render pass: the traced image, then
every overlay on top of it.

ONE pass, because that is what it is. It used to be `Mantle.blit!` — itself a
pass with one fullscreen draw — followed by a second `Mantle.pass!` for the
overlays, two submissions where the second only ever ran straight after the
first. The graph makes the difference visible: the blit is a draw like any
other, it just wants a different viewport, and per-draw viewports are why it
can share the pass.
"""
function frame_draws!(p, screen, source, cells, robjs, w, h)
    # Y-flipped: a negative height puts clip-space +Y at the top, matching
    # Makie's pixel convention, and this is the default every overlay that does
    # not name its own rect takes.
    default_vp = (0f0, Float32(h), Float32(w), -Float32(h))
    # The blit is NOT y-flipped — `Mantle.blit!` spells it `viewport!(p, 0, 0, w, h)`
    # and its shader is written for that. Two conventions in one pass is exactly
    # the case a per-draw viewport exists for.
    Mantle.checkblitsize(source, w, h)
    Mantle.draw!(p, Mantle.BLIT_PIPELINE, (), 3;
                 frag_args = (source, Int32(w), Int32(h)),
                 viewport = (0f0, 0f0, Float32(w), Float32(h)))
    for (i, (robj, vp)) in enumerate(robjs)
        declare_overlay_draw!(p, robj, cells[i], vp, default_vp)
    end
    return nothing
end

"""
    frame_signature(robjs, w, h)

What a frame plan FIXES, as opposed to what it merely reads.

A plan compiles each pipeline around its argument TYPES and fixes whether each
draw is indexed. It fixes none of the values: the arguments, the count, the
index buffer and the instance count all live in a `Mantle.DrawBinding` per
object and are rebound every frame. So a camera move, a tick recount, a colour
change and new contents in an existing buffer are all invisible here, which is
the point. What is left rebuilds a plan: a plot appearing or disappearing, a
plot's pipeline or argument types changing, a viewport moving, a window opening
or resizing.
"""
function frame_signature(robjs, w, h)
    (w, h,
     map(robjs) do (robj, vp)
         # `isnothing(indices)` and not the buffer's identity: WHETHER a draw is
         # indexed decides which command the backend records and so is compiled
         # in, but WHICH buffer holds the indices is rebound.
         # `objectid(robj.bindings)` IS here, and the comment that used to say
         # it need not be was wrong. A composited frame is a RECORDED plan and
         # `cmd_bind_descriptor_sets` bakes the set handle, so handing `rebind!`
         # a DIFFERENT set changes a value nothing reads again — the frame keeps
         # drawing the old texture. New pixels in the SAME texture are the fast
         # path and do not come through here at all: `update_texture!` uploads
         # into the existing image and leaves the set alone.
         (objectid(robj), objectid(robj.pipeline), objectid(robj.bindings), vp,
          isnothing(get(robj.buffers, :indices, nothing)),
          # The argument TYPES, because those are the pipeline and the layout.
          # Not the values and not the counts — a camera move and a tick recount
          # both leave those to the draw's cell, which is the whole point.
          map(typeof, build_args(robj)),
          # But DO carry each device array's identity. `record_draw!` bakes the
          # address of the packed argument block into a push constant, so a
          # buffer that `resize!` had to REALLOCATE is one a plan recorded
          # earlier cannot see. It showed up as text frozen at the glyph count
          # of whatever it first drew — "RAY TRACED" rendering as "RAY TR",
          # because the label had once said "RASTER" — and as the axis tick
          # labels that a zoom never redrew.
          #
          # `argidentity` is `nothing` for everything that is not a device
          # array, so a uniform still costs no rebuild.
          map(Mantle.argidentity, build_args(robj)),
          # And the COUNTS, for the same reason: `record_draw!` passes them to
          # `vkCmdDraw`, which bakes them. Rebinding a smaller count into the
          # cell changes nothing the recorded command reads — text shrinking
          # from twelve glyphs to two kept drawing twelve. The address above
          # does not catch this on its own, because `resize!` DOWNWARD stays
          # inside its capacity and keeps the buffer it had.
          #
          # This does mean a plot whose element count changes rebuilds its
          # plan. That is the price of the counts being compiled in, and it is
          # paid on a tick recount or a relaid-out label, not on a camera move.
          robj.vertex_count, robj.instances,
          isnothing(get(robj.buffers, :indices, nothing)) ? 0 :
              length(robj.buffers[:indices]))
     end)
end

"""
    overlay_binding(robj, dev) -> Mantle.DrawBinding

Everything `robj` re-reads each frame, in the cell its draw will read it from.

An indexed draw's count is an INDEX count; a non-indexed one's is a vertex count
and carries the instance count with it. That choice is compiled in — it decides
which command the backend records — so it is made here, once, and `rebind!` can
only ever supply the same kind.
"""
function overlay_binding(robj::RenderObject, dev)
    ix = get(robj.buffers, :indices, nothing)
    args = build_args(robj)
    return ix === nothing ?
        Mantle.DrawBinding(dev, args, robj.vertex_count; instances = robj.instances,
                           bindings = robj.bindings) :
        Mantle.DrawBinding(dev, args, length(ix); indices = ix, bindings = robj.bindings)
end

"""
    rebind_overlay_args!(cells, robjs, dev)

Put this frame's values into the cells the plan draws from.

This is the per-frame work, and all of it: no compile, no graph, no recording.
`Mantle.rebind!` refuses a value of a different type, which is the check
`frame_signature` does not have to make — a changed type is a changed pipeline
and would have rebuilt the plan anyway.
"""
function rebind_overlay_args!(cells, robjs, dev)
    for (i, (robj, _)) in enumerate(robjs)
        ix = get(robj.buffers, :indices, nothing)
        args = build_args(robj)
        if ix === nothing
            Mantle.rebind!(cells[i], dev, args, robj.vertex_count;
                           instances = robj.instances, bindings = robj.bindings)
        else
            Mantle.rebind!(cells[i], dev, args, length(ix); indices = ix,
                           bindings = robj.bindings)
        end
    end
    return nothing
end

"""
    frame_plan!(screen, key, mktarget, clear, source, robjs, w, h; finish)

The compiled plan for one composited frame, built on first use and reused until
[`frame_signature`](@ref) changes.

`mktarget(g)` makes the attachment inside the graph being built — a
`Mantle.Surface` for the window, a `Mantle.Transient.Image` for a readback.
`finish(g, target)` runs AFTER the render pass is declared and answers with
whatever the caller needs back out of the plan: a readback adds a copy pass and
hands back the buffer it copies into. Two callbacks and not one because the
order the passes are declared in is the order they read: a copy that names the
target has to be declared after the pass that fills it. `key` separates the two
target kinds, because a screen has both and they are not interchangeable.
"""
function frame_plan!(screen, key::Symbol, mktarget, clear, source, robjs, w, h;
                     finish = (g, target) -> nothing)
    # `todevice`: a screen keeps the BACKEND its user named, and a graph is
    # built on the device.
    dev = Mantle.todevice(screen.config.device)
    sig = (key, objectid(source), frame_signature(robjs, w, h))
    cached = get(screen.frame_plans, key, nothing)
    if cached !== nothing && cached[1] == sig
        rebind_overlay_args!(cached[4], robjs, dev)
        return cached[2], cached[3]
    end

    cells = [overlay_binding(robj, dev) for (robj, _) in robjs]
    g = Mantle.Graph(dev)
    target = mktarget(g)
    # The depth attachment the overlay pipelines test against. `Float32` is what
    # makes it one: a single-component 32-bit float attachment is `D32_SFLOAT`
    # and nothing else in Vulkan is.
    #
    # The pipelines compare with `DepthLessEq`, not `DepthLess`. Plots WITHIN a
    # scene share its z — a menu's option backgrounds and their labels are both
    # at 200 — so a strict test rejects whichever is drawn second and the labels
    # vanish into their own background. Equal depth passing means draw order
    # still decides inside a scene, and z only decides between scenes, which is
    # exactly the split Makie's convention asks for.
    #
    # Sized FROM the target, not to `(w, h)`: a transient given a target follows
    # it, and `run!` refits it when the window has been resized — which a
    # backend may notice only inside the frame, after this plan was built.
    # Fixed at `(w, h)`, a resized window drew one frame against a depth buffer
    # of the old size, `checkextents` refused it, and the render loop died: on
    # Metal, every drag of a window corner. The composite below draws through
    # an explicit viewport, so that one frame lands in the old rectangle and the
    # next is built at the new size.
    depth = Mantle.Transient.Image(g, Float32, target)
    Mantle.render!(g, "frame", target => clear, depth => Mantle.Clear(1f0)) do p
        frame_draws!(p, screen, source, cells, robjs, w, h)
    end
    extra = finish(g, target)
    # NOT `record!`: a windowed plan draws to a different swapchain image every
    # frame and core refuses to record one. An unrecorded plan re-emits per
    # frame, which is also what lets a rebound cell be seen — a recording packs
    # its arguments once and `Mantle.rebind!` on one is refused by name.
    plan = Mantle.Plan(g)
    screen.frame_plans[key] = (sig, plan, extra, cells)
    return plan, extra
end

"""
    overlay_robjs(screen; scenes = nothing)

Every overlay draw for the whole screen, from the ROOT states only.

`collect_overlay_robjs` answers for one state; a root's collection already
covers the scenes below it. Polling is separate and has to touch every state,
because each resolves its own scene's plots — see `poll_all_plots`.
"""
function overlay_robjs(screen; scenes = nothing)
    robjs = Tuple{RenderObject, NTuple{4, Float32}}[]
    for ss in overlay_root_states(screen)
        screen.state = ss
        append!(robjs, collect_overlay_robjs(ss, screen.scene; scenes))
    end
    # Every pipeline checked BEFORE the graph is built, so one this backend
    # cannot run is a named error rather than a half-composited frame.
    for (robj, _) in robjs
        require_drawable(screen.config.device, robj.pipeline)
    end
    # `Makie.viewport` answers in UNITS and the target is in PIXELS, so the
    # rectangles are scaled by the same number the drawable was. At
    # `px_per_unit == 1` this is the identity and nothing moves.
    ppu = screen.px_per_unit
    ppu == 1 && return robjs
    return [(robj, map(v -> v * ppu, vp)) for (robj, vp) in robjs]
end
