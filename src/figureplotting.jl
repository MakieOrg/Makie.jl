

get_scene(fig::FigureAxisPlot) = get_scene(fig.figure)

struct AxisPlot
    axis
    plot::AbstractPlot
end

Base.show(io::IO, fap::FigureAxisPlot) = show(io, fap.figure)
Base.show(io::IO, ::MIME"text/plain", fap::FigureAxisPlot) = print(io, "FigureAxisPlot()")

Base.iterate(fap::FigureAxisPlot, args...) = iterate((fap.figure, fap.axis, fap.plot), args...)
Base.iterate(ap::AxisPlot, args...) = iterate((ap.axis, ap.plot), args...)

function plot(P::PlotFunc, args...; axis = NamedTuple(), figure = NamedTuple(), kw_attributes...)
    # scene_attributes = extract_scene_attributes!(attributes)
    fig = Figure(; figure...)

    axis = Dict(pairs(axis))

    if haskey(axis, :type)
        axtype = axis[:type]
        pop!(axis, :type)
        ax = axtype(fig; axis...)
    else
        proxyscene = Scene()
        plot!(proxyscene, P, Attributes(kw_attributes), args...; show_axis = false)

        if is2d(proxyscene)
            ax = Axis(fig; axis...)
        else
            ax = LScene(fig; scenekw = (camera = automatic, show_axis = true, raw = false, axis...))
        end
    end

    fig[1, 1] = ax
    p = plot!(ax, P, Attributes(kw_attributes), args...)
    FigureAxisPlot(fig, ax, p)
end

# without scenelike, use current axis of current figure

function plot!(P::PlotFunc, args...; kw_attributes...)
    ax = current_axis(current_figure())
    isnothing(ax) && error("There is no current axis to plot into.")
    plot!(P, ax, args...; kw_attributes...)
end

function plot(P::PlotFunc, fp::FigurePosition, args...; axis = NamedTuple(), kwargs...)

    c = contents(fp.gp, exact = true)
    if !isempty(c)
        error("""
        You have used the non-mutating plotting syntax with a FigurePosition, which requires an empty GridLayout slot to create an axis in, but there are already the following objects at this layout position:

        $(c)

        If you meant to plot into an axis at this position, use the plotting function with `!` (e.g. `func!` instead of `func`).
        If you really want to place an axis on top of other layoutables, make your intention clear and create it manually.
        """)
    end

    axis = Dict(pairs(axis))

    if haskey(axis, :type)
        axtype = axis[:type]
        pop!(axis, :type)
        ax = axtype(fp.fig; axis...)
    else
        proxyscene = Scene()
        plot!(proxyscene, P, Attributes(kwargs), args...; show_axis = false)

        if is2d(proxyscene)
            ax = Axis(fp.fig; axis...)
        else
            ax = LScene(fp.fig; scenekw = (camera = automatic, show_axis = true, raw = false, axis...))
        end
    end

    fp[] = ax
    p = plot!(P, ax, args...; kwargs...)
    AxisPlot(ax, p)
end

function plot!(P::PlotFunc, fp::FigurePosition, args...; kwargs...)

    c = contents(fp.gp, exact = true)
    if !(length(c) == 1 && c[1] isa Union{Axis, LScene})
        error("There needs to be a single axis at $(fp.gp.span), $(fp.gp.side) to plot into.\nUse a non-mutating plotting command to create an axis implicitly.")
    end
    ax = first(c)
    plot!(P, ax, args...; kwargs...)
end

function plot(P::PlotFunc, fsp::FigureSubposition, args...; axis = NamedTuple(), kwargs...)

    c = contents(fsp, exact = true)
    if !isempty(c)
        error("""
        You have used the non-mutating plotting syntax with a FigureSubposition, which requires an empty GridLayout slot to create an axis in, but there are already the following objects at this layout position:

        $(c)

        If you meant to plot into an axis at this position, use the plotting function with `!` (e.g. `func!` instead of `func`).
        If you really want to place an axis on top of other layoutables, make your intention clear and create it manually.
        """)
    end

    fig = get_figure(fsp)

    axis = Dict(pairs(axis))

    if haskey(axis, :type)
        axtype = axis[:type]
        pop!(axis, :type)
        ax = axtype(fig; axis...)
    else
        proxyscene = Scene()
        plot!(proxyscene, P, Attributes(kwargs), args...; show_axis = false)

        if is2d(proxyscene)
            ax = Axis(fig; axis...)
        else
            ax = LScene(fig; scenekw = (camera = automatic, show_axis = true, raw = false, axis...))
        end
    end

    fsp.parent[fsp.rows, fsp.cols, fsp.side] = ax
    p = plot!(P, ax, args...; kwargs...)
    AxisPlot(ax, p)
end

function plot!(P::PlotFunc, fsp::FigureSubposition, args...; kwargs...)

    layout = get_layout_at!(fsp.parent, createmissing = false)

    gp = layout[fsp.rows, fsp.cols, fsp.side]

    c = contents(gp, exact = true)
    if !(length(c) == 1 && c[1] isa Union{Axis, LScene})
        error("There is not just one axis at $(gp).")
    end
    ax = first(c)
    plot!(P, ax, args...; kwargs...)
end
