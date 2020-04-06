module CairoMakie

using AbstractPlotting, LinearAlgebra
using Colors, GeometryTypes, FileIO, StaticArrays
import Cairo

using AbstractPlotting: Scene, Lines, Text, Image, Heatmap, Scatter, @key_str, broadcast_foreach
using AbstractPlotting: convert_attribute, @extractvalue, LineSegments, to_ndim, NativeFont
using AbstractPlotting: @info, @get_attribute, Combined
using AbstractPlotting: to_value, to_colormap, extrema_nan
using Cairo: CairoContext, CairoARGBSurface, CairoSVGSurface, CairoPDFSurface

@enum RenderType SVG PNG PDF

const LIB_CAIRO = if isdefined(Cairo, :libcairo)
    Cairo.libcairo
else
    Cairo._jl_libcairo
end

struct CairoBackend <: AbstractPlotting.AbstractBackend
    typ::RenderType
    path::String
end

function to_mime(x::RenderType)
    x == SVG && return MIME"image/svg+xml"()
    x == PDF && return MIME"application/pdf"()
    return MIME"image/png"()
end

to_mime(x::CairoBackend) = to_mime(x.typ)

function CairoBackend(path::String)
    ext = splitext(path)[2]
    typ = if ext == ".png"
        PNG
    elseif ext == ".svg"
        SVG
    elseif ext == ".pdf"
        PDF
    else
        error("Unsupported extension: $ext")
    end
    CairoBackend(typ, path)
end

struct CairoScreen{S} <: AbstractPlotting.AbstractScreen
    scene::Scene
    surface::S
    context::CairoContext
    pane::Nothing#Union{CairoGtkPane, Void}
end
# # we render the scene directly, since we have no screen dependant state like in e.g. opengl
Base.insert!(screen::CairoScreen, scene::Scene, plot) = nothing

function Base.show(io::IO, ::MIME"text/plain", screen::CairoScreen{S}) where S
    println(io, "CairoScreen{$S} with surface:")
    println(io, screen.surface)
end

# Default to Window+Canvas as backing device
function CairoScreen(scene::Scene)
    w, h = size(scene)
    surf = CairoARGBSurface(w, h)
    ctx = CairoContext(surf)
    CairoScreen(scene, surf, ctx, nothing)
end

function CairoScreen(scene::Scene, path::Union{String, IO}; mode = :svg)
    w, h = round.(Int, scene.camera.resolution[])
    # TODO: Add other surface types (PDF, etc.)
    if mode == :svg
        surf = CairoSVGSurface(path, w, h)
    elseif mode == :pdf
        surf = CairoPDFSurface(path, w, h)
    else
        error("No available Cairo surface for mode $mode")
    end
    ctx = CairoContext(surf)
    CairoScreen(scene, surf, ctx, nothing)
end

function project_position(scene, point, model)
    res = scene.camera.resolution[]
    p4d = to_ndim(Vec4f0, to_ndim(Vec3f0, point, 0f0), 1f0)
    clip = scene.camera.projectionview[] * model * p4d
    p = (clip ./ clip[4])[Vec(1, 2)]
    p = Vec2f0(p[1], -p[2])
    ((((p .+ 1f0) / 2f0) .* (res .- 1f0)) .+ 1f0)
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

function draw_atomic(scene::Scene, screen::CairoScreen, primitive::Mesh)
    @get_attribute(primitive, (color,))

    colormap = get(primitive, :colormap, nothing) |> to_value |> to_colormap
    colorrange = get(primitive, :colorrange, nothing) |> to_value

    ctx = screen.context
    model = primitive.model[]
    mesh = primitive[1][]
    vs = vertices(mesh); fs = faces(mesh)
    uv = hastexturecoordinates(mesh) ? texturecoordinates(mesh) : nothing
    pattern = Cairo.CairoPatternMesh()

    if mesh.attributes !== nothing && mesh.attribute_id !== nothing
        color = mesh.attributes[Int.(mesh.attribute_id .+ 1)]
    end
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
        Float64.(numbers), # ints don't work in AbstractPlotting
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
    if positions isa SubArray{<:Point3, 1, P, <:Tuple{Array{<:Face}}} where P
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
            # Cairo.move_to(ctx, positions[]...)
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
    CairoARGBSurface([img[j, i] for i in size(img, 2):-1:1, j in 1:size(img, 1)])
end
to_uint32_color(c) = reinterpret(UInt32, convert(ARGB32, c))
function to_cairo_image(img, attributes)
    to_cairo_image(to_uint32_color.(img), attributes)
end

function draw_atomic(scene::Scene, screen::CairoScreen, primitive::Image)
    draw_image(scene, screen, primitive)
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

function draw_marker(ctx, marker::Char, pos, scale, strokecolor, strokewidth)
    pos += Point2f0(scale[1] / 2, -scale[2] / 2)

    #TODO this shouldn't be hardcoded, but isn't available in the plot right now
    font = AbstractPlotting.assetpath("DejaVu Sans")
    Cairo.select_font_face(
        ctx, font,
        Cairo.FONT_SLANT_NORMAL,
        Cairo.FONT_WEIGHT_NORMAL
    )
    Cairo.move_to(ctx, pos[1], pos[2])
    mat = scale_matrix(scale...)
    set_font_matrix(ctx, mat)
    Cairo.show_text(ctx, string(marker))
    Cairo.fill(ctx)
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
    broadcast_foreach(primitive[1][], fields...) do point, c, markersize, strokecolor, strokewidth, marker, mo
        scale = project_scale(scene, markersize, size_model)
        pos = project_position(scene, point, model)
        mo = project_scale(scene, mo, size_model)
        pos += Point2f0(mo[1], -mo[2])
        Cairo.set_source_rgba(ctx, extract_color(cmap, crange, c)...)
        m = convert_attribute(marker, key"marker"(), key"scatter"())
        draw_marker(ctx, m, pos, scale, strokecolor, strokewidth)
    end
    nothing
end

scale_matrix(x, y) = Cairo.CairoMatrix(x, 0.0, 0.0, y, 0.0, 0.0)
function rot_scale_matrix(x, y, q)
    sx, sy, sz = 2q[4]*q[1], 2q[4]*q[2], 2q[4]*q[3]
    xx, xy, xz = 2q[1]^2, 2q[1]*q[2], 2q[1]*q[3]
    yy, yz, zz = 2q[2]^2, 2q[2]*q[3], 2q[3]^2
    m = Cairo.CairoMatrix(
        x, 1 - (xx + zz), yz + sx,
        y, yz - sx, 1 - (xx + yy)
    )
    m
end

function set_font_matrix(cr, matrix)
    ccall((:cairo_set_font_matrix, LIB_CAIRO), Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}), cr.ptr, Ref(matrix))
end


function set_ft_font(cr, font)
    font_face = ccall(
        (:cairo_ft_font_face_create_for_ft_face, LIB_CAIRO),
        Ptr{Cvoid}, (Ptr{Cvoid}, Cint),
        font, 0
    )
    ccall((:cairo_set_font_face, LIB_CAIRO), Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}), cr.ptr, font_face)
end
fontname(x::String) = x
fontname(x::Symbol) = string(x)
function fontname(x::NativeFont)
    return x.family_name
end

function fontscale(atlas, scene, c, font, s)
    s = (s ./ atlas.scale[AbstractPlotting.glyph_index!(atlas, c, font)]) ./ 0.02
    project_scale(scene, s)
end

function to_rel_scale(atlas, c, font, scale)
    gs = atlas.scale[AbstractPlotting.glyph_index!(atlas, c, font)]
    (scale ./ 0.02) ./ gs
end

function draw_atomic(scene::Scene, screen::CairoScreen, primitive::Text)
    ctx = screen.context
    @get_attribute(primitive, (textsize, color, font, align, rotation, model))
    txt = to_value(primitive[1])
    position = primitive.attributes[:position][]
    N = length(txt)
    atlas = AbstractPlotting.get_texture_atlas()
    if position isa StaticArrays.StaticArray # one position to place text
        position, textsize = AbstractPlotting.layout_text(
            txt, position, textsize,
            font, align, rotation, model
        )
    end
    stridx = 1
    broadcast_foreach(1:N, position, textsize, color, font, rotation) do i, p, ts, cc, f, r
        Cairo.save(ctx)
        char = txt[stridx]
        stridx = nextind(txt, stridx)
        rels = to_rel_scale(atlas, char, f, ts)
        pos = project_position(scene, p, Mat4f0(I))
        Cairo.move_to(ctx, pos[1], pos[2])
        Cairo.set_source_rgba(ctx, red(cc), green(cc), blue(cc), alpha(cc))
        Cairo.select_font_face(
            ctx, fontname(f),
            Cairo.FONT_SLANT_NORMAL,
            Cairo.FONT_WEIGHT_NORMAL
        )
        #set_ft_font(ctx, f)
        ts = fontscale(atlas, scene, char, f, ts)
        mat = scale_matrix(ts...)
        set_font_matrix(ctx, mat)
        # set_font_size(ctx, 16)
        # TODO this only works in 2d
        Cairo.rotate(ctx, -2acos(r[4]))
        Cairo.show_text(ctx, string(char))
        Cairo.restore(ctx)
    end
    nothing
end

function cairo_clear(screen::CairoScreen)
    ctx = screen.context
    w, h = Cairo.width(ctx), Cairo.height(ctx)
    Cairo.rectangle(ctx, 0, 0, w, h)
    # FIXME: Cairo.set_source_rgb(ctx, screen.scene.theme[:color]...)
    Cairo.fill(ctx)
end


function draw_background(screen::CairoScreen, scene::Scene)
    cr = screen.context
    Cairo.save(cr)
    if scene.clear[]
        bg = to_color(theme(scene, :backgroundcolor)[])
        Cairo.set_source_rgba(cr, red(bg), green(bg), blue(bg), alpha(bg));    # light gray
        r = pixelarea(scene)[]
        Cairo.rectangle(cr, minimum(r)..., widths(r)...) # background
        fill(cr)
    end
    Cairo.restore(cr)
    foreach(child_scene-> draw_background(screen, child_scene), scene.children)
end

function draw_plot(scene::Scene, screen::CairoScreen, primitive::Combined)
    isempty(primitive.plots) && return draw_atomic(scene, screen, primitive)
    for plot in primitive.plots
        (plot.visible[] == true) && draw_plot(scene, screen, plot)
    end
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

function draw_plot(screen::CairoScreen, scene::Scene)

    # get the root area to correct for its pixel size when translating
    root_area = AbstractPlotting.root(scene).px_area[]

    root_area_height = widths(root_area)[2]
    scene_area = pixelarea(scene)[]
    scene_height = widths(scene_area)[2]
    scene_x_origin, scene_y_origin = scene_area.origin

    Cairo.save(screen.context)

    # we need to translate x by the origin, so distance from the left
    # but y by the distance from the top, which is not the origin, but can
    # be calculated using the parent's height, the scene's height and the y origin
    # this is because y goes downwards in Cairo and upwards in AbstractPlotting

    top_offset = root_area_height - scene_height - scene_y_origin
    Cairo.translate(screen.context, scene_x_origin, top_offset)

    # clip the scene to its pixelarea
    Cairo.rectangle(screen.context, 0, 0, widths(scene_area)...)
    Cairo.clip(screen.context)

    for elem in scene.plots
        if to_value(get(elem, :visible, true))
             draw_plot(scene, screen, elem)
        end
    end
    Cairo.restore(screen.context)

    for child in scene.children
        draw_plot(screen, child)
    end

    return
end


function cairo_draw(screen::CairoScreen, scene::Scene)
    AbstractPlotting.update!(scene)
    draw_background(screen, scene)
    draw_plot(screen, scene)
    return
end

function AbstractPlotting.backend_display(x::CairoBackend, scene::Scene)
    return open(x.path, "w") do io
        AbstractPlotting.backend_show(x, io, to_mime(x), scene)
    end
end

function AbstractPlotting.colorbuffer(screen::CairoScreen)
    # extract scene
    scene = screen.scene
    # get resolution
    w, h = size(scene)
    # preallocate an image matrix
    img = Matrix{ARGB32}(undef, w, h)
    # create an image surface to draw onto the image
    surf = Cairo.CairoImageSurface(img)
    # draw the scene onto the image matrix
    ctx = Cairo.CairoContext(surf)
    scr = CairoScreen(scene, surf, ctx, nothing)
    cairo_draw(scr, scene)

    # x and y are flipped - return the transpose
    return transpose(img)

end

AbstractPlotting.backend_showable(x::CairoBackend, m::MIME"image/svg+xml", scene::Scene) = x.typ == SVG
AbstractPlotting.backend_showable(x::CairoBackend, m::MIME"application/pdf", scene::Scene) = x.typ == PDF
AbstractPlotting.backend_showable(x::CairoBackend, m::MIME"image/png", scene::Scene) = x.typ == PNG


function AbstractPlotting.backend_show(x::CairoBackend, io::IO, ::MIME"image/svg+xml", scene::Scene)
    screen = CairoScreen(scene, io)
    cairo_draw(screen, scene)
    Cairo.finish(screen.surface)
    return screen
end

function AbstractPlotting.backend_show(x::CairoBackend, io::IO, ::MIME"application/pdf", scene::Scene)
    screen = CairoScreen(scene, io,mode=:pdf)
    cairo_draw(screen, scene)
    Cairo.finish(screen.surface)
    return screen
end

function AbstractPlotting.backend_show(x::CairoBackend, io::IO, m::MIME"image/png", scene::Scene)
    screen = CairoScreen(scene, io)
    cairo_draw(screen, scene)
    Cairo.write_to_png(screen.surface, io)
    return screen
end

function AbstractPlotting.backend_show(x::CairoBackend, io::IO, m::MIME"image/jpeg", scene::Scene)
    screen = nothing
    open(display_path("png"), "w") do fio
        screen = AbstractPlotting.backend_show(x, fio, MIME"image/png"(), scene)
    end
    FileIO.save(FileIO.Stream(format"JPEG", io),  FileIO.load(display_path("png")))
    return screen
end

function __init__()
    activate!()
    AbstractPlotting.register_backend!(AbstractPlotting.current_backend[])
end

function display_path(type::String)
    if !(type in ("svg", "png", "pdf"))
        error("Only \"svg\", \"png\" and \"pdf\" are allowed for `type`. Found: $(type)")
    end
    return joinpath(@__DIR__, "display." * type)
end

function activate!(; inline = true, type = "svg")
    AbstractPlotting.current_backend[] = CairoBackend(display_path(type))
    AbstractPlotting.use_display[] = !inline
    return
end

end
