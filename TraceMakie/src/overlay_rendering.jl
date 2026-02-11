# =============================================================================
# Overlay Rendering
# =============================================================================
# Iterates all plots with overlay trace_renderobjects and dispatches to
# KA rasterize kernels. No CPU for-loops that scalar-index GPU arrays.

# =============================================================================
# Main entry point
# =============================================================================

function render_overlays!(screen)
    state = screen.state
    scene = screen.scene
    film = state.film
    overlay = state.overlay_buffer

    # Flip depth buffer Y (film: row 1=bottom, overlay: row 1=top)
    Overlay.flip_depth_y!(state.depth_flipped, film.depth)

    # Clear overlay buffer
    Overlay.clear_overlay!(overlay)

    # Find the 3D scene for camera matrices
    scene_3d = find_3d_scene(scene)
    if isnothing(scene_3d)
        return
    end

    # Create raster context from Makie's camera
    ctx = _create_raster_context(scene_3d, film.resolution)

    # Iterate all atomic plots with overlay trace_renderobjects
    has_overlay = Ref(false)
    depth_buf = state.depth_flipped
    Makie.for_each_atomic_plot(scene) do p
        haskey(p, :trace_renderobject) || return nothing
        robj = try
            p[:trace_renderobject][]
        catch
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
        elseif rtype === :scatter
            _render_overlay_scatter!(overlay, depth_buf, ctx, robj)
            has_overlay[] = true
        elseif rtype === :text
            _render_overlay_text!(overlay, depth_buf, ctx, robj)
            has_overlay[] = true
        end
        return nothing
    end

    # Composite overlay onto postprocessed image
    if has_overlay[]
        DEBUG_OVERLAY[] = Array(overlay)
        Overlay.composite!(film.postprocess, overlay)
    end
end

function _create_raster_context(scene::Makie.Scene, resolution::Point2f)
    cc = scene.camera_controls
    view_proj = Mat4f(scene.camera.projectionview[])
    near = Float32(cc.near[])
    far = Float32(cc.far[])
    return Overlay.RasterContext(view_proj, Vec2f(resolution); near=near, far=far)
end

# =============================================================================
# Per-type overlay rendering (dispatched from render_overlays!)
# =============================================================================

function _render_overlay_linesegments!(overlay, depth_buffer, ctx, robj)
    Overlay.rasterize_lines!(
        overlay, depth_buffer, ctx,
        robj.positions, robj.style.color, robj.style.linewidth,
        robj.buffers;
        connect=false,
    )
end

function _render_overlay_lines!(overlay, depth_buffer, ctx, robj)
    Overlay.rasterize_lines!(
        overlay, depth_buffer, ctx,
        robj.positions, robj.style.color, robj.style.linewidth,
        robj.buffers;
        connect=true,
    )
end

function _render_overlay_scatter!(overlay, depth_buffer, ctx, robj)
    Overlay.rasterize_scatter!(
        overlay, depth_buffer, ctx,
        robj.positions, robj.style.color, robj.style.markersize,
        robj.style.shape, robj.buffers,
    )
end

# =============================================================================
# Text rendering
# =============================================================================
# Text uses Makie's SDF atlas and glyph layout — glyph data is computed on CPU,
# uploaded to GPU, and rasterized via the KA text kernel.

function _render_overlay_text!(overlay, depth_buffer, ctx, robj)
    plot = robj.plot
    attr = plot.attributes

    # Check if computed glyph attributes are available
    if !haskey(attr, :sdf_uv) || !haskey(attr, :quad_scale)
        return
    end

    # Get computed glyph data
    sdf_uvs = attr[:sdf_uv][]
    quad_scales = attr[:quad_scale][]
    quad_offsets = attr[:quad_offset][]
    marker_offsets = attr[:marker_offset][]

    # Get per-character positions
    positions = if haskey(attr, :per_char_positions_transformed_f32c)
        attr[:per_char_positions_transformed_f32c][]
    else
        pos = plot.converted[1][]
        blocks = attr[:text_blocks][]
        [pos[i] for (i, r) in enumerate(blocks) for _ in r]
    end

    # Get per-character colors
    colors = if haskey(attr, :text_color)
        Makie.to_color.(attr[:text_color][])
    else
        color_attr = haskey(attr, :color) ? plot.color[] : RGBAf(0, 0, 0, 1)
        fill(Makie.to_color(color_attr), length(sdf_uvs))
    end

    n_glyphs = length(sdf_uvs)
    n_glyphs == 0 && return

    # Get texture atlas
    atlas = Makie.get_texture_atlas()
    atlas_data = atlas.data
    atlas_size = Vec2f(size(atlas_data, 2), size(atlas_data, 1))

    # Compute glyph instances on CPU
    backend = KernelAbstractions.get_backend(overlay)
    glyph_screen_pos = Vector{Vec2f}(undef, n_glyphs)
    glyph_screen_sizes = Vector{Vec2f}(undef, n_glyphs)
    glyph_depths = Vector{Float32}(undef, n_glyphs)
    glyph_uv_bounds = Vector{Vec4f}(undef, n_glyphs)
    glyph_colors = Vector{RGBA{Float32}}(undef, n_glyphs)

    valid_count = 0
    for i in 1:n_glyphs
        pos = positions[min(i, length(positions))]
        world_pos = Makie.to_ndim(Point3f, pos, 0f0)

        screen_anchor, depth, visible = Overlay.project(ctx, world_pos)
        !visible && continue

        uv_rect = sdf_uvs[i]
        scale = quad_scales[i]
        offset = quad_offsets[i]
        marker_off = marker_offsets[i]

        screen_pos = Vec2f(
            screen_anchor[1] + marker_off[1] + offset[1],
            screen_anchor[2] - marker_off[2] - offset[2]
        )

        glyph_width = scale[1]
        glyph_height = scale[2]
        (glyph_width < 1f0 || glyph_height < 1f0) && continue

        valid_count += 1
        glyph_screen_pos[valid_count] = screen_pos
        glyph_screen_sizes[valid_count] = Vec2f(glyph_width, glyph_height)
        glyph_depths[valid_count] = depth
        glyph_uv_bounds[valid_count] = uv_rect
        glyph_colors[valid_count] = RGBA{Float32}(colors[min(i, length(colors))])
    end

    valid_count == 0 && return

    # Upload to GPU via adapt
    gpu_screen_pos = Adapt.adapt(backend, glyph_screen_pos[1:valid_count])
    gpu_screen_sizes = Adapt.adapt(backend, glyph_screen_sizes[1:valid_count])
    gpu_depths = Adapt.adapt(backend, glyph_depths[1:valid_count])
    gpu_uv_bounds = Adapt.adapt(backend, glyph_uv_bounds[1:valid_count])
    gpu_colors = Adapt.adapt(backend, glyph_colors[1:valid_count])

    # Upload atlas to GPU (TODO: cache this)
    gpu_atlas = Adapt.adapt(backend, Float32.(atlas_data))

    # Launch text kernel
    h, w = size(overlay)
    Overlay.rasterize_text_kernel!(backend)(
        overlay, depth_buffer,
        gpu_screen_pos, gpu_screen_sizes, gpu_depths, gpu_uv_bounds, gpu_colors,
        gpu_atlas, Int32(size(atlas_data, 2)), Int32(size(atlas_data, 1)),
        Int32(valid_count);
        ndrange=(w, h)
    )
    KernelAbstractions.synchronize(backend)
end

# =============================================================================
# Color/Shape Utilities
# =============================================================================

const MARKER_SHAPE_MAP = Dict{Symbol, UInt8}(
    :circle => Overlay.CIRCLE, :o => Overlay.CIRCLE,
    :rect => Overlay.RECTANGLE, :square => Overlay.RECTANGLE,
    :diamond => Overlay.DIAMOND,
    :cross => Overlay.CROSS, :+ => Overlay.CROSS,
    :utriangle => Overlay.TRIANGLE, :dtriangle => Overlay.TRIANGLE, :triangle => Overlay.TRIANGLE,
    :hexagon => Overlay.HEXAGON,
    :star => Overlay.STAR, :star5 => Overlay.STAR,
)

marker_to_shape(marker::Symbol) = get(MARKER_SHAPE_MAP, marker, Overlay.CIRCLE)
marker_to_shape(::Any) = Overlay.CIRCLE
