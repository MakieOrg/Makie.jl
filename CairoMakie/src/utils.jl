################################################################################
#                             Projection utilities                             #
################################################################################


using Makie: apply_transform, transform_func, unclipped_indices, to_model_space,
    broadcast_foreach_index, is_clipped, is_visible

# No, we may need to filter over variables too!
# function apply_transform_and_clip(
#         transform_func, model::Mat4, clip_planes::Vector{<: Makie.Plane3}, 
#         space::Symbol, data
#     )

#     transformed = Makie.apply_transform(tf, data, space)
#     if space == :data && !isempty(clip_planes)
#         imodel = inv(model)
#         planes = Makie.apply_transform.((imodel,), clip_planes)
#         filter!(p -> Makie.is_visible(p, planes), transformed)
#     end
#     return transformed
# end


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
        M = Makie.space_to_clip(scene.camera, space) * model * f32convert
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
        M = Makie.space_to_clip(scene.camera, space) * model * f32convert
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
    clip = Makie.space_to_clip(scene.camera, space) * model * f32convert * p4d
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

function project_scale(scene::Scene, space, s::Number, model = Mat4d(I))
    project_scale(scene, space, Vec2d(s), model)
end

function project_scale(scene::Scene, space, s, model = Mat4d(I))
    p4d = model * to_ndim(Vec4d, s, 0)
    if is_data_space(space)
        @inbounds p = (scene.camera.projectionview[] * p4d)[Vec(1, 2)]
        return p .* scene.camera.resolution[] .* 0.5
    elseif is_pixel_space(space)
        return p4d[Vec(1, 2)]
    elseif is_relative_space(space)
        return p4d[Vec(1, 2)] .* scene.camera.resolution[]
    else # clip
        return p4d[Vec(1, 2)] .* scene.camera.resolution[] .* 0.5f0
    end
end

function project_shape(@nospecialize(scenelike), space, rect::Rect, model)
    mini = project_position(scenelike, space, minimum(rect), model)
    maxi = project_position(scenelike, space, maximum(rect), model)
    return Rect(mini, maxi .- mini)
end

function project_polygon(@nospecialize(scenelike), space, poly::Polygon{N, T}, model) where {N, T}
    PT = Point{N, Makie.float_type(T)}
    ext = decompose(PT, poly.exterior)
    project(p) = PT(project_position(scenelike, space, p, model))
    ext_proj = PT[project(p) for p in ext]
    interiors_proj = Vector{PT}[PT[project(p) for p in decompose(PT, points)] for points in poly.interiors]
    return Polygon(ext_proj, interiors_proj)
end

function project_multipolygon(@nospecialize(scenelike), space, multipoly::MP, model) where MP <: MultiPolygon
    return MultiPolygon(project_polygon.(Ref(scenelike), Ref(space), multipoly.polygons, Ref(model)))
end

scale_matrix(x, y) = Cairo.CairoMatrix(x, 0.0, 0.0, y, 0.0, 0.0)

function project_line_points(scene, plot::T, positions) where {T <: Union{Lines, LineSegments}}
    @get_attribute(plot, (space, model))

    # Standard transform from input space to clip space
    points = Makie.apply_transform(transform_func(plot), positions, space)
    f32convert = Makie.f32_convert_matrix(scene.float32convert, space)
    transform = Makie.space_to_clip(scene.camera, space) * model * f32convert
    clip_points = map(p -> transform * to_ndim(Vec4d, to_ndim(Vec3d, p, 0), 1), points)
    
    # yflip and clip -> screen/pixel coords
    res = scene.camera.resolution[]
    function clip2screen(p)
        s = Vec2f(0.5f0, -0.5f0) .* p[Vec(1, 2)] .+ 0.5f0
        return res .* s
    end

    # clip planes in clip space
    clip_planes = Makie.to_clip_space(scene.camera.projectionview[], plot.clip_planes[])
    
    # outputs
    screen_points = sizehint!(Vector{Vec2f}(undef, 0), length(clip_points))
    indices = Vector{Int}(undef, 0)

    # Handling one segment per iteration
    if plot isa Lines

        sizehint!(indices, length(clip_points))

        last_is_nan = true
        for i in 1:length(clip_points)-1
            hidden = false
            disconnect1 = false
            disconnect2 = false

            p4d1 = clip_points[i]
            p4d2 = clip_points[i+1]
            v = p4d2 - p4d1

            # Handle near/far clipping
            if p4d1[4] <= 0.0
                disconnect1 = true
                p4d1 = p4d1 + (-p4d1[4] - p4d1[3]) / (v[3] + v[4]) * v
            end
            if p4d2[4] <= 0.0
                disconnect2 = true
                p4d2 = p4d2 + (-p4d2[4] - p4d2[3]) / (v[3] + v[4]) * v
            end

            p1 = Vec3f(p4d1) / p4d1[4]
            p2 = Vec3f(p4d2) / p4d2[4]

            for plane in clip_planes
                d1 = Makie.distance(plane, p1)
                d2 = Makie.distance(plane, p2)

                if (d1 <= 0.0) && (d2 <= 0.0)
                    # start and end clipped by one plane -> not visible
                    hidden = true
                    break;
                elseif (d1 < 0.0) && (d2 > 0.0)
                    # p1 clipped, move it towards p2 until unclipped
                    disconnect1 = true
                    p1 = p1 - d1 * (p2 - p1) / (d2 - d1)
                elseif (d1 > 0.0) && (d2 < 0.0)
                    # p2 clipped, move it towards p1 until unclipped
                    disconnect2 = true
                    p2 = p2 - d2 * (p1 - p2) / (d1 - d2)
                end
            end

            if hidden && !last_is_nan
                # if segment hidden make sure the line separates
                last_is_nan = true
                push!(screen_points, Vec2f(NaN))
                push!(indices, i)
            elseif !hidden
                # if not hidden, always push the first element to 1:end-1 line points
                
                # if the start of the segment is disconnected (moved), make sure the 
                # line separates before it
                if disconnect1 && !last_is_nan
                    push!(screen_points, Vec2f(NaN))
                    push!(indices, i)
                end
                
                last_is_nan = false
                push!(screen_points, clip2screen(p1))
                push!(indices, i)

                # if the end of the segment is disconnected (moved), add the adjusted 
                # point and separate it from from the next segment
                if disconnect2
                    last_is_nan = true
                    push!(screen_points, clip2screen(p2), Vec2f(NaN))
                    push!(indices, i+1, i+1)
                end
            end
        end

        # If last_is_nan == true, the last segment is either hidden or the moved 
        # end point has been added. If it is false we're missing the last regular 
        # clip_points
        if !last_is_nan
            push!(screen_points, clip2screen(Vec3f(clip_points[end]) / clip_points[end][4]))
            push!(indices, length(clip_points))
        end

    else  # LineSegments
        
        for i in 1:2:length(clip_points)-1
            p4d1 = clip_points[i]
            p4d2 = clip_points[i+1]
            v = p4d2 - p4d1

            # Handle near/far clipping
            if p4d1[4] <= 0.0
                p4d1 = p4d1 + (-p4d1[4] - p4d1[3]) / (v[3] + v[4]) * v
            end
            if p4d2[4] <= 0.0
                p4d2 = p4d2 + (-p4d2[4] - p4d2[3]) / (v[3] + v[4]) * v
            end

            p1 = Vec3f(p4d1) / p4d1[4]
            p2 = Vec3f(p4d2) / p4d2[4]

            for plane in clip_planes
                d1 = Makie.distance(plane, p1)
                d2 = Makie.distance(plane, p2)

                if (d1 <= 0.0) && (d2 <= 0.0)
                    # start and end clipped by one plane -> not visible
                    # to keep index order we just set p1 and p2 to NaN and insert anyway
                    p1 = Vec2f(NaN)
                    p2 = Vec2f(NaN)
                    break;
                elseif (d1 < 0.0) && (d2 > 0.0)
                    # p1 clipped, move it towards p2 until unclipped
                    p1 = p1 - d1 * (p2 - p1) / (d2 - d1)
                elseif (d1 > 0.0) && (d2 < 0.0)
                    # p2 clipped, move it towards p1 until unclipped
                    p2 = p2 - d2 * (p1 - p2) / (d1 - d2)
                end
            end

            # no need to disconnected segments, just insert adjusted points
            push!(screen_points, clip2screen(p1), clip2screen(p2))
        end

    end

    return screen_points, indices
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
        return FaceIterator(color, faces)
    elseif color isa Makie.AbstractPattern
        # let next level extend and fill with CairoPattern
        return color
    elseif color isa AbstractMatrix{<: Colorant} && !isnothing(uv)
        wsize = reverse(size(color))
        wh = wsize .- 1
        cvec = map(uv) do uv
            x, y = clamp.(round.(Int, Tuple(uv) .* wh) .+ 1, 1, wsize)
            return color[end - (y - 1), x]
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
