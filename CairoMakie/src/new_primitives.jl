# TODO:
#   - Embed camera matrices in compute pipeline so we can easily and consistently
#     do projections here

# TODO: update Makie.Sampler to include lowclip, highclip, nan_color
#       and maybe also just RGBAf color types?
#       Or just move this to make as a more generic function?
# Note: This assumes to be called with data from ComputePipeline, i.e.
#       alpha and colorscale already applied
function sample_color(
        colormap::Vector{RGBAf}, value::Real, colorrange::VecTypes{2},
        lowclip::RGBAf = first(colormap), highclip::RGBAf = last(colormap),
        nan_color::RGBAf = RGBAf(0,0,0,0), interpolation = Makie.Linear
    )
    isnan(value) && return nan_color
    value < colorrange[1] && return lowclip
    value > colorrange[2] && return highclip
    if interpolation == Makie.Linear
        return Makie.interpolated_getindex(colormap, value, colorrange)
    else
        return Makie.nearest_getindex(colormap, value, colorrange)
    end
end

function cairo_colors(@nospecialize(plot), color_name = :scaled_color)
    Makie.register_computation!(plot.args[1]::Makie.ComputeGraph,
            [color_name, :scaled_colorrange, :alpha_colormap, :nan_color, :lowclip_color, :highclip_color],
            [:cairo_colors]
        ) do inputs, changed, cached
        (color, colorrange, colormap, nan_color, lowclip, highclip) = inputs
        # colormapping
        if color isa AbstractArray{<:Real} || color isa Real
            output = map(color) do v
                return sample_color(colormap, v, colorrange, lowclip, highclip, nan_color)
            end
            return (output,)
        else # Raw colors
            # Avoid update propagation if nothing changed
            !isnothing(last) && !changed[1] && return nothing
            return (color,)
        end
    end

    return plot.cairo_colors[]
end

function cairo_project_to_screen(
        scene::Scene, @nospecialize(plot::Plot);
        pos_name = :positions_transformed_f32c, yflip = true, output_type = Point2f
    )

    attr = plot.args[1]::Makie.ComputeGraph

    Makie.register_computation!(attr,
            [pos_name, :space, :model_f32c], [:cairo_screen_pos]
        ) do (pos, space, model), changed, cached

        # the existing methods include f32convert matrices which are already
        # applied in :positions_transformed_f32c (using this makes CairoMakie
        # less performant (extra O(N) step) but allows code reuse with other backends)
        M = Makie.space_to_clip(scene.camera, space) * model
        M = cairo_viewport_matrix(scene.camera.resolution[], yflip) * M

        output = project_position(output_type, M, pos, eachindex(pos))
        return (output,)
    end

    return attr[:cairo_screen_pos][]
end

################################################################################
#                             Lines, LineSegments                              #
################################################################################

function draw_atomic(scene::Scene, screen::Screen, plot::PT) where {PT <: Union{Lines, LineSegments}}
    linewidth = PT <: Lines ? plot.linewidth[] : plot.synched_linewidth[]
    color = PT <: Lines ? plot.scaled_color[] : plot.synched_color[]
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
    attr = plot.args[1]
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
    if plot isa Lines && to_value(plot.args[1]) isa BezierPath
        return draw_bezierpath_lines(ctx, to_value(plot.args[1]), plot, color, space, model, linewidth)
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
    args = p.markersize[], p.strokecolor[], p.strokewidth[], p.marker[], p.marker_offset[], p.rotation[],
           p.transform_marker[], p.model[], p.markerspace[], p.space[], p.clip_planes[]

    markersize, strokecolor, strokewidth, marker, marker_offset, rotation,
    transform_marker, model, markerspace, space, clip_planes = args

    attr = p.args[1]
    Makie.register_computation!(attr, [:marker], [:cairo_marker]) do (marker,), changed, outputs
        return (cairo_scatter_marker(marker),)
    end

    if !haskey(attr.outputs, :cairo_indices) # TODO: Why is this necessary? Is it still necessary?
        Makie.register_computation!(attr,
            [:positions_transformed_f32c, :model_f32c, :space, :clip_planes],
            [:cairo_indices]
        ) do (transformed, model, space, clip_planes), changed, outputs
            return (unclipped_indices(to_model_space(model, clip_planes), transformed, space),)
        end
    end

    # TODO: This requires (cam.projectionview, resolution) as inputs otherwise
    #       the output can becomes invalid from render to render.
    # Makie.register_computation!(attr,
    #     [:positions_transformed_f32c, :cairo_indices, :model_f32c, :projectionview, :resolution, :space],
    #     [:cairo_positions_px]
    # ) do (transformed, indices, model, pv, res, space), changed, outputs
    #     pos = project_position(scene, space[], transformed[], indices[], model[])
    #     return (pos,)
    # end
    indices = p.cairo_indices[]
    transform = Makie.clip_to_space(scene.camera, p.markerspace[]) *
        Makie.space_to_clip(scene.camera, p.space[]) * p.model_f32c[]
    positions = p.positions_transformed_f32c[]
    isempty(positions) && return

    marker = p.cairo_marker[] # this goes through CairoMakie's conversion system and not Makie's...
    ctx = screen.context
    size_model = transform_marker ? model[Vec(1,2,3), Vec(1,2,3)] : Mat3d(I)

    font = p.font[]
    colors = cairo_colors(p)
    billboard = p.rotation[] isa Billboard

    return draw_atomic_scatter(
        scene, ctx, transform, positions, indices, colors, markersize, strokecolor, strokewidth,
        marker, marker_offset, rotation, size_model, font, markerspace, billboard
        )
end

is_approx_zero(x) = isapprox(x, 0)
is_approx_zero(v::VecTypes) = any(x -> isapprox(x, 0), v)

function draw_atomic_scatter(
        scene, ctx, transform, positions, indices, colors, markersize, strokecolor, strokewidth,
        marker, marker_offset, rotation, size_model, font, markerspace, billboard
    )

    Makie.broadcast_foreach_index(positions, indices, colors, markersize, strokecolor,
        strokewidth, marker, marker_offset, remove_billboard(rotation)) do pos, col,
        markersize, strokecolor, strokewidth, m, mo, rotation

        isnan(pos) && return
        isnan(rotation) && return # matches GLMakie
        (isnan(markersize) || is_approx_zero(markersize)) && return

        p4d = transform * to_ndim(Point4d, to_ndim(Point3d, pos, 0), 1) # to markerspace
        o = p4d[Vec(1, 2, 3)] ./ p4d[4] .+ size_model * to_ndim(Vec3d, mo, 0)
        proj_pos, mat, jl_mat = project_marker(scene, markerspace, o,
            markersize, rotation, size_model, billboard) # to pixel space

        # mat and jl_mat are the same matrix, once as a CairoMatrix, once as a Mat2f
        # They both describe an approximate basis transformation matrix from
        # marker space to pixel space with scaling appropriate to markersize.
        # Markers that can be drawn from points/vertices of shape (e.g. Rect)
        # could be projected more accurately by projecting each point individually
        # and then building the shape.

        # Enclosed area of the marker must be at least 1 pixel?
        (abs(det(jl_mat)) < 1) && return

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
#                                Heatmap, Image                                #
################################################################################


# Note: Changed very little here
function draw_atomic(scene::Scene, screen::Screen{RT}, @nospecialize(primitive::Union{Heatmap, Image})) where RT
    ctx = screen.context

    xs = primitive.x[]
    ys = primitive.y[]
    image = primitive.image[]

    if xs isa Makie.EndPoints
        l, r = xs
        N = size(image, 1)
        xs = range(l, r, length = N+1)
    else
        xs = regularly_spaced_array_to_range(xs)
    end

    if ys isa Makie.EndPoints
        l, r = ys
        N = size(image, 2)
        ys = range(l, r, length = N+1)
    else
        ys = regularly_spaced_array_to_range(ys)
    end

    # TODO: heatmap doesn't handle f32c etc
    model = primitive.model[]::Mat4d
    interpolate = primitive.interpolate[]

    # Vector backends don't support FILTER_NEAREST for interp == false, so in that case we also need to draw rects
    is_vector = is_vector_backend(ctx)
    t = Makie.transform_func(primitive)
    is_identity_transform = (t === identity || t isa Tuple && all(x-> x === identity, t)) &&
        Makie.is_translation_scale_matrix(model)
    is_regular_grid = xs isa AbstractRange && ys isa AbstractRange
    is_xy_aligned = Makie.is_translation_scale_matrix(scene.camera.projectionview[])

    if interpolate
        if !is_regular_grid
            error("$(typeof(primitive).parameters[1]) with interpolate = true with a non-regular grid is not supported right now.")
        end
        if !is_identity_transform
            error("$(typeof(primitive).parameters[1]) with interpolate = true with a non-identity transform is not supported right now.")
        end
    end

    # TODO: Can we generalize this/reuse from other backends?
    #       - image could use `xy, xymax = cairo_screen_pos()[[1, 3]]`
    #       - heatmap doesn't apply f32c, transform_func, and also handles points
    #         differently...
    imsize = ((first(xs), last(xs)), (first(ys), last(ys)))
    # find projected image corners
    # this already takes care of flipping the image to correct cairo orientation
    space = primitive.space[]
    xy = project_position(primitive, space, Point2(first.(imsize)), model)
    xymax = project_position(primitive, space, Point2(last.(imsize)), model)
    w, h = xymax .- xy

    uv_transform = if primitive isa Image
        val = to_value(get(primitive, :uv_transform, I))
        T = Makie.convert_attribute(val, Makie.key"uv_transform"(), Makie.key"image"())
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
            ps = [Point2(x, y) for x in xs, y in ys]
            transformed = apply_transform(transform_func(primitive), ps)
            T = eltype(transformed)

            planes = if Makie.is_data_space(space)
                to_model_space(model, primitive.clip_planes[])
            else
                Plane3f[]
            end

            for i in eachindex(transformed)
                if is_clipped(planes, transformed[i])
                    transformed[i] = T(NaN)
                end
            end

            _project_position(scene, space, transformed, model, true)
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
        if !haskey(primitive, :faceculling)
            Makie.register_computation!(primitive.args[1]::Makie.ComputeGraph, Symbol[], [:faceculling]) do args...
                return (-10,)
            end
        end
        draw_mesh3D(scene, screen, primitive)
    end
    return nothing
end

function draw_mesh2D(scene, screen, @nospecialize(plot::Makie.Mesh))
    # TODO: no clip_planes?
    vs = cairo_project_to_screen(scene, plot)
    fs = plot.faces[]
    uv = plot.texturecoordinates[]
    uv_transform = plot.uv_transform[]
    if uv isa Vector{Vec2f} && to_value(uv_transform) !== nothing
        uv = map(uv -> uv_transform * to_ndim(Vec3f, uv, 1), uv)
    end
    color = cairo_colors(plot)
    cols = per_face_colors(color, nothing, fs, nothing, uv)
    if cols isa Cairo.CairoPattern
        align_pattern(cols, scene, model)
    end
    return draw_mesh2D(screen, cols, vs, fs)
end

# reworked, TODO: merge this with surface and maybe meshscatter and voxels again
# Mesh + surface only
function draw_mesh3D(scene, screen, @nospecialize(plot::Plot))
    @get_attribute(plot, (shading, diffuse, specular, shininess, faceculling, clip_planes))

    matcap = to_value(get(plot, :matcap, nothing))

    world_points = plot.positions_transformed_f32c[]
    screen_points = cairo_project_to_screen(scene, plot, output_type = Point3f)
    meshfaces = plot.faces[]
    meshnormals = plot.normals[]
    _meshuvs = plot.texturecoordinates[]

    if (_meshuvs isa AbstractVector{<:Vec3})
        error("Only 2D texture coordinates are supported right now. Use GLMakie for 3D textures.")
    end
    meshuvs::Union{Nothing,Vector{Vec2f}} = _meshuvs

    uv_transform = plot.uv_transform[]
    if meshuvs isa Vector{Vec2f} && to_value(uv_transform) !== nothing
        meshuvs = map(uv -> uv_transform * to_ndim(Vec3f, uv, 1), meshuvs)
    end

    # Prioritize colors of the mesh if present
    color = cairo_colors(plot)
    per_face_col = per_face_colors(color, matcap, meshfaces, meshnormals, meshuvs)

    space = plot.space[]::Symbol

    if per_face_col isa Cairo.CairoPattern
        # plot.model_f32c[] is f32c corrected, not f32c * model
        f32c_model = Makie.f32_convert_matrix(scene.float32convert, space) * plot.model[]
        align_pattern(per_face_col, scene, f32c_model)
    end

    # TODO: assume Symbol here after this has been deprecated for a while
    if shading isa Bool
        @warn "`shading::Bool` is deprecated. Use `shading = NoShading` instead of false and `shading = FastShading` or `shading = MultiLightShading` instead of true."
        shading_bool = shading
    else
        shading_bool = shading != NoShading
    end

    if !isnothing(meshnormals) && to_value(get(plot, :invert_normals, false))
        meshnormals .= -meshnormals
    end
    model = plot.model_f32c[]::Mat4f

    draw_mesh3D(
        scene, screen, space, world_points, screen_points, meshfaces, meshnormals, per_face_col,
        model, shading_bool::Bool, diffuse::Vec3f,
        specular::Vec3f, shininess::Float32, faceculling::Int, clip_planes
    )
end

function draw_mesh3D(
        scene, screen, space, world_points, screen_points, meshfaces, meshnormals, per_face_col,
        model, shading, diffuse, specular, shininess, faceculling, clip_planes
    )
    ctx = screen.context
    eyeposition = scene.camera.eyeposition[]

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


    # Light math happens in view/camera space
    dirlight = Makie.get_directional_light(scene)
    if !isnothing(dirlight)
        lightdirection = if dirlight.camera_relative
            T = inv(scene.camera.view[][Vec(1,2,3), Vec(1,2,3)])
            normalize(T * dirlight.direction[])
        else
            normalize(dirlight.direction[])
        end
        c = dirlight.color[]
        light_color = Vec3f(red(c), green(c), blue(c))
    else
        lightdirection = Vec3f(0,0,-1)
        light_color = Vec3f(0)
    end

    ambientlight = Makie.get_ambient_light(scene)
    ambient = if !isnothing(ambientlight)
        c = ambientlight.color[]
        Vec3f(c.r, c.g, c.b)
    else
        Vec3f(0)
    end

    # vs are used as camdir (camera to vertex) for light calculation (in world space)
    vs = map(v -> normalize(v[i] - eyeposition), world_points)

    draw_pattern(
        ctx, zorder, shading, meshfaces, screen_points, per_face_col, ns, vs,
        lightdirection, light_color, shininess, diffuse, ambient, specular)
    return
end