
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
