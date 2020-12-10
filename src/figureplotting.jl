function plot(P::PlotFunc, args...; axis = (;), figure = (;), kw_attributes...)
    # scene_attributes = extract_scene_attributes!(attributes)
    fig = Figure(; figure...)
    ax = LAxis(fig; axis...)
    fig.layout[1, 1] = ax
    push!(fig.content, ax)
    p = plot!(ax, P, Attributes(kw_attributes), args...)
    (figure = fig, axis = ax, plot = p)
end

function plot(P::PlotFunc, fp::Figureposition, args...; axis = (;), kwargs...)

    @assert isempty(contents(fp.gp, exact = true))

    ax = fp.gp[] = LAxis(fp.fig; axis...)
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

    # layout = find_or_make_layout!(fsp.parent)
    ax = fsp.parent[fsp.rows, fsp.cols, fsp.side] = LAxis(get_figure(fsp); axis...)
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