struct FigureAxisPlot
    figure::Figure
    axis
    plot::AbstractPlot
end

struct AxisPlot
    axis
    plot::AbstractPlot
end

Base.display(fap::FigureAxisPlot) = display(fap.figure)
Base.iterate(fap::FigureAxisPlot, args...) = iterate((fap.figure, fap.axis, fap.plot), args...)
Base.iterate(ap::AxisPlot, args...) = iterate((ap.axis, ap.plot), args...)

function plot(P::PlotFunc, args...; axis = (;), figure = (;), kw_attributes...)
    # scene_attributes = extract_scene_attributes!(attributes)
    fig = Figure(; figure...)

    proxyscene = Scene()
    plot!(proxyscene, P, Attributes(kw_attributes), args...)

    if is2d(proxyscene)
        ax = LAxis(fig; axis...)
    else
        ax = LScene(fig.scene; scenekw = (camera = cam3d!, show_axis = true, raw = false, axis...))
    end

    fig.layout[1, 1] = ax
    push!(fig.content, ax)
    p = plot!(ax, P, Attributes(kw_attributes), args...)

    FigureAxisPlot(fig, ax, p)
end

function plot(P::PlotFunc, fp::Figureposition, args...; axis = (;), kwargs...)

    @assert isempty(contents(fp.gp, exact = true))

    proxyscene = Scene()
    plot!(proxyscene, P, Attributes(kwargs), args...)

    if is2d(proxyscene)
        ax = LAxis(fp.fig; axis...)
    else
        ax = LScene(fp.fig.scene; scenekw = (camera = cam3d!, show_axis = true, raw = false, axis...))
    end

    fp.gp[] = ax
    p = plot!(P, ax, args...; kwargs...)

    AxisPlot(ax, p)
end

function plot!(P::PlotFunc, fp::Figureposition, args...; kwargs...)

    c = contents(fp.gp, exact = true)
    if !(length(c) == 1 && c[1] isa Union{LAxis, LScene})
        error("There is not just one axis at $(fp.gp).")
    end
    ax = only(c)
    plot!(P, ax, args...; kwargs...)

end

function plot(P::PlotFunc, fsp::FigureSubposition, args...; axis = (;), kwargs...)

    fig = get_figure(fsp)

    proxyscene = Scene()
    plot!(proxyscene, P, Attributes(kwargs), args...)

    if is2d(proxyscene)
        ax = LAxis(fig; axis...)
    else
        ax = LScene(fig.scene; scenekw = (camera = cam3d!, show_axis = true, raw = false, axis...))
    end

    # layout = find_or_make_layout!(fsp.parent)
    fsp.parent[fsp.rows, fsp.cols, fsp.side] = ax
    p = plot!(P, ax, args...; kwargs...)

    AxisPlot(ax, p)
end

function plot!(P::PlotFunc, fsp::FigureSubposition, args...; kwargs...)

    # TODO: if ax doesn't exist, layouts should also not be made
    layout = find_or_make_layout!(fsp.parent)

    gp = layout[fsp.rows, fsp.cols, fsp.side]

    c = contents(gp, exact = true)
    if !(length(c) == 1 && c[1] isa Union{LAxis, LScene})
        error("There is not just one axis at $(gp).")
    end
    ax = only(c)
    plot!(P, ax, args...; kwargs...)
end