################################################################################
#                             Projection utilities                             #
################################################################################

function project_position(scene, transform_func::T, space, point, model, yflip::Bool = true) where T
    # use transform func
    point = Makie.apply_transform(transform_func, point, space)
    _project_position(scene, space, point, model, yflip)
end

function _project_position(scene, space, point, model, yflip)
    res = scene.camera.resolution[]
    p4d = to_ndim(Vec4f, to_ndim(Vec3f, point, 0f0), 1f0)
    clip = Makie.space_to_clip(scene.camera, space) * model * p4d
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

function project_position(scene, space, point, model, yflip::Bool = true)
    project_position(scene, scene.transformation.transform_func[], space, point, model, yflip)
end

function project_scale(scene::Scene, space, s::Number, model = Mat4f(I))
    project_scale(scene, space, Vec2f(s), model)
end

function project_scale(scene::Scene, space, s, model = Mat4f(I))
    p4d = model * to_ndim(Vec4f, s, 0f0)
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

function project_rect(scene, space, rect::Rect, model)
    mini = project_position(scene, space, minimum(rect), model)
    maxi = project_position(scene, space, maximum(rect), model)
    return Rect(mini, maxi .- mini)
end

function project_polygon(scene, space, poly::P, model) where P <: Polygon
    ext = decompose(Point2f, poly.exterior)
    interiors = decompose.(Point2f, poly.interiors)
    Polygon(
        Point2f.(project_position.(Ref(scene), space, ext, Ref(model))),
        [Point2f.(project_position.(Ref(scene), space, interior, Ref(model))) for interior in interiors],
    )
end

function project_multipolygon(scene, space, multipoly::MP, model) where MP <: MultiPolygon
    return MultiPolygon(project_polygon.(Ref(scene), Ref(space), multipoly.polygons, Ref(model)))
end

scale_matrix(x, y) = Cairo.CairoMatrix(x, 0.0, 0.0, y, 0.0, 0.0)

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
#     Image/heatmap -> ARGBSurface     #
########################################

function to_cairo_image(img::AbstractMatrix{<: AbstractFloat}, attributes)
    to_cairo_image(to_rgba_image(img, attributes), attributes)
end

function to_rgba_image(img::AbstractMatrix{<: AbstractFloat}, attributes)
    Makie.@get_attribute attributes (colormap, colorrange, nan_color, lowclip, highclip)

    nan_color = Makie.to_color(nan_color)
    lowclip = isnothing(lowclip) ? lowclip : Makie.to_color(lowclip)
    highclip = isnothing(highclip) ? highclip : Makie.to_color(highclip)

    [get_rgba_pixel(pixel, colormap, colorrange, nan_color, lowclip, highclip) for pixel in img]
end

to_rgba_image(img::AbstractMatrix{<: Colorant}, attributes) = RGBAf.(img)

function get_rgba_pixel(pixel, colormap, colorrange, nan_color, lowclip, highclip)
    vmin, vmax = colorrange
    if isnan(pixel)
        RGBAf(nan_color)
    elseif pixel < vmin && !isnothing(lowclip)
        RGBAf(lowclip)
    elseif pixel > vmax && !isnothing(highclip)
        RGBAf(highclip)
    else
        RGBAf(Makie.interpolated_getindex(colormap, pixel, colorrange))
    end
end

function to_cairo_image(img::AbstractMatrix{<: Colorant}, attributes)
    to_cairo_image(to_uint32_color.(img), attributes)
end

function to_cairo_image(img::Matrix{UInt32}, attributes)
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

function per_face_colors(
        color, colormap, colorrange, matcap, faces, normals, uv,
        lowclip=nothing, highclip=nothing, nan_color=nothing
    )
    if matcap !== nothing
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
    elseif color isa AbstractArray
        if color isa AbstractVector{<: Colorant}
            return FaceIterator(color, faces)
        elseif color isa AbstractArray{<: Number}
            low, high = extrema(colorrange)
            cvec = map(color[:]) do c
                if isnan(c) && nan_color !== nothing
                    return nan_color
                elseif c < low && lowclip !== nothing
                    return lowclip
                elseif c > high && highclip !== nothing
                    return highclip
                else
                    Makie.interpolated_getindex(colormap, c, colorrange)
                end
            end
            return FaceIterator(cvec, faces)
        elseif color isa Makie.AbstractPattern
            # let next level extend and fill with CairoPattern
            return color
        elseif color isa AbstractMatrix{<: Colorant} && uv !== nothing
            wsize = reverse(size(color))
            wh = wsize .- 1
            cvec = map(uv) do uv
                x, y = clamp.(round.(Int, Tuple(uv) .* wh) .+ 1, 1, wh)
                return color[end - (y - 1), x]
            end
            # TODO This is wrong and doesn't actually interpolate
            # Inside the triangle sampling the color image
            return FaceIterator(cvec, faces)
        end
    end
    error("Unsupported Color type: $(typeof(color))")
end

function mesh_pattern_set_corner_color(pattern, id, c::Colorant)
    Cairo.mesh_pattern_set_corner_color_rgba(pattern, id, rgbatuple(c)...)
end

# NaN-aware normal handling


"""
    nan_aware_orthogonal_vector(v1, v2, v3) where N

Returns an un-normalized normal vector for the triangle formed by the three input points.
Skips any combination of the inputs for which any point has a NaN component.
"""
function nan_aware_orthogonal_vector(v1, v2, v3)
    centroid = Vec3f(((v1 .+ v2 .+ v3) ./ 3)...)
    normal = [0.0, 0.0, 0.0]
    # if the coord is NaN, then do not add.
    (isnan(v1) | isnan(v2)) || (normal += cross(v2 .- centroid, v1 .- centroid))
    (isnan(v2) | isnan(v3)) || (normal += cross(v3 .- centroid, v2 .- centroid))
    (isnan(v3) | isnan(v1)) || (normal += cross(v1 .- centroid, v3 .- centroid))
    return Vec3f(normal).*-1
end

# Hijack GeometryBasics.jl machinery

"A wrapper type which instructs `GeometryBasics.normals`` to use the NaN-aware path.  Construct as `_NanAware{normaltype}()`."
struct _NanAware{T}
end

# A NaN-aware version of GeometryBasics.normals.
function GeometryBasics.normals(vertices::AbstractVector{<:AbstractPoint{3,T}}, faces::AbstractVector{F},
                 ::_NanAware{N}) where {T,F<:NgonFace,N}
    normals_result = zeros(N, length(vertices))
    free_verts = GeometryBasics.metafree.(vertices)

    for face in faces

        v1, v2, v3 = free_verts[face]
        # we can get away with two edges since faces are planar.
        n = nan_aware_orthogonal_vector(v1, v2, v3)

        for i in 1:length(F)
            fi = face[i]
            normals_result[fi] = normals_result[fi] + n
        end
    end
    normals_result .= GeometryBasics.normalize.(normals_result)
    return normals_result
end

function GeometryBasics.normals(vertices::AbstractVector{<:AbstractPoint{2,T}}, faces::AbstractVector{F},
    normaltype::_NanAware{N}) where {T,F<:NgonFace,N}
    return Vec2f.(GeometryBasics.normals(map(v -> Point3{T}(v..., 0), vertices), faces, normaltype))
end


function GeometryBasics.normals(vertices::AbstractVector{<:GeometryBasics.PointMeta{D,T}}, faces::AbstractVector{F},
    normaltype::_NanAware{N}) where {D,T,F<:NgonFace,N}
    return GeometryBasics.normals(collect(metafree.(vertices)), faces, normaltype)
end

# Below are nan-aware versions of GeometryBasics functions.
# These are basically copied straight from GeometryBasics.jl,
# since the normal type on some of them is not exposed.

function nan_aware_normal_mesh(primitive::GeometryBasics.Meshable{N}; nvertices=nothing) where {N}
    if nvertices !== nothing
        @warn("nvertices argument deprecated. Wrap primitive in `Tesselation(primitive, nvertices)`")
        primitive = Tesselation(primitive, nvertices)
    end
    return GeometryBasics.mesh(primitive; pointtype=Point{N,Float32}, normaltype=_NanAware{Vec3f}(),
                facetype=GLTriangleFace)
end

function nan_aware_normal_mesh(points::AbstractVector{<:AbstractPoint},
    faces::AbstractVector{<:AbstractFace})
    _points = GeometryBasics.decompose(Point3f, points)
    _faces = GeometryBasics.decompose(GeometryBasics.GLTriangleFace, faces)
    return GeometryBasics.Mesh(GeometryBasics.meta(_points; normals=GeometryBasics.normals(_points, _faces, _NanAware{Vec3f}())), _faces)
end

function nan_aware_decompose(NT::GeometryBasics.Normal{T}, primitive) where {T}
    return GeometryBasics.collect_with_eltype(T, GeometryBasics.normals(GeometryBasics.coordinates(primitive), GeometryBasics.faces(primitive), _NanAware{T}()))
end

nan_aware_decompose_normals(primitive) = nan_aware_decompose(GeometryBasics.Normal(), primitive)


################################################################################
#                                Font handling                                 #
################################################################################


"""
Finds a font that can represent the unicode character!
Returns Makie.defaultfont() if not representable!
"""
function best_font(c::Char, font = Makie.defaultfont())
    if Makie.FreeType.FT_Get_Char_Index(font, c) == 0
        for afont in Makie.alternativefonts()
            if Makie.FreeType.FT_Get_Char_Index(afont, c) != 0
                return afont
            end
        end
        return Makie.defaultfont()
    end
    return font
end
