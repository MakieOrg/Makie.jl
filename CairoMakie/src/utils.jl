################################################################################
#                             Projection utilities                             #
################################################################################


using Makie: apply_transform, transform_func, unclipped_indices, to_model_space,
    broadcast_foreach_index, is_clipped, is_visible

function project_position(scene::Scene, transform_func::T, space::Symbol, point, model::Mat4, yflip::Bool = true) where T
    # use transform func
    point = Makie.apply_transform(transform_func, point, space)
    _project_position(scene, space, point, model, yflip)
end

# much faster than dot-ing `project_position` because it skips all the repeated mat * mat
function project_position(
        scene::Scene, space::Symbol, ps::Vector{<: VecTypes{N, T1}},
        indices::Vector{<:Integer}, model::Mat4, yflip::Bool = true
    ) where {N, T1}

    transform = let
        f32convert = Makie.f32_convert_matrix(scene.float32convert, space)
        M = Makie.space_to_clip(scene.camera, space) * f32convert * model
        res = scene.camera.resolution[]
        px_scale  = Vec3d(0.5 * res[1], 0.5 * (yflip ? -res[2] : res[2]), 1)
        px_offset = Vec3d(0.5 * res[1], 0.5 * res[2], 0)
        M = Makie.transformationmatrix(px_offset, px_scale) * M
        M[Vec(1,2,4), Vec(1,2,3,4)] # skip z, i.e. calculate (x, y, w)
    end

    output = Vector{Point2f}(undef, length(indices))

    @inbounds for (i_out, i_in) in enumerate(indices)
        p4d = to_ndim(Point4d, to_ndim(Point3d, ps[i_in], 0), 1)
        px_pos = transform * p4d
        output[i_out] = px_pos[Vec(1, 2)] / px_pos[3]
    end

    return output
end

function _project_position(scene::Scene, space, ps::AbstractArray{<: VecTypes{N, T1}}, model, yflip::Bool) where {N, T1}
    return project_position(scene, space, ps, eachindex(ps), model, yflip)
end

function project_position(
        scene::Scene, space::Symbol, ps::AbstractArray{<: VecTypes{N, T1}},
        indices::Base.OneTo, model::Mat4, yflip::Bool = true
    ) where {N, T1}

    transform = let
        f32convert = Makie.f32_convert_matrix(scene.float32convert, space)
        M = Makie.space_to_clip(scene.camera, space) * f32convert * model
        res = scene.camera.resolution[]
        px_scale  = Vec3d(0.5 * res[1], 0.5 * (yflip ? -res[2] : res[2]), 1)
        px_offset = Vec3d(0.5 * res[1], 0.5 * res[2], 0)
        M = Makie.transformationmatrix(px_offset, px_scale) * M
        M[Vec(1,2,4), Vec(1,2,3,4)] # skip z, i.e. calculate (x, y, w)
    end

    output = similar(ps, Point2f)

    @inbounds for i in indices
        p4d = to_ndim(Point4d, to_ndim(Point3d, ps[i], 0), 1)
        px_pos = transform * p4d
        output[i] = px_pos[Vec(1, 2)] / px_pos[3]
    end

    return output
end

function _project_position(scene::Scene, space, point::VecTypes{N, T1}, model, yflip::Bool) where {N, T1 <: Real}
    T = promote_type(Float32, T1) # always Float, at least Float32
    res = scene.camera.resolution[]
    p4d = to_ndim(Vec4{T}, to_ndim(Vec3{T}, point, 0), 1)
    f32convert = Makie.f32_convert_matrix(scene.float32convert, space)
    clip = Makie.space_to_clip(scene.camera, space) * f32convert * model * p4d
    @inbounds begin
        # between -1 and 1
        p = (clip ./ clip[4])[Vec(1, 2)]
        # flip y to match cairo
        p_yflip = Vec2f(p[1], (1f0 - 2f0 * yflip) * p[2])
        # normalize to between 0 and 1
        p_0_to_1 = (p_yflip .+ 1f0) ./ 2f0
    end
    # multiply with scene resolution for final position
    return p_0_to_1 .* res
end

function project_position(@nospecialize(scenelike), space, point, model, yflip::Bool = true)
    scene = Makie.get_scene(scenelike)
    project_position(scene, Makie.transform_func(scenelike), space, point, model, yflip)
end

function project_marker(scene, markerspace, origin, scale, rotation, model, billboard = false)
    scale3 = to_ndim(Vec2d, scale, first(scale))
    model33 = model[Vec(1,2,3), Vec(1,2,3)]
    origin3 = to_ndim(Point3d, origin, 0)
    return project_marker(scene, markerspace, origin3, scale3, rotation, model33, Mat4d(I), billboard)
end
function project_marker(scene, markerspace, origin::Point3, scale::Vec, rotation, model33::Mat3, id = Mat4d(I), billboard = false)
    # the CairoMatrix is found by transforming the right and up vector
    # of the marker into screen space and then subtracting the projected
    # origin. The resulting vectors give the directions in which the character
    # needs to be stretched in order to match the 3D projection

    xvec = rotation * (model33 * (scale[1] * Point3d(1, 0, 0)))
    yvec = rotation * (model33 * (scale[2] * Point3d(0, -1, 0)))

    proj_pos = _project_position(scene, markerspace, origin, id, true)

    if billboard && Makie.is_data_space(markerspace)
        p4d = scene.camera.view[] * to_ndim(Point4d, origin, 1)
        xproj = _project_position(scene, :eye, p4d[Vec(1,2,3)] / p4d[4] + xvec, id, true)
        yproj = _project_position(scene, :eye, p4d[Vec(1,2,3)] / p4d[4] + yvec, id, true)
    else
        xproj = _project_position(scene, markerspace, origin + xvec, id, true)
        yproj = _project_position(scene, markerspace, origin + yvec, id, true)
    end

    xdiff = xproj - proj_pos
    ydiff = yproj - proj_pos

    mat = Cairo.CairoMatrix(
        xdiff[1], xdiff[2],
        ydiff[1], ydiff[2],
        0, 0,
    )

    return proj_pos, mat, Mat2f(xdiff..., ydiff...)
end

function project_shape(@nospecialize(scenelike), space, rect::Rect, model)
    mini = project_position(scenelike, space, minimum(rect), model)
    maxi = project_position(scenelike, space, maximum(rect), model)
    return Rect(mini, maxi .- mini)
end

function clip_poly(clip_planes::Vector{Plane3f}, ps::Vector{PT}, space::Symbol, model::Mat4) where {PT <: VecTypes{2}}
    if isempty(clip_planes) || !Makie.is_data_space(space)
        return ps
    end

    planes = to_model_space(model, clip_planes)
    last_distance = Makie.min_clip_distance(planes, first(ps))
    last_point = first(ps)
    output = sizehint!(PT[], length(ps))

    for p in ps
        d = Makie.min_clip_distance(planes, p)
        if (last_distance < 0) && (d >= 0) # clipped -> unclipped
            # point between last and this on clip plane
            clip_point = - last_distance * (p - last_point) / (d - last_distance) + last_point
            push!(output, clip_point, p)
        elseif (last_distance >= 0) && (d < 0) # unclipped -> clipped
            clip_point = - last_distance * (p - last_point) / (d - last_distance) + last_point
            push!(output, clip_point)
        elseif (last_distance >= 0) && (d >= 0) # unclipped -> unclipped
            push!(output, p)
        end
        last_point = p
        last_distance = d
    end

    return output
end

function clip_shape(clip_planes::Vector{Plane3f}, shape::Rect2, space::Symbol, model::Mat4)
    if !Makie.is_data_space(space) || isempty(clip_planes)
        return shape
    end

    xy = origin(shape)
    w, h = widths(shape)
    ps = Vec2f[xy, xy + Vec2f(w, 0), xy + Vec2f(w, h), xy + Vec2f(0, h)]
    if any(p -> Makie.is_clipped(clip_planes, p), ps)
        push!(ps, xy)
        ps = clip_poly(clip_planes, ps, space, model)
        commands = Makie.PathCommand[MoveTo(ps[1]), LineTo.(ps[2:end])..., ClosePath()]
        return BezierPath(commands::Vector{Makie.PathCommand})
    else
        return shape
    end
end

function clip_shape(clip_planes::Vector{Plane3f}, shape::BezierPath, space::Symbol, model::Mat4)
    return shape
end

function project_polygon(@nospecialize(scenelike), space, poly::Polygon{N, T}, clip_planes, model) where {N, T}
    PT = Point{N, Makie.float_type(T)}
    ext = decompose(PT, poly.exterior)
    project(p) = PT(project_position(scenelike, space, p, model))

    ext_proj = PT[project(p) for p in clip_poly(clip_planes, ext, space, model)]
    interiors_proj = Vector{PT}[
        PT[project(p) for p in clip_poly(clip_planes, decompose(PT, points), space, model)]
        for points in poly.interiors]

    return Polygon(ext_proj, interiors_proj)
end

function project_multipolygon(@nospecialize(scenelike), space, multipoly::MP, clip_planes, model) where MP <: MultiPolygon
    return MultiPolygon(project_polygon.(Ref(scenelike), Ref(space), multipoly.polygons, Ref(clip_planes), Ref(model)))
end

scale_matrix(x, y) = Cairo.CairoMatrix(x, 0.0, 0.0, y, 0.0, 0.0)

function clip2screen(p, res)
    s = Vec2f(0.5f0, -0.5f0) .* p[Vec(1, 2)] / p[4].+ 0.5f0
    return res .* s
end



function project_line_points(scene, plot::T, positions::AbstractArray{<: Makie.VecTypes{N, FT}}, colors, linewidths) where {T <: Union{Lines, LineSegments}, N, FT <: Real}

    # Standard transform from input space to clip space
    # Note that this is type unstable, so there is a function barrier in place.
    space = (plot.space[])::Symbol
    points = Makie.apply_transform(transform_func(plot), positions, space)

    return project_transformed_line_points(scene, plot, points, colors, linewidths)
end

function project_transformed_line_points(scene, plot::T, points::AbstractArray{<: Makie.VecTypes{N, FT}}, colors, linewidths) where {T <: Union{Lines, LineSegments}, N, FT <: Real}
    # Note that here, `points` has already had `transform_func` applied.
    # If colors are defined per point they need to be interpolated like positions
    # at clip planes
    per_point_colors = colors isa AbstractArray
    per_point_linewidths = (T <: Lines) && (linewidths isa AbstractArray)

    space = (plot.space[])::Symbol
    model = (plot.model[])::Mat4d
    f32convert = Makie.f32_convert_matrix(scene.float32convert, space)
    transform = Makie.space_to_clip(scene.camera, space) * f32convert * model
    clip_points = map(points) do point
        return transform * to_ndim(Vec4d, to_ndim(Vec3d, point, 0), 1)
    end

    # yflip and clip -> screen/pixel coords
    res = scene.camera.resolution[]

    # clip planes in clip space
    clip_planes = if Makie.is_data_space(space)
        Makie.to_clip_space(scene.camera.projectionview[], plot.clip_planes[])::Vector{Plane3f}
    else
        Makie.Plane3f[]
    end

    # Fix lines with points far outside the clipped region not drawing at all
    # TODO this can probably be done more efficiently by checking -1 ≤ x, y ≤ 1
    #      directly and calculating intersections directly (1D)
    push!(clip_planes,
        Plane3f(Vec3f(-1, 0, 0), -1f0), Plane3f(Vec3f(+1, 0, 0), -1f0),
        Plane3f(Vec3f(0, -1, 0), -1f0), Plane3f(Vec3f(0, +1, 0), -1f0)
    )


    # outputs
    screen_points = sizehint!(Vec2f[], length(clip_points))
    color_output = sizehint!(eltype(colors)[], length(clip_points))
    skipped_color = RGBAf(1,0,1,1) # for debug purposes, should not show
    linewidth_output = sizehint!(eltype(linewidths)[], length(clip_points))

    # Handling one segment per iteration
    if plot isa Lines

        last_is_nan = true
        for i in 1:length(clip_points)-1
            hidden = false
            disconnect1 = false
            disconnect2 = false

            if per_point_colors
                c1 = colors[i]
                c2 = colors[i+1]
            end

            p1 = clip_points[i]
            p2 = clip_points[i+1]
            v = p2 - p1

            # Handle near/far clipping
            if p1[4] <= 0.0
                disconnect1 = true
                p1 = p1 + (-p1[4] - p1[3]) / (v[3] + v[4]) * v
                if per_point_colors
                    c1 = c1 + (-p1[4] - p1[3]) / (v[3] + v[4]) * (c2 - c1)
                end
            end
            if p2[4] <= 0.0
                disconnect2 = true
                p2 = p2 + (-p2[4] - p2[3]) / (v[3] + v[4]) * v
                if per_point_colors
                    c2 = c2 + (-p2[4] - p2[3]) / (v[3] + v[4]) * (c2 - c1)
                end
            end

            for plane in clip_planes
                d1 = dot(plane.normal, Vec3f(p1)) - plane.distance * p1[4]
                d2 = dot(plane.normal, Vec3f(p2)) - plane.distance * p2[4]

                if (d1 < 0.0) && (d2 < 0.0)
                    # start and end clipped by one plane -> not visible
                    hidden = true
                    break;
                elseif (d1 < 0.0)
                    # p1 clipped, move it towards p2 until unclipped
                    disconnect1 = true
                    p1 = p1 - d1 * (p2 - p1) / (d2 - d1)
                    if per_point_colors
                        c1 = c1 - d1 * (c2 - c1) / (d2 - d1)
                    end
                elseif (d2 < 0.0)
                    # p2 clipped, move it towards p1 until unclipped
                    disconnect2 = true
                    p2 = p2 - d2 * (p1 - p2) / (d1 - d2)
                    if per_point_colors
                        c2 = c2 - d2 * (c1 - c2) / (d1 - d2)
                    end
                end
            end

            if hidden && !last_is_nan
                # if segment hidden make sure the line separates
                last_is_nan = true
                push!(screen_points, Vec2f(NaN))
                if per_point_linewidths
                    push!(linewidth_output, linewidths[i])
                end
                if per_point_colors
                    push!(color_output, c1)
                end
            elseif !hidden
                # if not hidden, always push the first element to 1:end-1 line points

                # if the start of the segment is disconnected (moved), make sure the
                # line separates before it
                if disconnect1 && !last_is_nan
                    push!(screen_points, Vec2f(NaN))
                    if per_point_linewidths
                        push!(linewidth_output, linewidths[i])
                    end
                    if per_point_colors
                        push!(color_output, c1)
                    end
                end

                last_is_nan = false
                push!(screen_points, clip2screen(p1, res))
                if per_point_linewidths
                    push!(linewidth_output, linewidths[i])
                end
                if per_point_colors
                    push!(color_output, c1)
                end

                # if the end of the segment is disconnected (moved), add the adjusted
                # point and separate it from from the next segment
                if disconnect2
                    last_is_nan = true
                    push!(screen_points, clip2screen(p2, res), Vec2f(NaN))
                    if per_point_linewidths
                        push!(linewidth_output, linewidths[i+1], linewidths[i+1])
                    end
                    if per_point_colors
                        push!(color_output, c2, c2) # relevant, irrelevant
                    end
                end
            end
        end

        # If last_is_nan == true, the last segment is either hidden or the moved
        # end point has been added. If it is false we're missing the last regular
        # clip_points
        if !last_is_nan
            push!(screen_points, clip2screen(clip_points[end], res))
            if per_point_linewidths
                    push!(linewidth_output, linewidths[end])
            end
            if per_point_colors
                push!(color_output, colors[end])
            end
        end

    else  # LineSegments

        for i in 1:2:length(clip_points)-1
            if per_point_colors
                c1 = colors[i]
                c2 = colors[i+1]
            end

            p1 = clip_points[i]
            p2 = clip_points[i+1]
            v = p2 - p1

            # Handle near/far clipping
            if p1[4] <= 0.0
                p1 = p1 + (-p1[4] - p1[3]) / (v[3] + v[4]) * v
                if per_point_colors
                    c1 = c1 + (-p1[4] - p1[3]) / (v[3] + v[4]) * (c2 - c1)
                end
            end
            if p2[4] <= 0.0
                p2 = p2 + (-p2[4] - p2[3]) / (v[3] + v[4]) * v
                if per_point_colors
                    c2 = c2 + (-p2[4] - p2[3]) / (v[3] + v[4]) * (c2 - c1)
                end
            end

            for plane in clip_planes
                d1 = dot(plane.normal, Vec3f(p1)) - plane.distance * p1[4]
                d2 = dot(plane.normal, Vec3f(p2)) - plane.distance * p2[4]

                if (d1 < 0.0) && (d2 < 0.0)
                    # start and end clipped by one plane -> not visible
                    # to keep index order we just set p1 and p2 to NaN and insert anyway
                    p1 = Vec4f(NaN)
                    p2 = Vec4f(NaN)
                    break;
                elseif (d1 < 0.0)
                    # p1 clipped, move it towards p2 until unclipped
                    p1 = p1 - d1 * (p2 - p1) / (d2 - d1)
                    if per_point_colors
                        c1 = c1 - d1 * (c2 - c1) / (d2 - d1)
                    end
                elseif (d2 < 0.0)
                    # p2 clipped, move it towards p1 until unclipped
                    p2 = p2 - d2 * (p1 - p2) / (d1 - d2)
                    if per_point_colors
                        c2 = c2 - d2 * (c1 - c2) / (d1 - d2)
                    end
                end
            end

            # no need to disconnected segments, just insert adjusted points
            push!(screen_points, clip2screen(p1, res), clip2screen(p2, res))
            if per_point_colors
                push!(color_output, c1, c2)
            end
        end

    end

    return screen_points, ifelse(per_point_colors, color_output, colors),
        ifelse(per_point_linewidths, linewidth_output, linewidths)
end


########################################
#          Rotation handling           #
########################################

function to_2d_rotation(x)
    quat = to_rotation(x)
    return -Makie.quaternion_to_2d_angle(quat)
end

function to_2d_rotation(::Makie.Billboard)
    @warn "This should not be reachable!"
    0
end

remove_billboard(x) = x
remove_billboard(b::Makie.Billboard) = b.rotation

to_2d_rotation(quat::Makie.Quaternion) = -Makie.quaternion_to_2d_angle(quat)

# TODO: this is a hack around a hack.
# Makie encodes the transformation from a 2-vector
# to a quaternion as a rotation around the Y-axis,
# when it should be a rotation around the X-axis.
# Since I don't know how to fix this in GLMakie,
# I've reversed the order of arguments to atan,
# such that our behaviour is consistent with GLMakie's.
to_2d_rotation(vec::Vec2f) = atan(vec[1], vec[2])

to_2d_rotation(n::Real) = n


################################################################################
#                                Color handling                                #
################################################################################

function rgbatuple(c::Colorant)
    rgba = RGBA(c)
    red(rgba), green(rgba), blue(rgba), alpha(rgba)
end

function rgbatuple(c)
    colorant = to_color(c)
    if !(colorant isa Colorant)
        error("Can't convert $(c) to a colorant")
    end
    return rgbatuple(colorant)
end

to_uint32_color(c) = reinterpret(UInt32, convert(ARGB32, premultiplied_rgba(c)))

# handle patterns
function Cairo.CairoPattern(color::Makie.AbstractPattern)
    # the Cairo y-coordinate are fliped
    bitmappattern = reverse!(ARGB32.(Makie.to_image(color)); dims=2)
    cairoimage = Cairo.CairoImageSurface(bitmappattern)
    cairopattern = Cairo.CairoPattern(cairoimage)
    return cairopattern
end

########################################
#        Common color utilities        #
########################################

function to_cairo_color(colors::Union{AbstractVector{<: Number},Number}, plot_object)
    cmap = Makie.assemble_colors(colors, Observable(colors), plot_object)
    return to_color(to_value(cmap))
end

function to_cairo_color(color::Makie.AbstractPattern, plot_object)
    cairopattern = Cairo.CairoPattern(color)
    Cairo.pattern_set_extend(cairopattern, Cairo.EXTEND_REPEAT);
    return cairopattern
end

function to_cairo_color(color, plot_object)
    return to_color(color)
end

function set_source(ctx::Cairo.CairoContext, pattern::Cairo.CairoPattern)
    return Cairo.set_source(ctx, pattern)
end

function set_source(ctx::Cairo.CairoContext, color::Colorant)
    return Cairo.set_source_rgba(ctx, rgbatuple(color)...)
end

########################################
#        Marker conversion API         #
########################################

"""
    cairo_scatter_marker(marker)

Convert a Makie marker to a Cairo-compatible marker.  This defaults to calling
`Makie.to_spritemarker`, but can be overridden for specific markers that can
be directly rendered to vector formats using Cairo.
"""
cairo_scatter_marker(marker) = Makie.to_spritemarker(marker)

########################################
#     Image/heatmap -> ARGBSurface     #
########################################


to_cairo_image(img::AbstractMatrix{<: Colorant}) =  to_cairo_image(to_uint32_color.(img))

function to_cairo_image(img::Matrix{UInt32})
    # we need to convert from column-major to row-major storage,
    # therefore we permute x and y
    return Cairo.CairoARGBSurface(permutedims(img))
end


################################################################################
#                                Mesh handling                                 #
################################################################################

struct FaceIterator{Iteration, T, F, ET} <: AbstractVector{ET}
    data::T
    faces::F
end

function (::Type{FaceIterator{Typ}})(data::T, faces::F) where {Typ, T, F}
    FaceIterator{Typ, T, F}(data, faces)
end
function (::Type{FaceIterator{Typ, T, F}})(data::AbstractVector, faces::F) where {Typ, F, T}
    FaceIterator{Typ, T, F, NTuple{3, eltype(data)}}(data, faces)
end
function (::Type{FaceIterator{Typ, T, F}})(data::T, faces::F) where {Typ, T, F}
    FaceIterator{Typ, T, F, NTuple{3, T}}(data, faces)
end
function FaceIterator(data::AbstractVector, faces)
    if length(data) == length(faces)
        FaceIterator{:PerFace}(data, faces)
    else
        FaceIterator{:PerVert}(data, faces)
    end
end

Base.size(fi::FaceIterator) = size(fi.faces)
Base.getindex(fi::FaceIterator{:PerFace}, i::Integer) = fi.data[i]
Base.getindex(fi::FaceIterator{:PerVert}, i::Integer) = fi.data[fi.faces[i]]
Base.getindex(fi::FaceIterator{:Const}, i::Integer) = ntuple(i-> fi.data, 3)

color_or_nothing(c) = isnothing(c) ? nothing : to_color(c)
function get_color_attr(attributes, attribute)::Union{Nothing, RGBAf}
    return color_or_nothing(to_value(get(attributes, attribute, nothing)))
end

function per_face_colors(_color, matcap, faces, normals, uv)
    color = to_color(_color)
    if !isnothing(matcap)
        wsize = reverse(size(matcap))
        wh = wsize .- 1
        cvec = map(normals) do n
            muv = 0.5n[Vec(1,2)] .+ Vec2f(0.5)
            x, y = clamp.(round.(Int, Tuple(muv) .* wh) .+ 1, 1, wh)
            return matcap[end - (y - 1), x]
        end
        return FaceIterator(cvec, faces)
    elseif color isa Colorant
        return FaceIterator{:Const}(color, faces)
    elseif color isa AbstractVector{<: Colorant}
        return FaceIterator{:PerVert}(color, faces)
    elseif color isa Makie.AbstractPattern
        # let next level extend and fill with CairoPattern
        return color
    elseif color isa AbstractMatrix{<: Colorant} && !isnothing(uv)
        wsize = size(color)
        wh = wsize .- 1
        # nearest
        cvec = map(uv) do uv
            x, y = clamp.(round.(Int, Tuple(uv) .* wh) .+ 1, 1, wsize)
            return color[x, y]
        end
        # TODO This is wrong and doesn't actually interpolate
        # Inside the triangle sampling the color image
        return FaceIterator(cvec, faces)
    end
    error("Unsupported Color type: $(typeof(color))")
end

function mesh_pattern_set_corner_color(pattern, id, c::Colorant)
    Cairo.mesh_pattern_set_corner_color_rgba(pattern, id, rgbatuple(c)...)
end

################################################################################
#                                Font handling                                 #
################################################################################


"""
Finds a font that can represent the unicode character!
Returns Makie.defaultfont() if not representable!
"""
function best_font(c::Char, font = Makie.defaultfont())
    if Base.@lock font.lock Makie.FreeType.FT_Get_Char_Index(font, c) == 0
        for afont in Makie.alternativefonts()
            if Base.@lock afont.lock Makie.FreeType.FT_Get_Char_Index(afont, c) != 0
                return afont
            end
        end
        return Makie.defaultfont()
    end
    return font
end
