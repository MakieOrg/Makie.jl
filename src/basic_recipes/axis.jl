function ticks_and_labels end
using PlotUtils



module Formatters

using Showoff

function scientific(ticks::AbstractVector)
    Showoff.showoff(ticks, :scientific)
end

function plain(ticks::AbstractVector)
    try
        Showoff.showoff(ticks, :plain)
    catch e
        Base.showerror(stderr, e)
        println("with ticks: ", ticks)
        String["-Inf", "Inf"]
    end
end

end
using .Formatters

@recipe(Axis2D) do scene
    Theme(
        visible = true,
        ticks = Theme(

            labels = automatic,
            ranges = automatic,
            formatter = Formatters.plain,

            gap = 3,
            title_gap = 3,


            linewidth = (1, 1),
            linecolor = ((:black, 0.4), (:black, 0.4)),
            linestyle = (nothing, nothing),

            textcolor = (:black, :black),
            textsize = (5, 5),
            rotation = (0.0, 0.0),
            align = ((:center, :top), (:right, :center)),
            font = lift(dim2, theme(scene, :font)),
        ),

        grid = Theme(
            linewidth = (0.5, 0.5),
            linecolor = ((:black, 0.3), (:black, 0.3)),
            linestyle = (nothing, nothing),
        ),

        frame = Theme(
            linewidth = 1.0,
            linecolor = :black,
            linestyle = nothing,
            axis_position = nothing,
            axis_arrow = false,
            arrow_size = 2.5,
            frames = ((false, false), (false, false)),
        ),

        names = Theme(
            axisnames = ("x", "y"),
            textcolor = (:black, :black),
            textsize = (6, 6),
            rotation = (0.0, -1.5pi),
            align = ((:center, :top), (:center, :bottom)),
            font = lift(dim2, theme(scene, :font)),
        )
    )
end


@recipe(Axis3D) do scene

    q1 = qrotation(Vec3f0(1, 0, 0), -0.5f0*pi)
    q2 = qrotation(Vec3f0(0, 0, 1), 1f0*pi)
    tickrotations3d = (
        qrotation(Vec3f0(0,0,1), -1.5pi),
        q2,
        qrotation(Vec3f0(1, 0, 0), -0.5pi) * q2
    )
    axisnames_rotation3d = tickrotations3d
    tickalign3d = (
        (:left, :center), # x axis
        (:right, :center), # y axis
        (:right, :center), # z axis
    )
    axisnames_align3d = tickalign3d
    tick_color = RGBAf0(0.5, 0.5, 0.5, 0.6)
    grid_color = RGBAf0(0.5, 0.5, 0.5, 0.4)
    grid_thickness = 1
    gridthickness = ntuple(x-> 1f0, Val(3))
    tsize = 5 # in percent
    Theme(
        visible = true,
        showticks = (true, true, true),
        showaxis = (true, true, true),
        showgrid = (true, true, true),
        scale = Vec3f0(1),

        names = Theme(
            axisnames = ("x", "y", "z"),
            textcolor = (:black, :black, :black),
            rotation = axisnames_rotation3d,
            textsize = (6.0, 6.0, 6.0),
            align = axisnames_align3d,
            font = lift(dim3, theme(scene, :font)),
            gap = 1
        ),

        ticks = Theme(
            labels = automatic,
            ranges = automatic,
            formatter = Formatters.plain,

            textcolor = (tick_color, tick_color, tick_color),

            rotation = tickrotations3d,
            textsize =  (tsize, tsize, tsize),
            align = tickalign3d,
            gap = 1,
            font = lift(dim3, theme(scene, :font)),
        ),

        frame = Theme(
            linecolor = (grid_color, grid_color, grid_color),
            linewidth = (grid_thickness, grid_thickness, grid_thickness),
            axiscolor = (:black, :black, :black),
        )
    )
end

isaxis(x) = false
isaxis(x::Union{Axis2D, Axis3D}) = true


const Limits{N} = NTuple{N, Tuple{Number, Number}}

default_ticks(limits::Limits, ticks, scale_func = identity) = default_ticks.(limits, (ticks,), scale_func)
default_ticks(limits::Tuple{Number, Number}, ticks, scale_func = identity) = default_ticks(limits..., ticks, scale_func)

function default_ticks(lmin::Number, lmax::Number, ticks::AbstractVector{<: Number}, scale_func = identity)
    scale_func.((filter(t -> lmin <= t <= lmax, ticks)))
end
function default_ticks(lmin::Number, lmax::Number, ::Nothing, scale_func = identity)
    # scale the limits
    scaled_ticks, mini, maxi = optimize_ticks(
        scale_func(lmin),
        scale_func(lmax);
        k_min = 4, # minimum number of ticks
        k_max = 8, # maximum number of ticks
    )
    scaled_ticks
end

function default_ticks(lmin::Number, lmax::Number, n::Integer, scale_func = identity)
    scaled_ticks, mini, maxi = optimize_ticks(
        scale_func(lmin),
        scale_func(lmax);
        k_min = ticks, # minimum number of ticks
        k_max = ticks, # maximum number of ticks
        k_ideal = ticks,
        # `strict_span = false` rewards cases where the span of the
        # chosen  ticks is not too much bigger than amin - amax:
        strict_span = false,
    )
    scaled_ticks
end

function default_labels(x::NTuple{N, AbstractVector}, formatter::Function = Formatters.plain) where N
    default_labels.(x, formatter)
end

function default_labels(x::AbstractVector, y::AbstractVector, formatter::Function = Formatters.plain)
    default_labels.((x, y), formatter)
end

function default_labels(ticks::AbstractVector, formatter::Function = Formatters.plain)
    if applicable(formatter, ticks)
        formatter(ticks) # takes the whole array
    elseif applicable(formatter, first(ticks))
        formatter.(ticks)
    else
        error("Formatting function $(formatter) is neither applicable to $(typeof(ticks)) nor $(eltype(ticks)).")
    end
end

function convert_arguments(::Type{<: Axis2D}, limits::Rect)
    e = (minimum(limits), maximum(limits))
    (((e[1][1], e[2][1]), (e[1][2], e[2][2])),)
end
function convert_arguments(::Type{<: Axis3D}, limits::Rect)
    e = (minimum(limits), maximum(limits))
    (((e[1][1], e[2][1]), (e[1][2], e[2][2]), (e[1][3], e[2][3])),)
end
function calculated_attributes!(::Type{<: Union{Axis2D, Axis3D}}, plot)
    ticks = plot[:ticks]
    ranges = replace_automatic!(ticks, :ranges) do
        lift(default_ticks, plot[1], Node(nothing))
    end
    replace_automatic!(ticks, :labels) do
        lift(default_labels, ranges, plot[:ticks, :formatter])
    end
end

function draw_ticks(
        textbuffer, dim, origin, ticks,
        linewidth, linecolor, linestyle,
        textcolor, textsize, rotation, align, font
    )
    for (tick, str) in ticks
        pos = ntuple(i-> i != dim ? origin[i] : tick, Val(2))
        push!(
            textbuffer,
            str, pos,
            rotation = rotation[dim], textsize = textsize[dim],
            align = align[dim], color = textcolor[dim], font = font[dim]
        )
    end
end

function draw_grid(
        linebuffer, dim, origin, ticks, dir::NTuple{N},
        linewidth, linecolor, linestyle
    ) where N
    dirf0 = Pointf0{N}(dir)
    for (tick, str) in ticks
        tup = ntuple(i-> i != dim ? origin[i] : tick, Val(N))
        posf0 = Pointf0{N}(tup)
        append!(
            linebuffer,
            [posf0, posf0 .+ dirf0],
            color = linecolor[dim], linewidth = linewidth[dim]#, linestyle = linestyle[dim]
        )
    end
end


function draw_frame(
        linebuffer, limits::NTuple{N, Any},
        linewidth, linecolor, linestyle,
        axis_position, axis_arrow, arrow_size, frames
    ) where N

    mini = minimum.(limits)
    maxi = maximum.(limits)
    rect = HyperRectangle(Vec(mini), Vec(maxi .- mini))
    origin = Vec{N}(0.0)

    if (origin in rect) && axis_position == :origin
        for i = 1:N
            start = unit(Point{N, Float32}, i) * Float32(mini[i])
            to = unit(Point{N, Float32}, i) * Float32(maxi[i])
            if false #axis_arrow
                arrows(
                    scene, [start, to],
                    linewidth = linewidth, linecolor = linecolor, linestyle = linestyle,
                    arrowsize = arrow_size
                )
            else
                append!(
                    linebuffer, [start, to],
                    linewidth = linewidth, color = linecolor #linestyle = linestyle,
                )
            end
        end
    end
    limit_widths = maxi .- mini
    for side in 1:2
        from = Point{N, Float32}(getindex.(limits, side))
        # if axis is drawn at origin, and we draw frame from origin,
        # we already did this
        if !(from == origin && axis_position == :origin)
            for otherside in 1:2
                for dim in 1:N
                    if frames[N-dim+1][3-otherside]
                        p = ntuple(i-> i == dim ? limits[i][otherside] : limits[i][side], Val(N))
                        to = Point{N, Float32}(p)
                        append!(
                            linebuffer, [from, to],
                            linewidth = linewidth, color = linecolor#, linestyle = linestyle,
                        )
                    end
                end
            end
        end
    end
end

function draw_titles(
        textbuffer,
        xticks, yticks, origin, limit_widths,
        tickfont, tick_size, tick_gap, tick_title_gap,
        axis_labels,
        textcolor, textsize, rotation, align, font
    )
    tickspace_x = maximum(map(yticks) do tick
        str = last(tick)
        tick_bb = text_bb(str, to_font(tickfont[2]), tick_size[2])
        widths(tick_bb)[1]
    end)

    tickspace_y = widths(text_bb(
        last(first(xticks)), to_font(tickfont[1]), tick_size[1]
    ))[2]

    model_inv = inv(transformationmatrix(textbuffer)[])

    tickspace = transform(model_inv, (tickspace_x, tickspace_y))
    title_start = origin .- (tick_gap .+ tickspace .+ tick_title_gap)
    half_width = origin .+ (limit_widths ./ 2.0)

    posx = (half_width[1], title_start[2])
    posy = (title_start[1], half_width[2])
    positions = (posx, posy)
    for i = 1:2
        if !isempty(axis_labels[i])
            push!(
                textbuffer, axis_labels[i], positions[i],
                textsize = textsize[i], align = align[i], rotation = rotation[i],
                color = textcolor[i], font = font[i]
            )
        end
    end
end


function ticks_and_labels(x)
    st, s = extrema(x)
    r = range(st, stop=s, length=4)
    zip(r, string.(round.(r, 4)))
end

function transform(model::Mat4, x::T) where T
    x4d = to_ndim(Vec4f0, x, 0.0)
    to_ndim(T, model * x4d, 0.0)
end
un_transform(model::Mat4, x) = transform(inv(model), x)


to2tuple(x) = ntuple(i-> x, Val(2))
to2tuple(x::Tuple{<:Any, <: Any}) = x

function draw_axis2d(
        textbuffer, linebuffer, m, limits, xyrange, labels,
        # grid attributes
        g_linewidth, g_linecolor, g_linestyle,

        # tick attributes
        t_linewidth, t_linecolor, t_linestyle,
        t_textcolor, t_textsize, t_rotation, t_align, t_font,
        t_gap, t_title_gap,

        # frame attributes
        f_linewidth, f_linecolor, f_linestyle,
        f_axis_position, f_axis_arrow, f_arrow_size, f_frames,

        # title / axis name attributes
        ti_labels,
        ti_textcolor, ti_textsize, ti_rotation, ti_align, ti_font,
    )
    start!(textbuffer); start!(linebuffer)

    limit_widths = map(x-> x[2] - x[1], limits)
    % = mean(limit_widths) / 100 # percentage

    xyticks = zip.(xyrange, labels)
    model_inv = inv(transformationmatrix(textbuffer)[])

    ti_textsize = ti_textsize .* %
    t_textsize = t_textsize .* %
    t_gap = transform(model_inv, to2tuple(t_gap .* %))
    t_title_gap = transform(model_inv, to2tuple(t_title_gap .* %))

    origin = first.(limits)
    dirs = ((0.0, Float64(limit_widths[2])), (Float64(limit_widths[1]), 0.0))
    foreach(1:2, dirs, xyticks) do dim, dir, ticks
        draw_grid(
            linebuffer, dim, origin, ticks, dir,
            g_linewidth, g_linecolor, g_linestyle
        )
    end
    o_offsets = ((0.0, Float64(t_gap[2])), (Float64(t_gap[1]), Float64(0.0)))

    foreach(1:2, o_offsets, xyticks) do dim, offset, ticks
        draw_ticks(
            textbuffer, dim, origin .- offset, ticks,
            t_linewidth, t_linecolor, t_linestyle,
            t_textcolor, t_textsize, t_rotation, t_align, t_font
        )
    end

    draw_frame(
        linebuffer, limits,
        f_linewidth, f_linecolor, f_linestyle,
        f_axis_position, f_axis_arrow, f_arrow_size,
        f_frames,
    )

    draw_titles(
        textbuffer, xyticks..., origin, limit_widths,
        t_font, t_textsize, t_gap, t_title_gap,
        ti_labels,
        ti_textcolor, ti_textsize, ti_rotation, ti_align, ti_font,
    )
    finish!(textbuffer); finish!(linebuffer)
    return
end

# for axis, we don't want to have plot!(scene, args) called on it, so we need to overload it directly
function plot!(scene::SceneLike, ::Type{<: Axis2D}, attributes::Attributes, args...)
    # create "empty" plot type - empty meaning containing no plots, just attributes + arguments
    cplot, non_plot_kwargs = Axis2D(scene, attributes, args)
    g_keys = (:linewidth, :linecolor, :linestyle)
    f_keys = (:linewidth, :linecolor, :linestyle, :axis_position, :axis_arrow, :arrow_size, :frames)
    t_keys = (
        :linewidth, :linecolor, :linestyle,
        :textcolor, :textsize, :rotation, :align, :font,
        :gap, :title_gap
    )
    ti_keys = (:axisnames, :textcolor, :textsize, :rotation, :align, :font)

    g_args = getindex.(Ref(cplot[:grid]), g_keys)
    f_args = getindex.(Ref(cplot[:frame]), f_keys)
    t_args = getindex.(Ref(cplot[:ticks]), t_keys)
    ti_args = getindex.(Ref(cplot[:names]), ti_keys)

    textbuffer = TextBuffer(cplot, Point{2})

    linebuffer = LinesegmentBuffer(cplot, Point{2})

    map_once(
        draw_axis2d,
        to_node(textbuffer), to_node(linebuffer), transformationmatrix(scene),
        cplot[1], cplot[:ticks, :ranges], cplot[:ticks, :labels],
        g_args..., t_args..., f_args..., ti_args...
    )
    push!(scene.plots, cplot)

    return cplot
end

function labelposition(ranges, dim, dir, tgap, origin::StaticVector{N}) where N
    a, b = extrema(ranges[dim])
    whalf = Float32(((b - a) / 2))
    halfaxis = unit(Point{N, Float32}, dim) .* whalf

    origin .+ (halfaxis .+ (normalize(dir) * tgap))
end


function GeometryTypes.widths(x::AbstractRange)
    mini, maxi = Float32.(extrema(x))
    maxi - mini
end


_widths(x::Tuple{<: Number, <: Number}) = x[2] - x[1]
_widths(x) = Float32(maximum(x) - minimum(x))

to3tuple(x::Tuple{Any, Any, Any}) = x
to3tuple(x) = ntuple(i-> x, Val(3))

function draw_axis3d(textbuffer, linebuffer, limits, ranges, labels, args...)
    # make sure we extend all args to 3D
    args3d = to3tuple.(args)
    (
        showaxis, showticks, showgrid,
        axisnames, axisnames_color, axisnames_size, axisrotation, axisalign,
        axisnames_font, titlegap,
        gridcolors, gridthickness, axiscolors,
        ttextcolor, trotation, ttextsize, talign, tfont, tgap
    ) = args3d # splat to names

    N = 3
    start!(textbuffer); start!(linebuffer)
    ranges_ticks = zip.(ranges, labels)
    mini, maxi = first.(limits), last.(limits)

    ranges = map(i-> [mini[i]; ranges_ticks[i].a; maxi[i]], 1:3)
    ticklabels = map(x-> [""; x.b; ""], ranges_ticks)
    origin = Point{N, Float32}(mini)
    limit_widths = maxi .- mini
    % = minimum(limit_widths) / 100 # percentage
    ttextsize = (%) .* ttextsize
    axisnames_size = (%) .* axisnames_size

    titlegap = (%) .* titlegap
    tgap = (%) .* tgap
    for i = 1:N
        axis_vec = unit(Point{N, Float32}, i)
        width = _widths(ranges[i])
        stop = origin .+ (width .* axis_vec)
        if showaxis[i]
            append!(linebuffer, [origin, stop], color = axiscolors[i], linewidth = 1.5f0)
        end
        if showticks[i]
            range = ranges[i]
            j = mod1(i + 1, N)
            tickdir = unit(Point{N, Float32}, j)
            tickdir, offset2 = if i != 2
                tickdir = unit(Vec{N, Float32}, j)
                tickdir, Float32(_widths(ranges[j]) + tgap[i]) * tickdir
            else
                tickdir = unit(Vec{N, Float32}, 1)
                tickdir, Float32(_widths(ranges[1]) + tgap[i]) * tickdir
            end
            for (j, tick) in enumerate(range)
                labels = ticklabels[i]
                if length(labels) >= j
                    str = labels[j]
                    if !isempty(str)
                        startpos = (origin .+ ((Float32(tick - range[1]) * axis_vec)) .+ offset2)
                        push!(
                            textbuffer, str, startpos,
                            color = ttextcolor[i], rotation = trotation[i],
                            textsize = ttextsize[i], align = talign[i], font = tfont[i]
                        )
                    end
                end
            end
            if !isempty(axisnames[i])
                tick_widths = if length(ticklabels[i]) >= 3
                    widths(text_bb(ticklabels[i][end-1], to_font(tfont[i]), ttextsize[i]))[1]
                else
                    0f0
                end
                pos = (labelposition(ranges, i, tickdir, titlegap[i] + tick_widths, origin) .+ offset2)
                push!(
                    textbuffer, to_latex(axisnames[i]), pos,
                    textsize = axisnames_size[i], color = axisnames_color[i],
                    rotation = axisrotation[i], align = axisalign[i], font = axisnames_font[i]
                )
            end
        end
        if showgrid[i]
            c = gridcolors[i]
            thickness = gridthickness[i]
            for _j = (i + 1):(i + N - 1)
                j = mod1(_j, N)
                dir = unit(Point{N, Float32}, j)
                range = ranges[j]
                for tick in drop(range, 1)
                    offset = Float32(tick - range[1]) * dir
                    append!(
                        linebuffer, [origin .+ offset, stop .+ offset],
                        color = c, linewidth = thickness
                    )
                end
            end
        end
        finish!(textbuffer); finish!(linebuffer)
    end
    return
end


function plot!(scene::SceneLike, ::Type{<: Axis3D}, attributes::Attributes, args...)
    axis, non_plot_kwargs = Axis3D(scene, attributes, args)
    textbuffer = TextBuffer(axis, Point{3})
    linebuffer = LinesegmentBuffer(axis, Point{3})

    tstyle, ticks, frame = to_value.(getindex.(axis, (:names, :ticks, :frame)))
    titlevals = getindex.(tstyle, (:axisnames, :textcolor, :textsize, :rotation, :align, :font, :gap))
    framevals = getindex.(frame, (:linecolor, :linewidth, :axiscolor))
    tvals = getindex.(ticks, (:textcolor, :rotation, :textsize, :align, :font, :gap))
    args = (
        getindex.(axis, (:showaxis, :showticks, :showgrid))...,
        titlevals..., framevals..., tvals...
    )
    map_once(
        draw_axis3d,
        Node(textbuffer), Node(linebuffer),
        axis[1], axis[:ticks, :ranges], axis[:ticks, :labels], args...
    )
    push!(scene.plots, axis)
    return axis
end
