
"""
Ugh, so much special casing (╯°□°）╯︵ ┻━┻
"""
function label_scatter(d, w, ho)
    kw = KW()
    extract_stroke(d, kw)
    extract_marker(d, kw)
    kw[:scale] = Vec2f0(w/2)
    kw[:offset] = Vec2f0(-w/4)
    if haskey(kw, :intensity)
        cmap = kw[:color_map]
        norm = kw[:color_norm]
        kw[:color] = GLVisualize.color_lookup(cmap, kw[:intensity][1], norm)
        delete!(kw, :intensity)
        delete!(kw, :color_map)
        delete!(kw, :color_norm)
    else
        color = get(kw, :color, nothing)
        kw[:color] = isa(color, Array) ? first(color) : color
    end
    strcolor = get(kw, :stroke_color, RGBA{Float32}(0,0,0,0))
    kw[:stroke_color] = isa(strcolor, Array) ? first(strcolor) : strcolor
    p = get(kw, :primitive, GeometryTypes.Circle)
    if isa(p, GLNormalMesh)
        bb = GeometryTypes.AABB{Float32}(GeometryTypes.vertices(p))
        bbw = GeometryTypes.widths(bb)
        if isapprox(bbw[3], 0)
            bbw = Vec3f0(bbw[1], bbw[2], 1)
        end
        mini = minimum(bb)
        m = GLAbstraction.translationmatrix(-mini)
        m *= GLAbstraction.scalematrix(1 ./ bbw)
        kw[:primitive] = m * p
        kw[:scale] = Vec3f0(w/2)
        delete!(kw, :offset)
    end
    if isa(p, Array)
        kw[:primitive] = GeometryTypes.Circle
    end
    GL.scatter(Point2f0[(w/2, ho)], kw)
end


function make_label(sp, series, i)
    GL = Plots
    w, gap, ho = 20f0, 5f0, 5
    result = []
    d = series.d
    st = d[:seriestype]
    kw_args = KW()
    if (st in (:path, :path3d)) && d[:linewidth] > 0
        points = Point2f0[(0, ho), (w, ho)]
        kw = KW()
        extract_linestyle(d, kw)
        append!(result, GL.lines(points, kw))
        if d[:markershape] != :none
            push!(result, label_scatter(d, w, ho))
        end
    elseif st in (:scatter, :scatter3d) #|| d[:markershape] != :none
        push!(result, label_scatter(d, w, ho))
    else
        extract_c(d, kw_args, :fill)
        if isa(kw_args[:color], AbstractVector)
            kw_args[:color] = first(kw_args[:color])
        end
        push!(result, visualize(
            GeometryTypes.SimpleRectangle(-w/2, ho-w/4, w/2, w/2),
            Style(:default), kw_args
        ))
    end
    labeltext = if isa(series[:label], Array)
        i += 1
        series[:label][i]
    else
        series[:label]
    end
    color = sp[:foreground_color_legend]
    ft = sp[:legendfont]
    font = Plots.Font(ft.family, ft.pointsize, :left, :bottom, 0.0, color)
    xy = Point2f0(w+gap, 0.0)
    kw = Dict(:model => text_model(font, xy), :scale_primitive=>false)
    extract_font(font, kw)
    t = PlotText(labeltext, font)
    push!(result, glvisualize_text(xy, t, kw))
    GLAbstraction.Context(result...), i
end


function generate_legend(sp, screen, model_m)
    legend = GLAbstraction.Context[]
    if sp[:legend] != :none
        i = 0
        for series in series_list(sp)
            should_add_to_legend(series) || continue
            result, i = make_label(sp, series, i)
            push!(legend, result)
        end
        if isempty(legend)
            return
        end
        list = visualize(legend, gap=Vec3f0(0,5,0))
        bb = GLAbstraction._boundingbox(list)
        wx,wy,_ = GeometryTypes.widths(bb)
        xmin, _ = Plots.axis_limits(sp[:xaxis])
        _, ymax = Plots.axis_limits(sp[:yaxis])
        area = map(model_m) do m
            p = m * GeometryTypes.Vec4f0(xmin, ymax, 0, 1)
            h = round(Int, wy)+20
            w = round(Int, wx)+20
            x,y = round(Int, p[1])+30, round(Int, p[2]-h)-30
            GeometryTypes.SimpleRectangle(x, y, w, h)
        end
        sscren = GLWindow.Screen(
            screen, area = area,
            color = sp[:background_color_legend],
            stroke = (2f0, RGBA(0.3, 0.3, 0.3, 0.9))
        )
        GLAbstraction.translate!(list, Vec3f0(10,10,0))
        GLVisualize._view(list, sscren, camera=:fixed_pixel)
    end
    return
end
