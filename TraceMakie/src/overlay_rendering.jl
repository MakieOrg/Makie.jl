# =============================================================================
# Overlay Plot Collection
# =============================================================================

"""
    get_overlay_plot_type(plot) -> Symbol or nothing

Determine if a plot should be rendered as an overlay and return its type.
"""
get_overlay_plot_type(::Makie.Plot{Makie.lines}) = :lines
get_overlay_plot_type(::Makie.Plot{Makie.linesegments}) = :linesegments
get_overlay_plot_type(::Makie.Plot{Makie.scatter}) = :scatter
get_overlay_plot_type(::Makie.Plot{Makie.text}) = :text
get_overlay_plot_type(::Makie.AbstractPlot) = nothing

"""
    collect_overlay_plots(mscene::Makie.Scene) -> Vector{OverlayPlotInfo}

Collect all plots that should be rendered as overlays (lines, scatter, text).
These are not converted to ray-traced geometry but rasterized in a separate pass.
Recursively collects from child scenes (handles LScene) and child plots (like Axis3D).
"""
function collect_overlay_plots(mscene::Makie.Scene)
    overlay_plots = OverlayPlotInfo[]
    collect_overlay_plots_from_scene!(overlay_plots, mscene)
    return overlay_plots
end

"""
    collect_overlay_plots_from_scene!(overlay_plots, scene)

Recursively collect overlay plots from a scene and all its child scenes.
"""
function collect_overlay_plots_from_scene!(overlay_plots::Vector{OverlayPlotInfo}, scene::Makie.Scene)
    # Collect from this scene's plots
    for plot in scene.plots
        collect_overlay_plots_recursive!(overlay_plots, plot)
    end
    # Recurse into child scenes (handles LScene nested structure)
    for child in scene.children
        collect_overlay_plots_from_scene!(overlay_plots, child)
    end
end

"""
    collect_overlay_plots_recursive!(overlay_plots, plot)

Recursively collect overlay plots from a plot and its children.
"""
function collect_overlay_plots_recursive!(overlay_plots::Vector{OverlayPlotInfo}, plot)
    # Check if this plot is an overlay type
    plot_type = get_overlay_plot_type(plot)
    if !isnothing(plot_type)
        push!(overlay_plots, OverlayPlotInfo(plot, plot_type))
    end

    # Recurse into child plots (for composite plots like Axis3D)
    if hasfield(typeof(plot), :plots) && !isempty(plot.plots)
        for child in plot.plots
            collect_overlay_plots_recursive!(overlay_plots, child)
        end
    end
end

# =============================================================================
# Overlay Rendering
# =============================================================================

"""
    render_overlays!(state::TraceMakieState, scene::Makie.Scene)

Render all overlay plots (lines, scatter, text) using the Overlay module.
Uses Makie's camera matrices to ensure overlay aligns with ray-traced content.
"""
function render_overlays!(state::TraceMakieState, scene::Makie.Scene)
    film = state.film
    overlay = state.overlay_buffer
    # Flip depth buffer Y to match overlay's flipped Y coordinates
    # Overlay uses Y flip (NDC Y=1 -> screen Y=0), so depth buffer needs same flip
    depth_buffer = reverse(film.depth, dims=1)

    # Clear overlay buffer
    Overlay.clear_overlay!(overlay)

    # Find the 3D scene for proper camera matrices (handles LScene nested structure)
    scene_3d = find_3d_scene(scene)
    if isnothing(scene_3d)
        @warn "No 3D scene found for overlay rendering"
        return  # No 3D scene found, skip overlay rendering
    end

    # Create raster context from Makie's camera (ensures correct projection)
    ctx = create_raster_context(scene_3d, film.resolution)

    # Render each overlay plot
    for info in state.overlay_plots
        render_overlay_plot!(overlay, depth_buffer, ctx, info)
    end
end

function create_raster_context(scene::Makie.Scene, resolution::Point2f)
    cc = scene.camera_controls
    view_proj = scene.camera.projectionview[]
    near = Float32(cc.near[])
    far = Float32(cc.far[])
    return Overlay.RasterContext(view_proj, Vec2f(resolution); near=near, far=far)
end

"""
    render_overlay_plot!(overlay, depth_buffer, ctx, info::OverlayPlotInfo)

Render a single overlay plot based on its type.
"""
function render_overlay_plot!(overlay, depth_buffer, ctx, info::OverlayPlotInfo)
    plot = info.plot

    if info.plot_type == :lines
        render_lines_overlay!(overlay, depth_buffer, ctx, plot)
    elseif info.plot_type == :linesegments
        render_linesegments_overlay!(overlay, depth_buffer, ctx, plot)
    elseif info.plot_type == :scatter
        render_scatter_overlay!(overlay, depth_buffer, ctx, plot)
    elseif info.plot_type == :text
        render_text_overlay!(overlay, depth_buffer, ctx, plot)
    end
end

"""
    render_lines_overlay!(overlay, depth_buffer, ctx, plot)

Render a lines plot as overlay.
"""
function render_lines_overlay!(overlay, depth_buffer, ctx, plot)
    # Extract positions from plot (converted is a Computed, [] unwraps to tuple)
    positions = plot.converted[][1]

    # Handle different position formats
    points = if positions isa AbstractVector{<:Point3f}
        positions
    elseif positions isa AbstractVector{<:Point2f}
        # Convert 2D to 3D (z=0)
        [Point3f(p[1], p[2], 0f0) for p in positions]
    else
        # Try to convert
        Point3f.(positions)
    end

    # Get color
    color_attr = haskey(plot.attributes, :color) ? plot.color[] : RGBAf(0, 0, 0, 1)
    color = to_overlay_color(color_attr)

    # Handle linewidth (can be scalar or vector, may be empty)
    lw_attr = haskey(plot.attributes, :linewidth) ? plot.linewidth[] : 1f0
    linewidth = if lw_attr isa AbstractVector
        isempty(lw_attr) ? 1f0 : Float32(first(lw_attr))
    else
        Float32(lw_attr)
    end

    Overlay.rasterize_lines!(overlay, depth_buffer, ctx, points, color, linewidth; connect=true)
end

"""
    render_linesegments_overlay!(overlay, depth_buffer, ctx, plot)

Render a linesegments plot as overlay.
"""
function render_linesegments_overlay!(overlay, depth_buffer, ctx, plot)
    positions = plot.converted[][1]

    points = if positions isa AbstractVector{<:Point3f}
        positions
    elseif positions isa AbstractVector{<:Point2f}
        [Point3f(p[1], p[2], 0f0) for p in positions]
    else
        Point3f.(positions)
    end

    color_attr = haskey(plot.attributes, :color) ? plot.color[] : RGBAf(0, 0, 0, 1)
    color = to_overlay_color(color_attr)

    # Handle linewidth (can be scalar or vector, may be empty)
    lw_attr = haskey(plot.attributes, :linewidth) ? plot.linewidth[] : 1f0
    linewidth = if lw_attr isa AbstractVector
        isempty(lw_attr) ? 1f0 : Float32(first(lw_attr))
    else
        Float32(lw_attr)
    end

    Overlay.rasterize_linesegments!(overlay, depth_buffer, ctx, points, color, linewidth)
end

"""
    render_scatter_overlay!(overlay, depth_buffer, ctx, plot)

Render a scatter plot as overlay.
"""
function render_scatter_overlay!(overlay, depth_buffer, ctx, plot)
    positions = plot.converted[][1]

    points = if positions isa AbstractVector{<:Point3f}
        positions
    elseif positions isa AbstractVector{<:Point2f}
        [Point3f(p[1], p[2], 0f0) for p in positions]
    else
        Point3f.(positions)
    end

    color_attr = haskey(plot.attributes, :color) ? plot.color[] : RGBAf(0, 0, 0, 1)
    color = to_overlay_color(color_attr)

    # Get marker size (can be scalar, Vec2, or vector)
    ms_attr = haskey(plot.attributes, :markersize) ? plot.markersize[] : 10f0
    markersize = if ms_attr isa Number
        Float32(ms_attr)
    elseif ms_attr isa Vec2f
        Float32(max(ms_attr[1], ms_attr[2]))  # Use max dimension
    elseif ms_attr isa AbstractVector
        isempty(ms_attr) ? 10f0 : Float32(first(ms_attr) isa Number ? first(ms_attr) : first(ms_attr)[1])
    else
        10f0
    end

    # Get marker shape
    marker = haskey(plot.attributes, :marker) ? plot.marker[] : :circle
    shape = marker_to_shape(marker)

    Overlay.rasterize_scatter!(overlay, depth_buffer, ctx, points, color, markersize, shape)
end

"""
    render_text_overlay!(overlay, depth_buffer, ctx, plot)

Render a text plot as overlay using Makie's computed glyph data.
"""
function render_text_overlay!(overlay, depth_buffer, ctx, plot)
    attr = plot.attributes

    # Check if computed attributes are available
    if !haskey(attr, :sdf_uv) || !haskey(attr, :quad_scale)
        @warn "Text plot missing computed glyph attributes" maxlog=1
        return
    end

    # Get computed glyph data
    sdf_uvs = attr[:sdf_uv][]              # Vec4f per glyph (u_min, v_min, u_max, v_max)
    quad_scales = attr[:quad_scale][]      # Vec2f per glyph
    quad_offsets = attr[:quad_offset][]    # Vec2f per glyph
    marker_offsets = attr[:marker_offset][] # Point3f per glyph (glyph origin + offset)

    # Get per-character positions (these are the text anchor positions, repeated per char)
    positions = if haskey(attr, :per_char_positions_transformed_f32c)
        attr[:per_char_positions_transformed_f32c][]
    else
        # Fallback to regular positions expanded
        pos = plot.converted[1][]
        blocks = attr[:text_blocks][]
        [pos[i] for (i, r) in enumerate(blocks) for _ in r]
    end

    # Get per-character colors
    colors = if haskey(attr, :text_color)
        [to_overlay_color(c) for c in attr[:text_color][]]
    else
        color_attr = haskey(attr, :color) ? plot.color[] : RGBAf(0, 0, 0, 1)
        fill(to_overlay_color(color_attr), length(sdf_uvs))
    end

    # Get rotations (per character)
    rotations = if haskey(attr, :text_rotation)
        attr[:text_rotation][]
    else
        fill(Quaternionf(0, 0, 0, 1), length(sdf_uvs))
    end

    # Get the texture atlas
    atlas = Makie.get_texture_atlas()
    atlas_data = atlas.data
    atlas_size = Vec2f(size(atlas_data, 2), size(atlas_data, 1))

    n_glyphs = length(sdf_uvs)
    n_glyphs == 0 && return

    # Render each glyph
    for i in 1:n_glyphs
        pos = positions[min(i, length(positions))]
        color = colors[min(i, length(colors))]
        uv_rect = sdf_uvs[i]
        scale = quad_scales[i]       # Screen-space glyph size in pixels
        offset = quad_offsets[i]      # Screen-space quad offset (fine positioning)
        marker_off = marker_offsets[i] # Screen-space offset from text anchor to glyph origin
        rotation = rotations[min(i, length(rotations))]

        # Convert position to Point3f
        world_pos = if pos isa Point3f
            pos
        elseif pos isa Point2f
            Point3f(pos[1], pos[2], 0f0)
        else
            Point3f(pos...)
        end

        # Project text anchor to screen space
        screen_anchor, depth, visible = Overlay.project(ctx, world_pos)
        !visible && continue

        # All offsets (marker_offset, quad_offset, quad_scale) are in screen pixels
        # marker_offset: offset from text anchor to this glyph's origin
        # quad_offset: fine offset for the glyph quad (e.g., for baseline alignment)
        # quad_scale: size of the glyph quad in screen pixels
        # Makie computes offsets for GLMakie where Y+ is up, but our screen has Y+ down
        # So we negate the Y components of the offsets
        screen_pos = Vec2f(
            screen_anchor[1] + marker_off[1] + offset[1],
            screen_anchor[2] - marker_off[2] - offset[2]
        )

        # quad_scale is already the screen-space glyph size
        glyph_width = scale[1]
        glyph_height = scale[2]

        # Create and render glyph instance
        glyph = Overlay.GlyphInstance(
            screen_pos,
            Vec2f(glyph_width, glyph_height),
            depth,
            uv_rect,
            color
        )

        render_single_glyph!(overlay, depth_buffer, glyph, atlas_data, atlas_size)
    end
end

"""
    render_single_glyph!(overlay, depth_buffer, glyph, atlas_data, atlas_size)

Render a single glyph to the overlay buffer.
"""
function render_single_glyph!(
    overlay::Matrix{RGBA{Float32}},
    depth_buffer::AbstractMatrix{Float32},
    glyph::Overlay.GlyphInstance,
    atlas_data::AbstractMatrix,
    atlas_size::Vec2f,
)
    h, w = size(overlay)

    # Skip tiny glyphs
    (glyph.screen_size[1] < 1f0 || glyph.screen_size[2] < 1f0) && return

    # Glyph bounding box in screen space
    min_x = max(1, floor(Int, glyph.screen_pos[1]))
    max_x = min(w, ceil(Int, glyph.screen_pos[1] + glyph.screen_size[1]))
    min_y = max(1, floor(Int, glyph.screen_pos[2]))
    max_y = min(h, ceil(Int, glyph.screen_pos[2] + glyph.screen_size[2]))

    # Early exit if completely outside screen
    (max_x < min_x || max_y < min_y) && return

    # UV bounds in atlas
    u_min, v_min, u_max, v_max = glyph.uv_bounds[1], glyph.uv_bounds[2], glyph.uv_bounds[3], glyph.uv_bounds[4]

    # Rasterize glyph quad
    for py in min_y:max_y
        for px in min_x:max_x
            # Compute UV within glyph [0, 1]
            # Flip local_v because GLMakie's quad origin is at bottom-left
            # but we iterate with py increasing downward from screen_pos (top)
            local_u = (Float32(px) - glyph.screen_pos[1]) / glyph.screen_size[1]
            local_v = 1f0 - (Float32(py) - glyph.screen_pos[2]) / glyph.screen_size[2]

            # Skip if outside glyph bounds
            (local_u < 0f0 || local_u > 1f0 || local_v < 0f0 || local_v > 1f0) && continue

            # Map to atlas UV coordinates (no flip - direct mapping)
            atlas_u = u_min + local_u * (u_max - u_min)
            atlas_v = v_min + local_v * (v_max - v_min)

            # Sample SDF from atlas (bilinear interpolation)
            sdf = sample_atlas_bilinear(atlas_data, atlas_size, atlas_u, atlas_v)

            # Depth test
            rt_depth = depth_buffer[py, px]
            depth_bias = 0.001f0 * glyph.depth
            glyph.depth > rt_depth + depth_bias && continue

            # The atlas SDF: edge is at glyph_padding (12), inside < 12, outside > 12
            # SDF values are in atlas pixel units
            edge_threshold = 12f0  # atlas.glyph_padding
            aa_width = 1.5f0
            coverage = clamp((edge_threshold - sdf + aa_width) / (2f0 * aa_width), 0f0, 1f0)
            coverage < 0.001f0 && continue

            # Apply alpha and blend
            alpha = glyph.color.alpha * coverage
            overlay[py, px] = Overlay.alpha_blend(
                RGBA{Float32}(glyph.color.r, glyph.color.g, glyph.color.b, alpha),
                overlay[py, px]
            )
        end
    end
end

"""
    sample_atlas_bilinear(atlas_data, atlas_size, u, v)

Sample the atlas with bilinear interpolation.
u, v are in [0, 1] normalized coordinates.
"""
@inline function sample_atlas_bilinear(
    atlas_data::AbstractMatrix,
    atlas_size::Vec2f,
    u::Float32,
    v::Float32,
)
    # Convert normalized UV to pixel coordinates
    # Atlas data is stored as Julia matrix with row 1 at top
    px = u * atlas_size[1]
    py = v * atlas_size[2]

    # Get integer and fractional parts
    x0 = floor(Int, px)
    y0 = floor(Int, py)
    x1 = x0 + 1
    y1 = y0 + 1
    fx = px - Float32(x0)
    fy = py - Float32(y0)

    # Clamp to valid range
    h, w = size(atlas_data)
    x0 = clamp(x0, 1, w)
    x1 = clamp(x1, 1, w)
    y0 = clamp(y0, 1, h)
    y1 = clamp(y1, 1, h)

    # Sample four corners (atlas is [row, col] = [y, x])
    v00 = Float32(atlas_data[y0, x0])
    v10 = Float32(atlas_data[y0, x1])
    v01 = Float32(atlas_data[y1, x0])
    v11 = Float32(atlas_data[y1, x1])

    # Bilinear interpolation
    v0 = v00 * (1f0 - fx) + v10 * fx
    v1 = v01 * (1f0 - fx) + v11 * fx
    return v0 * (1f0 - fy) + v1 * fy
end

# =============================================================================
# Color/Shape Utilities
# =============================================================================

"""
    to_overlay_color(color) -> RGBA{Float32}

Convert various color formats to RGBA{Float32} for overlay rendering.
"""
function to_overlay_color(color)
    if color isa RGBA{Float32}
        return color
    elseif color isa RGBA
        return RGBA{Float32}(color.r, color.g, color.b, color.alpha)
    elseif color isa RGB
        return RGBA{Float32}(color.r, color.g, color.b, 1f0)
    elseif color isa Colorant
        c = convert(RGBA{Float32}, color)
        return c
    else
        # Default to black
        return RGBA{Float32}(0f0, 0f0, 0f0, 1f0)
    end
end

"""
    marker_to_shape(marker) -> UInt8

Convert Makie marker symbol to Overlay shape constant.
"""
function marker_to_shape(marker)
    if marker == :circle || marker == :o
        return Overlay.CIRCLE
    elseif marker == :rect || marker == :square
        return Overlay.RECTANGLE
    elseif marker == :diamond
        return Overlay.DIAMOND
    elseif marker == :cross || marker == :+
        return Overlay.CROSS
    elseif marker == :utriangle || marker == :dtriangle || marker == :triangle
        return Overlay.TRIANGLE
    elseif marker == :hexagon
        return Overlay.HEXAGON
    elseif marker == :star || marker == :star5
        return Overlay.STAR
    else
        return Overlay.CIRCLE  # Default
    end
end
