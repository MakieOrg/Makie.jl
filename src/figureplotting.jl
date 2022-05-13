struct AxisPlot
    axis
    plot::AbstractPlot
end

Base.show(io::IO, fap::FigureAxisPlot) = show(io, fap.figure)
Base.show(io::IO, ::MIME"text/plain", fap::FigureAxisPlot) = print(io, "FigureAxisPlot()")

Base.iterate(fap::FigureAxisPlot, args...) = iterate((fap.figure, fap.axis, fap.plot), args...)
Base.iterate(ap::AxisPlot, args...) = iterate((ap.axis, ap.plot), args...)

get_scene(ap::AxisPlot) = get_scene(ap.axis.scene)

plot_preferred_axis(@nospecialize(x)) = nothing # nothing == I dont know
plot_preferred_axis(p::PlotFunc) = plot_preferred_axis(Makie.conversion_trait(p))
plot_preferred_axis(::Type{<:Volume}) = LScene
plot_preferred_axis(::Type{<:Surface}) = LScene
plot_preferred_axis(::VolumeLike) = LScene
plot_preferred_axis(::Type{<:Image}) = Axis
plot_preferred_axis(::Type{<:Heatmap}) = Axis

function args_preferred_axis(P::Type, args...)
    result = plot_preferred_axis(P)
    isnothing(result) || return result
    return args_preferred_axis(args...)
end
args_preferred_axis(::Type{<: Surface}, x::AbstractArray, y::AbstractArray, z::AbstractArray) = LScene
args_preferred_axis(::Type{<: Wireframe}, x::AbstractArray, y::AbstractArray, z::AbstractArray) = LScene

function args_preferred_axis(@nospecialize(args...))
    # Fallback: check each single arg if they have a favorite axis type
    for arg in args
        r = args_preferred_axis(arg)
        isnothing(r) || return r
    end
    return nothing
end

args_preferred_axis(x) = nothing
args_preferred_axis(x::AbstractVector, y::AbstractVector, z::AbstractVector, f::Function) = LScene
args_preferred_axis(m::AbstractArray{T, 3}) where T = LScene

function args_preferred_axis(m::Union{AbstractGeometry{DIM}, GeometryBasics.Mesh{DIM}}) where DIM
    return DIM === 2 ? Axis : LScene
end

args_preferred_axis(::AbstractVector{<: Point3}) = LScene
args_preferred_axis(::AbstractVector{<: Point2}) = Axis

function preferred_axis_type(@nospecialize(p::PlotFunc), @nospecialize(args...))
    # First check if the Plot type "knows" whether it's always 3D
    result = plot_preferred_axis(p)
    isnothing(result) || return result

    # Otherwise, we check the arguments
    non_obs = to_value.(args)
    RealP = plottype(p, non_obs...)
    result = plot_preferred_axis(RealP)
    isnothing(result) || return result
    conv = convert_arguments(RealP, non_obs...)
    Typ, args_conv = apply_convert!(RealP, Attributes(), conv)
    result = args_preferred_axis(Typ, args_conv...)
    isnothing(result) && return Axis # Fallback to Axis if nothing found
    return result
end

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

function plot(P::PlotFunc, args...; axis = NamedTuple(), figure = NamedTuple(), kw_attributes...)
    _validate_nt_like_keyword(axis, "axis")
    _validate_nt_like_keyword(figure, "figure")

    fig = Figure(; figure...)
    axis = Dict(pairs(axis))
    AxType = if haskey(axis, :type)
        pop!(axis, :type)
    else
        preferred_axis_type(P, args...)
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

    _validate_nt_like_keyword(axis, "axis")

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

    axis = Dict(pairs(axis))
    AxType = if haskey(axis, :type)
        pop!(axis, :type)
    else
        preferred_axis_type(P, args...)
    end
    ax = AxType(f; axis...)
    gp[] = ax
    p = plot!(P, ax, args...; kwargs...)
    AxisPlot(ax, p)
end

function plot!(P::PlotFunc, gp::GridPosition, args...; kwargs...)
    c = contents(gp, exact = true)
    if !(length(c) == 1 && can_be_current_axis(c[1]))
        error("There needs to be a single axis-like object at $(gp.span), $(gp.side) to plot into.\nUse a non-mutating plotting command to create an axis implicitly.")
    end
    ax = first(c)
    plot!(P, ax, args...; kwargs...)
end

function plot(P::PlotFunc, gsp::GridSubposition, args...; axis = NamedTuple(), kwargs...)

    _validate_nt_like_keyword(axis, "axis")

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

    axis = Dict(pairs(axis))
    AxType = if haskey(axis, :type)
        pop!(axis, :type)
    else
        preferred_axis_type(P, args...)
    end
    ax = AxType(fig; axis...)
    gsp.parent[gsp.rows, gsp.cols, gsp.side] = ax
    p = plot!(P, ax, args...; kwargs...)
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