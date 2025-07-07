function extract_attributes!(attr::ComputeGraph, inputs::Vector{Symbol}, output::Symbol)
    # Make a namedtuple that holds all the attributes we need
    return register_computation!(attr, inputs, [output]) do inputs, changed, outputs
        return (inputs,)
    end
end

################################################################################
#                             Projection utilities                             #
################################################################################

using Makie: apply_transform, transform_func, unclipped_indices, to_model_space,
    broadcast_foreach_index, is_clipped, is_visible

function project_position(scene::Scene, transform_func::T, space::Symbol, point, model::Mat4, yflip::Bool = true) where {T}
    # use transform func
    point = Makie.apply_transform(transform_func, point)
    return _project_position(scene, space, point, model, yflip)
end


function _project_position(scene::Scene, space, ps::AbstractArray{<:VecTypes{N, T1}}, model, yflip::Bool) where {N, T1}
    return project_position(scene, space, ps, eachindex(ps), model, yflip)
end

function cairo_viewport_matrix(res::VecTypes{2}, yflip = true)
    px_scale = Vec3d(0.5 * res[1], 0.5 * (yflip ? -res[2] : res[2]), 1)
    px_offset = Vec3d(0.5 * res[1], 0.5 * res[2], 0)
    return Makie.transformationmatrix(px_offset, px_scale)
end

function build_combined_transformation_matrix(
        scene::Scene, space::Symbol, model::Mat4, yflip = true
    )
    f32convert = Makie.f32_convert_matrix(scene.float32convert, space)
    M = Makie.space_to_clip(scene.camera, space) * f32convert * model
    return cairo_viewport_matrix(scene.camera.resolution[], yflip) * M
end

function project_position(
        scene::Scene, space::Symbol, ps::AbstractArray{<:VecTypes},
        indices::Union{Vector{<:Integer}, Base.OneTo}, model::Mat4,
        yflip::Bool = true
    )
    # much faster to calculate the combined projection-transformation matrix
    # once than dot-ing `project_position` because it skips all the repeated mat * mat
    transform = build_combined_transformation_matrix(scene, space, model, yflip)
    # skip z with Vec(1,2,4), i.e. calculate only (x, y, w)
    return project_position(Point2f, transform[Vec(1, 2, 4), Vec(1, 2, 3, 4)], ps, indices)
end

# Assumes (transform * ps[i])[end] to be w component, always
function project_position(
        ::Type{PT}, transform::Mat{M, 4}, ps::AbstractVector{<:VecTypes},
        indices::Vector{<:Integer}
    ) where {N, PT <: VecTypes{N}, M}

    output = Vector{PT}(undef, length(indices))
    dims = Vec(ntuple(identity, N))

    @inbounds for (i_out, i_in) in enumerate(indices)
        p4d = to_ndim(Point4d, to_ndim(Point3d, ps[i_in], 0), 1)
        px_pos = transform * p4d
        output[i_out] = px_pos[dims] / px_pos[end]
    end

    return output
end
function project_position(
        ::Type{PT}, transform::Mat{M, 4}, ps::AbstractArray{<:VecTypes},
        indices::Base.OneTo
    ) where {N, PT <: VecTypes{N}, M}

    output = similar(ps, PT)
    dims = Vec(ntuple(identity, N))

    @inbounds for i in indices
        p4d = to_ndim(Point4d, to_ndim(Point3d, ps[i], 0), 1)
        px_pos = transform * p4d
        output[i] = px_pos[dims] / px_pos[end]
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
        p_yflip = Vec2f(p[1], (1.0f0 - 2.0f0 * yflip) * p[2])
        # normalize to between 0 and 1
        p_0_to_1 = (p_yflip .+ 1.0f0) ./ 2.0f0
    end
    # multiply with scene resolution for final position
    return p_0_to_1 .* res
end


function project_position(@nospecialize(scenelike), space, point, model, yflip::Bool = true)
    scene = Makie.get_scene(scenelike)
    return project_position(scene, Makie.transform_func(scenelike), space, point, model, yflip)
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
            for points in poly.interiors
    ]

    return Polygon(ext_proj, interiors_proj)
end

function project_multipolygon(@nospecialize(scenelike), space, multipoly::MP, clip_planes, model) where {MP <: MultiPolygon}
    return MultiPolygon(project_polygon.(Ref(scenelike), Ref(space), multipoly.polygons, Ref(clip_planes), Ref(model)))
end

scale_matrix(x, y) = Cairo.CairoMatrix(x, 0.0, 0.0, y, 0.0, 0.0)

function clip2screen(p, res)
    s = Vec2f(0.5f0, -0.5f0) .* p[Vec(1, 2)] / p[4] .+ 0.5f0
    return res .* s
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
    return 0
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
    return red(rgba), green(rgba), blue(rgba), alpha(rgba)
end

function rgbatuple(c)
    colorant = to_color(c)
    if !(colorant isa Colorant)
        error("Can't convert $(c) to a colorant")
    end
    return rgbatuple(colorant)
end

premultiplied_rgba(a::AbstractArray{<:ColorAlpha}) = map(premultiplied_rgba, a)
premultiplied_rgba(a::AbstractArray{<:Color}) = RGBA.(a)
premultiplied_rgba(r::RGBA) = RGBA(r.r * r.alpha, r.g * r.alpha, r.b * r.alpha, r.alpha)
premultiplied_rgba(c::Colorant) = premultiplied_rgba(RGBA(c))

to_uint32_color(c) = reinterpret(UInt32, convert(ARGB32, premultiplied_rgba(c)))

# handle patterns
function Cairo.CairoPattern(color::Makie.AbstractPattern)
    # the Cairo y-coordinate are flipped
    bitmappattern = reverse(Makie.to_image(color); dims = 2)
    # Cairo wants pre-multiplied alpha - ARGB32 doesn't do that on its own
    bitmappattern = map(bitmappattern) do c
        a = alpha(c)
        return ARGB32(a * red(c), a * green(c), a * blue(c), a)
    end
    cairoimage = Cairo.CairoImageSurface(bitmappattern)
    cairopattern = Cairo.CairoPattern(cairoimage)
    Cairo.pattern_set_extend(cairopattern, Cairo.EXTEND_REPEAT)
    return cairopattern
end

function align_pattern(pattern::Cairo.CairoPattern, scene, model)
    o = Makie.pattern_offset(scene.camera.projectionview[] * model, scene.camera.resolution[], true)
    T = Mat{2, 3, Float32}(1, 0, 0, 1, -o[1], -o[2])
    pattern_set_matrix(pattern, Cairo.CairoMatrix(T...))
    return
end

########################################
#        Common color utilities        #
########################################

function to_cairo_color(colors::Union{AbstractVector, Number}, plot_object)
    cmap = Makie.assemble_colors(colors, Observable(colors), plot_object)
    return to_color(to_value(cmap))
end

function to_cairo_color(color::Makie.AbstractPattern, plot)
    cairopattern = Cairo.CairoPattern(color)
    # This should be reset after drawing
    align_pattern(cairopattern, Makie.parent_scene(plot), plot.model[])
    return cairopattern
end

function to_cairo_color(color, plot_object)
    return to_color((color, to_value(plot_object.alpha)))
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


to_cairo_image(img::AbstractMatrix{<:Colorant}) = to_cairo_image(to_uint32_color.(img))

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
    return FaceIterator{Typ, T, F}(data, faces)
end
function (::Type{FaceIterator{Typ, T, F}})(data::AbstractVector, faces::F) where {Typ, F, T}
    return FaceIterator{Typ, T, F, NTuple{3, eltype(data)}}(data, faces)
end
function (::Type{FaceIterator{Typ, T, F}})(data::T, faces::F) where {Typ, T, F}
    return FaceIterator{Typ, T, F, NTuple{3, T}}(data, faces)
end
function FaceIterator(data::AbstractVector, faces)
    return if length(data) == length(faces)
        FaceIterator{:PerFace}(data, faces)
    else
        FaceIterator{:PerVert}(data, faces)
    end
end

Base.size(fi::FaceIterator) = size(fi.faces)
Base.getindex(fi::FaceIterator{:PerFace}, i::Integer) = fi.data[i]
Base.getindex(fi::FaceIterator{:PerVert}, i::Integer) = fi.data[fi.faces[i]]
Base.getindex(fi::FaceIterator{:Const}, i::Integer) = ntuple(i -> fi.data, 3)

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
            muv = 0.5n[Vec(1, 2)] .+ Vec2f(0.5)
            x, y = clamp.(round.(Int, Tuple(muv) .* wh) .+ 1, 1, wh)
            return matcap[end - (y - 1), x]
        end
        return FaceIterator(cvec, faces)
    elseif color isa Colorant
        return FaceIterator{:Const}(color, faces)
    elseif color isa AbstractVector{<:Colorant}
        return FaceIterator{:PerVert}(color, faces)
    elseif color isa Makie.AbstractPattern
        return Cairo.CairoPattern(color)
    elseif color isa Makie.ShaderAbstractions.Sampler # currently target for AbstractPattern
        @assert color.repeat === (:repeat, :repeat)
        return Cairo.CairoPattern(Makie.ImagePattern(color.data))
    elseif color isa AbstractMatrix{<:Colorant} && !isnothing(uv)
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
    elseif color isa AbstractArray{<:Any, 3}
        error("Volume texture only supported in GLMakie right now")
    end

    error("Unsupported Color type: $(typeof(color))")
end

function mesh_pattern_set_corner_color(pattern, id, c::Colorant)
    return Cairo.mesh_pattern_set_corner_color_rgba(pattern, id, rgbatuple(c)...)
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

is_approx_zero(x) = isapprox(x, 0)
is_approx_zero(v::VecTypes) = any(x -> isapprox(x, 0), v)

function is_degenerate(M::Mat2f)
    v1 = M[Vec(1, 2), 1]
    v2 = M[Vec(1, 2), 2]
    l1 = dot(v1, v1)
    l2 = dot(v2, v2)
    # Bad cases:   nan   ||     0 vector     ||   linearly dependent
    return any(isnan, M) || l1 ≈ 0 || l2 ≈ 0 || dot(v1, v2)^2 ≈ l1 * l2
end

zero_normalize(v::AbstractVector{T}) where {T} = v ./ (norm(v) + eps(zero(T)))
