using Colors, GeometryTypes, GLVisualize, GLAbstraction
using Base.Iterators: repeated, drop

include("scene.jl")
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

N = 3

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
            offset2 = (maximum(x.ranges[j]) .+ 0.05f0) * unit(Vec{N, Float32}, j)
            offset = tickdir .* 0.1f0
            rotation = rotationmatrix_z(pi*0.5f0)
            for tick in drop(range, 1)
                startpos = ((tick * axis_vec) .+ offset) .+ offset2
                str = sprint() do io
                    print(io, tick)
                end
                position = GLVisualize.calc_position(str, Point2f0(0), 0.1, font, atlas)
                toffset = GLVisualize.calc_offset(str, 0.1, font, atlas)
                position = map(position) do x
                    x = Point3f0(x[1], x[2], 0)
                    xx = rotationmatrix_z(pi/2f0) * Point4f0(x[1], x[2], x[3], 0)
                    Point3f0(xx[1], xx[2], xx[3]) .+ startpos
                end
                toffset = map(toffset) do x
                    xx = rotationmatrix_z(pi/2f0) * Vec4f0(x[1], x[2], 0, 0)
                    Vec2f0(xx[1], xx[2])
                end
                append!(textpositions, position)
                append!(textoffsets, toffset)
                if i == 1
                    θ = pi * 1f0
                    tickdir = (rotation* Vec4f0(0, 0, 2, 0))[1:3]
                end
                append!(textrotations, repeated(tickdir, length(position)))
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
        rotation = textrotations,
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
ls, lc, trobj = draw_axes(x, scene)

_view(visualize(ls, :linesegment, color = lc), scene[:screen], camera = :perspective)
_view(trobj, scene[:screen], camera = :perspective)

center!(scene[:screen])

function draw_axes_2d(sp::Plots.Subplot{Plots.GLVisualizeBackend}, model, area)
    xticks, yticks, xspine_segs, yspine_segs, xgrid_segs, ygrid_segs, xborder_segs, yborder_segs = Plots.axis_drawing_info(sp)
    xaxis = sp[:xaxis]; yaxis = sp[:yaxis]

    xgc = Colors.color(Plots.color(xaxis[:foreground_color_grid]))
    ygc = Colors.color(Plots.color(yaxis[:foreground_color_grid]))
    axis_vis = []
    if xaxis[:grid]
        grid = draw_grid_lines(sp, xgrid_segs, xaxis[:gridlinewidth], xaxis[:gridstyle], model, RGBA(xgc, xaxis[:gridalpha]))
        push!(axis_vis, grid)
    end
    if yaxis[:grid]
        grid = draw_grid_lines(sp, ygrid_segs, yaxis[:gridlinewidth], yaxis[:gridstyle], model, RGBA(ygc, yaxis[:gridalpha]))
        push!(axis_vis, grid)
    end

    xac = Colors.color(Plots.color(xaxis[:foreground_color_axis]))
    yac = Colors.color(Plots.color(yaxis[:foreground_color_axis]))
    if alpha(xaxis[:foreground_color_axis]) > 0
        spine = draw_grid_lines(sp, xspine_segs, 1f0, :solid, model, RGBA(xac, 1.0f0))
        push!(axis_vis, spine)
    end
    if alpha(yaxis[:foreground_color_axis]) > 0
        spine = draw_grid_lines(sp, yspine_segs, 1f0, :solid, model, RGBA(yac, 1.0f0))
        push!(axis_vis, spine)
    end
    fcolor = Plots.color(xaxis[:foreground_color_axis])

    xlim = Plots.axis_limits(xaxis)
    ylim = Plots.axis_limits(yaxis)

    if !(xaxis[:ticks] in (nothing, false, :none)) && !(sp[:framestyle] == :none)
        ticklabels = map(model) do m
            mirror = xaxis[:mirror]
            t, positions, offsets = draw_ticks(xaxis, xticks, true, ylim, m)
            mirror = xaxis[:mirror]
            t, positions, offsets = draw_ticks(
                yaxis, yticks, false, xlim, m,
                t, positions, offsets
            )
        end
        kw_args = Dict{Symbol, Any}(
            :position => map(x-> x[2], ticklabels),
            :offset => map(last, ticklabels),
            :color => fcolor,
            :relative_scale => pointsize(xaxis[:tickfont]),
            :scale_primitive => false
        )
        push!(axis_vis, visualize(map(first, ticklabels), Style(:default), kw_args))
    end

    xbc = Colors.color(Plots.color(xaxis[:foreground_color_border]))
    ybc = Colors.color(Plots.color(yaxis[:foreground_color_border]))
    intensity = sp[:framestyle] == :semi ? 0.5f0 : 1.0f0
    if sp[:framestyle] in (:box, :semi)
        xborder = draw_grid_lines(sp, xborder_segs, intensity, :solid, model, RGBA(xbc, intensity))
        yborder = draw_grid_lines(sp, yborder_segs, intensity, :solid, model, RGBA(ybc, intensity))
        push!(axis_vis, xborder, yborder)
    end

    area_w = GeometryTypes.widths(area)
    if sp[:title] != ""
        tf = sp[:titlefont]; color = color(sp[:foreground_color_title])
        font = Plots.Font(tf.family, tf.pointsize, :hcenter, :top, tf.rotation, color)
        xy = Point2f0(area.w/2, area_w[2] + pointsize(tf)/2)
        kw = Dict(:model => text_model(font, xy), :scale_primitive => true)
        extract_font(font, kw)
        t = PlotText(sp[:title], font)
        push!(axis_vis, glvisualize_text(xy, t, kw))
    end
    if xaxis[:guide] != ""
        tf = xaxis[:guidefont]; color = color(xaxis[:foreground_color_guide])
        xy = Point2f0(area.w/2, - pointsize(tf)/2)
        font = Plots.Font(tf.family, tf.pointsize, :hcenter, :bottom, tf.rotation, color)
        kw = Dict(:model => text_model(font, xy), :scale_primitive => true)
        t = PlotText(xaxis[:guide], font)
        extract_font(font, kw)
        push!(axis_vis, glvisualize_text(xy, t, kw))
    end

    if yaxis[:guide] != ""
        tf = yaxis[:guidefont]; color = color(yaxis[:foreground_color_guide])
        font = Plots.Font(tf.family, tf.pointsize, :hcenter, :top, 90f0, color)
        xy = Point2f0(-pointsize(tf)/2, area.h/2)
        kw = Dict(:model => text_model(font, xy), :scale_primitive=>true)
        t = PlotText(yaxis[:guide], font)
        extract_font(font, kw)
        push!(axis_vis, glvisualize_text(xy, t, kw))
    end

    axis_vis
end
