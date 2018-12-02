module CairoMakie

using AbstractPlotting
using AbstractPlotting: Scene, Lines, Text, Image, Heatmap, Scatter, @key_str, broadcast_foreach
using AbstractPlotting: convert_attribute, @extractvalue, LineSegments, to_ndim, NativeFont
using AbstractPlotting: @info, @get_attribute, Combined
using Colors, GeometryTypes
using AbstractPlotting: to_value, to_colormap, extrema_nan
using Cairo, FileIO
using LinearAlgebra

@enum RenderType SVG PNG

struct CairoBackend <: AbstractPlotting.AbstractBackend
    typ::RenderType
    path::String
end

function to_mime(x::RenderType)
    x == SVG && return MIME"image/svg+xml"()
    return MIME"image/png"()
end
to_mime(x::CairoBackend) = to_mime(x.typ)

function CairoBackend(path::String)
    ext = splitext(path)[2]
    typ = if ext == ".png"
        PNG
    elseif ext == ".svg"
        SVG
    else
        error("Unsupported extension: $ext")
    end
    CairoBackend(typ, path)
end

struct CairoScreen{S}
    scene::Scene
    surface::S
    context::CairoContext
    pane::Nothing#Union{CairoGtkPane, Void}
end
# # we render the scene directly, since we have no screen dependant state like in e.g. opengl
Base.insert!(screen::CairoScreen, scene::Scene, plot) = nothing

# Default to Gtk Window+Canvas as backing device
function CairoScreen(scene::Scene)
    w, h = size(scene)
    surf = CairoRGBSurface(w, h)
    ctx = CairoContext(surf)
    CairoScreen(scene, surf, ctx, nothing)
end

function CairoScreen(scene::Scene, path::Union{String, IO}; mode = :svg)
    w, h = round.(Int, scene.camera.resolution[])
    # TODO: Add other surface types (PDF, etc.)
    if mode == :svg
        surf = CairoSVGSurface(path, w, h)
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
    p = (clip / clip[4])[Vec(1, 2)]
    p = Vec2f0(p[1], -p[2])
    ((((p + 1f0) / 2f0) .* (res - 1f0)) + 1f0)
end
project_scale(scene::Scene, s::Number, model = Mat4f0(I)) = project_scale(scene, Vec2f0(s), model)
function project_scale(scene::Scene, s, model = Mat4f0(I))
    p4d = to_ndim(Vec4f0, s, 0f0)
    p = (scene.camera.projectionview[] * model * p4d)[Vec(1, 2)] ./ 2f0
    p .* scene.camera.resolution[]
end

function draw_segment(scene, ctx, point::Point, model, c, linewidth, linestyle, primitive, idx, N)
    pos = project_position(scene, point, model)
    function stroke()
        Cairo.set_line_width(ctx, Float64(linewidth))
        Cairo.set_source_rgba(ctx, red(c), green(c), blue(c), alpha(c))
        if linestyle != nothing
            #set_dash(ctx, linestyle, 0.0)
        end
        Cairo.stroke(ctx)
    end
    if !all(isfinite.(pos))
        stroke() # stroke last points, ignore this one (NaN for disconnects)
    else
        if isa(primitive, LineSegments)
            if isodd(idx) # on each odd move to
                Cairo.move_to(ctx, pos[1], pos[2])
            else
                Cairo.line_to(ctx, pos[1], pos[2])
                stroke() # stroke after each segment
            end
        else
            if idx == 1
                Cairo.move_to(ctx, pos[1], pos[2])
            else
                Cairo.line_to(ctx, pos[1], pos[2])
                Cairo.move_to(ctx, pos[1], pos[2])
            end
        end
    end
    if idx == N && isa(primitive, Lines) # after adding all points, lines need a stroke
        stroke()
    end
end

function draw_segment(scene, ctx, point::Tuple{<: Point, <: Point}, model, c, linewidth, linestyle, primitive, idx, N)
    draw_segment(scene, ctx, point[1], model, c, linewidth, linestyle, primitive, 1 + (idx - 1) * 2, N)
    draw_segment(scene, ctx, point[2], model, c, linewidth, linestyle, primitive, (idx - 1) * 2, N)
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

function per_face_colors(color, colormap, colorrange, vertices, faces)
    if color isa Colorant
        return FaceIterator{:Const}(color, faces)
    elseif color isa AbstractVector
        if color isa AbstractVector{<: Colorant}
            return FaceIterator(color, faces)
        elseif color isa AbstractVector{<: Number}
            cvec = AbstractPlotting.interpolated_getindex.((colormap,), color, (colorrange,))
            return FaceIterator(cvec, faces)
        end
    end
    error("Unsupported Color type: $(typeof(color))")
end

function color2tuple3(c)
    (red(c), green(c), blue(c))
end

function draw_atomic(scene::Scene, screen::CairoScreen, primitive::Mesh)
    @get_attribute(primitive, (color,))

    colormap = get(primitive, :colormap, nothing) |> to_value |> to_colormap
    colorrange = get(primitive, :colorrange, nothing) |> to_value

    ctx = screen.context
    model = primitive.model[]
    mesh = primitive[1][]
    vs = vertices(mesh); fs = faces(mesh);
    pattern = Cairo.CairoPatternMesh()
    cols = per_face_colors(color, colormap, colorrange, vs, fs)
    for (f, (c1, c2, c3)) in zip(fs, cols)
        t1, t2, t3 =  project_position.(scene, vs[f], (model,)) #triangle points
        Cairo.mesh_pattern_begin_patch(pattern)

        Cairo.mesh_pattern_move_to(pattern, t1...)
        Cairo.mesh_pattern_line_to(pattern, t2...)
        Cairo.mesh_pattern_line_to(pattern, t3...)

        Cairo.mesh_pattern_set_corner_color_rgb(pattern, 0, color2tuple3(c1)...)
        Cairo.mesh_pattern_set_corner_color_rgb(pattern, 1, color2tuple3(c2)...)
        Cairo.mesh_pattern_set_corner_color_rgb(pattern, 2, color2tuple3(c3)...)

        Cairo.mesh_pattern_end_patch(pattern)

        Cairo.set_source(ctx, pattern)
        Cairo.close_path(ctx)
        Cairo.paint(ctx)
    end
    nothing
end

function draw_atomic(scene::Scene, screen::CairoScreen, primitive::Union{Lines, LineSegments})
    fields = @get_attribute(primitive, (color, linewidth, linestyle))
    ctx = screen.context
    model = primitive[:model][]
    positions = primitive[1][]
    isempty(positions) && return
    N = length(positions)
    broadcast_foreach(1:N, positions, color, linewidth) do i, point, c, linewidth
        draw_segment(scene, ctx, point, model, c, linewidth, linestyle, primitive, i, N)
    end
    nothing
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
    xy = project_position(scene, Point2f0(first.(imsize)), model)
    xymax = project_position(scene, Point2f0(last.(imsize)), model)
    w, h = xymax .- xy
    interp = to_value(get(attributes, :interpolate, true))
    interp = interp ? Cairo.FILTER_BEST : Cairo.FILTER_NEAREST
    Cairo.save(ctx);
    pattern = Cairo.CairoPattern(to_cairo_image(image, attributes))
    Cairo.pattern_set_extend(pattern, Cairo.EXTEND_PAD)
    Cairo.pattern_set_filter(pattern, interp)
    Cairo.set_source(ctx, pattern)
    Cairo.rectangle(ctx, xy..., w, h)
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

function draw_marker(ctx, marker, pos, scale, color, strokecolor, strokewidth)
    Cairo.set_source_rgba(ctx, color...)
    Cairo.arc(ctx, pos[1], pos[2], scale[1] / 2, 0, 2*pi)
    Cairo.fill(ctx)
    sc = to_color(strokecolor)
    Cairo.set_source_rgba(ctx, red(sc), green(sc), blue(sc), alpha(sc))
    Cairo.set_line_width(ctx, Float64(strokewidth))
    Cairo.arc(ctx, pos[1], pos[2], scale[1], 0, 2*pi)
    Cairo.stroke(ctx)
end

function draw_marker(ctx, marker::Union{Rect, Type{<: Rect}}, pos, scale, color, strokecolor, strokewidth)
    Cairo.set_source_rgba(ctx, color...)
    Cairo.rectangle(ctx, pos..., scale[1], -scale[2])
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
    cmap = get(primitive, :colormap, nothing) |> to_value |> to_colormap
    crange = get(primitive, :colorrange, nothing) |> to_value
    ctx = screen.context
    model = primitive[:model][]
    positions = primitive[1][]
    isempty(positions) && return
    broadcast_foreach(primitive[1][], fields...) do point, c, markersize, strokecolor, strokewidth, marker, mo
        # TODO: Implement marker
        # TODO: Accept :radius field or similar?
        scale = project_scale(scene, markersize, model)
        pos = project_position(scene, point, model)
        mo = project_scale(scene, mo)
        pos += mo
        draw_marker(ctx, marker, pos, scale, extract_color(cmap, crange, c), strokecolor, strokewidth)
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
    ccall((:cairo_set_font_matrix, Cairo._jl_libcairo), Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}), cr.ptr, Ref(matrix))
end


function set_ft_font(cr, font)
    font_face = ccall(
        (:cairo_ft_font_face_create_for_ft_face, Cairo._jl_libcairo),
        Ptr{Cvoid}, (Ptr{Cvoid}, Cint),
        font, 0
    )
    ccall((:cairo_set_font_face, Cairo._jl_libcairo), Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}), cr.ptr, font_face)
end
fontname(x::String) = x
fontname(x::Symbol) = string(x)
function fontname(x::NativeFont)
    ft_rect = unsafe_load(x[1])
    unsafe_string(ft_rect.family_name)
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
    broadcast_foreach(1:N, position, textsize, color, font, rotation) do i, p, ts, cc, f, r
        Cairo.save(ctx)
        char = N == length(position) ? txt[i] : first(txt)
        rels = to_rel_scale(atlas, char, f, ts)
        b = AbstractPlotting.glyph_bearing!(atlas, char, f, rels)
        p2 = to_ndim(Point{length(p), Float32}, b, 0f0)
        pos = project_position(scene, p, model)
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
        rotate(ctx, 2acos(r[4]))
        if N == length(position) # if one position per glyph
            Cairo.show_text(ctx, string(txt[i]))
        else
            Cairo.show_text(ctx, txt)
        end
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
    if theme(scene, :clear)[]
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
        draw_plot(scene, screen, plot)
    end
end

function draw_plot(screen::CairoScreen, scene::Scene)
    Cairo.save(screen.context)
    Cairo.translate(screen.context, minimum(pixelarea(scene)[])...)
    for elem in scene.plots
        draw_plot(scene, screen, elem)
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
    open(x.path, "w") do io
        AbstractPlotting.backend_show(x, io, to_mime(x), scene)
    end
    (x, scene)
end

function AbstractPlotting.colorbuffer(tup::Tuple{<: CairoBackend, Scene})
    screen, scene = tup
    # TODO this is super slow, we need to design the colorbuffer
    # api to be able to reuse a RGB surface
    AbstractPlotting.backend_display(screen, scene)
    FileIO.load(screen.path)
end
AbstractPlotting.backend_showable(x::CairoBackend, m::MIME"image/svg+xml", scene::SceneLike) = x.typ == SVG
AbstractPlotting.backend_showable(x::CairoBackend, m::MIME"image/png", scene::SceneLike) = x.typ == PNG


function AbstractPlotting.backend_show(x::CairoBackend, io::IO, ::MIME"image/svg+xml", scene::Scene)
    screen = CairoScreen(scene, io)
    cairo_draw(screen, scene)
    Cairo.finish(screen.surface)
    (x, scene)
end

function AbstractPlotting.backend_show(x::CairoBackend, io::IO, m::MIME"image/png", scene::Scene)
    screen = CairoScreen(scene, io)
    cairo_draw(screen, scene)
    write_to_png(screen.surface, io)
    (x, scene)
end

function __init__()
    dir = mktempdir()
    temp_file = joinpath(dir, "cairo.svg")
    AbstractPlotting.register_backend!(CairoBackend(temp_file))
    atexit() do
        rm(dir, force = true, recursive = true)
    end
end

function activate!(inline = false)
    AbstractPlotting.current_backend[] = CairoBackend()
    AbstractPlotting.use_display[] = !inline
    return
end

end
