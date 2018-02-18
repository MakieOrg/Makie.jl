
function draw_ticks(
        scene, idx, origin, ticks, scale, pscale,
        linewidth, linecolor, textcolor, textsize, rotation, align, font
    )
    for (tick, str) in ticks
        pos = ntuple(i-> i != idx ? origin[i] : (tick .* scale[idx]), Val{2})
        text(
            scene,
            str, position = pos,
            rotation = rotation, textsize = textsize,
            align = align, color = textcolor
        )
    end
end


function draw_grid(
        scene, dim, origin, ticks, scale, dir::VecLike{N},
        linewidth, linecolor, linestyle
    ) where N
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


function draw_frame(
        scene, limits::NTuple{N, Any}, scale,
        linewidth, linecolor, linestyle, axis_position, axis_arrow, arrow_size
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

function draw_titles(
        
        yticks, xticks, origin_scaled, limit_widths, scale,

        tickfont, tick_size, tick_gap, tick_title_gap,

        axis_labels, textsize, align, rotation

    )

    tickspace_x = maximum(map(yticks) do tick
        str = last(tick)
        tick_bb = text_bb(str, to_font(scene, tickfont[2]), tick_size)
        widths(tick_bb)[1]
    end)

    tickspace_y = widths(text_bb(
        last(first(xticks)), to_font(scene, tickfont[1]), tick_size
    ))[2]

    tickspace = (tickspace_x, tickspace_y)
    title_start = origin_scaled .- (tick_gap .+ tickspace .+ tick_title_gap)

    half_width = origin_scaled .+ ((limit_widths .* scale2d) ./ 2.0)

    posx = (half_width[1], title_start[2])
    posy = (title_start[1], half_width[2])
    positions = (posx, posy)
    for i = 1:2
        text(
            scene, axis_labels[i],
            position = positions[i], textsize = textsize[i],
            align = align[i], rotation = rotation[i]
        )
    end

end

function axis(scene::Scene, ranges::Node{<: NTuple{2}}, attributes::Dict)
    root = get_root_scene(scene)

    values = lift_node(ranges) do ranges
        limits = extrema.(ranges)
        limit_widths = map(x-> x[2] - x[1], limits)
        pscale = minimum(limit_widths) / 100
        
        xyticks = generate_ticks.(limits)
        rect = Reactive.value(root[:screen].inputs[:window_area])
        xyfit = Makie.fit_ratio(rect, limits)
        scale = Vec3f0(xyfit..., 1)

        limits, limit_widths, xyticks, pscale, scale
    end
    tick_args = getindex.(attributes[:ticks], (
        :linewidth, :linecolor, :textcolor, :textsize, :rotation, :align, :font
    ))
    args = (values, attributes[:tick_gap], tick_args...)
    lift_node(args...) do values, tick_gap, style...
        for idx = 1:2
            o = mini_scaled .- unit((0.0, tick_gap)
            draw_ticks(
                scene, idx, origin, ticks, scale,
                ticks...
            )
        end
    end
    @lift_node(attributes) do title_size, tick_size, tick_gap, tick_title_gap
        # we use percentage of whole plot area for sizes

        title_size = pscale * title_size
        tick_size = pscale * tick_size
        tick_gap = pscale * tick_gap
        tick_title_gap = pscale * tick_title_gap

        
        mini_scaled = (minimum(x), minimum(y)) .* scale2d

        draw_ticks(scene, 1, , xticks, tickstyle, scale)
        draw_ticks(scene, 2, mini_scaled .- (tick_gap, 0.0), yticks, tickstyle, scale)

        draw_grid(scene, 1, mini_scaled, xticks, scale, (0.0, limit_widths[2]), gridstyle)
        draw_grid(scene, 2, mini_scaled, yticks, scale, (limit_widths[1], 0.0), gridstyle)

        draw_frame(scene, limits, framestyle)
    end
end
