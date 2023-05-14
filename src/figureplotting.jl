struct AxisPlot
    axis
    plot::AbstractPlot
end

Base.show(io::IO, fap::FigureAxisPlot) = show(io, fap.figure)
Base.show(io::IO, ::MIME"text/plain", fap::FigureAxisPlot) = print(io, "FigureAxisPlot()")

Base.iterate(fap::FigureAxisPlot, args...) = iterate((fap.figure, fap.axis, fap.plot), args...)
Base.iterate(ap::AxisPlot, args...) = iterate((ap.axis, ap.plot), args...)

get_scene(ap::AxisPlot) = get_scene(ap.axis.scene)

function _validate_nt_like_keyword(@nospecialize(kw), name)
    if !(kw isa NamedTuple || kw isa AbstractDict{Symbol} || kw isa Attributes)
        throw(ArgumentError("""
            The $name keyword argument received an unexpected value $(repr(kw)).
            The $name keyword expects a collection of Symbol => value pairs, such as NamedTuple, Attributes, or AbstractDict{Symbol}.
            The most common cause of this error is trying to create a one-element NamedTuple like (key = value) which instead creates a variable `key` with value `value`.
            Write (key = value,) or (; key = value) instead."""
        ))
    end
end

function _disallow_keyword(kw, attributes)
    if haskey(attributes, kw)
        throw(ArgumentError("You cannot pass `$kw` as a keyword argument to this plotting function. Note that `axis` can only be passed to non-mutating plotting functions (not ending with a `!`) that implicitly create an axis, and `figure` only to those that implicitly create a `Figure`."))
    end
end

function plot(@nospecialize(P::PlotFunc), @nospecialize(args...); axis = NamedTuple(), figure = NamedTuple(), kw_attributes...)

    _validate_nt_like_keyword(axis, "axis")
    _validate_nt_like_keyword(figure, "figure")

    axisattr = Attributes(axis)
    figureattr = Attributes(figure)
    kwattr = Attributes(kw_attributes)

    plot(P, axisattr, figureattr, kwattr, args...)
end

function plot(@nospecialize(P::PlotFunc), axisattr::Attributes, figureattr::Attributes, kwattr::Attributes, @nospecialize args...)
    fig = Figure(figureattr)

    if haskey(axisattr, :type)
        axtype = to_value(axisattr.type)
        pop!(axisattr, :type)
        ax = axtype(axisattr, fig)
    else
        proxyscene = Scene()
        delete!(kwattr, :show_axis)
        delete!(kwattr, :limits)
        plot!(proxyscene, P, kwattr, args...)
        if is2d(proxyscene)
            ax = Axis(axisattr, fig)
        else
            ax = LScene(axisattr, fig)
        end
        empty!(proxyscene)
    end

    fig[1, 1] = ax
    p = plot!(ax, P, kwattr, args...)
    FigureAxisPlot(fig, ax, p)
end

# without scenelike, use current axis of current figure

function plot!(@nospecialize(P::PlotFunc), @nospecialize args...; kw_attributes...)
    plot!(P, Attributes(kw_attributes), args...)
end

function plot!(@nospecialize(P::PlotFunc), attr::Attributes, @nospecialize args...)
    figure = current_figure()
    isnothing(figure) && error("There is no current figure to plot into.")
    ax = current_axis(figure)
    isnothing(ax) && error("There is no current axis to plot into.")
    plot!(ax, P, attr, args...)
end

function plot(@nospecialize(P::PlotFunc), gp::GridPosition, @nospecialize(args...); axis = NamedTuple(), kwargs...)
    _validate_nt_like_keyword(axis, "axis")
    plot(P, Attributes(axis), Attributes(kwargs), gp, args...)
end

function plot(@nospecialize(P::PlotFunc), axisattr::Attributes, kwattr::Attributes, gp::GridPosition, @nospecialize args...)

    f = get_top_parent(gp)

    c = contents(gp, exact = true)
    if !isempty(c)
        error("""
        You have used the non-mutating plotting syntax with a GridPosition, which requires an empty GridLayout slot to create an axis in, but there are already the following objects at this layout position:

        $(c)

        If you meant to plot into an axis at this position, use the plotting function with `!` (e.g. `func!` instead of `func`).
        If you really want to place an axis on top of other blocks, make your intention clear and create it manually.
        """)
    end

    if haskey(axisattr, :type)
        axtype = to_value(axisattr[:type])
        pop!(axisattr, :type)
        ax = axtype(f, axisattr)
    else
        proxyscene = Scene()
        plot!(proxyscene, P, kwattr, args...)
        if is2d(proxyscene)
            ax = Axis(axisattr, f)
        else
            ax = LScene(axisattr, f)
        end
    end

    gp[] = ax
    p = plot!(ax, P, kwattr, args...)
    AxisPlot(ax, p)
end

function plot!(@nospecialize(P::PlotFunc), gp::GridPosition, @nospecialize args...; kwargs...)
    kwattr = Attributes(kwargs)
    plot!(P, kwattr, gp, args...)
end

function plot!(@nospecialize(P::PlotFunc), kwattr::Attributes, gp::GridPosition, @nospecialize args...)
    c = contents(gp, exact = true)
    if !(length(c) == 1 && can_be_current_axis(c[1]))
        error("There needs to be a single axis-like object at $(gp.span), $(gp.side) to plot into.\nUse a non-mutating plotting command to create an axis implicitly.")
    end
    ax = first(c)
    plot!(ax, P, kwattr, args...)
end

function plot(@nospecialize(P::PlotFunc), gsp::GridSubposition, @nospecialize args...; axis = NamedTuple(), kwargs...)
    _validate_nt_like_keyword(axis, "axis")
    axisattr = Attributes(axis)
    attr = Attributes(kwargs)
    plot(P, attr, axisattr, gsp, args...)
end

function plot(@nospecialize(P::PlotFunc), attr::Attributes, axisattr::Attributes, gsp::GridSubposition, @nospecialize args...)

    layout = GridLayoutBase.get_layout_at!(gsp.parent, createmissing = true)
    c = contents(gsp, exact = true)
    if !isempty(c)
        error("""
        You have used the non-mutating plotting syntax with a GridSubposition, which requires an empty GridLayout slot to create an axis in, but there are already the following objects at this layout position:

        $(c)

        If you meant to plot into an axis at this position, use the plotting function with `!` (e.g. `func!` instead of `func`).
        If you really want to place an axis on top of other blocks, make your intention clear and create it manually.
        """)
    end

    fig = get_top_parent(gsp)

    if haskey(axisattr, :type)
        axtype = to_value(axisattr.type)
        pop!(axisattr, :type)
        ax = axtype(fig; axisattr...)
    else
        proxyscene = Scene()
        plot!(proxyscene, P, attr, args...)

        if is2d(proxyscene)
            ax = Axis(axisattr, fig)
        else
            axisattr = merge!(axisattr, Attributes((; scenekw = (camera = automatic,))))
            ax = LScene(axisattr, fig)
        end
    end

    gsp.parent[gsp.rows, gsp.cols, gsp.side] = ax
    p = plot!(ax, P, attr, args...)
    AxisPlot(ax, p)
end

function plot!(P::PlotFunc, gsp::GridSubposition, args...; kwargs...)

    layout = GridLayoutBase.get_layout_at!(gsp.parent, createmissing = false)

    gp = layout[gsp.rows, gsp.cols, gsp.side]

    c = contents(gp, exact = true)
    if !(length(c) == 1 && can_be_current_axis(c[1]))
        error("There is not just one axis at $(gp).")
    end
    ax = first(c)
    plot!(P, ax, args...; kwargs...)
end

update_state_before_display!(f::FigureAxisPlot) = update_state_before_display!(f.figure)

function update_state_before_display!(f::Figure)
    for c in f.content
        update_state_before_display!(c)
    end
    return
end
