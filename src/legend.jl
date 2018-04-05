struct Legend{T} <: AbstractPlot
    args::T
    attributes::Attributes
end
struct ColorLegend{T} <: AbstractPlot
    args::T
    attributes::Attributes
end


function default_theme(scene::Scene, ::Type{Legend})
    Theme(
        backgroundcolor = :white,
        strokecolor = RGBA(0.3, 0.3, 0.3, 0.9),
        strokewidth = 1,
        position = (0, 1),
        gap = 20,
        textgap = 15,
        labelwidth = 20,
        padding = 10,
        outerpadding = 10,
        align = (:left, :hcenter),
        rotation = Vec4f0(0, 0, 0, 1),
        textcolor = :black,
        textsize = 16,
        markersize = 5,
        linepattern = Point2f0[(0, 0), (1, 0.0)],
        scatterpattern = Point2f0[(0.5, 0.0)],
    )
end

function default_theme(scene::Scene, ::Type{ColorLegend})
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

    return if isa(plot, Union{Lines, Linesegments})
        linesegments!(
            scene, map(scale, lpattern, w, padding, gap, tsize),
            color = plot[:color], linestyle = plot[:linestyle],
            raw = true
        )
    else
        scatter!(
            scene, map(scale, mpattern, w, padding, gap, tsize),
            markersize = msize, color = plot[:color],
            raw = true
        )
    end
end



function legend(scene::Scene, legends::AbstractVector{<:AbstractPlot}, labels::AbstractVector{<:String}, attributes)
    isempty(legends) && return
    attributes, rest = merged_get!(:legend, scene, attributes) do
        default_theme(scene, Legend)
    end

    N = length(legends)

    position, color, stroke, strokecolor, padding, opad = getindex.(attributes, (
        :position, :backgroundcolor, :strokewidth, :strokecolor, :padding,
        :outerpadding
    ))

    lscene = Scene(scene, scene.px_area)
    campixel!(lscene) # map coordinates to pixel
    textbuffer = TextBuffer(lscene, Point2)

    args = getindex.(attributes, (
        :labelwidth, :gap, :textgap, :padding,
        :textsize, :textcolor, :rotation, :align
    ))

    legends = make_label.(lscene, legends, labels, 1:N, attributes)

    map_once(to_node(labels), args...) do labels, w, gap, tgap, padding, font...
        start!(textbuffer)
        for i = 1:length(labels)
            yposition = (i - 1) * gap
            tsize = floor(font[1] / 2) # textsize at position one, half of it since we used centered align
            xy = Point2f0(w + padding + tgap, yposition + tsize + padding)
            push!(textbuffer, labels[i], xy, textsize = font[1], color = font[2], rotation = font[3], align = font[4], font = "default")
            raw = true
        end
        finish!(textbuffer)
        return
    end
    #
    legendarea = map(position, scene.px_area, opad, args[4:5]..., args[1:3]...) do xy, area, opad, padding, unused...
        bb = data_limits(lscene)
        mini = minimum(bb)
        wx, wy, _ = widths(bb) .+ mini
        xy = (Vec2f0(xy) .* widths(area))
        w, h = if isfinite(wx) && isfinite(wy)
            round.(Int, (wx, wy)) .+ padding
        else
            (0, 0)
        end
        rect = dont_touch(area, IRect(xy[1], xy[2], w, h), Vec2f0(opad))
        lscene.transformation.translation[] = Vec3f0(minimum(rect)..., 0)
        FRect2D(rect)
    end

    bg = Scene(scene, scene.px_area)
    campixel!(bg)
    lines!(bg, legendarea, raw = true)
    Legend((legends, labels), attributes)
end

    #
    # :legend => """
    #     legend(series, labels)
    # creates a legend from an array of plots and labels
    # """,
    # :colorlegend => """
    #

to_range(x::VecTypes{2}) = linspace(x[1], x[2], 4)
function to_range(x::AbstractVector)
    if length(x) <= 5
        x
    else
        linspace(minimum(x), maximum(x), 5)
    end
end

"""
colorlegend(scene, colormap, range)
creates a legend from a colormap
"""
function colorlegend(scene::Scene, colormap, range, attributes)
    attributes, rest = merged_get!(:colorlegend, scene, attributes) do
        default_theme(scene, ColorLegend)
    end

    lscene = Scene(scene, scene.px_area)
    campixel!(lscene) # map coordinates to pixel

    padding, textsize, textcolor, align, textgap, width, position, opad = getindex.(attributes, (
        :padding, :textsize, :textcolor, :align, :textgap, :width, :position, :outerpadding
    ))

    vertices = Point3f0[(0, 0, 0), (0, 1, 0), (1, 1, 0), (1, 0, 0)]
    mesh = GLNormalUVMesh(
        vertices = copy(vertices),
        faces = GLTriangle[(1, 2, 3), (3, 4, 1)],
        texturecoordinates = UV{Float32}[(0, 0), (0, 1), (0, 1), (0, 0)]
    )

    cmap_node = map(to_node(colormap)) do cmap
        c = attribute_convert(cmap, key"colormap"())
        # TODO cover the case of a 1D colormap explicitely in the shader
        reshape(c, (length(c), 1))
    end
    tio = TextBuffer(lscene, Point2)
    rect = map(
                to_node(range), textsize, textcolor, align,
                textgap, width, padding, opad, position, scene.px_area
            ) do r, ts, tc, a, tg, w, pad, opad, position, area

        start!(tio)
        real_range = to_range(r)
        N = length(real_range)
        for i = 1:N
            o1 = (i - 1) / (N - 1) # 0 to 1
            pos = Point2f0(w[1] + tg, (ts/2) + o1 * w[2]) .+ pad
            label = string(round(real_range[i], 3))
            push!(tio, label, pos, textsize = ts, color = tc, rotation = 0.0, align = a, font = "default")
        end
        finish!(tio)
        limits = data_limits(tio)
        bbw = limits[2][1] - limits[1][1]
        bbh = limits[2][2] - limits[1][2]
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
    meshnode = map(width, padding, textsize) do w, pad, ts
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
