struct AxisPlot
    axis
    plot::AbstractPlot
end

Base.show(io::IO, fap::FigureAxisPlot) = show(io, fap.figure)
Base.show(io::IO, ::MIME"text/plain", fap::FigureAxisPlot) = print(io, "FigureAxisPlot()")

Base.iterate(fap::FigureAxisPlot, args...) = iterate((fap.figure, fap.axis, fap.plot), args...)
Base.iterate(ap::AxisPlot, args...) = iterate((ap.axis, ap.plot), args...)

get_scene(ap::AxisPlot) = get_scene(ap.axis.scene)

function is_plot_3d(p::PlotFunc, args...)
    # First check if the Plot type "knows" whether it's always 3D
    result = is_plot_type_3d(p)
    isnothing(result) || return result

    # Otherwise, we check the arguments
    non_obs = to_value.(args)
    RealP = plottype(p, non_obs...)
    result = is_plot_type_3d(RealP)
    isnothing(result) || return result
    conv = convert_arguments(RealP, non_obs...)
    Typ, args_conv = apply_convert!(RealP, Attributes(), conv)
    return are_args_3d(Typ, args_conv...)
end

is_plot_type_3d(p::PlotFunc) = is_plot_type_3d(Makie.conversion_trait(p))
is_plot_type_3d(::Type{<:Volume}) = true
is_plot_type_3d(::Type{<:Contour}) = nothing
is_plot_type_3d(::Type{<:Image}) = false
is_plot_type_3d(::Type{<:Heatmap}) = false
is_plot_type_3d(::VolumeLike) = true
is_plot_type_3d(x) = nothing

function are_args_3d(P::Type, args...)
    result = is_plot_type_3d(P)
    isnothing(result) || return result
    return are_args_3d(args...)
end

are_args_3d(::Type{<: Surface}, x::AbstractArray, y::AbstractArray, z::AbstractArray) = any(x-> x != 0.0, z)
are_args_3d(::Type{<: Wireframe}, x::AbstractArray, y::AbstractArray, z::AbstractArray) = any(x-> x != 0.0, z)

function are_args_3d(args...)
    return any(args) do arg
        r = are_args_3d(arg)
        return isnothing(r) ? false : r
    end
end

are_args_3d(x) = nothing
are_args_3d(x::AbstractVector, y::AbstractVector, z::AbstractVector, f::Function) = true
are_args_3d(m::AbstractArray{T, 3}) where T = true

function are_args_3d(m::Union{AbstractGeometry, GeometryBasics.Mesh})
    return ndims(m) == 2 ? false : !is2d(Rect3f(m))
end

are_args_3d(xyz::AbstractVector{<: Point3}) = any(x-> x[3] > 0, xyz)

function get_axis_type(p::PlotFunc, args...)
    result = is_plot_3d(p, args...)
    # We fallback to the 2D Axis if we don't get a definitive answer, which seems like the best default.
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
        If you really want to place an axis on top of other blocks, make your intention clear and create it manually.
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
            ax = LScene(f; axis...)
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
        If you really want to place an axis on top of other blocks, make your intention clear and create it manually.
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
            ax = LScene(fig; axis..., scenekw = (camera = automatic,))
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
