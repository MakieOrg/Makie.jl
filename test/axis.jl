using Makie, GeometryTypes, Quaternions, StaticArrays, PlotUtils, Showoff
using Makie: VecTypes

using Makie: draw_ticks, draw_grid, draw_frame, @extractvals, generate_ticks

function scalescene(scene)

    for (k, v) in scene.data
        if k != :camera
            v[:scale] = scale
        end
    end
    yield()
end

function axis(scene, x, y)

    root = Makie.rootscene(scene)
    limit_widths = (maximum(x) - minimum(x)), (maximum(y) - minimum(y))
    # we use percentage of whole plot area for sizes
    pscale = minimum(limit_widths) / 100



    @extractvals axis_style (outer_padding, title_size, tick_size, tick_gap, tick_title_gap)

    outer_padding = pscale * outer_padding
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


    draw_frame(scene, limits, framestyle, scale)

    tickspace_x = maximum(map(yticks) do tick
        str = last(tick)
        tick_bb = Makie.text_bb(str, to_font(scene, tickstyle[:font][2]), tick_size)
        GeometryTypes.widths(tick_bb)[1]
    end)

    tickspace_y = GeometryTypes.widths(Makie.text_bb(
        last(first(xticks)), to_font(scene, tickstyle[:font][1]), tick_size
    ))[2]

    tickx_range = xticks.a
    ticky_range = yticks.a
    tickspace = (tickspace_x, tickspace_y)
    title_start = origin_scaled .- (tick_gap .+ tickspace .+ tick_title_gap)

    half_width = origin_scaled .+ ((limit_widths .* scale2d) ./ 2.0)

    posx = (half_width[1], title_start[2])
    posy = (title_start[1], half_width[2])

    text(
        scene, "X Axis",
        position = posx,
        textsize = title_size, align = (:center, :top)
    )
    text(
        scene, "Y Axis",
        position = posy, textsize = title_size,
        align = (:center, :bottom), rotation = -1.5pi
    )

end






scene = Scene()
x = linspace(0, 2, 10)
y = linspace(0, 4, 10)
axis(scene, x, y)
center!(scene)

# scatter(scene, [from, Point2f0(minimum(x), maximum(y))], markersize = 1, scale = scale)
# scatter(scene, [from, Point2f0(maximum(x), minimum(y))], markersize = 1, scale = scale)

# using Plots; gr(size = (1000, 200))
#
# # x = rand(10) .+ 3
# # y = rand(10) .+ 6
# p = plot(x, y, xaxis = "X Axis", yaxis = "Y Axis")
# fieldnames(p)
# p.attr

# annotate(scene,
#     "Full canvas: title_size + tick_title_gap + tick_size + tick_gap + outer_padding",
#     (axis_middle[1], min_size[2] .- 0.05), (axis_middle[1], min_size[2]),
#     linecolor = :gray, knobcolor = :black,
#     color = :red, textsize = title_size / 3, align = (:center, :top)
# )
#
# annotate(scene,
#     "outer_padding",
#     (min_size[1], min_size[2] .- 0.05), (min_size[1], min_size[2] + outer_padding),
#     linecolor = :gray, knobcolor = :black,
#     color = (:black, 0.4), textsize = title_size / 3, align = (:left, :top)
# )
#
# annotate(scene,
#     "outer_padding",
#     (min_size[1], min_size[2] .- 0.05), (min_size[1], min_size[2] + outer_padding),
#     linecolor = :gray, knobcolor = :black,
#     color = (:black, 0.4), textsize = title_size / 3, align = (:left, :top)
# )
