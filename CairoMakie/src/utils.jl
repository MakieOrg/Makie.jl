################################################################################
#                             Projection utilities                             #
################################################################################

function project_position(scene::Scene, transform_func::T, space, point, model::Mat4, yflip::Bool = true) where T
    # use transform func
    point = Makie.apply_transform(transform_func, point, space)
    _project_position(scene, space, point, model, yflip)
end

function _project_position(scene::Scene, space, point, model, yflip::Bool)
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

function project_position(@nospecialize(scenelike), space, point, model, yflip::Bool = true)
    scene = Makie.get_scene(scenelike)
    project_position(scene, Makie.transform_func(scenelike), space, point, model, yflip)
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

function project_shape(@nospecialize(scenelike), space, rect::Rect, model)
    mini = project_position(scenelike, space, minimum(rect), model)
    maxi = project_position(scenelike, space, maximum(rect), model)
    return Rect(mini, maxi .- mini)
end

function project_polygon(@nospecialize(scenelike), space, poly::P, model) where P <: Polygon
    ext = decompose(Point2f, poly.exterior)
    interiors = decompose.(Point2f, poly.interiors)
    Polygon(
        Point2f.(project_position.(Ref(scenelike), space, ext, Ref(model))),
        [Point2f.(project_position.(Ref(scenelike), space, interior, Ref(model))) for interior in interiors],
    )
end

function project_multipolygon(@nospecialize(scenelike), space, multipoly::MP, model) where MP <: MultiPolygon
    return MultiPolygon(project_polygon.(Ref(scenelike), Ref(space), multipoly.polygons, Ref(model)))
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
