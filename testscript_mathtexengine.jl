using CairoMakie
using MathTeXEngine
using MathTeXEngine.MathTeXParser

CairoMakie.activate!(type = "svg")


##

struct MyTex <: AbstractString
    s::String
end

MakieLayout.iswhitespace(t::MyTex) = t.s == ""
Base.isempty(::MyTex) = false

##
import FreeTypeAbstraction: ascender, descender, get_extent, hadvance, inkheight, inkwidth,
    leftinkbound, rightinkbound, topinkbound, bottominkbound

include("dev/MathTeXEngine/src/fonts.jl")
include("dev/MathTeXEngine/src/texelements.jl")
include("dev/MathTeXEngine/src/layout.jl")

##

function Makie.plot!(plot::Makie.Text{<:Tuple{MyTex}})

    # attach a function to any text that calculates the glyph layout and stores it
    lineels_glyphlayout_offset = lift(plot[1], plot.textsize, plot.align, plot.rotation, plot.model) do mytex, ts, al, rot, mo
        ts = to_textsize(ts)
        rot = to_rotation(rot)

        tex_elements, glyphlayout = texelems_and_glyph_positions(mytex, ts, al[1], al[2], rot)
    end

    glyphlayout = @lift($lineels_glyphlayout_offset[2])


    linepairs = Node(Tuple{Point2f0, Point2f0}[])
    linewidths = Node(Float32[])

    onany(lineels_glyphlayout_offset, plot.position, plot.textsize, plot.rotation) do (allels, _, offs), pos, ts, rot

        ts = to_textsize(ts)
        rot = convert_attribute(rot, key"rotation"())

        offset = Point2f0(pos)

        els = map(allels) do el
            if el[1] isa VLine
                h = el[1].height
                t = el[1].thickness * ts
                pos = el[2]
                size = el[3]
                ps = (Point2f0(pos[1], pos[2]) .* ts, Point2f0(pos[1], pos[2] + h) .* ts) .- Ref(offs)
                ps = Ref(rot) .* to_ndim.(Point3f0, ps, 0)
                ps = Point2f0.(ps) .+ Ref(offset)
                (ps, t)
            elseif el[1] isa HLine
                w = el[1].width
                t = el[1].thickness * ts
                pos = el[2]
                size = el[3]
                ps = (Point2f0(pos[1], pos[2]) .* ts, Point2f0(pos[1] + w, pos[2]) .* ts) .- Ref(offs)
                ps = Ref(rot) .* to_ndim.(Point3f0, ps, 0)
                ps = Point2f0.(ps) .+ Ref(offset)
                (ps, t)
            else
                nothing
            end
        end
        pairs = filter(!isnothing, els)
        linewidths.val = repeat(last.(pairs), inner = 2)
        linepairs[] = first.(pairs)
        # @show linepairs
    end

    notify(plot.position)

    if !(glyphlayout isa Observable{<:Makie.GlyphLayout3})
        error("Incorrect type parameter $(typeof(glyphlayout))")
    end

    text!(plot, glyphlayout; plot.attributes...)
    # linesegments!(plot, linepairs, linewidth = linewidths)
    linesegments!(plot, linepairs, linewidth = linewidths, color = plot.color)

    plot
end

##

function get_tex_elements(str::MyTex)
    texexpr = texparse(str.s)
    layout = tex_layout(texexpr)

    map(Tuple, unravel(layout))
end

function texelems_and_glyph_positions(str::MyTex, fontscale_px, halign, valign, rotation)

    rot = Makie.convert_attribute(rotation, key"rotation"())

    all_els = get_tex_elements(str)
    els = filter(x -> x[1] isa TeXChar, all_els)

    # hacky, but attr per char needs to be fixed
    fs = Vec2f0(first(fontscale_px))

    scales_2d = [Vec2f0(x[3] * Vec2f0(fs)) for x in els]

    libs = leftinkbound.(getindex.(els, 1))

    chars = [x[1].char for x in els]
    fonts = [x[1].font for x in els]

    extents = [Makie.FreeTypeAbstraction.get_extent(f, c) for (f, c) in zip(fonts, chars)]

    bboxes = map(extents, fonts, scales_2d) do ext, font, scale
        unscaled_hi_bb = FreeTypeAbstraction.height_insensitive_boundingbox(ext, font)
        hi_bb = FRect2D(
            Makie.origin(unscaled_hi_bb) * scale,
            widths(unscaled_hi_bb) * scale
        )
    end

    basepositions = [to_ndim(Vec3f0, fs, 0) .* to_ndim(Point3f0, x[2], 0)
        for x in els]

    bb = isempty(bboxes) ? BBox(0, 0, 0, 0) : begin
        mapreduce(union, zip(bboxes, basepositions)) do (b, pos)
            FRect2D(FRect3D(b) + pos)
        end
    end


    xshift = if halign == :center
        width(bb) / 2
    elseif halign == :left
        minimum(bb)[1]
    elseif halign == :right
        maximum(bb)[1]
    end

    yshift = if valign == :center
        maximum(bb)[2] - (height(bb) / 2)
    elseif valign == :top
        maximum(bb)[2]
    else
        minimum(bb)[2]
    end

    positions = basepositions .- Ref(Point3f0(xshift, yshift, 0))
    positions .= Ref(rot) .* (positions .- Point3f0.(getindex.(scales_2d, 1) .* libs, 0, 0))
   
    pre_align_gl = Makie.GlyphLayout3(
        chars,
        fonts,
        Point3f0.(positions),
        extents,
        scales_2d,
        fill(rot, length(chars)),
    )

    all_els, pre_align_gl, Point2f0(xshift, yshift)
end
##
with_theme() do
    f, ax , l = lines(cumsum(randn(1000)),
        axis = (
            title = MyTex(raw"\sum_k{x y_k}"),
            xlabel = MyTex(raw"\lim_{x →\infty} A^j v_{(a + b)_k}^i \sqrt{23.5} x!= \sqrt{\frac{1+6}{4+a+g}}\int_{0}^{2π} \sin(x) dx"),
            ylabel = MyTex(raw"x + y - sin(x) × tan(y) + \sqrt{2}"),
        ),
        figure = (fontsize = 18, font = raw"dev\MathTeXEngine\assets\fonts\NewCM10-Regular.otf")
    )
    text!(MyTex(raw"\int_{0}^{2π} \sin(x) dx"), position = (500, 0))

    Legend(f[1, 2], [l, l, l], [MyTex(raw"\sum{xy}"), MyTex(raw"a\int_0^5x^2+2ab"), "hello you!"])
    f
end
# save("test.pdf", f)
##
Makie.attribute_per_char(str::MyTex, attr) = attr

##
s = Scene(camera = campixel!)
t = text!(s,
    MyTex(raw"\sqrt{2}"),
    # MyTex(raw"x + y - sin(x) × tan(y) + \sqrt{2}"),
    position = (50, 50),
    rotation = pi/2,
    show_axis = false,
    space = :data)
s

##
Makie.glyph_positions(MyTex("x_{2}"), 0, 0, 0, 0, 0, 0, 0)
##
# function Makie.boundingbox(x::Makie.Text{Tuple{MyTex}}, y, z)
#     Makie.data_text_boundingbox(nothing, x._glyphlayout[], x.rotation[], x.position[])
# end




##
data = randn(100, 2)
f, ax, _ = scatter(data)
vlines!(ax, data[:, 1], ymax = 0.03, color = :black)
hlines!(ax, data[:, 2], xmax = 0.02, color = :black)
f

##
s = Scene(camera = campixel!)
t = text!(s,
    "hi what's up?",
    position = (50, 50),
    rotation = 0.0,
    show_axis = false,
    space = :data)
s

##

s = Scene(camera = campixel!)
t = text!(s,
    MyTex(raw"\int_0^5x^2+2ab"),
    position = Point2f0(50, 50),
    rotation = 0.0,
    show_axis = false,
    space = :data)
wireframe!(s, boundingbox(t))
s

##

lines(cumsum(randn(99)), axis = (title = "lol", xlabel = "hello", ylabel = "you too"))


##
