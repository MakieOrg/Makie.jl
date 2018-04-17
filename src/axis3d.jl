function default_theme(scene, ::Type{Axis3D})
    q1 = qrotation(Vec3f0(1, 0, 0), -0.5f0*pi)
    q2 = qrotation(Vec3f0(0, 0, 1), 1f0*pi)
    tickrotations3d = (
        qrotation(Vec3f0(0,0,1), -1.5pi),
        q2,
        qmul(qmul(q2, q1), qrotation(Vec3f0(0, 1, 0), 1pi))
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
            font = "default",
            gap = 3
        ),

        tickstyle = Theme(
            textcolor = (tick_color, tick_color, tick_color),
            rotation = tickrotations3d,
            textsize =  (tsize, tsize, tsize),
            align = tickalign3d,
            gap = 3,
            font = "default",
        ),

        framestyle = Theme(
            linecolor = (grid_color, grid_color, grid_color),
            linewidth = (grid_thickness, grid_thickness, grid_thickness),
            axiscolor = (darktext, darktext, darktext),
        )
    )
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
                    textsize = ttextsize[i], align = talign[i], font = tfont
                )
            end
            if !isempty(axisnames[i])
                pos = (labelposition(ranges, i, tickdir, origin) .+ offset2) .* scale
                push!(
                    textbuffer, to_latex(axisnames[i]), pos,
                    textsize = axisnames_size[i], color = axisnames_color[i],
                    rotation = axisrotation[i], align = axisalign[i], font = axisnames_font
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
