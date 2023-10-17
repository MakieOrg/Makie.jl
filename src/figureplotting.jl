struct AxisPlot
    axis::Any
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
            Write (key = value,) or (; key = value) instead."""))
    end
end

function _disallow_keyword(kw, attributes)
    if haskey(attributes, kw)
        throw(ArgumentError("You cannot pass `$kw` as a keyword argument to this plotting function. Note that `axis` can only be passed to non-mutating plotting functions (not ending with a `!`) that implicitly create an axis, and `figure` only to those that implicitly create a `Figure`."))
    end
end

@nospecialize
function get_axis(fig, P, axis_kw::Dict, plot_attr, plot_args)
    if haskey(axis_kw, :type)
        axtype = axis_kw[:type]
        pop!(axis_kw, :type)
        ax = axtype(fig; axis_kw...)
    else
        proxyscene = Scene()
        # We dont forward the attributes to the plot, since we only need the arguments to determine the axis type
        # Remove arguments may not work with plotting into the scene
        delete!(plot_attr, :show_axis)
        delete!(plot_attr, :limits)
        if get(plot_attr, :color, nothing) isa Cycled
            # Color may contain Cycled(1), which needs the axis to get resolved to a color
            delete!(plot_attr, :color)
        end
        plot!(proxyscene, P, Attributes(plot_attr), plot_args...)
        if is2d(proxyscene)
            ax = Axis(fig; axis_kw...)
        else
            ax = LScene(fig; axis_kw...)
        end
        empty!(proxyscene)
    end
    return ax
end
@specialize

function plot(P::PlotFunc, args...; axis=NamedTuple(), figure=NamedTuple(), kw_attributes...)
    _validate_nt_like_keyword(axis, "axis")
    _validate_nt_like_keyword(figure, "figure")

    fig = Figure(; figure...)

    axis = Dict(pairs(axis))
    ax = get_axis(fig, P, axis, Dict{Symbol, Any}(kw_attributes), args)

    fig[1, 1] = ax
    p = plot!(ax, P, Attributes(kw_attributes), args...)
    return FigureAxisPlot(fig, ax, p)
end

# without scenelike, use current axis of current figure

function plot!(P::PlotFunc, args...; kw_attributes...)
    figure = current_figure()
    isnothing(figure) && error("There is no current figure to plot into.")
    ax = current_axis(figure)
    isnothing(ax) && error("There is no current axis to plot into.")
    return plot!(P, ax, args...; kw_attributes...)
end

function plot(P::PlotFunc, gp::GridPosition, args...; axis=NamedTuple(), kw_attributes...)
    _validate_nt_like_keyword(axis, "axis")

    c = contents(gp; exact=true)
    if !isempty(c)
        error("""
        You have used the non-mutating plotting syntax with a GridPosition, which requires an empty GridLayout slot to create an axis in, but there are already the following objects at this layout position:

        $(c)

        If you meant to plot into an axis at this position, use the plotting function with `!` (e.g. `func!` instead of `func`).
        If you really want to place an axis on top of other blocks, make your intention clear and create it manually.
        """)
    end

    axis = Dict(pairs(axis))
    fig = get_top_parent(gp)
    ax = get_axis(fig, P, axis, Dict{Symbol,Any}(kw_attributes), args)

    gp[] = ax
    p = plot!(P, ax, args...; kw_attributes...)
    return AxisPlot(ax, p)
end

function plot!(P::PlotFunc, gp::GridPosition, args...; kwargs...)
    c = contents(gp; exact=true)
    if !(length(c) == 1 && can_be_current_axis(c[1]))
        error("There needs to be a single axis-like object at $(gp.span), $(gp.side) to plot into.\nUse a non-mutating plotting command to create an axis implicitly.")
    end
    ax = first(c)
    return plot!(P, ax, args...; kwargs...)
end

function plot(P::PlotFunc, gsp::GridSubposition, args...; axis=NamedTuple(), kw_attributes...)
    _validate_nt_like_keyword(axis, "axis")

    GridLayoutBase.get_layout_at!(gsp.parent; createmissing=true)
    c = contents(gsp; exact=true)
    if !isempty(c)
        error("""
        You have used the non-mutating plotting syntax with a GridSubposition, which requires an empty GridLayout slot to create an axis in, but there are already the following objects at this layout position:

        $(c)

        If you meant to plot into an axis at this position, use the plotting function with `!` (e.g. `func!` instead of `func`).
        If you really want to place an axis on top of other blocks, make your intention clear and create it manually.
        """)
    end

    fig = get_top_parent(gsp)
    axis = Dict(pairs(axis))
    ax = get_axis(fig, P, axis, Dict{Symbol,Any}(kw_attributes), args)

    gsp.parent[gsp.rows, gsp.cols, gsp.side] = ax
    p = plot!(P, ax, args...; kw_attributes...)
    return AxisPlot(ax, p)
end

function plot!(P::PlotFunc, gsp::GridSubposition, args...; kwargs...)
    layout = GridLayoutBase.get_layout_at!(gsp.parent; createmissing=false)

    gp = layout[gsp.rows, gsp.cols, gsp.side]

    c = contents(gp; exact=true)
    if !(length(c) == 1 && can_be_current_axis(c[1]))
        error("There is not just one axis at $(gp).")
    end
    ax = first(c)
    return plot!(P, ax, args...; kwargs...)
end

update_state_before_display!(f::FigureAxisPlot) = update_state_before_display!(f.figure)

function update_state_before_display!(f::Figure)
    for c in f.content
        update_state_before_display!(c)
    end
    return
end
