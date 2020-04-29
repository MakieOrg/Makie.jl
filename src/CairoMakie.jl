module CairoMakie

using AbstractPlotting, LinearAlgebra
using Colors, GeometryBasics, FileIO, StaticArrays
import Cairo

using AbstractPlotting: Scene, Lines, Text, Image, Heatmap, Scatter, @key_str, broadcast_foreach
using AbstractPlotting: convert_attribute, @extractvalue, LineSegments, to_ndim, NativeFont
using AbstractPlotting: @info, @get_attribute, Combined
using AbstractPlotting: to_value, to_colormap, extrema_nan
using Cairo: CairoContext, CairoARGBSurface, CairoSVGSurface, CairoPDFSurface

const LIB_CAIRO = if isdefined(Cairo, :libcairo)
    Cairo.libcairo
else
    Cairo._jl_libcairo
end

include("infrastructure.jl")

function project_position(scene, point, model)
    res = scene.camera.resolution[]
    p4d = to_ndim(Vec4f0, to_ndim(Vec3f0, point, 0f0), 1f0)
    clip = scene.camera.projectionview[] * model * p4d
    # between -1 and 1
    p = (clip ./ clip[4])[Vec(1, 2)]
    # flip y to match cairo
    p_yflip = Vec2f0(p[1], -p[2])
    # normalize to between 0 and 1
    p_0_to_1 = (p_yflip .+ 1f0) / 2f0
    # multiply with scene resolution for final position
    result = p_0_to_1 .* res
end

project_scale(scene::Scene, s::Number, model = Mat4f0(I)) = project_scale(scene, Vec2f0(s), model)

function project_scale(scene::Scene, s, model = Mat4f0(I))
    p4d = to_ndim(Vec4f0, s, 0f0)
    p = (scene.camera.projectionview[] * model * p4d)[Vec(1, 2)] ./ 2f0
    p .* scene.camera.resolution[]
end

function draw_atomic(::Scene, ::CairoScreen, x)
    @warn "$(typeof(x)) is not supported by cairo right now"
end

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

function per_face_colors(color, colormap, colorrange, vertices, faces, uv)
    if color isa Colorant
        return FaceIterator{:Const}(color, faces)
    elseif color isa AbstractArray
        if color isa AbstractVector{<: Colorant}
            return FaceIterator(color, faces)
        elseif color isa AbstractVector{<: Number}
            cvec = AbstractPlotting.interpolated_getindex.((colormap,), color, (colorrange,))
            return FaceIterator(cvec, faces)
        elseif color isa AbstractMatrix{<: Colorant} && uv !== nothing
            cvec = map(uv) do uv
                wsize = reverse(size(color))
                wh = wsize .- 1
                x, y = round.(Int, Tuple(uv) .* wh) .+ 1
                return color[size(color, 1) - (y - 1), x]
            end
            # TODO This is wrong and doesn't actually interpolate
            # Inside the triangle sampling the color image
            return FaceIterator(cvec, faces)
        end
    end
    error("Unsupported Color type: $(typeof(color))")
end

function color2tuple3(c)
    (red(c), green(c), blue(c))
end
function colorant2tuple4(c)
    (red(c), green(c), blue(c), alpha(c))
end

mesh_pattern_set_corner_color(pattern, id, c::Color3) =
    Cairo.mesh_pattern_set_corner_color_rgb(pattern, id, color2tuple3(c)...)
mesh_pattern_set_corner_color(pattern, id, c::Colorant{T,4} where T) =
    Cairo.mesh_pattern_set_corner_color_rgba(pattern, id, colorant2tuple4(c)...)

function draw_atomic(scene::Scene, screen::CairoScreen, primitive::AbstractPlotting.Mesh)
    @get_attribute(primitive, (color,))

    colormap = get(primitive, :colormap, nothing) |> to_value |> to_colormap
    colorrange = get(primitive, :colorrange, nothing) |> to_value

    ctx = screen.context
    model = primitive.model[]
    mesh = primitive[1][]
    vs = coordinates(mesh); fs = faces(mesh)
    uv = hasproperty(mesh, :uv) ? mesh.uv : nothing
    pattern = Cairo.CairoPatternMesh()

    cols = per_face_colors(color, colormap, colorrange, vs, fs, uv)
    for (f, (c1, c2, c3)) in zip(fs, cols)
        t1, t2, t3 =  project_position.(scene, vs[f], (model,)) #triangle points
        Cairo.mesh_pattern_begin_patch(pattern)

        Cairo.mesh_pattern_move_to(pattern, t1...)
        Cairo.mesh_pattern_line_to(pattern, t2...)
        Cairo.mesh_pattern_line_to(pattern, t3...)

        mesh_pattern_set_corner_color(pattern, 0, c1)
        mesh_pattern_set_corner_color(pattern, 1, c2)
        mesh_pattern_set_corner_color(pattern, 2, c3)

        Cairo.mesh_pattern_end_patch(pattern)
    end
    Cairo.set_source(ctx, pattern)
    Cairo.close_path(ctx)
    Cairo.paint(ctx)
    return nothing
end

function numbers_to_colors(numbers::AbstractArray{<:Number}, primitive)

    colormap = get(primitive, :colormap, nothing) |> to_value |> to_colormap
    colorrange = get(primitive, :colorrange, nothing) |> to_value

    if colorrange === AbstractPlotting.automatic
        colorrange = extrema(numbers)
    end

    AbstractPlotting.interpolated_getindex.(
        Ref(colormap),
        Float64.(numbers), # ints don't work in interpolated_getindex
        Ref(colorrange))
end

function draw_atomic(scene::Scene, screen::CairoScreen, primitive::Union{Lines, LineSegments})
    fields = @get_attribute(primitive, (color, linewidth, linestyle))
    linestyle = AbstractPlotting.convert_attribute(linestyle, AbstractPlotting.key"linestyle"())
    ctx = screen.context
    model = primitive[:model][]
    positions = primitive[1][]

    isempty(positions) && return

    # workaround for a LineSegments object created from a GLNormalMesh
    # the input argument is a view of points using faces, which results in
    # a vector of tuples of two points. we convert those to a list of points
    # so they don't trip up the rest of the pipeline
    # TODO this shouldn't be necessary anymore!
    if positions isa SubArray{<:Point3, 1, P, <:Tuple{Array{<:AbstractFace}}} where P
        positions = let
            pos = Point3f0[]
            for tup in positions
                push!(pos, tup[1])
                push!(pos, tup[2])
            end
            pos
        end
    end

    projected_positions = project_position.(Ref(scene), positions, Ref(model))

    if color isa AbstractArray{<: Number}
        color = numbers_to_colors(color, primitive)
    end

    # color is now a color or an array of colors
    # if it's an array of colors, each segment must be stroked separately

    # linestyle can be set globally
    !isnothing(linestyle) && Cairo.set_dash(ctx, linestyle)

    if color isa AbstractArray || linewidth isa AbstractArray
        # stroke each segment separately, this means disjointed segments with probably
        # wonky dash patterns if segments are short

        # we can hide the gaps by setting the line cap to round
        Cairo.set_line_cap(ctx, Cairo.CAIRO_LINE_CAP_ROUND)
        draw_multi(primitive, ctx, projected_positions, color, linewidth)
    else
        # stroke the whole line at once if it has only one color
        # this allows correct linestyles and line joins as well and will be the
        # most common case
        Cairo.set_line_width(ctx, linewidth)
        Cairo.set_source_rgba(ctx, red(color), green(color), blue(color), alpha(color))
        draw_single(primitive, ctx, projected_positions)
    end
    nothing
end

function draw_single(primitive::Lines, ctx, positions)
    Cairo.move_to(ctx, positions[1]...)
    for i in 2:length(positions)
        if isnan(positions[i])
            i == length(positions) && break
            Cairo.move_to(ctx, positions[i+1]...)
        else
            Cairo.line_to(ctx, positions[i]...)
        end
    end
    Cairo.stroke(ctx)
end

function draw_single(primitive::LineSegments, ctx, positions)
    @assert iseven(length(positions))
    Cairo.move_to(ctx, positions[1]...)
    for i in 2:length(positions)
        if iseven(i)
            Cairo.line_to(ctx, positions[i]...)
        else
            Cairo.move_to(ctx, positions[i]...)
        end
    end
    Cairo.stroke(ctx)
end

# if linewidth is not an array
function draw_multi(primitive, ctx, positions, colors::AbstractArray, linewidth)
    draw_multi(primitive, ctx, positions, colors, [linewidth for c in colors])
end

# if color is not an array
function draw_multi(primitive, ctx, positions, color, linewidths::AbstractArray)
    draw_multi(primitive, ctx, positions, [color for l in linewidths], linewidths)
end

function draw_multi(primitive::Union{Lines, LineSegments}, ctx, positions, colors::AbstractArray, linewidths::AbstractArray)
    if primitive isa LineSegments
        @assert iseven(length(positions))
    end
    @assert length(positions) == length(colors)
    @assert length(linewidths) == length(colors)

    iterator = if primitive isa Lines
        1:length(positions)-1
    elseif primitive isa LineSegments
        1:2:length(positions)
    end

    for i in iterator
        if isnan(positions[i+1]) || isnan(positions[i])
            continue
        end
        Cairo.move_to(ctx, positions[i]...)

        Cairo.line_to(ctx, positions[i+1]...)
        if linewidths[i] != linewidths[i+1]
            error("Cairo doesn't support two different line widths ($(linewidths[i]) and $(linewidths[i+1])) at the endpoints of a line.")
        end
        Cairo.set_line_width(ctx, linewidths[i])
        c1 = colors[i]
        c2 = colors[i+1]
        # we can avoid the more expensive gradient if the colors are the same
        # this happens if one color was given for each segment
        if c1 == c2
            Cairo.set_source_rgba(ctx, red(c1), green(c1), blue(c1), alpha(c1))
            Cairo.stroke(ctx)
        else
            pat = Cairo.pattern_create_linear(positions[i]..., positions[i+1]...)
            Cairo.pattern_add_color_stop_rgba(pat, 0, red(c1), green(c1), blue(c1), alpha(c1))
            Cairo.pattern_add_color_stop_rgba(pat, 1, red(c2), green(c2), blue(c2), alpha(c2))
            Cairo.set_source(ctx, pat)
            Cairo.stroke(ctx)
            Cairo.destroy(pat)
        end
    end
end

function to_cairo_image(img::AbstractMatrix{<: AbstractFloat}, attributes)
    AbstractPlotting.@get_attribute attributes (colormap, colorrange)
    imui32 = to_uint32_color.(AbstractPlotting.interpolated_getindex.(Ref(colormap), img, (colorrange,)))
    to_cairo_image(imui32, attributes)
end

function to_cairo_image(img::Matrix{UInt32}, attributes)
    # In Cairo, the y-axis is expected to go from the top
    # to the bottom of the image, whereas in Makie we
    # expect it to go from the bottom to the top.
    # Therefore, we flip the y-axis here, to conform
    # to Cairo's notion of the image direction.

    # In addition, we are iterating over the y-axis first,
    # such that the "first" axis of the image is what used to
    # be the rows, instead of the columns.
    # This conforms to the row-major matrix interface which
    # Cairo expects, again.

    # To achieve all of this, it is sufficient to "rotate" the
    # matrix left by 90 degrees.
    return CairoARGBSurface(rotl90(img))
end
to_uint32_color(c) = reinterpret(UInt32, convert(ARGB32, c))
function to_cairo_image(img, attributes)
    to_cairo_image(to_uint32_color.(img), attributes)
end

function draw_atomic(scene::Scene, screen::CairoScreen, primitive::Union{Heatmap, Image})
    draw_image(scene, screen, primitive)
end

function draw_image(scene, screen, attributes)
    ctx = screen.context
    image = attributes[3][]
    x, y = attributes[1][], attributes[2][]
    model = attributes[:model][]
    imsize = (extrema_nan(x), extrema_nan(y))
    xy_ = project_position(scene, Point2f0(first.(imsize)), model)
    xymax_ = project_position(scene, Point2f0(last.(imsize)), model)
    xy = min.(xy_, xymax_)
    xymax = max.(xy_, xymax_)
    w, h = xymax .- xy
    interp = to_value(get(attributes, :interpolate, true))
    interp = interp ? Cairo.FILTER_BEST : Cairo.FILTER_NEAREST
    s = to_cairo_image(image, attributes)
    Cairo.rectangle(ctx, xy..., w, h)
    Cairo.save(ctx)
    Cairo.translate(ctx, xy[1], xy[2])
    Cairo.scale(ctx, w / s.width, h / s.height)
    Cairo.set_source_surface(ctx, s, 0, 0)
    p = Cairo.get_source(ctx)
    # Set filter doesn't work!?
    Cairo.pattern_set_filter(p, interp)
    Cairo.fill(ctx)
    Cairo.restore(ctx)
end
_extract_color(cmap, range, c) = to_color(c)
_extract_color(cmap, range, c::RGBf0) = RGBAf0(c, 1.0)
_extract_color(cmap, range, c::RGBAf0) = c
function _extract_color(cmap, range, c::Number)
    AbstractPlotting.interpolated_getindex(cmap, c, range)
end
function extract_color(cmap, range, c)
    c = _extract_color(cmap, range, c)
    red(c), green(c), blue(c), alpha(c)
end

function draw_marker(ctx, marker, pos, scale, strokecolor, strokewidth)
    pos += Point2f0(scale[1] / 2, -scale[2] / 2)
    Cairo.arc(ctx, pos[1], pos[2], scale[1] / 2, 0, 2*pi)
    Cairo.fill(ctx)
    sc = to_color(strokecolor)
    if strokewidth > 0.0
        Cairo.set_source_rgba(ctx, red(sc), green(sc), blue(sc), alpha(sc))
        Cairo.set_line_width(ctx, Float64(strokewidth))
        Cairo.stroke(ctx)
    end
end

function draw_marker(ctx, marker::Char, font, pos, scale, strokecolor, strokewidth)

    cairoface = set_ft_font(ctx, font)

    charextent = AbstractPlotting.FreeTypeAbstraction.internal_get_extent(font, marker)
    inkbb = AbstractPlotting.FreeTypeAbstraction.inkboundingbox(charextent)

    # scale normalized bbox by font size
    inkbb_scaled = FRect2D(origin(inkbb) .* scale, widths(inkbb) .* scale)

    # flip y for the centering shift of the character because in Cairo y goes down
    centering_offset = [1, -1] .* (-origin(inkbb_scaled) .- 0.5 .* widths(inkbb_scaled))
    # this is the origin where we actually have to place the glyph so it's centered
    charorigin = pos .+ centering_offset

    Cairo.move_to(ctx, charorigin...)
    mat = scale_matrix(scale...)
    set_font_matrix(ctx, mat)
    Cairo.text_path(ctx, string(marker))
    Cairo.fill_preserve(ctx)
    Cairo.set_line_width(ctx, strokewidth)
    Cairo.set_source_rgba(ctx, rgbatuple(strokecolor)...)
    Cairo.stroke(ctx)

    # if we use set_ft_font we should destroy the pointer it returns
    cairo_font_face_destroy(cairoface)

end


function draw_marker(ctx, marker::Union{Rect, Type{<: Rect}}, pos, scale, strokecolor, strokewidth)
    s2 = Point2f0(scale[1], -scale[2])
    Cairo.rectangle(ctx, pos..., s2...)
    Cairo.fill(ctx);
    if strokewidth > 0.0
        sc = to_color(strokecolor)
        Cairo.set_source_rgba(ctx, red(sc), green(sc), blue(sc), alpha(sc))
        Cairo.set_line_width(ctx, Float64(strokewidth))
        Cairo.stroke(ctx)
    end
end

function draw_atomic(scene::Scene, screen::CairoScreen, primitive::Scatter)
    fields = @get_attribute(primitive, (color, markersize, strokecolor, strokewidth, marker, marker_offset))
    @get_attribute(primitive, (transform_marker,))

    cmap = get(primitive, :colormap, nothing) |> to_value |> to_colormap
    crange = get(primitive, :colorrange, nothing) |> to_value
    ctx = screen.context
    model = primitive[:model][]
    positions = primitive[1][]
    isempty(positions) && return
    size_model = transform_marker ? model : Mat4f0(I)

    font = AbstractPlotting.defaultfont()

    broadcast_foreach(primitive[1][], fields...) do point, c, markersize, strokecolor, strokewidth, marker, mo

        # if we give size in pixels, the size is always equal to that value
        scale = if markersize isa AbstractPlotting.Pixel
            [markersize.value, markersize.value]
        else
            # otherwise calculate a scaled size
            project_scale(scene, markersize, size_model)
        end
        pos = project_position(scene, point, model)

        Cairo.set_source_rgba(ctx, extract_color(cmap, crange, c)...)
        m = convert_attribute(marker, key"marker"(), key"scatter"())
        if m isa Char
            draw_marker(ctx, m, font, pos, scale, strokecolor, strokewidth)
        else
            draw_marker(ctx, m, pos, scale, strokecolor, strokewidth)
        end
    end
    nothing
end

scale_matrix(x, y) = Cairo.CairoMatrix(x, 0.0, 0.0, y, 0.0, 0.0)

function set_font_matrix(cr, matrix)
    ccall((:cairo_set_font_matrix, LIB_CAIRO), Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}), cr.ptr, Ref(matrix))
end

function set_ft_font(cr, font)
    font_face = ccall(
        (:cairo_ft_font_face_create_for_ft_face, LIB_CAIRO),
        Ptr{Cvoid}, (AbstractPlotting.FreeTypeAbstraction.FT_Face, Cint),
        font, 0
    )
    ccall((:cairo_set_font_face, LIB_CAIRO), Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}), cr.ptr, font_face)
    font_face
end

function cairo_font_face_destroy(font_face)
    ccall(
        (:cairo_font_face_destroy, LIB_CAIRO),
        Cvoid, (Ptr{Cvoid},),
        font_face
    )
end

fontname(x::String) = x
fontname(x::Symbol) = string(x)
function fontname(x::NativeFont)
    return x.family_name
end

function draw_atomic(scene::Scene, screen::CairoScreen, primitive::Text)
    ctx = screen.context
    @get_attribute(primitive, (textsize, color, font, align, rotation, model, justification, lineheight))
    txt = to_value(primitive[1])
    position = primitive.attributes[:position][]
    N = length(txt)
    atlas = AbstractPlotting.get_texture_atlas()
    if position isa StaticArrays.StaticArray # one position to place text
        position = AbstractPlotting.layout_text(
            txt, position, textsize,
            font, align, rotation, model, justification, lineheight
        )
    end
    stridx = 1
    broadcast_foreach(1:N, position, textsize, color, font, rotation) do i, p, ts, cc, f, r
        Cairo.save(ctx)
        char = txt[stridx]

        stridx = nextind(txt, stridx)
        pos = project_position(scene, p, model)
        scale = project_scale(scene, ts, model)
        Cairo.move_to(ctx, pos[1], pos[2])
        Cairo.set_source_rgba(ctx, red(cc), green(cc), blue(cc), alpha(cc))
        cairoface = set_ft_font(ctx, f)

        mat = scale_matrix(scale...)
        set_font_matrix(ctx, mat)

        # TODO this only works in 2d
        Cairo.rotate(ctx, -AbstractPlotting.quaternion_to_2d_angle(r))

        if !(char in ('\r', '\n'))
            Cairo.show_text(ctx, string(char))
        end

        cairo_font_face_destroy(cairoface)

        Cairo.restore(ctx)
    end
    nothing
end

function rgbatuple(c::Colorant)
    rgba = RGBA(c)
    red(rgba), green(rgba), blue(rgba), alpha(rgba)
end

"""
Special method for polys so we don't fall back to atomic meshes, which are much more
complex and slower to draw than standard paths with single color.
"""
function draw_plot(scene::Scene, screen::CairoScreen, poly::Poly)
    # dispatch on input arguments to poly to use smarter drawing methods than
    # meshes if possible
    draw_poly(scene, screen, poly, to_value.(poly.input_args)...)
end

"""
Fallback method for args without special treatment.
"""
function draw_poly(scene::Scene, screen::CairoScreen, poly, args...)
    draw_poly_as_mesh(scene, screen, poly)
end

function draw_poly_as_mesh(scene, screen, poly)
    draw_plot(scene, screen, poly.plots[1])
    draw_plot(scene, screen, poly.plots[2])
end

function draw_poly(scene::Scene, screen::CairoScreen, poly, points::Vector{<:Point2})

    # in the rare case of per-vertex colors redirect to mesh drawing
    if poly.color[] isa Array
        draw_poly_as_mesh(scene, screen, poly)
        return
    end

    model = poly.model[]
    points = project_position.(Ref(scene), points, Ref(model))
    Cairo.move_to(screen.context, points[1]...)
    for p in points[2:end]
        Cairo.line_to(screen.context, p...)
    end
    Cairo.close_path(screen.context)
    Cairo.set_source_rgba(screen.context, rgbatuple(to_color(poly.color[]))...)
    Cairo.fill_preserve(screen.context)
    Cairo.set_source_rgba(screen.context, rgbatuple(to_color(poly.strokecolor[]))...)
    Cairo.set_line_width(screen.context, poly.strokewidth[])
    Cairo.stroke(screen.context)
end

function project_rect(scene, rect::Rect, model)
    mini = project_position(scene, minimum(rect), model)
    maxi = project_position(scene, maximum(rect), model)
    Rect(mini, maxi .- mini)
end

function draw_poly(scene::Scene, screen::CairoScreen, poly, rects::Vector{<:Rect2D})
    model = poly.model[]
    projected_rects = project_rect.(Ref(scene), rects, Ref(model))

    color = poly.color[]
    if color isa AbstractArray{<:Number}
        color = numbers_to_colors(color, poly)
    end
    strokecolor = poly.strokecolor[]
    if strokecolor isa AbstractArray{<:Number}
        strokecolor = numbers_to_colors(strokecolor, poly)
    end

    broadcast_foreach(projected_rects, color, strokecolor, poly.strokewidth[]) do r, c, sc, sw
        Cairo.rectangle(screen.context, origin(r)..., widths(r)...)
        Cairo.set_source_rgba(screen.context, rgbatuple(to_color(c))...)
        Cairo.fill_preserve(screen.context)
        Cairo.set_source_rgba(screen.context, rgbatuple(to_color(sc))...)
        Cairo.set_line_width(screen.context, sw)
        Cairo.stroke(screen.context)
    end
end

function draw_poly(scene::Scene, screen::CairoScreen, poly, rect::Rect2D)
    draw_poly(scene, screen, poly, [rect])
end

function __init__()
    activate!()
    AbstractPlotting.register_backend!(AbstractPlotting.current_backend[])
end

function display_path(type::String)
    if !(type in ("svg", "png", "pdf", "eps"))
        error("Only \"svg\", \"png\", \"eps\" and \"pdf\" are allowed for `type`. Found: $(type)")
    end
    return joinpath(@__DIR__, "display." * type)
end

function activate!(; inline = true, type = "svg")
    AbstractPlotting.current_backend[] = CairoBackend(display_path(type))
    AbstractPlotting.use_display[] = !inline
    return
end

end
