# =============================================================================
# Overlay Rendering
# =============================================================================
# Iterates all plots with overlay trace_renderobjects and dispatches to
# KA rasterize kernels. No CPU for-loops that scalar-index GPU arrays.

# Cached GPU atlas (module-level, avoids re-upload each frame when unchanged)
const _CACHED_ATLAS = Ref{Any}(nothing)
const _CACHED_ATLAS_SIZE = Ref{Int}(0)  # length(atlas.data) at last upload

# =============================================================================
# Main entry point
# =============================================================================

function render_overlays!(screen)
    state = screen.state
    film = state.film
    overlay = state.overlay_buffer

    # Clear overlay buffer
    Overlay.clear_overlay!(overlay)

    has_overlay = Ref(false)
    depth_buf = film.depth  # bottom-up; rasterize kernels flip Y index internally

    # Lazily prepare atlas GPU data (only if sprites exist)
    gpu_atlas_ref = Ref{Any}(nothing)
    atlas_w_ref = Ref{Int32}(Int32(0))
    atlas_h_ref = Ref{Int32}(Int32(0))

    if state.overlay_only
        # Overlay-only: iterate ALL overlay-eligible scenes, each with its own
        # viewport-remapped raster context rendering into the single root buffer.
        root_scene = state.makie_scene
        root_w, root_h = size(root_scene)
        root_res = Vec2f(Float32(root_w), Float32(root_h))
        overlay_scenes = collect_overlay_scenes(root_scene)

        for rscene in overlay_scenes
            ctx = _create_raster_context_remapped(rscene, root_res)
            remap = _compute_viewport_remap(rscene, root_res)
            _render_scene_overlay_plots!(
                overlay, depth_buf, ctx, rscene, remap,
                gpu_atlas_ref, atlas_w_ref, atlas_h_ref, has_overlay,
            )
        end
    else
        # Standard 3D: single scene with its own camera
        scene = state.makie_scene
        ctx = _create_raster_context(scene, film.resolution)
        remap = Mat4f(I)
        Makie.for_each_atomic_plot(scene) do p
            _dispatch_overlay_plot!(
                overlay, depth_buf, ctx, p, remap,
                gpu_atlas_ref, atlas_w_ref, atlas_h_ref, has_overlay,
            )
        end
    end

    # Composite overlay onto postprocessed image
    if has_overlay[]
        DEBUG_OVERLAY[] = Array(overlay)
        Overlay.composite!(film.postprocess, overlay)
    end
end

# Render overlay plots for a single scene (direct plots only, not children)
function _render_scene_overlay_plots!(
    overlay, depth_buf, ctx, scene, remap::Mat4f,
    gpu_atlas_ref, atlas_w_ref, atlas_h_ref, has_overlay,
)
    for p in scene.plots
        Makie.for_each_atomic_plot(p) do ap
            _dispatch_overlay_plot!(
                overlay, depth_buf, ctx, ap, remap,
                gpu_atlas_ref, atlas_w_ref, atlas_h_ref, has_overlay,
            )
        end
    end
end

# Dispatch a single atomic plot to the appropriate overlay rasterizer
function _dispatch_overlay_plot!(
    overlay, depth_buf, ctx, p, remap::Mat4f,
    gpu_atlas_ref, atlas_w_ref, atlas_h_ref, has_overlay,
)
    haskey(p, :trace_renderobject) || return nothing
    p.visible[] || return nothing
    robj = try
        p[:trace_renderobject][]
    catch e
        @warn "TraceMakie: failed to access trace_renderobject for $(typeof(p))" exception=(e, catch_backtrace())
        return nothing
    end
    isnothing(robj) && return nothing
    hasproperty(robj, :type) || return nothing

    rtype = robj.type
    if rtype === :linesegments
        _render_overlay_linesegments!(overlay, depth_buf, ctx, robj)
        has_overlay[] = true
    elseif rtype === :lines
        _render_overlay_lines!(overlay, depth_buf, ctx, robj)
        has_overlay[] = true
    elseif rtype === :sprite
        # Lazily upload atlas on first sprite encounter
        if isnothing(gpu_atlas_ref[])
            gpu_atlas_ref[], atlas_w_ref[], atlas_h_ref[] = _get_gpu_atlas(overlay)
        end
        # Extract the marker-space matrices from the plot's camera attributes
        # (matches GLMakie's sprites.geom uniforms: preprojection, projection, view).
        # GLMakie: trans = (billboard ? projection : pview) * qmat(rotation)
        # So marker_projection is projection when billboard, projectionview otherwise.
        marker_proj = if robj.billboard
            _get_marker_projection(p, remap)  # p[:projection]
        else
            _get_marker_pview(p, remap)        # p[:projectionview] = projection * view
        end
        preproj = _get_preprojection(p)
        marker_pview = _get_marker_pview(p, remap)
        _render_overlay_sprite!(
            overlay, depth_buf, ctx, robj,
            gpu_atlas_ref[], atlas_w_ref[], atlas_h_ref[],
            marker_proj, preproj, marker_pview,
        )
        has_overlay[] = true
    end
    return nothing
end

# Extract the marker-space projection matrix from a plot's camera attributes,
# applying the viewport remap for overlay-only mode.
function _get_marker_projection(p, remap::Mat4f)
    if haskey(p, :projection)
        return Mat4f(remap * Mat4f(p[:projection][]))
    else
        return Mat4f(I)
    end
end

# Extract preprojection (space → markerspace transform, e.g. data → pixel).
# Does NOT need remap since it transforms between plot-local coordinate systems.
function _get_preprojection(p)
    if haskey(p, :preprojection)
        return Mat4f(p[:preprojection][])
    else
        return Mat4f(I)
    end
end

# Extract the marker-space projectionview (projection * view in markerspace),
# applying the viewport remap. This is `pview` in sprites.geom.
function _get_marker_pview(p, remap::Mat4f)
    if haskey(p, :projectionview)
        return Mat4f(remap * Mat4f(p[:projectionview][]))
    else
        return Mat4f(I)
    end
end

# =============================================================================
# Raster context creation
# =============================================================================

function _create_raster_context(scene::Makie.Scene, resolution)
    view_proj = Mat4f(scene.camera.projectionview[])
    proj = Mat4f(scene.camera.projection[])
    view_m = Mat4f(scene.camera.view[])
    near, far = _extract_near_far(scene, proj)
    return Overlay.RasterContext(
        view_proj, proj, view_m, Vec2f(resolution);
        px_per_unit=1f0, near=near, far=far,
    )
end

# Compute the NDC remap matrix for a child scene's viewport within the root.
# Maps child NDC → root NDC so that screen_x = (ndc_x * 0.5 + 0.5) * root_w
# gives correct pixel positions in the root buffer.
function _compute_viewport_remap(scene::Makie.Scene, root_resolution::Vec2f)
    vp = Makie.viewport(scene)[]
    vx, vy = Float32.(vp.origin)
    vw, vh = Float32.(Makie.widths(vp))
    rw, rh = root_resolution[1], root_resolution[2]
    return Mat4f(
        vw / rw,  0f0,      0f0, 0f0,
        0f0,      vh / rh,  0f0, 0f0,
        0f0,      0f0,      1f0, 0f0,
        (vw + 2f0 * vx - rw) / rw, (vh + 2f0 * vy - rh) / rh, 0f0, 1f0,
    )
end

# Create a raster context that remaps a child scene's camera into the root
# viewport coordinate system. This allows rendering all scenes' overlays into
# a single buffer (like OpenGL viewport rendering).
function _create_raster_context_remapped(scene::Makie.Scene, root_resolution::Vec2f)
    view_proj = Mat4f(scene.camera.projectionview[])
    proj = Mat4f(scene.camera.projection[])
    view_m = Mat4f(scene.camera.view[])
    near, far = _extract_near_far(scene, proj)

    remap = _compute_viewport_remap(scene, root_resolution)
    remapped_vp = remap * view_proj
    remapped_proj = remap * proj

    return Overlay.RasterContext(
        remapped_vp, remapped_proj, view_m, root_resolution;
        px_per_unit=1f0, near=near, far=far,
    )
end

function _extract_near_far(scene::Makie.Scene, proj::Mat4f)
    cc = scene.camera_controls
    if hasproperty(cc, :near) && hasproperty(cc, :far)
        near = Float32(cc.near[])
        far = Float32(cc.far[])
    else
        # Extract near/far from projection matrix (OpenGL convention)
        A = proj[3, 3]
        B = proj[3, 4]
        near = B / (A - 1f0)
        far = B / (A + 1f0)
        if !isfinite(near) || near <= 0f0
            near = 0.1f0
        end
        if !isfinite(far) || far <= near
            far = 1000f0
        end
    end
    return near, far
end

# =============================================================================
# Atlas GPU upload (cached)
# =============================================================================

function _get_gpu_atlas(overlay)
    atlas = Makie.get_texture_atlas()
    atlas_data = atlas.data
    backend = KernelAbstractions.get_backend(overlay)

    # Check if atlas has changed (size changes when new glyphs are rasterized)
    atlas_len = length(atlas_data)
    if _CACHED_ATLAS_SIZE[] == atlas_len && !isnothing(_CACHED_ATLAS[])
        gpu_atlas = _CACHED_ATLAS[]
        # Verify backend matches (could change between renders)
        if KernelAbstractions.get_backend(gpu_atlas) === backend
            # Makie atlas is stored as data[x, y]: dim1=width(U), dim2=height(V)
            aw = Int32(size(atlas_data, 1))
            ah = Int32(size(atlas_data, 2))
            return gpu_atlas, aw, ah
        end
    end

    # Upload atlas to GPU
    gpu_atlas = Adapt.adapt(backend, Float32.(atlas_data))
    _CACHED_ATLAS[] = gpu_atlas
    _CACHED_ATLAS_SIZE[] = atlas_len

    # Makie atlas is stored as data[x, y]: dim1=width(U), dim2=height(V)
    aw = Int32(size(atlas_data, 1))
    ah = Int32(size(atlas_data, 2))
    return gpu_atlas, aw, ah
end

# =============================================================================
# Per-type overlay rendering (dispatched from render_overlays!)
# =============================================================================

function _render_overlay_linesegments!(overlay, depth_buffer, ctx, robj)
    effective_ctx = _apply_model_to_ctx(ctx, robj)
    Overlay.rasterize_lines!(
        overlay, depth_buffer, effective_ctx,
        robj.positions, robj.style.color, robj.style.linewidth,
        robj.buffers;
        connect=false,
    )
end

function _render_overlay_lines!(overlay, depth_buffer, ctx, robj)
    effective_ctx = _apply_model_to_ctx(ctx, robj)
    Overlay.rasterize_lines!(
        overlay, depth_buffer, effective_ctx,
        robj.positions, robj.style.color, robj.style.linewidth,
        robj.buffers;
        connect=true,
    )
end

# Apply model_f32c from a renderobject to the raster context's view_proj.
# This ensures positions_transformed_f32c are correctly projected when model
# is not baked into positions (the common case for Axis3 etc.).
function _apply_model_to_ctx(ctx, robj)
    if !hasproperty(robj, :model)
        return ctx
    end
    model = robj.model
    model == Mat4f(I) && return ctx
    vp = ctx.view_proj * model
    return Overlay.RasterContext(
        vp, ctx.projection, ctx.view_mat, ctx.resolution;
        px_per_unit=ctx.px_per_unit, near=ctx.near, far=ctx.far,
    )
end

function _render_overlay_sprite!(
    overlay, depth_buffer, ctx, robj, gpu_atlas, atlas_w, atlas_h,
    marker_projection::Mat4f, preprojection::Mat4f, marker_pview::Mat4f,
)
    Overlay.rasterize_sprites!(
        overlay, depth_buffer, ctx,
        robj.positions,
        robj.quad_offsets,
        robj.quad_scales,
        robj.marker_offsets,
        robj.rotations,
        robj.colors,
        robj.uv_rects,
        robj.shapes,
        gpu_atlas, atlas_w, atlas_h;
        billboard=robj.billboard,
        scale_primitive=robj.scale_primitive,
        model=robj.model,
        marker_projection=marker_projection,
        preprojection=preprojection,
        marker_pview=marker_pview,
    )
end
