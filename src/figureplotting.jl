struct AxisPlot
    axis
    plot::AbstractPlot
end

Base.show(io::IO, fap::FigureAxisPlot) = show(io, fap.figure)
Base.show(io::IO, ::MIME"text/plain", fap::FigureAxisPlot) = print(io, "FigureAxisPlot()")

Base.iterate(fap::FigureAxisPlot, args...) = iterate((fap.figure, fap.axis, fap.plot), args...)
Base.iterate(ap::AxisPlot, args...) = iterate((ap.axis, ap.plot), args...)

get_scene(ap::AxisPlot) = get_scene(ap.axis.scene)

function plot(P::PlotFunc, attributes::Attributes, args...)
    # scene_attributes = extract_scene_attributes!(attributes)
    axis = get_as_dict(attributes,  :axis)
    figure = get_as_dict(attributes, :figure)

    fig = Figure(; figure...)
    if haskey(axis, :type)
        axtype = axis[:type]
        pop!(axis, :type)
        ax = axtype(fig; axis...)
    else
        proxyscene = Scene()
        delete!(attributes, :show_axis)
        delete!(attributes, :limits)
        plot!(P, attributes, proxyscene, args...)
        if is2d(proxyscene)
            ax = Axis(fig; axis...)
        else
            ax = LScene(fig; axis...)
        end
    end

    fig[1, 1] = ax
    p = plot!(P, attributes, ax, args...)
    FigureAxisPlot(fig, ax, p)
end

# without scenelike, use current axis of current figure

function plot!(P::PlotFunc, attributes::Attributes, args...)
    ax = current_axis(current_figure())
    isnothing(ax) && error("There is no current axis to plot into.")
    plot!(P, attributes, ax, args...)
end

function plot(P::PlotFunc, attributes::Attributes, gp::GridPosition, args...)

    f = MakieLayout.get_top_parent(gp)

    c = contents(gp, exact = true)
    if !isempty(c)
        error("""
        You have used the non-mutating plotting syntax with a GridPosition, which requires an empty GridLayout slot to create an axis in, but there are already the following objects at this layout position:

        $(c)

        If you meant to plot into an axis at this position, use the plotting function with `!` (e.g. `func!` instead of `func`).
        If you really want to place an axis on top of other blocks, make your intention clear and create it manually.
        """)
    end

    axis = get_as_dict(attributes, :axis)

    if haskey(axis, :type)
        axtype = axis[:type]
        pop!(axis, :type)
        ax = axtype(f; axis...)
    else
        proxyscene = Scene()
        plot!(P, attributes, proxyscene, args...)
        if is2d(proxyscene)
            ax = Axis(f; axis...)
        else
            ax = LScene(f; axis...)
        end
    end

    gp[] = ax
    p = plot!(P, attributes, ax, args...)
    AxisPlot(ax, p)
end

function plot!(P::PlotFunc, attributes::Attributes, gp::GridPosition, args...)
    c = contents(gp, exact = true)
    if !(length(c) == 1 && c[1] isa Union{Axis, LScene})
        error("There needs to be a single axis at $(gp.span), $(gp.side) to plot into.\nUse a non-mutating plotting command to create an axis implicitly.")
    end
    ax = first(c)
    plot!(P, attributes, ax, args...)
end

attr_to_dict(obs::Observable) = obs[]

function attr_to_dict(attributes::Union{Attributes, NamedTuple})
    Dict((k=> attr_to_dict(v)) for (k, v) in attributes)
end

function get_as_dict(attributes, key)
    attr = to_value(pop!(attributes, key, Attributes()))
    return attr_to_dict(attr)
end

function plot(P::PlotFunc, attributes::Attributes, gsp::GridSubposition, args...)

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

    fig = MakieLayout.get_top_parent(gsp)
    axis = get_as_dict(attributes, :axis)

    if haskey(axis, :type)
        axtype = axis[:type]
        pop!(axis, :type)
        ax = axtype(fig; axis...)
    else
        proxyscene = Scene()
        plot!(P, attributes, proxyscene, args...)
        if is2d(proxyscene)
            ax = Axis(fig; axis...)
        else
            ax = LScene(fig; axis..., scenekw = (camera = automatic,))
        end
    end

    gsp.parent[gsp.rows, gsp.cols, gsp.side] = ax
    p = plot!(P, attributes, ax, args...)
    AxisPlot(ax, p)
end

function plot!(P::PlotFunc, attributes::Attributes, gsp::GridSubposition, args...)

    layout = GridLayoutBase.get_layout_at!(gsp.parent, createmissing = false)

    gp = layout[gsp.rows, gsp.cols, gsp.side]

    c = contents(gp, exact = true)
    if !(length(c) == 1 && c[1] isa Union{Axis, LScene})
        error("There is not just one axis at $(gp).")
    end
    ax = first(c)
    plot!(P, attributes, ax, args...)
end
