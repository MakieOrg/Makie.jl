
@recipe(Legend, plots, labels) do scene
    Theme(
        outer_area = IRect(0, 0, 1, 1),
        backgroundcolor = :white,
        strokecolor = RGBA(0.3, 0.3, 0.3, 0.9),
        strokewidth = 1,
        position = (1, 1),
        gap = 20,
        textgap = 15,
        labelwidth = 20,
        padding = 10,
        outerpadding = 10,
        align = (:left, :hcenter),
        rotation = Quaternionf0(0, 0, 0, 1),
        textcolor = :black,
        textsize = 16,
        font = theme(scene, :font),
        markersize = 5,
        linepattern = Point2f0[(0, 0), (1, 0.0)],
        scatterpattern = Point2f0[(0.5, 0.0)],
    )
end

"""
    colorlegend(scene, colormap, range)

creates a legend from a colormap
"""
@recipe(ColorLegend, colormap, colorrange) do scene
    Theme(
        width = (20, 200),
        backgroundcolor = :white,
        strokecolor = RGBA(0.3, 0.3, 0.3, 0.9,),
        strokewidth = 1,
        position = (1, 1),
        textgap = 15,
        padding = 10,
        outerpadding = 10,
        align = (:left, :hcenter),
        rotation = 0.0,
        textcolor = :black,
        textsize = 16,
        font = theme(scene, :font),
    )
end


function make_label(scene, plot, labeltext, i, attributes)
    w, gap, msize, tsize, lpattern, mpattern, padding = getindex.(attributes, (
        :labelwidth, :gap, :markersize, :textsize,
        :linepattern, :scatterpattern, :padding
    ))
    _scale(x, w, pad, g, t) = Point2f0(
        pad + (x[1]w),
        pad + floor(t/2) + x[2]w + ((i - 1) * g)
    )
    scale(args...) = _scale.(args...)

    return if isa(plot, Union{Lines, LineSegments})
        linesegments!(
            scene, lift(scale, lpattern, w, padding, gap, tsize),
            color = plot[:color], linestyle = plot[:linestyle]
        )
    else
        scatter!(
            scene, lift(scale, mpattern, w, padding, gap, tsize),
            markersize = msize, color = plot[:color]
        )
    end
end

outerbox(x::AbstractPlot) = outerbox(x.parent)
outerbox(x::Scene) = pixelarea(x)

convert_argument(::Type{<:Legend}, plots::AbstractVector, labels::AbstractVector{<: AbstractString}) = (plots, labels)

function plot!(plot::Legend)
    @extract plot (plots, labels)
    scene = detach!(plot)
#    cam2d!(scene)
    isempty(plots[]) && return
    N = length(plots[])
    position, color, stroke, strokecolor, padding, opad = getindex.(plot, (
        :position, :backgroundcolor, :strokewidth, :strokecolor, :padding,
        :outerpadding
    ))

    textbuffer = TextBuffer(plot, Point2)

    args = getindex.(plot, (
        :labelwidth, :gap, :textgap, :padding,
        :textsize, :textcolor, :rotation, :align, :font
    ))

    legends = make_label.(plot, plots[], labels[], 1:N, plot)

    map_once(labels, args...) do labels, w, gap, tgap, padding, font...
        start!(textbuffer)
        for i = 1:length(labels)
            yposition = (i - 1) * gap
            tsize = floor(font[1] / 2) # textsize at position one, half of it since we used centered align
            xy = Point2f0(w + padding + tgap, yposition + tsize + padding)
            push!(
                textbuffer,
                labels[i], xy, textsize = font[1], color = font[2],
                rotation = font[3], align = font[4],
                font = font[5]
            )
        end
        finish!(textbuffer)
        return
    end
    legendarea = map_once(position, outerbox(plot), opad, args[4:5]..., args[1:3]...) do xy, area, opad, padding, unused...
        bb = boundingbox(plot)
        mini = minimum(bb)
        wx, wy, _ = widths(bb) .+ mini
        xy = (Vec2f0(xy) .* widths(area))
        w, h = if isfinite(wx) && isfinite(wy)
            round.(Int, (wx, wy)) .+ padding
        else
            (0, 0)
        end
        rect = dont_touch(area, IRect(xy[1], xy[2], w, h), Vec2f0(opad))
        translate!(plot, minimum(rect)..., 0)
        FRect2D(rect)
    end
    lines!(plot, legendarea)
end


function argument_convert(::Type{<: ColorLegend}, plot::AbstractPlot)
    (plot[:colormap], plot[:colorrange])
end


function plot!(plot::ColorLegend)
    lscene = Scene(scene, scene.px_area)
    campixel!(lscene) # map coordinates to pixel
    @extract plot (colormap, colorrange)

    @extract(
        plot,
        (
            padding, textsize, textcolor, align, font,
            textgap, width, position, outerpadding
        )
    )

    vertices = Point3f0[(0, 0, 0), (0, 1, 0), (1, 1, 0), (1, 0, 0)]
    mesh = GLNormalUVMesh(
        vertices = copy(vertices),
        faces = GLTriangle[(1, 2, 3), (3, 4, 1)],
        texturecoordinates = UV{Float32}[(0, 0), (0, 1), (0, 1), (0, 0)]
    )

    cmap_node = lift(colormap) do cmap
        c = to_colormap(cmap)
        # TODO cover the case of a 1D colormap explicitely in the shader
        reshape(c, (length(c), 1))
    end
    tio = TextBuffer(lscene, Point2)
    rect = lift(
                colorrange, textsize, textcolor, align, font,
                textgap, width, padding, outerpadding, position, scene.px_area
            ) do r, ts, tc, a, font, tg, w, pad, opad, position, area

        start!(tio)
        real_range, labels = to_range(r)
        N = length(real_range)
        for (i, label) in zip(1:N, labels)
            o1 = (i - 1) / (N - 1) # 0 to 1
            pos = Point2f0(w[1] + tg, (ts/2) + o1 * w[2]) .+ pad
            push!(
                tio, label, pos, textsize = ts, color = tc, rotation = 0.0,
                align = a, font = font
            )
        end
        finish!(tio)
        limits = data_limits(tio)
        bbw, bbh = widths(limits)
        rect = FRect(
            0, 0,
            w[1] + 2pad + bbw + tg,
            2pad + bbh + (ts/2)
        )
        p = (Vec2f0(position) .* widths(area))
        r2 = FRect(p, widths(rect))
        p = p .+ move_from_touch(FRect(area), r2, Vec2f0(opad))
        lscene.transformation.translation[] = Vec3f0(p[1], p[2], 0)
        rect
    end
    meshnode = lift(width, padding, textsize) do w, pad, ts
        mesh.vertices .= broadcast(vertices) do v
            Point3f0(((Point2f0(v[1], v[2]) .* Point2f0(w)) .+ Point2f0(0, ts/2) .+ pad)..., 0.0)
        end
        mesh
    end
    lvis = lines!(
        lscene,
        rect,
        linewidth = attributes[:strokewidth],
        color = attributes[:strokecolor],
        raw = true
    )
    Makie.mesh!(lscene, meshnode, color = cmap_node, shading = false, raw = true)
    lscene
end
