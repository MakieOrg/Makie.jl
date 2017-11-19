
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
    w, gap, msize, tsize, lpattern, mpattern, padding = getindex.(attributes, (
        :labelwidth, :gap, :markersize, :textsize,
        :linepattern, :scatterpattern, :padding
    ))

    scale(x, w, pad, g, t) = Point2f0(
        pad + (x[1]w),
        pad + floor(t/2) + x[2]w + ((i - 1) * g)
    )

    return if plot.name in (:lines, :linesegment)
        linesegment(
            p, scale.(lpattern, w, padding, gap, tsize),
            color = plot[:color], linestyle = plot[:linestyle], show = false,
            camera = :pixel
        )
    else
        scatter(
            p, scale.(mpattern, w, padding, gap, tsize),
            markersize = msize, color = get(plot, :color, :black), show = false,
            camera = :pixel
        )
    end
end



function legend(scene::Scene, legends::AbstractVector{<:Scene}, labels::AbstractVector{<:String}, attributes)
    isempty(legends) && return
    N = length(legends)
    legendarea = Signal(IRect(0, 0, 50, 50))

    attributes = legend_defaults(scene, attributes)

    position, color, stroke, strokecolor, padding = getindex.(attributes, (
        :position, :backgroundcolor, :strokewidth, :strokecolor, :padding
    ))

    textbuffer = TextBuffer(Point2f0(0))

    args = getindex.(attributes, (
        :labelwidth, :gap, :textgap, :padding,
        :textsize, :textcolor, :rotation, :align
    ))

    legend = make_label.(scene, legends, labels, 1:N, attributes)

    lift_node(to_node(labels), args...) do labels, w, gap, tgap, padding, font...
        empty!(textbuffer)
        for i = 1:length(labels)
            yposition = (i - 1) * gap
            tsize = floor(font[1] / 2) # textsize at position one, half of it since we used centered align
            xy = Point2f0(w + padding + tgap, yposition + tsize + padding)
            append!(textbuffer, xy, labels[i], font...)
        end
        return
    end

    bblist = (native_visual.(legend)..., textbuffer.robj)
    screen = getscreen(scene)

    legendarea = lift_node(position, to_node(screen.area), args[4:5]..., args[1:3]...) do xy, area, padding, unused...
        bb = mapreduce(x-> value(x.boundingbox), union, bblist)
        mini = minimum(bb)
        wx, wy, _ = widths(bb) .+ mini
        xy = (xy .* widths(area))
        w, h = if isfinite(wx) && isfinite(wy)
            round.(Int, (wx, wy)) .+ padding
        else
            (0, 0)
        end
        # TODO check for overlaps, eliminate them!!
        IRect(xy[1], xy[2], w, h)
    end
    legend_scene = Scene(
        scene, legendarea,
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
