function plot(P::PlotFunc, args...; axis = (;), figure = (;), kw_attributes...)
    # scene_attributes = extract_scene_attributes!(attributes)
    fig = Figure(; figure...)

    proxyscene = Scene()
    plot!(proxyscene, P, Attributes(kw_attributes), args...)

    if is2d(proxyscene)
        ax = LAxis(fig; axis...)
    else
        ax = LScene(fig.scene; scenekw = (camera = cam3d!, show_axis = true))
    end

    fig.layout[1, 1] = ax
    push!(fig.content, ax)
    p = plot!(ax, P, Attributes(kw_attributes), args...)
    (figure = fig, axis = ax, plot = p)
end

function plot(P::PlotFunc, fp::Figureposition, args...; axis = (;), kwargs...)

    @assert isempty(contents(fp.gp, exact = true))

    proxyscene = Scene()
    plot!(proxyscene, P, Attributes(kwargs), args...)

    if is2d(proxyscene)
        ax = LAxis(fp.fig; axis...)
    else
        ax = LScene(fp.fig.scene; scenekw = (camera = cam3d!, show_axis = true))
    end

    fp.gp[] = ax
    p = plot!(P, ax, args...; kwargs...)
    (axis = ax, plot = p)
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
        ax = LScene(fig.scene; scenekw = (camera = cam3d!, show_axis = true))
    end

    # layout = find_or_make_layout!(fsp.parent)
    fsp.parent[fsp.rows, fsp.cols, fsp.side] = ax
    p = plot!(P, ax, args...; kwargs...)
    (axis = ax, plot = p)
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