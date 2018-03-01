
"""
Text align, e.g. :
"""
to_textalign(b, x) = x

# @default function legend(scene, kw_args)
#     backgroundcolor = to_color(backgroundcolor)
#     strokecolor = to_color(strokecolor)
#     strokewidth = to_float(strokewidth)
#     position = to_position(position)
#     gap = to_float(gap)
#     textgap = to_float(textgap)
#     labelwidth = to_float(labelwidth)
#     padding = to_float(padding)
#     align = to_textalign(align)
#     rotation = to_rotation(rotation)
#     textcolor = to_color(textcolor)
#     textsize = to_float(textsize)
#     markersize = to_markersize2d(markersize)
#     linepattern = to_positions(linepattern)
#     scatterpattern = to_positions(scatterpattern)
# end
@default function legend(scene, kw_args)
    backgroundcolor = to_color(backgroundcolor)
    strokecolor = to_color(strokecolor)
    strokewidth = to_float(strokewidth)
    position = to_position(position)
    gap = to_float(gap)
    textgap = to_float(textgap)
    labelwidth = to_float(labelwidth)
    padding = to_float(padding)
    outerpadding = to_markersize2d(outerpadding)
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

    attributes = legend_defaults(scene, attributes)

    position, color, stroke, strokecolor, padding, opad = getindex.(attributes, (
        :position, :backgroundcolor, :strokewidth, :strokecolor, :padding,
        :outerpadding
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

    legendarea = lift_node(position, to_node(screen.area), opad, args[4:5]..., args[1:3]...) do xy, area, opad, padding, unused...
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
        dont_touch(area, IRect(xy[1], xy[2], w, h), opad)
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


@default function color_legend(scene, kw_args)
    width = to_markersize2d(width)
    backgroundcolor = to_color(backgroundcolor)
    strokecolor = to_color(strokecolor)
    strokewidth = to_float(strokewidth)
    position = to_position(position)
    textgap = to_float(textgap)
    padding = to_markersize2d(padding)
    outerpadding = to_markersize2d(outerpadding)
    align = to_textalign(align)
    rotation = to_rotation(rotation)
    textcolor = to_color(textcolor)
    textsize = to_float(textsize)
end


function legend(scene::Scene, colormap::AbstractVector{<: Colorant}, range, attributes)
    attributes = color_legend_defaults(scene, attributes)
    attributes[:offset] = to_node(Vec3f0(0))
    attributes[:camera] = :pixel
    lscene = Scene(scene, attributes)

    padding, textsize, textcolor, align, textgap, width, position, opad = getindex.(attributes, (
        :padding, :textsize, :textcolor, :align, :textgap, :width, :position, :outerpadding
    ))

    vertices = Point3f0[(0, 0, 0), (0, 1, 0), (1, 1, 0), (1, 0, 0)]
    mesh = GLNormalUVMesh(
        vertices = copy(vertices),
        faces = GLTriangle[(1, 2, 3), (3, 4, 1)],
        texturecoordinates = UV{Float32}[(0, 0), (0, 1), (0, 1), (0, 0)]
    )

    cmap_node = lift_node(to_node(colormap)) do cmap
        reshape(cmap, (length(cmap), 1))
    end
    tio = TextBuffer(Point2f0(0))
    area = to_node(scene[:screen].area)
    rect = lift_node(
                to_node(range), textsize, textcolor, align,
                textgap, width, padding, opad, position, area
            ) do r, ts, tc, a, tg, w, pad, opad, position, area

        empty!(tio)
        N = length(r)
        for i = 1:N
            o1 = (i-1) / (N - 1) # 0 to 1
            pos = Point2f0(w[1] + tg, (ts/2) + o1 * w[2]) .+ pad
            label = string(r[i])
            append!(tio, pos, label, ts, tc, Vec4f0(0, 0, 0, 1), a)
        end
        bbw, bbh, _ = widths(value(boundingbox(tio.robj)))
        rect = FRect(
            0, 0,
            w[1] + 2pad[1] + bbw + tg,
            2pad[2] + bbh + (ts/2)
        )
        p = (position .* widths(area))
        r2 = FRect(p, rect.w, rect.h)
        p = p .+ move_from_touch(FRect(area), r2, opad)
        lscene[:offset] = Vec3f0(p[1], p[2], 0)
        rect
    end
    meshnode = lift_node(width, padding, textsize) do w, pad, ts
        mesh.vertices .= broadcast(vertices) do v
            Point3f0(((Point2f0(v[1], v[2]) .* w) .+ Point2f0(0, ts/2) .+ pad)..., 0.0)
        end
        mesh
    end
    lvis = Makie.lines(
        lscene,
        rect,
        linewidth = attributes[:strokewidth],
        color = attributes[:strokecolor]
    )
    tio.robj[:model] = lvis.visual[:model]

    GLVisualize._view(tio.robj, getscreen(scene), camera = :fixed_pixel)
    Makie.mesh(lscene, meshnode, color = cmap_node, shading = false)
    lscene
end
