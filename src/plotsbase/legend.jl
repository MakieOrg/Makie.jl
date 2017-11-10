
"""
Text align, e.g. :
"""
to_textalign(b, x) = x

@default function legend(scene, kw_args)
    backgroundcolor = to_color(backgroundcolor)
    strokecolor = to_color(strokecolor)
    strokewidth = to_float(strokewidth)
    position = to_position(position)
    gap = to_float(gap)
    textgap = to_float(textgap)
    labelwidth = to_float(labelwidth)
    padding = to_float(padding)
    align = to_textalign(align)
    rotation = to_rotation(rotation)
    textcolor = to_color(textcolor)
    textsize = to_float(textsize)
    markersize = to_markersize2d(markersize)
    linepattern = to_positions(linepattern)
    scatterpattern = to_positions(scatterpattern)
end


function make_label(p, plot, labeltext, i, attributes)

    w, gap, msize, lpattern, mpattern, padding = getindex.(attributes, (
        :labelwidth, :gap, :markersize, :linepattern, :scatterpattern, :padding
    ))

    scale(x, w, pad, g) = Point2f0(pad + (x[1] * w), x[2] + (i * g))

    return if plot.name in (:lines, :linesegment)
        linesegment(
            p, scale.(lpattern, w, padding, gap),
            color = plot[:color], linestyle = plot[:linestyle], show = false
        )
    else
        scatter(
            p, scale.(mpattern, w, padding, gap),
            markersize = msize, color = get(plot, :color, :black), show = false
        )
    end
end



function legend(scene::Scene, legends::AbstractVector{<:Scene}, labels::AbstractVector{<:String}, attributes)
    isempty(legends) && return
    N = length(legends)

    attributes = legend_defaults(scene, attributes)

    position, color, stroke, strokecolor, padding = getindex.(attributes, (
        :position, :backgroundcolor, :strokewidth, :strokecolor, :padding
    ))

    textbuffer = TextBuffer(Point2f0(0))
    legend = make_label.(scene, legends, labels, 1:N, attributes)

    args = getindex.(attributes, (:labelwidth, :gap, :textgap, :padding, :textsize, :textcolor, :rotation, :align))
    lift_node(to_node(labels), args...) do labels, w, gap, tgap, padding, font...
        empty!(textbuffer)
        for i = 1:length(labels)
            yposition = i * gap
            xy = Point2f0(w + padding + tgap, yposition)
            append!(textbuffer, xy, labels[i], font...)
        end
        return
    end

    bblist = (native_visual.(legend)..., textbuffer.robj)
    screen = getscreen(scene)

    #
    area = to_signal(lift_node(position, to_node(screen.area), args[4:5]..., args[1:3]...) do xy, area, padding, unused...
        wx, wy, _ = widths(mapreduce(GLAbstraction._boundingbox, union, bblist))
        xy = (xy .* widths(area))
        w, h = round.(Int, (wx, wy)) .+ (2padding, padding)
        # TODO check for overlaps, eliminate them!!
        IRect(xy[1], xy[2], w, h)
    end)

    legend_scene = Scene(
        scene, area,
        color = to_value(color),
        stroke = (to_value(stroke), to_value(strokecolor))
    )
    # Nasty, but Scene doesn't accept signals... Guess at some point we will just fold
    # GLWindow into makie anyways (or the gl backend package)
    lscreen = legend_scene[:screen]
    lift_node(x-> (lscreen.color = x), color)
    lift_node((x...)-> (lscreen.stroke = x), stroke, strokecolor)
    show!.(legend_scene, legend)
    GLVisualize._view(textbuffer.robj, lscreen, camera = :fixed_pixel)
    Scene(attributes)
end
