struct AxisPlot
    axis
    plot::AbstractPlot
end

Base.show(io::IO, fap::FigureAxisPlot) = show(io, fap.figure)
Base.show(io::IO, ::MIME"text/plain", fap::FigureAxisPlot) = print(io, "FigureAxisPlot()")

Base.iterate(fap::FigureAxisPlot, args...) = iterate((fap.figure, fap.axis, fap.plot), args...)
Base.iterate(ap::AxisPlot, args...) = iterate((ap.axis, ap.plot), args...)


# This is such a hack ...  We really need to clean up the conversion pipeline
# But, we really want to convert arguments before we apply axis conversions, so that
# convert_arguments can return units etc...
# Now, we DON'T want to convert things to points though, since axis conversions
# are applied to x and y values separately... This is why we need this beautiful function:
function convert_arguments_no_points(P, args...; kw...)
    if Makie.conversion_trait(P) isa Makie.PointBased && length(args) == 2 && all(x-> x isa AbstractVector, args)
        return args
    end
    return try_convert_arguments(P, args...; kw...)
end

function try_convert_arguments(P, args...; kw...)
    try
        return Makie.convert_arguments(P, args...; kw...)
    catch e
        if e isa MethodError || e isa Makie.ConversionError
            return args
        else
            rethrow(e)
        end
    end
end

function is_plot_3d(p::PlotFunc, args...)
    result = is_plot_3d(p)
    isnothing(result) || return result
    converted = try_convert_arguments(p, to_value.(args)...)
    if converted isa Tuple
        return is_plot_3d(converted...)
    else
        return false
    end
end

is_plot_3d(p::PlotFunc) = is_plot_3d(Makie.conversion_trait(p))
is_plot_3d(::Type{<: Union{Surface, Volume}}) = true
is_plot_3d(::Type{<: Contour}) = nothing
is_plot_3d(::VolumeLike) = true
is_plot_3d(args...) = any(args) do arg
    r = is_plot_3d(arg)
    return isnothing(r) ? false : r
end

is_plot_3d(x) = nothing
is_plot_3d(x::AbstractVector, y::AbstractVector, z::AbstractVector, f::Union{AbstractArray{<: Any, 3}, Function}) = true
is_plot_3d(m::AbstractArray{T, 3}) where T = true
is_plot_3d(x::AbstractVector, y::AbstractVector, z::AbstractVector) = true
is_plot_3d(m::Union{AbstractGeometry, GeometryBasics.Mesh}) = !is2d(Rect(decompose(Point, m)))
is_plot_3d(x, y, z, m::AbstractArray{T, 3}) where T = true
is_plot_3d(xyz::AbstractVector{<: Point3}) = any(x-> x[3] > 0, xyz)

function get_axis_type(p::PlotFunc, args...)
    result = is_plot_3d(p, args...)
    isnothing(result) && return Axis
    return result ? LScene : Axis
end

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

function plot(P::PlotFunc, args...; axis = NamedTuple(), figure = NamedTuple(), kw_attributes...)

    _validate_nt_like_keyword(axis, "axis")
    _validate_nt_like_keyword(figure, "figure")

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
