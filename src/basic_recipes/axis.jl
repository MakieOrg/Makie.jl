range_labels(x) = not_implemented(x)




@recipe(Axis2D) do scene
    darktext = RGBAf0(0.0, 0.0, 0.0, 0.4)
    Theme(
        scale = Vec3f0(1),
        tickstyle = Theme(
            gap = 3,
            title_gap = 3,

            linewidth = (1, 1),
            linecolor = ((:black, 0.4), (:black, 0.4)),
            linestyle = (nothing, nothing),

            textcolor = (darktext, darktext),
            textsize = (5, 5),
            rotation = (0.0, 0.0),
            align = ((:center, :top), (:right, :center)),
            font = map(dim2, theme(scene, :font)),
        ),

        gridstyle = Theme(
            linewidth = (0.5, 0.5),
            linecolor = ((:black, 0.3), (:black, 0.3)),
            linestyle = (nothing, nothing),
        ),

        framestyle = Theme(
            linewidth = 1.0,
            linecolor = :black,
            linestyle = nothing,
            axis_position = :origin,
            axis_arrow = false,
            arrow_size = 2.5,
            frames = ((false, false), (false, false)),
            frames = ((false, false), (false, false)),
        ),

        titlestyle = Theme(
            axisnames = ("X Axis", "Y Axis"),
            textcolor = (:black, :black),
            textsize = (6, 6),
            rotation = (0.0, -1.5pi),
            align = ((:center, :top), (:center, :top)),
            font = map(dim2, theme(scene, :font)),
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
        (:hcenter, :left), # x axis
        (:right, :vcenter), # y axis
        (:right, :vcenter), # z axis
    )
    axisnames_align3d = tickalign3d
    tick_color = RGBAf0(0.5, 0.5, 0.5, 0.6)
    grid_color = RGBAf0(0.5, 0.5, 0.5, 0.4)
    darktext = RGB(0.4, 0.4, 0.4)
    grid_thickness = 1
    gridthickness = ntuple(x-> 1f0, 3)
    tsize = 5 # in percent
    Theme(
        showticks = (true, true, true),
        showaxis = (true, true, true),
        showgrid = (true, true, true),
        scale = Vec3f0(1),

        titlestyle = Theme(
            axisnames = ("X Axis", "Y Axis", "Z Axis"),
            textcolor = (darktext, darktext, darktext),
            rotation = axisnames_rotation3d,
            textsize = (6.0, 6.0, 6.0),
            align = axisnames_align3d,
            font = map(dim3, theme(scene, :font)),
            gap = 3
        ),

        tickstyle = Theme(
            textcolor = (tick_color, tick_color, tick_color),
            rotation = tickrotations3d,
            textsize =  (tsize, tsize, tsize),
            align = tickalign3d,
            gap = 3,
            font = map(dim3, theme(scene, :font)),
        ),

        framestyle = Theme(
            linecolor = (grid_color, grid_color, grid_color),
            linewidth = (grid_thickness, grid_thickness, grid_thickness),
            axiscolor = (darktext, darktext, darktext),
        )
    )
end

isaxis(x) = false
isaxis(x::Union{Axis2D, Axis3D}) = true


function draw_ticks(
        textbuffer, dim, origin, ticks,
        linewidth, linecolor, linestyle,
        textcolor, textsize, rotation, align, font
    )
    for (tick, str) in ticks
        pos = ntuple(i-> i != dim ? origin[i] : tick, Val{2})
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
        tup = ntuple(i-> i != dim ? origin[i] : tick, Val{N})
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
        axis_position, axis_arrow, arrow_size
    ) where N

    mini = minimum.(limits)
    maxi = maximum.(limits)
    rect = HyperRectangle(Vec(mini), Vec(maxi .- mini))
    origin = Vec{N}(0.0)

    if (origin in rect) && axis_position == :origin
        for i = 1:N
            start = unit(Point{N, Float32}, i) * Float32(mini[i])
            to = unit(Point{N, Float32}, i) * Float32(maxi[i])
            if false#axis_arrow
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
                    p = ntuple(i-> i == dim ? limits[i][otherside] : limits[i][side], Val{N})
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
    tickspace = (tickspace_x, tickspace_y)
    title_start = origin .- (tick_gap .+ tickspace .+ tick_title_gap)
    half_width = origin .+ (limit_widths ./ 2.0)

    posx = (half_width[1], title_start[2])
    posy = (title_start[1], half_width[2])
    positions = (posx, posy)
    for i = 1:2
        push!(
            textbuffer, axis_labels[i], positions[i],
            textsize = textsize[i], align = align[i], rotation = rotation[i],
            color = textcolor[i], font = font[i]
        )
    end

end
generate_ticks(args...) = zip(0:4, string.(0:4))
function draw_axis(
        textbuffer, linebuffer, ranges,
        # grid attributes
        g_linewidth, g_linecolor, g_linestyle,

        # tick attributes
        t_linewidth, t_linecolor, t_linestyle,
        t_textcolor, t_textsize, t_rotation, t_align, t_font,
        t_gap, t_title_gap,

        # frame attributes
        f_linewidth, f_linecolor, f_linestyle,
        f_axis_position, f_axis_arrow, f_arrow_size,

        # title / axis name attributes
        ti_labels,
        ti_textcolor, ti_textsize, ti_rotation, ti_align, ti_font,
    )
    start!(textbuffer); start!(linebuffer)

    limits = ((ranges[1][1], ranges[2][1]), (ranges[1][2], ranges[2][2]))
    limit_widths = map(x-> x[2] - x[1], limits)
    % = mean(limit_widths) / 100 # percentage

    xyticks = generate_ticks.(limits)

    ti_textsize = ti_textsize .* %
    t_textsize = t_textsize .* %; t_gap = t_gap .* %;
    t_title_gap = t_title_gap .* %

    origin = first.(limits)
    dirs = ((0.0, Float64(limit_widths[2])), (Float64(limit_widths[1]), 0.0))
    foreach(1:2, dirs, xyticks) do dim, dir, ticks
        draw_grid(
            linebuffer, dim, origin, ticks, dir,
            g_linewidth, g_linecolor, g_linestyle
        )
    end

    o_offsets = ((0.0, Float64(t_gap)), (t_gap, Float64(0.0)))

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
        f_axis_position, f_axis_arrow, f_arrow_size
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

# for axis, we don't want to have plot!(scene, args called on it, so we need to overload it directly)
function plot!(scene::SceneLike, ::Type{<: Axis2D}, attributes::Attributes, args...)
    # create "empty" plot type - empty meaning containing no plots, just attributes + arguments
    cplot, non_plot_kwargs = Axis2D(scene, attributes, args)
    g_keys = (:linewidth, :linecolor, :linestyle)
    f_keys = (:linewidth, :linecolor, :linestyle, :axis_position, :axis_arrow, :arrow_size)
    t_keys = (
        :linewidth, :linecolor, :linestyle,
        :textcolor, :textsize, :rotation, :align, :font,
        :gap, :title_gap
    )
    ti_keys = (:axisnames, :textcolor, :textsize, :rotation, :align, :font)

    g_args = getindex.(cplot[:gridstyle][], g_keys)
    f_args = getindex.(cplot[:framestyle][], f_keys)
    t_args = getindex.(cplot[:tickstyle][], t_keys)
    ti_args = getindex.(cplot[:titlestyle][], ti_keys)

    textbuffer = TextBuffer(cplot, Point{2})
    linebuffer = LinesegmentBuffer(cplot, Point{2})
    map_once(
        draw_axis,
        to_node(textbuffer), to_node(linebuffer), cplot[1],
        g_args..., t_args..., f_args..., ti_args...
    )
    return cplot
end

function labelposition(ranges, dim, dir, origin::StaticVector{N}) where N
    a, b = extrema(ranges[dim])
    whalf = Float32(((b - a) / 2))
    halfaxis = unit(Point{N, Float32}, dim) .* whalf

    origin .+ (halfaxis .+ (dir * (whalf / 3f0)))
end


function GeometryTypes.widths(x::Range)
    mini, maxi = Float32.(extrema(x))
    maxi - mini
end


_widths(x::Tuple{<: Number, <: Number}) = x[2] - x[1]
_widths(x) = Float32(maximum(x) - minimum(x))

to_tickrange(x::Tuple) = linspace(x..., 4)


function draw_axis(
        textbuffer, linebuffer, _ranges,
        scale, showaxis, showticks, showgrid,
        axisnames, axisnames_color, axisnames_size, axisrotation, axisalign,
        axisnames_font, titlegap,
        gridcolors, gridthickness, axiscolors,
        ttextcolor, trotation, ttextsize, talign, tfont, tgap
    )
    N = 3
    start!(textbuffer); start!(linebuffer)
    ranges = to_tickrange.(_ranges)
    mini, maxi = minimum.(ranges), maximum.(ranges)

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
                tickdir, Float32(_widths(ranges[j]) + titlegap) * tickdir
            else
                tickdir = unit(Vec{N, Float32}, 1)
                tickdir, Float32(_widths(ranges[1]) + titlegap) * tickdir
            end
            for tick in drop(range, 1)
                startpos = (origin .+ ((Float32(tick - range[1]) * axis_vec)) .+ offset2) .* scale
                str = sprint(io-> print(io, round(tick, 2)))
                push!(
                    textbuffer, str, startpos,
                    color = ttextcolor[i], rotation = trotation[i],
                    textsize = ttextsize[i], align = talign[i], font = tfont[i]
                )
            end
            if !isempty(axisnames[i])
                pos = (labelposition(ranges, i, tickdir, origin) .+ offset2) .* scale
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


function axis3d(scene::Scene, ranges::Node{<: NTuple{3, Any}}, attributes::Attributes)
    attributes, rest = merged_get!(:axis3d, scene, attributes) do
        default_theme(scene, Axis3D)
    end
    scene_unscaled = Scene(scene, transformation = Transformation())
    axis = Axis3D(scene, attributes, ranges)
    # TODO, how to have an unscaled and scaled scene inside Axis3D?
    axis2 = Axis3D(scene_unscaled, attributes, ranges)
    textbuffer = TextBuffer(axis2, Point{3})
    linebuffer = LinesegmentBuffer(axis, Point{3})

    tstyle, tickstyle, framestyle = value.(getindex.(attributes, (:titlestyle, :tickstyle, :framestyle)))

    titlevals = getindex.(tstyle, (:axisnames, :textcolor, :textsize, :rotation, :align, :font, :gap))
    tvals = getindex.(tickstyle, (:textcolor, :rotation, :textsize, :align, :font, :gap))
    framevals = getindex.(framestyle, (:linecolor, :linewidth, :axiscolor))

    args = (
        getindex.(attributes, (:scale, :showaxis, :showticks, :showgrid))...,
        titlevals..., framevals..., tvals...
    )
    map_once(
        draw_axis,
        Node(textbuffer), Node(linebuffer), ranges, args...
    )
    return axis
end
