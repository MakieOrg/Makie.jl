using PlotUtils, Showoff

export optimal_ticks_and_labels, generate_ticks

function text_bb(str, font, size)
    positions, toffset, uv_offset_width, scale = to_gl_text(
        str, Point2f0(0), size, font, Vec2f0(0), Vec4f0(0,0,0,1), eye(Mat4f0)
    )
    AABB(vcat(positions, positions .+ scale))
end

function optimal_ticks_and_labels(limits, ticks = nothing)
    amin, amax = limits
    # scale the limits
    scale = :identity
    sf = identity
    invscale = identity #invscalefunc(scale)
    # If the axis input was a Date or DateTime use a special logic to find
    # "round" Date(Time)s as ticks
    # This bypasses the rest of optimal_ticks_and_labels, because
    # optimize_datetime_ticks returns ticks AND labels: the label format (Date
    # or DateTime) is chosen based on the time span between amin and amax
    # rather than on the input format
    # TODO: maybe: non-trivial scale (:ln, :log2, :log10) for date/datetime
    # get a list of well-laid-out ticks
    if ticks == nothing
        scaled_ticks = optimize_ticks(
            sf(amin),
            sf(amax);
            k_min = 4, # minimum number of ticks
            k_max = 8, # maximum number of ticks
        )[1]
    elseif isa(ticks, Integer) # a single integer for number of ticks
        scaled_ticks, viewmin, viewmax = optimize_ticks(
            sf(amin),
            sf(amax);
            k_min = ticks, # minimum number of ticks
            k_max = ticks, # maximum number of ticks
            k_ideal = ticks,
            # `strict_span = false` rewards cases where the span of the
            # chosen  ticks is not too much bigger than amin - amax:
            strict_span = false,
        )
    else
        scaled_ticks = map(sf, (filter(t -> amin <= t <= amax, ticks)))
    end
    unscaled_ticks = map(invscale, scaled_ticks)

    labels = if any(isfinite, unscaled_ticks)
        formatter = :auto #axis[:formatter]
        if formatter == :auto
            # the default behavior is to make strings of the scaled values and then apply the labelfunc
            lfunc = identity#labelfunc(scale, backend())
            map(identity, Showoff.showoff(scaled_ticks, :plain))
        elseif formatter == :scientific
            Showoff.showoff(unscaled_ticks, :scientific)
        else
            # there was an override for the formatter... use that on the unscaled ticks
            map(formatter, unscaled_ticks)
        end
    else
        # no finite ticks to show...
        String[]
    end
    unscaled_ticks, labels
end



function generate_ticks(limits)
    ticks, labels = optimal_ticks_and_labels(limits, nothing)
    zip(ticks, labels)
end
function draw_ticks(
        scene, dim, origin, ticks, scale,
        linewidth, linecolor, linestyle,
        textcolor, textsize, rotation, align, font
    )
    for (tick, str) in ticks
        pos = ntuple(i-> i != dim ? origin[i] : (tick .* scale[dim]), Val{2})
        text!(
            scene,
            str, position = pos,
            rotation = rotation[dim], textsize = textsize[dim],
            align = align[dim], color = textcolor[dim], font = font[dim]
        )
    end
end

function draw_grid(
        scene, dim, origin, ticks, scale, dir::NTuple{N},
        linewidth, linecolor, linestyle
    ) where N
    scaleND = Pointf0{N}(ntuple(i-> scale[i], Val{N}))
    dirf0 = Pointf0{N}(dir) .* scaleND
    for (tick, str) in ticks
        tup = ntuple(i-> i != dim ? origin[i] : (tick .* scaleND[dim]), Val{N})
        posf0 = Pointf0{N}(tup)
        linesegments!(
            scene,
            [posf0, posf0 .+ dirf0],
            color = linecolor[dim], linewidth = linewidth[dim], linestyle = linestyle[dim]
        )
    end
end


function draw_frame(
        scene, limits::NTuple{N, Any}, scale,
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
            if axis_arrow
                arrows(
                    scene, [start => to],
                    linewidth = linewidth, linecolor = linecolor, linestyle = linestyle,
                    scale = scale, arrowsize = arrow_size
                )
            else
                linesegments!(
                    scene, [start, to],
                    linewidth = linewidth, color = linecolor, linestyle = linestyle,
                    scale = scale
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
                    linesegments!(
                        [from, to],
                        linewidth = linewidth, color = linecolor, linestyle = linestyle,
                        scale = scale
                    )
                end
            end
        end
    end
end

function draw_titles(
        scene,
        xticks, yticks, origin, limit_widths, scale,
        tickfont, tick_size, tick_gap, tick_title_gap,
        axis_labels,
        textcolor, textsize, rotation, align, font
    )

    tickspace_x = maximum(map(yticks) do tick
        str = last(tick)
        tick_bb = text_bb(str, attribute_convert(tickfont[2], Key{:font}()), tick_size[2])
        widths(tick_bb)[1]
    end)

    tickspace_y = widths(text_bb(
        last(first(xticks)), attribute_convert(tickfont[1], Key{:font}()), tick_size[1]
    ))[2]

    tickspace = (tickspace_x, tickspace_y)
    title_start = origin .- (tick_gap .+ tickspace .+ tick_title_gap)
    scale2d = ntuple(i-> scale[i], Val{2})
    half_width = origin .+ ((limit_widths .* scale2d) ./ 2.0)

    posx = (half_width[1], title_start[2])
    posy = (title_start[1], half_width[2])
    positions = (posx, posy)
    for i = 1:2
        text!(
            scene, axis_labels[i],
            position = positions[i], textsize = textsize[i],
            align = align[i], rotation = rotation[i]
        )
    end

end

function draw_axis(
        scene, ranges,

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
    limits = extrema.(ranges)
    limit_widths = map(x-> x[2] - x[1], limits)
    % = minimum(limit_widths) / 100 # percentage

    xyticks = generate_ticks.(limits)
    rect = scene.px_area[]
    xyfit = Makie.fit_ratio(rect, limits)
    scale = Vec3f0(1)

    ti_textsize = ti_textsize .* %
    t_textsize = t_textsize .* %; t_gap = t_gap .* %;
    t_title_gap = t_title_gap .* %

    scale2d = ntuple(i-> scale[i], Val{2})
    origin = first.(limits) .* scale2d

    dirs = ((0.0, Float64(limit_widths[2])), (Float64(limit_widths[1]), 0.0))
    foreach(1:2, dirs, xyticks) do dim, dir, ticks
        draw_grid(
            scene, dim, origin, ticks, scale, dir,
            g_linewidth, g_linecolor, g_linestyle
        )
    end

    o_offsets = ((0.0, Float64(t_gap)), (t_gap, Float64(0.0)))
    foreach(1:2, o_offsets, xyticks) do dim, offset, ticks
        draw_ticks(
            scene, dim, origin .- offset, ticks, scale,
            t_linewidth, t_linecolor, t_linestyle,
            t_textcolor, t_textsize, t_rotation, t_align, t_font
        )
    end

    draw_frame(
        scene, limits, scale,
        f_linewidth, f_linecolor, f_linestyle,
        f_axis_position, f_axis_arrow, f_arrow_size
    )

    draw_titles(
        scene, xyticks..., origin, limit_widths, scale,
        t_font, t_textsize, t_gap, t_title_gap,
        ti_labels,
        ti_textcolor, ti_textsize, ti_rotation, ti_align, ti_font,
    )
    return
end

struct Axis2D end

function default_theme(scene, ::Type{Axis2D})
    darktext = RGBAf0(0.0, 0.0, 0.0, 0.4)
    Theme(
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
            font = ("default", "default"),
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
        ),

        titlestyle = Theme(
            axisnames = ("X Axis", "Y Axis"),
            textcolor = (darktext, darktext),
            textsize = (6, 6),
            rotation = (0.0, -1.5pi),
            align = ((:center, :top), (:center, :bottom)),
            font = ("default", "default"),
        )
    )
end

function axis2d(scene::Scene, ranges::Node{<: NTuple{2, Any}})
    attributes, rest = merged_get!(:axis2d, scene, Attributes()) do
        default_theme(scene, Axis2D)
    end
    g_keys = (:linewidth, :linecolor, :linestyle)
    f_keys = (:linewidth, :linecolor, :linestyle, :axis_position, :axis_arrow, :arrow_size)
    t_keys = (
        :linewidth, :linecolor, :linestyle,
        :textcolor, :textsize, :rotation, :align, :font,
        :gap, :title_gap
    )
    ti_keys = (:axisnames, :textcolor, :textsize, :rotation, :align, :font)

    g_args = getindex.(attributes[:gridstyle][], g_keys)
    f_args = getindex.(attributes[:framestyle][], f_keys)
    t_args = getindex.(attributes[:tickstyle][], t_keys)
    ti_args = getindex.(attributes[:titlestyle][], ti_keys)

    map_once(
        draw_axis,
        to_node(scene), ranges,
        g_args..., t_args..., f_args..., ti_args...
    )
    return attributes
end
