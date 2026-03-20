function extract_attributes!(attr::ComputeGraph, inputs::Vector{Symbol}, output::Symbol)
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
    M = Makie.get_space_to_space_matrix(scene, space, :clip) * f32convert * model
    return cairo_viewport_matrix(scene.camera.resolution[], yflip) * M
end

function project_position(
        scene::Scene, space::Symbol, ps::AbstractArray{<:VecTypes},
        indices::Union{Vector{<:Integer}, Base.OneTo}, model::Mat4,
        yflip::Bool = true
    )
    transform = build_combined_transformation_matrix(scene, space, model, yflip)
    return project_position(Point2f, transform[Vec(1, 2, 4), Vec(1, 2, 3, 4)], ps, indices)
end

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
    T = promote_type(Float32, T1)
    res = scene.camera.resolution[]
    p4d = to_ndim(Vec4{T}, to_ndim(Vec3{T}, point, 0), 1)
    f32convert = Makie.f32_convert_matrix(scene.float32convert, space)
    clip = Makie.space_to_clip(scene.camera, space) * f32convert * model * p4d
    @inbounds begin
        p = (clip ./ clip[4])[Vec(1, 2)]
        p_yflip = Vec2f(p[1], (1.0f0 - 2.0f0 * yflip) * p[2])
        p_0_to_1 = (p_yflip .+ 1.0f0) ./ 2.0f0
    end
    return p_0_to_1 .* res
end

function project_position(@nospecialize(scenelike), space, point, model, yflip::Bool = true)
    scene = Makie.get_scene(scenelike)
    return project_position(scene, Makie.transform_func(scenelike), space, point, model, yflip)
end

function project_shape(@nospecialize(scenelike), space, rect::Rect, model)
    res = Makie.get_scene(scenelike).camera.resolution[]
    mini = clamp.(project_position(scenelike, space, minimum(rect), model), -res, 2 .* res)
    maxi = clamp.(project_position(scenelike, space, maximum(rect), model), -res, 2 .* res)
    return Rect(mini, maxi .- mini)
end

function clip_poly(clip_planes::Vector{Plane3f}, ps::AbstractVector{PT}, space::Symbol, model::Mat4) where {PT <: VecTypes{2}}
    if isempty(clip_planes) || !Makie.is_data_space(space)
        return ps
    end
    planes = to_model_space(model, clip_planes)
    last_distance = Makie.min_clip_distance(planes, first(ps))
    last_point = first(ps)
    output = sizehint!(PT[], length(ps))
    for p in ps
        d = Makie.min_clip_distance(planes, p)
        if (last_distance < 0) && (d >= 0)
            clip_point = - last_distance * (p - last_point) / (d - last_distance) + last_point
            push!(output, clip_point, p)
        elseif (last_distance >= 0) && (d < 0)
            clip_point = - last_distance * (p - last_point) / (d - last_distance) + last_point
            push!(output, clip_point)
        elseif (last_distance >= 0) && (d >= 0)
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
    ps = Point2d[xy, xy + Vec2d(w, 0), xy + Vec2d(w, h), xy + Vec2d(0, h)]
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

########################################
#        Common color utilities        #
########################################

function to_skia_plotcolor(colors::Union{AbstractVector, Number}, plot_object)
    cmap = Makie.assemble_colors(colors, Observable(colors), plot_object)
    return to_color(to_value(cmap))
end

function to_skia_plotcolor(color, plot_object)
    return to_color((color, to_value(plot_object.alpha)))
end

#######################################
#        Stroking properties          #
#######################################

to_skia_linestyle(::Nothing, ::Any) = nothing
to_skia_linestyle(::AbstractVector, ::AbstractArray) = nothing
function to_skia_linestyle(linestyle::AbstractVector, linewidth::Real)
    pattern = diff(Float64.(linestyle)) .* linewidth
    isodd(length(pattern)) && push!(pattern, 0)
    return pattern
end

function to_skia_miter_limit(miter_limit)
    return 2.0f0 * Makie.miter_angle_to_distance(miter_limit)
end

########################################
#        Marker conversion API         #
########################################

skia_scatter_marker(marker) = Makie.to_spritemarker(marker)

########################################
#     Image/heatmap helpers            #
########################################

function to_skia_image(img::AbstractMatrix{<:Colorant})
    return to_skia_image(to_uint32_color.(img))
end

function to_skia_image(img::AbstractMatrix{UInt32})
    # Return permuted for row-major Skia layout
    return convert(Matrix, permutedims(img))
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
        wsize1 = reverse(size(matcap::Matrix{RGBAf}))
        wh1 = wsize1 .- 1
        cvec = map(normals) do n
            muv = 0.5n[Vec(1, 2)] .+ Vec2f(0.5)
            x, y = clamp.(round.(Int, Tuple(muv) .* wh1) .+ 1, 1, wh1)
            return matcap[end - (y - 1), x]
        end
        return FaceIterator(cvec, faces)
    elseif color isa Colorant
        return FaceIterator{:Const}(color::RGBAf, faces)
    elseif color isa AbstractVector{<:Colorant}
        return FaceIterator{:PerVert}(color::Vector{RGBAf}, faces)
    elseif color isa AbstractMatrix{<:Colorant} && !isnothing(uv)
        wsize2 = size(color::Matrix{RGBAf})
        wh2 = wsize2 .- 1
        cvec = map(uv::Vector{Vec2f}) do uv
            x, y = clamp.(round.(Int, uv .* wh2) .+ 1, 1, wsize2)
            return color[x, y]::RGBAf
        end
        return FaceIterator(cvec, faces)
    end
    error("Unsupported Color type: $(typeof(color))")
end

################################################################################
#                                Font handling                                 #
################################################################################

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
    return any(isnan, M) || l1 ≈ 0 || l2 ≈ 0 || dot(v1, v2)^2 ≈ l1 * l2
end

zero_normalize(v::AbstractVector{T}) where {T} = v ./ (norm(v) + eps(zero(T)))

########################################
#     Screen-space projection for mesh #
########################################

function cairo_project_to_screen_impl(projectionview, resolution, model, pos, output_type = Point2f, yflip = true)
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
        attr;
        input_name = :positions_transformed_f32c, yflip = true, output_type = Point2f
    )
    Makie.register_computation!(
        attr,
        [:projectionview, :resolution, :model_f32c, input_name], [:cairo_screen_pos]
    ) do inputs, changed, cached
        output = cairo_project_to_screen_impl(values(inputs)..., output_type, yflip)
        return (output,)
    end
    return attr[:cairo_screen_pos][]
end
