
function make_label(textbuffer, scene, labeltext, yposition, attributes)
    w, gap, msize, lpattern, mpattern, padding = to_value.(getindex.(attributes, (
        :labelwidth, :textgap, :markersize, :linepattern, :scatterpattern, :padding
    )))
    p = parent(scene)
    xpad = padding[1]
    result = if scene.name in (:lines, :linesegment)
        linesegment(
            p, map(x-> Point2f0(x[1] * w + xpad, x[2] + yposition), lpattern),
            color = scene[:color], linestyle = scene[:linestyle]
        )
    elseif scene.name == :scatter
        scatter(
            p, map(x-> Point2f0(x[1] * w + xpad, x[2] + yposition), mpattern),
            markersize = msize, color = scene[:color]
        )
    else
        scatter(p, points, markershape = :rect, color = scene[:color])
    end
    #color = to_color(:white) #scene[:legendcolor]
    #ft = scene[:legendfont]
    xy = Point2f0(w + xpad + gap, yposition)
    font = to_value.(getindex.(attributes, (:textsize, :textcolor, :rotation, :align)))
    append!(textbuffer, xy, labeltext, font...)
    # TODO do composition with scene objects
    result
end


to_textalign(b, x) = x

function legend_defaults(kw_args)
    @theme theme = begin
        backgroundcolor = to_color(:white)
        strokecolor = to_color(RGBA(0.3, 0.3, 0.3, 0.9))
        strokewidth = to_float(2)
        position = to_position((0.1, 0.5))
        gap = to_float(10)
        textgap = to_float(5)
        labelwidth = to_float(20)
        padding = to_float(20)
        align = to_textalign((:left, :hcenter))
        rotation = to_rotation(Vec4f0(0, 0, 0, 1))
        textcolor = to_color(:black)
        textsize = to_float(12)
        markersize = to_markersize(5)
        linepattern = to_positions(Point2f0[(0, 0), (1, 0.0)])
        scatterpattern = to_positions(Point2f0[(0.5, 0.0)])
    end
    merge(kw_args, theme.data)
end



function legend(scene::Scene, legends::AbstractVector{<:Scene}, labels::AbstractVector{<:String}, attributes)
    isempty(legends) && return
    attributes = legend_defaults(attributes)
    position, color, stroke, strokecolor, padding, gap = getindex.(attributes, (
        :position, :backgroundcolor, :strokewidth, :strokecolor, :padding, :gap
    ))
    gap = to_value(gap)
    textbuffer = TextBuffer(Point2f0(0))
    N = length(legends)
    legend = make_label.(textbuffer, legends, labels, linspace(gap, gap * (N + 1), N), (attributes,))
    list = GLAbstraction.Context(native_visual.(legend)..., textbuffer.robj)
    root = MakiE.rootscene(first(legends))
    screen = rootscreen(root)
    bb = GLAbstraction._boundingbox(list)
    wx, wy, _ = GeometryTypes.widths(bb)
    area = to_signal(lift_node(position, to_node(screen.area), padding) do xy, area, padding
        xy = (xy .* widths(area))
        w, h = round.(Int, (wx, wy)) .+ (2padding, padding)
        # TODO check for overlaps, eliminate them!!
        IRect(xy[1], xy[2], w, h)
    end)
    sscren = GLWindow.Screen(
        screen, area = area,
        color = to_value(color),
        stroke = (to_value(stroke), to_value(strokecolor))
    )
    GLVisualize._view(list, sscren, camera = :fixed_pixel)
    Scene(attributes)
end
