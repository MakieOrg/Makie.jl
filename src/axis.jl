using Colors, GeometryTypes, GLVisualize, GLAbstraction
using Base.Iterators: repeated, drop

include("scene.jl")
include("primitives\\scatter.jl")
include("primitives.jl")

const RGBAf0 = RGBA{Float32}

struct Axis{N}
    title::Text
    axes_names::NTuple{N, Text}
    screen_area::HyperRectangle{N, Float32}
    world_area::HyperRectangle{N, Float32}
    ranges::NTuple{N, T} where T <: Range

    show::Bool
    showticks::NTuple{N, Bool}
    showaxis::NTuple{N, Bool}
    showgrid::NTuple{N, Bool}

    flips::NTuple{N, Bool}
    scalefuncs::NTuple{N, Function}
    theme::Theme
end

axistheme = Theme(
    :gridcolors => ntuple(x-> RGBAf0(0.5, 0.5, 0.5, 0.4), 3),
    :axiscolors => ntuple(x-> RGBAf0(0.0, 0.0, 0.0, 0.4), 3)
)

N = 2

x = Axis(
    Text(""),
    ntuple(i-> Text(""), N),
    HyperRectangle{N, Float32}(Vec{N, Float32}(0), Vec{N, Float32}(3)),
    HyperRectangle{N, Float32}(Vec{N, Float32}(0), Vec{N, Float32}(3)),
    ntuple(i-> linspace(0, 3, 5), N),

    true,
    ntuple(i-> true, N),
    ntuple(i-> true, N),
    ntuple(i-> true, N),

    ntuple(i-> false, N),
    ntuple(i-> identity, N),
    axistheme
)


function draw_axes(x::Axis{N}, scene) where N
    line_segments = Point{N, Float32}[]
    line_colors = RGBAf0[]
    textpositions = Point{N, Float32}[]
    textoffsets = Point2f0[]
    textrotations = Vec{N, Float32}[]
    textcolors = RGBAf0[]
    textio = IOBuffer()
    atlas = GLVisualize.get_texture_atlas(scene[:screen])
    aligns = (
        (:hcenter, :top), # x axis
        (:right, :vcenter), # y axis
    )
    for i = 1:N
        axis_vec = unit(Point{N, Float32}, i)
        mini, maxi = extrema(x.ranges[i])
        start, stop = mini .* axis_vec, maxi .* axis_vec
        if x.showaxis[i]
            push!(line_segments, start, stop)
            c = x.theme[:axiscolors].value[i]
            push!(line_colors, c, c)
        end
        if x.showticks[i]
            font = GLVisualize.defaultfont()
            range = x.ranges[i]
            j = mod1(i + 1, N)
            tickdir = unit(Point{N, Float32}, j)
            offset2 = Vec{N, Float32}(0) # (maximum(x.ranges[j]) .+ 0.05f0) * unit(Vec{N, Float32}, j)
            offset = -tickdir .* 0.1f0
            rotation = rotationmatrix_z(pi*0.5f0)
            rscale = 0.1
            for tick in drop(range, 1)
                startpos = ((tick * axis_vec) .+ offset) .+ offset2
                str = sprint() do io
                    print(io, tick)
                end
                position = GLVisualize.calc_position(str, Point2f0(0), rscale, font, atlas)
                toffset = GLVisualize.calc_offset(str, rscale, font, atlas)
                aoffsetvec = Vec2f0(alignment2num.(aligns[i]))
                aoffset = align_offset(Point2f0(0), position[end], atlas, rscale, font, aoffsetvec)
                position .= position .+ (startpos .+ aoffset,)
                # position = map(position) do x
                #     xx = rotationmatrix_z(pi/2f0) * Point4f0(x[1], x[2], 0, 0)
                #     Point{N, Float32}(ntuple(i->xx[i], Val{N})) .+ startpos
                # end
                # toffset = map(toffset) do x
                #     xx = rotationmatrix_z(pi/2f0) * Vec4f0(x[1], x[2], 0, 0)
                #     Vec2f0(xx[1], xx[2])
                # end
                append!(textpositions, position)
                append!(textoffsets, toffset)
                # append!(textrotations, repeated(tickdir, length(position)))
                append!(textcolors, repeated(to_color(:black), length(position)))
                print(textio, str)
            end
        end
        if x.showgrid[i]
            c = x.theme[:gridcolors].value[i]
            for _j = (i + 1):(i + N - 1)
                j = mod1(_j, N)
                dir = unit(Point{N, Float32}, j)
                range = x.ranges[j]
                for tick in drop(range, 1)
                    offset = tick * dir
                    push!(line_segments, start .+ offset, stop .+ offset)
                    push!(line_colors, c, c)
                end
            end
        end
    end
    textrobj = visualize(
        String(take!(textio)),
        position = textpositions,
        # rotation = textrotations,
        atlas = atlas,
        offset = textoffsets,
        color = textcolors,
        relative_scale = 0.1f0,
        billboard = false,
        scale_primitive = false
    )
    line_segments, line_colors, textrobj
end

scene = Scene()
GLVisualize.empty_screens!()
GLVisualize.add_screen(scene[:screen])
ls, lc, trobj = draw_axes(x, scene)

_view(visualize(ls, :linesegment, color = lc), scene[:screen], camera = :orthographic_pixel)
_view(trobj, scene[:screen], camera = :orthographic_pixel)


scatter(rand(Point2f0, 10) .* 3f0, markersize = 0.05f0)

center!(scene[:screen], :orthographic_pixel, border = 0.1)

x = @ref(scene.mouseposition, scene.time)
extract_fields(:(a.b))
# scatter(map((mpos, t)-> mpos .+ (sin(t), cos(t)), ))
