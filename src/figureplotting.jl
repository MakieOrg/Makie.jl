

get_scene(fig::FigureAxisPlot) = get_scene(fig.figure)

struct AxisPlot
    axis
    plot::AbstractPlot
end

Base.show(io::IO, fap::FigureAxisPlot) = show(io, fap.figure)
Base.show(io::IO, ::MIME"text/plain", fap::FigureAxisPlot) = print(io, "FigureAxisPlot()")

Base.iterate(fap::FigureAxisPlot, args...) = iterate((fap.figure, fap.axis, fap.plot), args...)
Base.iterate(ap::AxisPlot, args...) = iterate((ap.axis, ap.plot), args...)

function is_plot_3d(p::PlotFunc, args...)
    result = is_plot_3d(p)
    isnothing(result) || return result
    converted = MakieLayout.try_convert_arguments(p, to_value.(args)...)
    if converted isa Tuple
        return is_plot_3d(converted...)
    else
        return false
    end
end

is_plot_3d(p::PlotFunc) = is_plot_3d(Makie.conversion_trait(p))
is_plot_3d(::Type{<: Union{Surface, Volume}}) = true
is_plot_3d(::Type{<: Contour}) = nothing
is_plot_3d(::Type{<: Union{Image, Heatmap}}) = false
is_plot_3d(::VolumeLike) = true
is_plot_3d(args...) = any(args) do arg
    r = is_plot_3d(arg)
    isnothing(r) ? false : r
end

is_plot_3d(x) = nothing
is_plot_3d(x::AbstractVector, y::AbstractVector, z::AbstractVector, f::Union{AbstractArray{<: Any, 3}, Function}) = true
is_plot_3d(x::AbstractVector, y::AbstractVector, z::AbstractVector) = true
is_plot_3d(x::AbstractArray, y::AbstractArray, z::AbstractArray) = true
is_plot_3d(m::Union{AbstractGeometry, GeometryBasics.Mesh}) = !is2d(Rect(decompose(Point, m)))
is_plot_3d(m::AbstractArray{T, 3}) where T = true
is_plot_3d(x, y, z, m::AbstractArray{T, 3}) where T = true
is_plot_3d(xyz::AbstractVector{<: Point3}) = true
is_plot_3d(::Type{<: Contour}, x, y, z::Union{Function, AbstractMatrix}) = false
is_plot_3d(::Type{<: Contour}, z::AbstractMatrix) = false

function get_axis_type(p::PlotFunc, args...)
    result = is_plot_3d(p, args...)
    isnothing(result) && return Axis
    return result ? LScene : Axis
end

function plot(P::PlotFunc, args...; axis = NamedTuple(), figure = NamedTuple(), kw_attributes...)
    # scene_attributes = extract_scene_attributes!(attributes)
    fig = Figure(; figure...)

    axis = Dict(pairs(axis))

    AxType = if haskey(axis, :type)
        pop!(axis, :type)
    else
        get_axis_type(P, args...)
    end
    ax = AxType(fig[1, 1]; axis...)
    p = plot!(ax, P, Attributes(kw_attributes), args...)
    return FigureAxisPlot(fig, ax, p)
end

# without scenelike, use current axis of current figure

function plot!(P::PlotFunc, args...; kw_attributes...)
    ax = current_axis(current_figure())
    isnothing(ax) && error("There is no current axis to plot into.")
    plot!(P, ax, args...; kw_attributes...)
end

function plot(P::PlotFunc, gp::GridPosition, args...; axis = NamedTuple(), kwargs...)

    f = MakieLayout.get_top_parent(gp)

    c = contents(gp, exact = true)
    if !isempty(c)
        error("""
        You have used the non-mutating plotting syntax with a GridPosition, which requires an empty GridLayout slot to create an axis in, but there are already the following objects at this layout position:

        $(c)

        If you meant to plot into an axis at this position, use the plotting function with `!` (e.g. `func!` instead of `func`).
        If you really want to place an axis on top of other layoutables, make your intention clear and create it manually.
        """)
    end

    axis = Dict(pairs(axis))

    if haskey(axis, :type)
        axtype = axis[:type]
        pop!(axis, :type)
        ax = axtype(f; axis...)
    else
        proxyscene = Scene()
        plot!(proxyscene, P, Attributes(kwargs), args...)
        if is2d(proxyscene)
            ax = Axis(f; axis...)
        else
            ax = LScene(f; scenekw = (camera = cam3d!, axis...))
        end
    end

    gp[] = ax
    p = plot!(P, ax, args...; kwargs...)
    AxisPlot(ax, p)
end

function plot!(P::PlotFunc, gp::GridPosition, args...; kwargs...)

    c = contents(gp, exact = true)
    if !(length(c) == 1 && c[1] isa Union{Axis, LScene})
        error("There needs to be a single axis at $(gp.span), $(gp.side) to plot into.\nUse a non-mutating plotting command to create an axis implicitly.")
    end
    ax = first(c)
    plot!(P, ax, args...; kwargs...)
end

function plot(P::PlotFunc, gsp::GridSubposition, args...; axis = NamedTuple(), kwargs...)

    layout = GridLayoutBase.get_layout_at!(gsp.parent, createmissing = true)
    c = contents(gsp, exact = true)
    if !isempty(c)
        error("""
        You have used the non-mutating plotting syntax with a GridSubposition, which requires an empty GridLayout slot to create an axis in, but there are already the following objects at this layout position:

        $(c)

        If you meant to plot into an axis at this position, use the plotting function with `!` (e.g. `func!` instead of `func`).
        If you really want to place an axis on top of other layoutables, make your intention clear and create it manually.
        """)
    end

    fig = MakieLayout.get_top_parent(gsp)

    axis = Dict(pairs(axis))

    if haskey(axis, :type)
        axtype = axis[:type]
        pop!(axis, :type)
        ax = axtype(fig; axis...)
    else
        proxyscene = Scene()
        plot!(proxyscene, P, Attributes(kwargs), args...)

        if is2d(proxyscene)
            ax = Axis(fig; axis...)
        else
            ax = LScene(fig; scenekw = (camera = automatic, axis...))
        end
    end

    gsp.parent[gsp.rows, gsp.cols, gsp.side] = ax
    p = plot!(P, ax, args...; kwargs...)
    AxisPlot(ax, p)
end

function plot!(P::PlotFunc, gsp::GridSubposition, args...; kwargs...)

    layout = GridLayoutBase.get_layout_at!(gsp.parent, createmissing = false)

    gp = layout[gsp.rows, gsp.cols, gsp.side]

    c = contents(gp, exact = true)
    if !(length(c) == 1 && c[1] isa Union{Axis, LScene})
        error("There is not just one axis at $(gp).")
    end
    ax = first(c)
    plot!(P, ax, args...; kwargs...)
end
