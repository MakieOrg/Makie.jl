# =============================================================================
# Overlay Rendering — draws LavaRenderObjects via Lava graphics pipeline
# =============================================================================

function render_overlays!(screen, bq, target; scenes=nothing)
    render_overlays_gfx!(screen, bq, target; scenes)
end

# =============================================================================
# Helper: extract near/far from camera
# =============================================================================

function extract_near_far(scene::Makie.Scene, proj::Mat4f)
    cc = scene.camera_controls
    if hasproperty(cc, :near) && hasproperty(cc, :far)
        near = Float32(cc.near[])
        far = Float32(cc.far[])
    else
        A = proj[3, 3]; B = proj[3, 4]
        near = B / (A - 1f0); far = B / (A + 1f0)
        (!isfinite(near) || near <= 0f0) && (near = 0.1f0)
        (!isfinite(far) || far <= near) && (far = 1000f0)
    end
    return near, far
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

function draw_lava_renderobject!(screen, bq::Lava.BatchQueue, robj::LavaRenderObject, viewport, color_format, default_vp, default_sc)
    batch = bq.active_batch
    cmd = batch.cmd_buf

    if viewport !== nothing
        vx, vy, vw, vh = viewport
        dvp = Vulkan.Viewport(vx, vy, vw, vh, 0f0, 1f0)
        Vulkan.cmd_set_viewport(cmd, [dvp])
        sc_y = vh < 0 ? Int32(floor(vy + vh)) : Int32(floor(vy))
        sc_h = UInt32(ceil(abs(vh)))
        dsc = Vulkan.Rect2D(
            Vulkan.Offset2D(Int32(floor(vx)), sc_y),
            Vulkan.Extent2D(UInt32(ceil(abs(vw))), sc_h))
        Vulkan.cmd_set_scissor(cmd, [dsc])
    else
        Vulkan.cmd_set_viewport(cmd, [default_vp])
        Vulkan.cmd_set_scissor(cmd, [default_sc])
    end

    args = build_args(robj)
    tt = gfx_type_tuple(args)
    ds_layout = robj.bindings !== nothing ? robj.bindings.layout : nothing
    vert_shader, compiled = Lava._ensure_compiled_with_shader!(robj.pipeline,
        robj.pipeline.vertex, robj.pipeline.fragment, tt, tt;
        color_format=color_format, descriptor_set_layout=ds_layout)

    if robj.bindings !== nothing
        Vulkan.cmd_bind_descriptor_sets(cmd,
            Vulkan.PIPELINE_BIND_POINT_GRAPHICS,
            compiled.pipeline_layout, UInt32(0),
            [robj.bindings.set], UInt32[])
        push!(batch.data_refs, robj.bindings)
    end

    push_data = Lava.pack_gfx_args(args, vert_shader.push_info)

    if haskey(robj.buffers, :indices)
        ib = robj.buffers[:indices]
        Lava.vk_draw_indexed_in_pass!(bq, compiled, length(ib);
            push_data=push_data, indices_buffer=ib.buf[].buffer)
    else
        Lava.vk_draw_in_pass!(bq, compiled, robj.vertex_count;
            push_data=push_data, instances=robj.instances)
    end

    push!(batch.data_refs, compiled)
    for (_, buf) in robj.buffers
        push!(batch.data_refs, buf)
    end
end

# =============================================================================
# Main render pass — collect and draw all LavaRenderObjects
# =============================================================================

"""
    render_overlays_gfx!(screen, target; scenes=nothing)

Render overlay plots (scatter, lines, text, mesh) via the Lava graphics pipeline
directly onto `target` (a `WindowTarget` or `OffscreenTarget`).

When `scenes` is provided, only plots from those scenes are rendered (used for
uncovered overlay rendering). Otherwise, uses the current screen state's scene.
"""
function render_overlays_gfx!(screen, bq, target; scenes=nothing)
    state = screen.state
    scene = state.makie_scene

    robjs = Tuple{LavaRenderObject, Any}[]

    overlay_scenes = if scenes !== nothing
        scenes
    elseif state.overlay_only
        collect_overlay_scenes(state.makie_scene)
    else
        [scene]
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
                robj = try ap[:trace_renderobject][] catch; return nothing end
                robj isa LavaRenderObject && robj.visible && push!(robjs, (robj, vp_rect))
            end
        end
    end

    isempty(robjs) && return

    # Render directly to target using the provided BatchQueue

    if target isa Lava.WindowTarget
        win = target.window
        w, h = Lava.size(win)
        view = win.views[win.current_image_idx + 1]
        image = win.images[win.current_image_idx + 1]
    else
        fb = target.fb
        w, h = fb.width, fb.height
        view = fb.color_view
        image = fb.color_image
    end

    extent = Vulkan.Extent2D(UInt32(w), UInt32(h))
    # No clear — overlays are alpha-blended on top of existing content
    Lava.vk_begin_pass!(bq, view, image, extent; clear_color=nothing)

    batch = bq.active_batch
    cmd = batch.cmd_buf
    vp = Vulkan.Viewport(0f0, Float32(h), Float32(w), -Float32(h), 0f0, 1f0)
    Vulkan.cmd_set_viewport(cmd, [vp])
    sc = Vulkan.Rect2D(Vulkan.Offset2D(0, 0), extent)
    Vulkan.cmd_set_scissor(cmd, [sc])

    fmt = target isa Lava.WindowTarget ? target.window.format : target.fb.color_format
    for (robj, robj_vp) in robjs
        draw_lava_renderobject!(screen, bq, robj, robj_vp, fmt, vp, sc)
    end

    Lava.vk_end_pass!(bq)
end
