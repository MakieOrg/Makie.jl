
function draw_ticks(scene, idx, origin, ticks, tickstyle, scale)
    tickstyle = map(tickstyle) do ns
        ns[1] => to_value(ns[2])[idx]
    end
    vals = @extract tickstyle (linewidth, linecolor, textcolor, textsize, rotation, align, font)
    for (tick, str) in ticks
        pos = ntuple(i-> i != idx ? origin[i] : (tick .* scale[idx]), Val{2})
        text(
            scene,
            str, position = pos,
            rotation = rotation, textsize = textsize,
            align = align, color = textcolor
        )
        #linesegment([pos, endpos], color = linecolor, linewidth = linewidth)
    end
    positions = first.(ticks)
end


function draw_grid(scene, dim, origin, ticks, scale, dir::VecLike{N}, style) where N
    @extractvals style (linewidth, linecolor, linestyle)
    scaleND = Pointf0{N}(ntuple(i-> scale[i], Val{N}))
    dirf0 = Pointf0{N}(dir) .* scaleND
    for (tick, str) in ticks
        tup = ntuple(i-> i != dim ? origin[i] : (tick .* scaleND[dim]), Val{N})
        posf0 = Pointf0{N}(tup)
        linesegment(
            scene,
            [posf0, posf0 .+ dirf0],
            color = linecolor[dim], linewidth = linewidth[dim], linestyle = linestyle[dim]
        )
    end
end
function draw_frame(scene, limits::NTuple{N, Any}, framestyle, scale) where N
    vals = @extract framestyle (linewidth, linecolor, linestyle, axis_position, axis_arrow, arrow_size)
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
                linesegment(
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
                    linesegment(
                        [from, to],
                        linewidth = linewidth, color = linecolor, linestyle = linestyle,
                        scale = scale
                    )
                end
            end
        end
    end
end




    textbuffer = TextBuffer(Point{N, Float32}(0))
    linebuffer = LinesegmentBuffer(Point{N, Float32}(0))
    scene = get_global_scene()
    attributes = axis_defaults(scene, attributes)
    tickfont = N == 2 ? :tickfont2d : :tickfont3d
    names = (
        :axisnames, :axisnames_color, :axisnames_size, :axisnames_rotation_align, :axisnames_font, :visible, :showaxis, :showticks,
        :showgrid, :axiscolors, :gridcolors, :gridthickness, tickfont
    )
    args = getindex.(attributes, names)
    lift_node(
        draw_axis,
        to_node(textbuffer), to_node(linebuffer), ranges, args...
    )
    bb = to_signal(lift_node(ranges) do ranges
        mini, maxi = Vec{N, Float32}(map(minimum, ranges)), Vec{N, Float32}(map(maximum, ranges))
        mini3d, w = Vec3f0(to_nd(mini, Val{3}, 0f0)), Vec3f0(to_nd(maxi .- mini, Val{3}, 0f0))
        HyperRectangle(mini3d, w)
    end)
    linebuffer.robj.boundingbox = bb
    viz = Context(linebuffer.robj, textbuffer.robj)
    insert_scene!(scene, :axis, viz, attributes)
end

function draw_titles(yticks, xticks, tickstyle, titlestyle)

    tickspace_x = maximum(map(yticks) do tick
        str = last(tick)
        tick_bb = text_bb(str, to_font(scene, tickstyle[:font][2]), tick_size)
        widths(tick_bb)[1]
    end)

    tickspace_y = widths(text_bb(
        last(first(xticks)), to_font(scene, tickstyle[:font][1]), tick_size
    ))[2]

    tickspace = (tickspace_x, tickspace_y)
    title_start = origin_scaled .- (tick_gap .+ tickspace .+ tick_title_gap)

    half_width = origin_scaled .+ ((limit_widths .* scale2d) ./ 2.0)

    posx = (half_width[1], title_start[2])
    posy = (title_start[1], half_width[2])

    text(
        scene, titlestyle[:xaxis],
        position = posx,
        textsize = titlestyle[:title_size][1], align = (:center, :top)
    )
    text(
        scene, titlestyle[:yaxis],
        position = posy, textsize = titlestyle[:title_size][2],
        align = (:center, :bottom), rotation = -1.5pi
    )

end

function axis(scene::Scene, ranges::Node{<: NTuple{2}}, attributes::Dict)
    root = get_root_scene(scene)
    limit_widths = (maximum(x) - minimum(x)), (maximum(y) - minimum(y))
    # we use percentage of whole plot area for sizes
    pscale = minimum(limit_widths) / 100

    @extractvals axis_style (title_size, tick_size, tick_gap, tick_title_gap)

    title_size = pscale * title_size
    tick_size = pscale * tick_size
    tick_gap = pscale * tick_gap
    tick_title_gap = pscale * tick_title_gap

    limits = extrema.((x, y))

    xticks, yticks = generate_ticks.(limits)

    rect = Reactive.value(root[:screen].inputs[:window_area])
    xfit, yfit = Makie.fit_ratio(rect, (extrema(x), extrema(y)))
    scale = Vec3f0(xfit, yfit, 1)

    scale2d = ntuple(i-> scale[i], Val{2})
    origin_scaled = (minimum(x), minimum(y)) .* scale2d

    draw_ticks(scene, 1, origin_scaled .- (0.0, tick_gap), xticks, tickstyle, scale)
    draw_ticks(scene, 2, origin_scaled .- (tick_gap, 0.0), yticks, tickstyle, scale)

    draw_grid(scene, 1, origin_scaled, xticks, scale, (0.0, limit_widths[2]), gridstyle)
    draw_grid(scene, 2, origin_scaled, yticks, scale, (limit_widths[1], 0.0), gridstyle)


    draw_frame(scene, limits, framestyle)



end
