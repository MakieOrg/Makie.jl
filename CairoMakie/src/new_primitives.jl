function cairo_colors(@nospecialize(plot), color_name = :scaled_color)
    Makie.add_computation!(plot.attributes, Val(:computed_color), color_name)
    return plot.computed_color[]
end

function cairo_project_to_screen_impl(projectionview, resolution, model, pos, output_type = Point2f, yflip = true)
    # the existing methods include f32convert matrices which are already
    # applied in :positions_transformed_f32c (using this makes CairoMakie
    # less performant (extra O(N) step) but allows code reuse with other backends)
    M = cairo_viewport_matrix(resolution, yflip) * projectionview * model
    return project_position(output_type, M, pos, eachindex(pos))
end

function cairo_project_to_screen_impl(projectionview, resolution, model, pos::VecTypes, output_type = Point2f, yflip = true)
    p4d = to_ndim(Point4d, to_ndim(Point3d, pos, 0), 1)
    p4d = model * p4d
    p4d = projectionview * p4d
    p4d = cairo_viewport_matrix(resolution, yflip) * p4d
    return output_type(p4d) / p4d[4]
end

function cairo_project_to_screen(
        @nospecialize(plot::Plot);
        input_name = :positions_transformed_f32c, yflip = true, output_type = Point2f
    )

    attr = plot.attributes::Makie.ComputeGraph

    Makie.register_computation!(attr,
            [:projectionview, :resolution, :model_f32c, input_name], [:cairo_screen_pos]
        ) do inputs, changed, cached

        output = cairo_project_to_screen_impl(values(inputs)..., output_type, yflip)
        return (output,)
    end

    return attr[:cairo_screen_pos][]
end

# TODO: This stack should be generalized and moved to Makie
function cairo_project_to_markerspace_impl(preprojection, model, pos, output_type = Point3f)
    # the existing methods include f32convert matrices which are already
    # applied in :positions_transformed_f32c (using this makes CairoMakie
    # less performant (extra O(N) step) but allows code reuse with other backends)
    return project_position(output_type, preprojection * model, pos, eachindex(pos))
end

function cairo_project_to_markerspace(
        @nospecialize(plot::Plot);
        input_name = :positions_transformed_f32c, output_type = Point3d
    )

    attr = plot.attributes::Makie.ComputeGraph

    Makie.register_computation!(attr,
            [:preprojection, :model_f32c, input_name], [:cairo_markerspace_pos]
        ) do inputs, changed, cached

        output = cairo_project_to_markerspace_impl(inputs..., output_type)
        return (output,)
    end

    return attr[:cairo_markerspace_pos][]
end

function cairo_unclipped_indices(attr::Makie.ComputeGraph)
    Makie.register_computation!(attr,
        [:positions_transformed_f32c, :model_f32c, :space, :clip_planes],
        [:unclipped_indices]
    ) do (transformed, model, space, clip_planes), changed, outputs
        return (unclipped_indices(to_model_space(model, clip_planes), transformed, space),)
    end

    return attr[:unclipped_indices][]
end


################################################################################
#                             Lines, LineSegments                              #
################################################################################


function draw_atomic(scene::Scene, screen::Screen, plot::PT) where {PT <: Union{Lines, LineSegments}}
    linewidth = plot.uniform_linewidth[]
    color = plot.scaled_color[]
    linestyle, space, model = plot.linestyle[], plot.space[], plot.model[]
    ctx = screen.context
    positions = plot.positions[]

    isempty(positions) && return

    # color is now a color or an array of colors
    # if it's an array of colors, each segment must be stroked separately
    color = cairo_colors(plot, ifelse(PT <: Lines, :scaled_color, :synched_color))

    # Lines need to be handled more carefully with perspective projections to
    # avoid them inverting.
    # TODO: If we have neither perspective projection not clip_planes we can
    #       use the normal projection_position() here
    projected_positions, color, linewidth = project_line_points(scene, plot, positions, color, linewidth)

    # The linestyle can be set globally, as we do here.
    # However, there is a discrepancy between Makie
    # and Cairo when it comes to linestyles.
    # For Makie, the linestyle array is cumulative,
    # and defines the "absolute" endpoints of segments.
    # However, for Cairo, each value provides the length of
    # alternate "on" and "off" portions of the stroke.
    # Therefore, we take the diff of the given linestyle,
    # to convert the "absolute" coordinates into "relative" ones.
    if !isnothing(linestyle) && !(linewidth isa AbstractArray)
        pattern = diff(Float64.(linestyle)) .* linewidth
        isodd(length(pattern)) && push!(pattern, 0)
        Cairo.set_dash(ctx, pattern)
    end

    # linecap
    linecap = plot.linecap[]
    if linecap == 1
        Cairo.set_line_cap(ctx, Cairo.CAIRO_LINE_CAP_SQUARE)
    elseif linecap == 2
        Cairo.set_line_cap(ctx, Cairo.CAIRO_LINE_CAP_ROUND)
    elseif linecap == 0
        Cairo.set_line_cap(ctx, Cairo.CAIRO_LINE_CAP_BUTT)
    else
        error("$linecap is not a valid linecap. Valid: 0 (:butt), 1 (:square), 2 (:round)")
    end

    # joinstyle
    attr = plot.attributes
    miter_angle = plot isa Lines ? attr.outputs[:miter_limit][] : 2pi/3
    set_miter_limit(ctx, 2.0 * Makie.miter_angle_to_distance(miter_angle))

    joinstyle = plot isa Lines ? attr.outputs[:joinstyle][] : linecap
    if joinstyle == 2
        Cairo.set_line_join(ctx, Cairo.CAIRO_LINE_JOIN_ROUND)
    elseif joinstyle == 3
        Cairo.set_line_join(ctx, Cairo.CAIRO_LINE_JOIN_BEVEL)
    elseif joinstyle == 0
        Cairo.set_line_join(ctx, Cairo.CAIRO_LINE_JOIN_MITER)
    else
        error("$linecap is not a valid linecap. Valid: 0 (:miter), 2 (:round), 3 (:bevel)")
    end

    # TODO, how do we allow this conversion?s
    if plot isa Lines && to_value(plot.attributes) isa BezierPath
        return draw_bezierpath_lines(ctx, to_value(plot.attributes), plot, color, space, model, linewidth)
    end

    if color isa AbstractArray || linewidth isa AbstractArray
        # stroke each segment separately, this means disjointed segments with probably
        # wonky dash patterns if segments are short
        draw_multi(
            plot, ctx,
            projected_positions,
            color, linewidth,
            isnothing(linestyle) ? nothing : diff(Float64.(linestyle))
        )
    else
        # stroke the whole line at once if it has only one color
        # this allows correct linestyles and line joins as well and will be the
        # most common case
        Cairo.set_line_width(ctx, linewidth)
        Cairo.set_source_rgba(ctx, red(color), green(color), blue(color), alpha(color))
        draw_single(plot, ctx, projected_positions)
    end
    nothing
end


################################################################################
#                                   Scatter                                    #
################################################################################


function draw_atomic(scene::Scene, screen::Screen, @nospecialize(p::Scatter))
    isempty(p.positions_transformed_f32c[]) && return
    attr = p.attributes

    Makie.add_computation!(attr, scene, Val(:meshscatter_f32c_scale))

    @get_attribute(p, (
        markersize, strokecolor, strokewidth, marker, marker_offset,
        converted_rotation, billboard, transform_marker, model, markerspace,
        space, clip_planes, f32c_scale
    ))

    Makie.register_computation!(attr, [:marker], [:cairo_marker]) do (marker,), changed, outputs
        return (cairo_scatter_marker(marker),)
    end

    # TODO: This requires (cam.projectionview, resolution) as inputs otherwise
    #       the output can becomes invalid from render to render.
    indices = cairo_unclipped_indices(attr)
    markerspace_pos = cairo_project_to_markerspace(p)
    # ^ if some positions get clipped they still get transformed here because they
    # need to synchronize with other attributes

    marker = p.cairo_marker[] # this goes through CairoMakie's conversion system and not Makie's...
    ctx = screen.context
    size_model = transform_marker ? model[Vec(1,2,3), Vec(1,2,3)] : Mat3d(I)
    size_model = Mat3d(f32c_scale[1], 0, 0, 0, f32c_scale[2], 0, 0, 0, f32c_scale[3]) * size_model

    font = p.font[]
    colors = cairo_colors(p)

    return draw_atomic_scatter(
        scene, ctx, markerspace_pos, indices, colors, markersize, strokecolor, strokewidth,
        marker, marker_offset, converted_rotation, size_model, font, markerspace, billboard
    )
end

is_approx_zero(x) = isapprox(x, 0)
is_approx_zero(v::VecTypes) = any(x -> isapprox(x, 0), v)

function is_degenerate(M::Mat2f)
    v1 = M[Vec(1,2), 1]
    v2 = M[Vec(1,2), 2]
    l1 = dot(v1, v1)
    l2 = dot(v2, v2)
    # Bad cases:   nan   ||     0 vector     ||   linearly dependent
    return any(isnan, M) || l1 ≈ 0 || l2 ≈ 0 || dot(v1, v2)^2 ≈ l1 * l2
end

function draw_atomic_scatter(
        scene, ctx, markerspace_positions, indices, colors, markersize, strokecolor, strokewidth,
        marker, marker_offset, rotation, size_model, font, markerspace, billboard
    )

    Makie.broadcast_foreach_index(indices, markerspace_positions, colors, markersize, strokecolor,
        strokewidth, marker, marker_offset, remove_billboard(rotation)) do ms_pos, col,
        markersize, strokecolor, strokewidth, m, mo, rotation

        isnan(ms_pos) && return
        isnan(rotation) && return # matches GLMakie
        (isnan(markersize) || is_approx_zero(markersize)) && return

        o = ms_pos .+ size_model * to_ndim(Vec3d, mo, 0)
        proj_pos, mat, jl_mat = project_marker(scene, markerspace, o,
            markersize, rotation, size_model, billboard) # to pixel space

        # mat and jl_mat are the same matrix, once as a CairoMatrix, once as a Mat2f
        # They both describe an approximate basis transformation matrix from
        # marker space to pixel space with scaling appropriate to markersize.
        # Markers that can be drawn from points/vertices of shape (e.g. Rect)
        # could be projected more accurately by projecting each point individually
        # and then building the shape.

        # make sure the matrix is not degenerate
        is_degenerate(jl_mat) && return

        Cairo.set_source_rgba(ctx, rgbatuple(col)...)
        Cairo.save(ctx)
        if m isa Char
            draw_marker(ctx, m, best_font(m, font), proj_pos, strokecolor, strokewidth, jl_mat, mat)
        else
            draw_marker(ctx, m, proj_pos, strokecolor, strokewidth, mat)
        end
        Cairo.restore(ctx)
    end

    return
end


################################################################################
#                                     Text                                     #
################################################################################


function draw_atomic(scene::Scene, screen::Screen, @nospecialize(primitive::Text))
    # :text_strokewidth # TODO: missing, but does per-glyph strokewidth even work? Same for strokecolor?
    @get_attribute(primitive, (
        text_blocks,
        font_per_char,
        glyphindices,
        marker_offset,
        text_rotation,
        text_scales,
        text_strokewidth,
        text_strokecolor,
        markerspace,
        transform_marker,
        text_color
    ))

    ctx = screen.context
    attr = primitive.attributes::Makie.ComputeGraph

    # input -> markerspace
    # TODO: This sucks, we're doing per-string/glyphcollection work per glyph here
    valid_indices = cairo_unclipped_indices(attr)
    markerspace_positions = cairo_project_to_markerspace(primitive)

    model33 = transform_marker ? primitive.model[][Vec(1, 2, 3), Vec(1, 2, 3)] : Mat3d(I)
    if !isnothing(scene.float32convert) && Makie.is_data_space(markerspace)
        model33 = Makie.scalematrix(scene.float32convert.scaling[].scale::Vec3d)[Vec(1,2,3), Vec(1,2,3)] * model33
    end

    for (block_idx, glyph_indices) in enumerate(text_blocks)

        Cairo.save(ctx)

        for glyph_idx in glyph_indices
            glyph_idx in valid_indices || continue

            glyph = glyphindices[glyph_idx]
            offset = marker_offset[glyph_idx]
            font = font_per_char[glyph_idx]
            rotation = Makie.sv_getindex(text_rotation, glyph_idx)
            color = Makie.sv_getindex(text_color, glyph_idx)
            strokewidth = Makie.sv_getindex(text_strokewidth, glyph_idx)
            strokecolor = Makie.sv_getindex(text_strokecolor, glyph_idx)
            scale = Makie.sv_getindex(text_scales, glyph_idx)

            glyph_pos = markerspace_positions[glyph_idx]

            # Not renderable by font (e.g. '\n')
            # TODO, filter out \n in GlyphCollection, and render unrenderables as box
            glyph == 0 && continue

            cairoface = set_ft_font(ctx, font)
            old_matrix = get_font_matrix(ctx)

            Cairo.save(ctx)
            Cairo.set_source_rgba(ctx, rgbatuple(color)...)

            # offsets and scale apply in markerspace
            gp3 = glyph_pos .+ model33 * offset

            if any(isnan, gp3)
                Cairo.restore(ctx)
                continue
            end

            scale2 = scale isa Number ? Vec2d(scale, scale) : scale
            glyphpos, mat, _ = project_marker(scene, markerspace, gp3, scale2, rotation, model33)

            Cairo.save(ctx)
            set_font_matrix(ctx, mat)
            show_glyph(ctx, glyph, glyphpos...)
            Cairo.restore(ctx)

            if strokewidth > 0 && strokecolor != RGBAf(0, 0, 0, 0)
                Cairo.save(ctx)
                Cairo.move_to(ctx, glyphpos...)
                set_font_matrix(ctx, mat)
                glyph_path(ctx, glyph, glyphpos...)
                Cairo.set_source_rgba(ctx, rgbatuple(strokecolor)...)
                Cairo.set_line_width(ctx, strokewidth)
                Cairo.stroke(ctx)
                Cairo.restore(ctx)
            end
            Cairo.restore(ctx)

            cairo_font_face_destroy(cairoface)
            set_font_matrix(ctx, old_matrix)
        end

        Cairo.restore(ctx)
    end

    nothing
end


################################################################################
#                                Heatmap, Image                                #
################################################################################

#=
Image:
- positions_transformed_f32c are rect vertices
Heatmap:
- nope
- heatmap transform adds x_transformed_f32c, y_transformed_f32c
=#

function image_grid(@nospecialize(primitive::Heatmap))
    Makie.add_computation!(primitive.attributes, nothing, Val(:heatmap_transform))
    xs = regularly_spaced_array_to_range(primitive.x_transformed_f32c[])
    ys = regularly_spaced_array_to_range(primitive.y_transformed_f32c[])
    return xs, ys
end
function image_grid(@nospecialize(primitive::Image))
    # Rect vertices
    (x0, y0), _, (x1, y1), _ = primitive.positions_transformed_f32c[]
    image = primitive.image[]
    xs = range(x0, x1, length = size(image, 1) + 1)
    ys = range(y0, y1, length = size(image, 2) + 1)
    return xs, ys
end


# Note: Changed very little here
function draw_atomic(scene::Scene, screen::Screen{RT}, @nospecialize(primitive::Union{Heatmap, Image})) where RT
    @get_attribute(primitive, (interpolate, space, image, projectionview, resolution))
    ctx = screen.context

    xs, ys = image_grid(primitive)
    model = primitive.model_f32c[]

    # Vector backends don't support FILTER_NEAREST for interp == false, so in that case we also need to draw rects
    is_vector = is_vector_backend(ctx)
    # transform_func is already included in xs, ys, so we can see its effect in is_regular_grid
    is_identity_transform = Makie.is_translation_scale_matrix(model)
    is_regular_grid = xs isa AbstractRange && ys isa AbstractRange
    is_xy_aligned = Makie.is_translation_scale_matrix(projectionview)

    if interpolate
        if !is_regular_grid
            error("$(typeof(primitive).parameters[1]) with interpolate = true with a non-regular grid is not supported right now.")
        end
        if !is_identity_transform
            error("$(typeof(primitive).parameters[1]) with interpolate = true with a non-identity transform is not supported right now.")
        end
    end

    # find projected image corners
    # this already takes care of flipping the image to correct cairo orientation

    xy    = cairo_project_to_screen_impl(projectionview, resolution, model, Point2(first(xs), first(ys)))
    xymax = cairo_project_to_screen_impl(projectionview, resolution, model, Point2(last(xs), last(ys)))

    w, h = xymax .- xy

    uv_transform = if primitive isa Image
        T = primitive.uv_transform[]
        # Cairo uses pixel units so we need to transform those to a 0..1 range,
        # then apply uv_transform, then scale them back to pixel units.
        # Cairo also doesn't have the yflip we have in OpenGL, so we need to
        # invert y.
        T3 = Mat3f(T[1], T[2], 0, T[3], T[4], 0, T[5], T[6], 1)
        T3 = Makie.uv_transform(Vec2f(size(image))) * T3 *
            Makie.uv_transform(Vec2f(0, 1), 1f0 ./ Vec2f(size(image, 1), -size(image, 2)))
        T3[Vec(1, 2), Vec(1,2,3)]
    else
        Mat{2, 3, Float32}(1,0,0,1,0,0)
    end

    can_use_fast_path = !(is_vector && !interpolate) && is_regular_grid && is_identity_transform &&
        (interpolate || is_xy_aligned) && isempty(primitive.clip_planes[])

    # Debug attribute we can set to disable fastpath
    # probably shouldn't really be part of the interface
    use_fast_path = can_use_fast_path && to_value(get(primitive, :fast_path, true))::Bool

    color_image = cairo_colors(primitive)

    if use_fast_path
        s = to_cairo_image(color_image)

        weird_cairo_limit = (2^15) - 23
        if s.width > weird_cairo_limit || s.height > weird_cairo_limit
            error("Cairo stops rendering images bigger than $(weird_cairo_limit), which is likely a bug in Cairo. Please resample your image/heatmap with heatmap(Resampler(data)).")
        end
        Cairo.rectangle(ctx, xy..., w, h)
        Cairo.save(ctx)
        Cairo.translate(ctx, xy...)
        Cairo.scale(ctx, w / s.width, h / s.height)
        Cairo.set_source_surface(ctx, s, 0, 0)
        p = Cairo.get_source(ctx)
        if RT !== SVG
            # this is needed to avoid blurry edges in png renderings, however since Cairo 1.18 this
            # setting seems to create broken SVGs
            Cairo.pattern_set_extend(p, Cairo.EXTEND_PAD)
        end
        filt = interpolate ? Cairo.FILTER_BILINEAR : Cairo.FILTER_NEAREST
        Cairo.pattern_set_filter(p, filt)
        pattern_set_matrix(p, Cairo.CairoMatrix(uv_transform...))
        Cairo.fill(ctx)
        Cairo.restore(ctx)
        pattern_set_matrix(p, Cairo.CairoMatrix(1, 0, 0, 1, 0, 0))
    else
        # find projected image corners
        # this already takes care of flipping the image to correct cairo orientation
        space = primitive.space[]
        xys = let
            transformed = [Point2f(x, y) for x in xs, y in ys]

            # This should transform to the coordinate system transformed is in,
            # which is pre model_f32c application, not pre model application
            planes = if Makie.is_data_space(space)
                to_model_space(model, primitive.clip_planes[])
            else
                Plane3f[]
            end

            for i in eachindex(transformed)
                if is_clipped(planes, transformed[i])
                    transformed[i] = Point2f(NaN)
                end
            end

            cairo_project_to_screen_impl(projectionview, resolution, model, transformed)
        end

        # Note: xs and ys should have size ni+1, nj+1
        ni, nj = size(image)
        if ni + 1 != length(xs) || nj + 1 != length(ys)
            error("Error in conversion pipeline. xs and ys should have size ni+1, nj+1. Found: xs: $(length(xs)), ys: $(length(ys)), ni: $(ni), nj: $(nj)")
        end
        _draw_rect_heatmap(ctx, xys, ni, nj, color_image)
    end
end


################################################################################
#                                     Mesh                                     #
################################################################################


function draw_atomic(scene::Scene, screen::Screen, @nospecialize(primitive::Makie.Mesh))
    if Makie.cameracontrols(scene) isa Union{Camera2D, Makie.PixelCamera, Makie.EmptyCamera}
        draw_mesh2D(scene, screen, primitive)
    else
        draw_mesh3D(scene, screen, primitive)
    end
    return nothing
end

function draw_mesh2D(scene, screen, @nospecialize(plot::Makie.Mesh))
    # TODO: no clip_planes?
    vs = cairo_project_to_screen(plot)
    fs = plot.faces[]
    uv = plot.texturecoordinates[]
    uv_transform = plot.pattern_uv_transform[]
    if uv isa Vector{Vec2f} && to_value(uv_transform) !== nothing
        uv = map(uv -> uv_transform * to_ndim(Vec3f, uv, 1), uv)
    end
    color = cairo_colors(plot)
    cols = per_face_colors(color, nothing, fs, nothing, uv)
    if cols isa Cairo.CairoPattern
        align_pattern(cols, scene, plot.model[])
    end
    return draw_mesh2D(screen, cols, vs, fs)
end

# Mesh + surface entry point
function draw_mesh3D(scene, screen, @nospecialize(plot::Plot))
    @get_attribute(plot, (clip_planes, ))
    uv_transform = plot.pattern_uv_transform[]

    # per-element in meshscatter
    world_points = Makie.apply_model(plot.model_f32c[], plot.positions_transformed_f32c[])
    screen_points = cairo_project_to_screen(plot, output_type = Point3f)
    meshfaces = plot.faces[]
    meshnormals = plot.normals[]
    _meshuvs = plot.texturecoordinates[]

    if (_meshuvs isa AbstractVector{<:Vec3})
        error("Only 2D texture coordinates are supported right now. Use GLMakie for 3D textures.")
    end
    meshuvs::Union{Nothing,Vector{Vec2f}} = _meshuvs

    color = cairo_colors(plot)

    draw_mesh3D(
        scene, screen, plot,
        world_points, screen_points, meshfaces, meshnormals, meshuvs,
        uv_transform, color, clip_planes
    )
end

function draw_mesh3D(
        scene, screen, @nospecialize(plot::Plot),
        world_points, screen_points, meshfaces, meshnormals, meshuvs,
        uv_transform, color, clip_planes, model = plot.model_f32c[]::Mat4f
    )

    @get_attribute(plot, (shading, diffuse, specular, shininess, faceculling))

    shading = shading && (scene.compute.shading[] != NoShading)

    if meshuvs isa Vector{Vec2f} && to_value(uv_transform) !== nothing
        meshuvs = map(uv -> uv_transform * to_ndim(Vec3f, uv, 1), meshuvs)
    end

    matcap = to_value(get(plot, :matcap, nothing))
    per_face_col = per_face_colors(color, matcap, meshfaces, meshnormals, meshuvs)

    space = plot.space[]::Symbol
    if per_face_col isa Cairo.CairoPattern
        # plot.model_f32c[] is f32c corrected, not f32c * model
        f32c_model = Makie.f32_convert_matrix(scene.float32convert, space) * plot.model[]
        align_pattern(per_face_col, scene, f32c_model)
    end

    if !isnothing(meshnormals) && to_value(get(plot, :invert_normals, false))
        meshnormals .= -meshnormals
    end

    faceculling = to_value(get(plot, :faceculling, -10))

    draw_mesh3D(
        scene, screen, space, world_points, screen_points, meshfaces, meshnormals, per_face_col,
        model, shading::Bool, diffuse::Vec3f,
        specular::Vec3f, shininess::Float32, faceculling::Int, clip_planes, plot.eyeposition[]
    )
end

to_vec(c::Colorant) = Vec3f(red(c), green(c), blue(c))

function draw_mesh3D(
        scene, screen, space, world_points, screen_points, meshfaces, meshnormals, per_face_col,
        model, shading, diffuse, specular, shininess, faceculling, clip_planes, eyeposition
    )
    ctx = screen.context

    # local_model applies rotation and markersize from meshscatter to vertices
    i = Vec(1, 2, 3)
    normalmatrix = transpose(inv(model[i, i])) # see issue #3702

    if Makie.is_data_space(space) && !isempty(clip_planes)
        valid = Bool[is_visible(clip_planes, p) for p in world_points]
    else
        valid = Bool[]
    end

    # Approximate zorder
    average_zs = map(f -> average_z(screen_points, f), meshfaces)
    zorder = sortperm(average_zs)

    if isnothing(meshnormals)
        ns = nothing
    else
        ns = map(n -> normalize(normalmatrix * n), meshnormals)
    end

    # Face culling
    if isempty(valid) && !isnothing(ns)
        zorder = filter(i -> any(last.(ns[meshfaces[i]]) .> faceculling), zorder)
    elseif !isempty(valid)
        zorder = filter(i -> all(valid[meshfaces[i]]), zorder)
    else
        # no clipped faces, no normals to rely on for culling -> do nothing
    end

    # If per_face_col is a CairoPattern the plot is using an AbstractPattern
    # as a color. In this case we don't do shading and fall back to mesh2D
    # rendering
    if per_face_col isa Cairo.CairoPattern
        return draw_mesh2D(ctx, per_face_col, screen_points, meshfaces, reverse(zorder))
    end

    ambient = to_vec(scene.compute[:ambient_color][])
    light_color = to_vec(scene.compute[:dirlight_color][])
    light_direction = scene.compute[:dirlight_final_direction][]

    # vs are used as camdir (camera to vertex) for light calculation (in world space)
    vs = map(v -> normalize(to_ndim(Point3f, v, 0) - eyeposition), world_points)

    draw_pattern(
        ctx, zorder, shading, meshfaces, screen_points, per_face_col, ns, vs,
        light_direction, light_color, shininess, diffuse, ambient, specular)

    return
end


################################################################################
#                                   Surface                                    #
################################################################################


function draw_atomic(scene::Scene, screen::Screen, @nospecialize(primitive::Makie.Surface))
    attr = primitive.attributes::Makie.ComputeGraph

    # Generate mesh from surface data and add its data to the compute graph.
    # Use that to draw surface as a mesh
    Makie.register_computation!(attr,
            [:x, :y, :z], [:positions, :faces, :texturecoordinates, :normals]
        ) do (x, y, z), changed, cached

        # (x, y, z) are generated after convert_arguments and dim_converts,
        # before apply_transform and
        m = Makie.surface2mesh(x, y, z)
        return coordinates(m), decompose(GLTriangleFace, m), texturecoordinates(m), normals(m)
    end

    # TODO: Should we always have this registered for positions derived from x, y, z?
    #       That can coexist with range/vector path in GL backends...
    #       Note that surface2mesh may not be compatible with the order used in
    #       GL backends.
    Makie.register_position_transforms!(attr)
    Makie.register_pattern_uv_transform!(attr)

    draw_mesh3D(scene, screen, primitive)
    return nothing
end


################################################################################
#                                 MeshScatter                                  #
################################################################################


function draw_atomic(scene::Scene, screen::Screen, @nospecialize(primitive::Makie.MeshScatter))
    @get_attribute(primitive, (
        model_f32c, marker, markersize, rotation, positions_transformed_f32c,
        clip_planes, transform_marker))

    # We combine vertices and positions in world space.
    # Here we do the transformation to world space of meshscatter args
    # The rest happens in draw_scattered_mesh()
    transformed_pos = Makie.apply_model(model_f32c, positions_transformed_f32c)
    colors = cairo_colors(primitive)
    uv_transform = primitive.pattern_uv_transform[]

    draw_scattered_mesh(
        scene, screen, primitive, marker,
        transformed_pos, markersize, rotation, colors,
        clip_planes, transform_marker, uv_transform
    )
end

function draw_scattered_mesh(
        scene, screen, @nospecialize(plot::Plot), mesh,
        # positions in world space, acting as translations for mesh
        positions, scales, rotations, colors,
        clip_planes, transform_marker, uv_transform
    )
    @get_attribute(plot, (model, space))

    meshpoints = decompose(Point3f, mesh)
    meshfaces = decompose(GLTriangleFace, mesh)
    meshnormals = normals(mesh)
    meshuvs = texturecoordinates(mesh)

    # transformation matrix to mesh into world space, see loop
    f32c_model = ifelse(transform_marker, strip_translation(plot.model[]), Mat4d(I))
    if !isnothing(scene.float32convert) && Makie.is_data_space(space)
        f32c_model = Makie.scalematrix(scene.float32convert.scaling[].scale::Vec3d) * f32c_model
    end

    # Z sorting based on meshscatter arguments
    # For correct z-ordering we need to be in view/camera or screen space
    view = plot.view[]
    zorder = sortperm(positions, by = p -> begin
        p4d = to_ndim(Vec4d, p, 1)
        cam_pos = view[Vec(3,4), Vec(1,2,3,4)] * p4d
        cam_pos[1] / cam_pos[2]
    end, rev=false)

    proj_mat = cairo_viewport_matrix(plot.resolution[]) * plot.projectionview[]

    for i in zorder
        # Get per-element data
        element_color = Makie.sv_getindex(colors, i)
        element_uv_transform = Makie.sv_getindex(uv_transform, i)
        element_translation = to_ndim(Point4d, positions[i], 0)
        element_rotation = Makie.rotationmatrix4(Makie.sv_getindex(rotations, i))
        element_scale = Makie.scalematrix(Makie.sv_getindex(scales, i))
        element_transform = element_rotation * element_scale # different order from transformationmatrix()

        # TODO: Should we cache this? Would be a lot of data...
        # mesh transformations
        # - transform_func does not apply to vertices (only pos)
        # - only scaling from float32convert applies to vertices
        #   f32c_scale * (maybe model) *  rotation * scale * vertices  +  f32c * model * transform_func(plot[1])
        # =        f32c_model          * element_transform * vertices  +       element_translation
        element_world_pos = map(meshpoints) do p
            p4d = to_ndim(Point4d, to_ndim(Point3d, p, 0), 1)
            p4d = f32c_model * element_transform * p4d + element_translation
            return Point3f(p4d) / p4d[4]
        end

        # TODO: And this?
        element_screen_pos = project_position(Point3f, proj_mat, element_world_pos, eachindex(element_world_pos))

        draw_mesh3D(
            scene, screen, plot,
            element_world_pos, element_screen_pos, meshfaces, meshnormals, meshuvs,
            element_uv_transform, element_color, clip_planes, f32c_model * element_transform
        )
    end

    return nothing
end


################################################################################
#                                    Voxel                                     #
################################################################################


function draw_atomic(scene::Scene, screen::Screen, @nospecialize(primitive::Makie.Voxels))
    pos = Makie.voxel_positions(primitive)
    scale = Makie.voxel_size(primitive)
    colors = Makie.voxel_colors(primitive)
    marker = GeometryBasics.expand_faceviews(normal_mesh(Rect3f(Point3f(-0.5), Vec3f(1))))

    # transformation to world space
    transformed_pos = _transform_to_world(scene, primitive, pos)

    # clip full voxel instead of faces
    if !isempty(primitive.clip_planes[]) && Makie.is_data_space(primitive)
        valid = [is_visible(primitive.clip_planes[], p) for p in transformed_pos]
        transformed_pos = transformed_pos[valid]
        colors = colors[valid]
    end

    # sneak in model_f32c so we don't have to pass through another variable
    Makie.register_computation!(primitive.attributes::Makie.ComputeGraph, [:model], [:model_f32c]) do (model,), _, __
        return (Mat4f(model),)
    end

    draw_scattered_mesh(
        scene, screen, primitive, marker,
        transformed_pos, scale, Quaternionf(0,0,0,1), colors,
        Plane3f[], true, primitive.uv_transform[]
    )

    return nothing
end
