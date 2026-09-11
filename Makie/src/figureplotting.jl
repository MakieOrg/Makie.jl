struct AxisPlot
    axis::Any
    plot::AbstractPlot
end

struct FigureAxis
    figure::Figure
    axis::Any
end

Base.show(io::IO, fap::FigureAxisPlot) = show(io, fap.figure)
Base.show(io::IO, ::MIME"text/plain", fap::FigureAxisPlot) = print(io, "FigureAxisPlot()")

Base.iterate(fap::FigureAxisPlot, args...) = iterate((fap.figure, fap.axis, fap.plot), args...)
Base.iterate(ap::AxisPlot, args...) = iterate((ap.axis, ap.plot), args...)

get_scene(ap::AxisPlot) = get_scene(ap.axis.scene)

function _validate_nt_like_keyword(@nospecialize(kw), name)
    return if !(kw isa NamedTuple || kw isa AbstractDict{Symbol} || kw isa Attributes)
        throw(
            ArgumentError(
                """
                The $name keyword argument received an unexpected value $(repr(kw)).
                The $name keyword expects a collection of Symbol => value pairs, such as NamedTuple, Attributes, or AbstractDict{Symbol}.
                The most common cause of this error is trying to create a one-element NamedTuple like (key = value) which instead creates a variable `key` with value `value`.
                Write (key = value,) or (; key = value) instead."""
            )
        )
    end
end

function _disallow_keyword(kw, attributes)
    return if haskey(attributes, kw)
        throw(ArgumentError("You cannot pass `$kw` as a keyword argument to this plotting function. Note that `axis` can only be passed to non-mutating plotting functions (not ending with a `!`) that implicitly create an axis, and `figure` only to those that implicitly create a `Figure`."))
    end
end

# For plots that dont require an axis,
# E.g. BlockSpec
struct FigureOnly end


function args_preferred_axis(
        ::Type{<:Union{Wireframe, Surface, Contour3d}}, x::AbstractArray, y::AbstractArray,
        z::AbstractArray
    )
    return all(x -> z[1] ≈ x, z) ? Axis : LScene
end

args_preferred_axis(x) = nothing

function args_preferred_axis(@nospecialize(args...))
    # Fallback: check each single arg if they have a favorite axis type
    for arg in args
        r = args_preferred_axis(arg)
        isnothing(r) || return r
    end
    return nothing
end

args_preferred_axis(::AbstractVector, ::AbstractVector, ::AbstractVector, ::Function) = LScene
args_preferred_axis(::AbstractArray{T, 3}) where {T} = LScene

function args_preferred_axis(::AbstractVector{<:Union{AbstractGeometry{DIM}, GeometryBasics.Mesh{DIM}}}) where {DIM}
    return DIM === 2 ? Axis : LScene
end

function args_preferred_axis(::Union{AbstractGeometry{DIM}, GeometryBasics.Mesh{DIM}}) where {DIM}
    return DIM === 2 ? Axis : LScene
end

args_preferred_axis(::AbstractVector{<:Point3}) = LScene
args_preferred_axis(::AbstractVector{<:Point2}) = Axis


preferred_axis_type(::Volume) = LScene
preferred_axis_type(::Union{Image, Heatmap}) = Axis

function preferred_axis_type(p::Plot{F}) where {F}
    # Otherwise, we check the arguments
    input_args = p.args[]
    result = args_preferred_axis(Plot{F}, input_args...)
    isnothing(result) || return result
    conv_args = p.converted[]
    result = args_preferred_axis(Plot{F}, conv_args...)
    isnothing(result) && return Axis # Fallback to Axis if nothing found
    return result
end

to_dict(dict::Dict) = convert(Dict{Symbol, Any}, dict)
to_dict(nt::NamedTuple) = Dict{Symbol, Any}(pairs(nt))
to_dict(attr::Attributes) = attributes(attr)

function extract_attributes(dictlike, key)
    dictlike = pop!(dictlike, key, Dict{Symbol, Any}())
    _validate_nt_like_keyword(dictlike, key)
    return to_dict(dictlike)
end

function create_axis_for_plot(figure::Figure, plot::AbstractPlot, attributes::Dict)
    axis_kw = extract_attributes(attributes, :axis)
    AxType = if haskey(axis_kw, :type)
        pop!(axis_kw, :type)
    else
        preferred_axis_type(plot)
    end
    if AxType == FigureOnly # For FigureSpec, which creates Axes dynamically
        return nothing
    end
    bbox = pop!(axis_kw, :bbox, nothing)
    set_axis_attributes!(AxType, axis_kw, plot)
    return _block(AxType, figure, [], axis_kw, bbox)
end

const PlotOrNot = Union{AbstractPlot, Nothing}

# For recipes (plot!(plot_object, ...)))
create_axis_like!(::Dict, s::Union{Plot, Scene}) = s

# For plotspec
# create_axis_like!(::PlotSpecPlot, ::Dict, fig::Figure) = fig
create_axis_like!(::Dict, f::Figure) = f

"""
    create_axis_like!(attributes::Dict, ax::AbstractAxis)

Method to plot to an existing axis.

E.g.: `plot!(ax, 1:4)` which plots to `ax`.
"""
function create_axis_like!(attributes::Dict, ax::AbstractAxis)
    _disallow_keyword(:axis, attributes)
    return ax
end

"""
    create_axis_like!(attributes::Dict, gsp::GridSubposition)

Method to plot to an axis defined at a given sub-grid position.

E.g.: `plot!(fig[1, 1][1, 1], 1:4)` which needs an axis to exist at f[1, 1][1, 1].
"""
function create_axis_like!(attributes::Dict, gsp::GridSubposition)
    _disallow_keyword(:figure, attributes)
    layout = GridLayoutBase.get_layout_at!(gsp.parent; createmissing = false)
    gp = layout[gsp.rows, gsp.cols, gsp.side]
    c = contents(gp; exact = true)
    if !(length(c) == 1 && can_be_current_axis(c[1]))
        error("There is not just one axis at $(gp).")
    end
    _disallow_keyword(:axis, attributes)
    return first(c)
end

"""
    create_axis_like!(attributes::Dict, ::Nothing)

Method to plot to the last created axis.

E.g.: `plot!(1:4)` which requires a current figure and axis.
"""
function create_axis_like!(attributes::Dict, ::Nothing)
    figure = current_figure()
    isnothing(figure) && error("There is no current figure to plot into.")
    _disallow_keyword(:figure, attributes)
    ax = current_axis(figure)
    isnothing(ax) && error("There is no current axis to plot into.")
    _disallow_keyword(:axis, attributes)
    return ax
end

"""
    create_axis_like!(attributes::Dict, gp::GridPosition)

Method to plot to an axis defined at a given grid position.

E.g.: `plot!(fig[1, 1], 1:4)` which requires an axis to exist at `f[1, 1]`.
"""
function create_axis_like!(attributes::Dict, gp::GridPosition)
    _disallow_keyword(:figure, attributes)
    c = contents(gp; exact = true)
    if !(length(c) == 1 && can_be_current_axis(c[1]))
        error("There needs to be a single axis-like object at $(gp.span), $(gp.side) to plot into.\nUse a non-mutating plotting command to create an axis implicitly.")
    end
    ax = first(c)
    _disallow_keyword(:axis, attributes)
    return ax
end

function create_axis_like(::AbstractPlot, ::Dict, ::Union{Scene, AbstractAxis})
    return error("Plotting into an axis without `!` (e.g. `scatter` instead of `scatter!`)")
end

"""
    create_axis_like(plot::AbstractPlot, attributes::Dict, ::Nothing)

Method to create a default Figure and Axis from a plot function.

E.g.: `plot(1:4)` which requires a new Figure and Axis to be created.
"""
function create_axis_like(plot::AbstractPlot, attributes::Dict, ::Nothing)
    figure_kw = extract_attributes(attributes, :figure)
    figure = Figure(; figure_kw...)
    ax = create_axis_for_plot(figure, plot, attributes)
    if isnothing(ax) # For FigureSpec
        return figure
    else
        figure[1, 1] = ax
        return FigureAxis(figure, ax)
    end
end

"""
    create_axis_like(plot::AbstractPlot, attributes::Dict, gp::GridPosition)

Method to create an Axis at a grid position given int a plot call.

E.g.: `plot(fig[1, 1], 1:4)` which requires and Axis to be created at f[1, 1].
"""
function create_axis_like(plot::AbstractPlot, attributes::Dict, gp::GridPosition)
    isnothing(plot) && return nothing
    _disallow_keyword(:figure, attributes)
    figure = get_top_parent(gp)
    c = contents(gp; exact = true)
    if !isempty(c)
        error(
            """
            You have used the non-mutating plotting syntax with a GridPosition, which requires an empty GridLayout slot to create an axis in, but there are already the following objects at this layout position:
            $(c)
            If you meant to plot into an axis at this position, use the plotting function with `!` (e.g. `func!` instead of `func`).
            If you really want to place an axis on top of other blocks, make your intention clear and create it manually.
            """
        )
    end
    ax = create_axis_for_plot(figure, plot, attributes)
    if isnothing(ax) # For FigureSpec
        return gp
    else
        gp[] = ax
        return ax
    end
end

"""
    create_axis_like(plot::AbstractPlot, attributes::Dict, gsp::GridSubposition)

Method to create an Axis at a sub-grid position given in a plot.

E.g.: `plot(fig[1, 1][1, 1], 1:4)` which creates an Axis at f[1, 1][1, 1].
"""
function create_axis_like(plot::AbstractPlot, attributes::Dict, gsp::GridSubposition)
    isnothing(plot) && return nothing
    _disallow_keyword(:figure, attributes)
    GridLayoutBase.get_layout_at!(gsp.parent; createmissing = true)
    c = contents(gsp; exact = true)
    if !isempty(c)
        error(
            """
            You have used the non-mutating plotting syntax with a GridSubposition, which requires an empty GridLayout slot to create an axis in, but there are already the following objects at this layout position:

            $(c)

            If you meant to plot into an axis at this position, use the plotting function with `!` (e.g. `func!` instead of `func`).
            If you really want to place an axis on top of other blocks, make your intention clear and create it manually.
            """
        )
    end

    figure = get_top_parent(gsp)
    ax = create_axis_for_plot(figure, plot, attributes)
    gsp.parent[gsp.rows, gsp.cols, gsp.side] = ax
    return ax
end

figurelike_return(fa::FigureAxis, plot::AbstractPlot) = FigureAxisPlot(fa.figure, fa.axis, plot)
figurelike_return(ax::AbstractAxis, plot::AbstractPlot) = AxisPlot(ax, plot)
figurelike_return!(::AbstractAxis, plot::AbstractPlot) = plot
figurelike_return!(::Union{Plot, Scene}, plot::AbstractPlot) = plot

update_state_before_display!(f::FigureAxisPlot) = update_state_before_display!(f.figure)

function update_state_before_display!(f::Figure)
    for c in f.content
        update_state_before_display!(c)
    end
    return
end

@inline plot_args(args...) = (nothing, args)
@inline function plot_args(
        a::Union{Figure, AbstractAxis, Scene, Plot, GridSubposition, GridPosition},
        args...
    )
    return (a, args)
end
function fig_keywords!(kws)
    figkws = Dict{Symbol, Any}()
    if haskey(kws, :axis)
        figkws[:axis] = pop!(kws, :axis)
    end
    if haskey(kws, :figure)
        figkws[:figure] = pop!(kws, :figure)
    end
    return figkws
end

# Narrows down the default plotfunc early on, if `plot` is used
default_plot_func(f::F, args) where {F} = f
default_plot_func(::typeof(plot), args) = plotfunc(plottype(map(to_value, args)...))

# Don't inline these, since they will get called from `scatter!(args...; kw...)` which gets specialized to all kw args
@noinline function _create_plot(F, attributes::Dict, args...)
    figarg, pargs = plot_args(args...)
    figkws = fig_keywords!(attributes)
    if haskey(figkws, :axis)
        ax_kw = figkws[:axis]
        _validate_nt_like_keyword(ax_kw, :axis)
        if any(x -> x in [:dim1_conversion, :dim2_conversion, :dim3_conversion], keys(ax_kw))
            conversions = get_conversions(ax_kw)
            if haskey(attributes, :dim_conversions)
                connect_conversions!(attributes[:dim_conversions], conversions)
            else
                attributes[:dim_conversions] = conversions
            end
        end
    end
    plot = Plot{default_plot_func(F, pargs)}(pargs, attributes)
    ax = create_axis_like(plot, figkws, figarg)
    plot!(ax, plot)
    return figurelike_return(ax, plot)
end

function set_axis_attributes!(T::Type{<:AbstractAxis}, attributes::Dict, plot::Plot)
    conversions = get(plot.kw, :dim_conversions, nothing)
    isnothing(conversions) && return
    for i in 1:3
        key = Symbol("dim$(i)_conversion")
        if hasfield(T, key)
            attributes[key] = conversions[i]
        end
    end
    return
end


# This enables convert_arguments(::Type{<:AbstractPlot}, ::X) -> FigureSpec
# Which skips axis creation
# TODO, what to return for the dynamically created axes?
const PlotSpecPlot = Plot{plot, Tuple{<:GridLayoutSpec}}

get_conversions(scene::Scene) = scene.conversions
get_conversions(fig::Figure) = get_conversions(fig.scene)

@noinline function _create_plot!(F, attributes::Dict, args...)
    if length(args) > 0
        if args[1] isa FigureAxisPlot
            throw(
                ArgumentError(
                    """
                    Tried plotting with `$(F)!` into a `FigureAxisPlot` object, this is not allowed.

                    The `FigureAxisPlot` object is returned by plotting functions not ending in `!` like `lines(...)` or `scatter(...)`.

                    It contains the new `Figure`, the new axis object, for example an `Axis`, `LScene` or `Axis3`, and the new plot object. It exists just as a convenience because returning it displays the contained figure. For all further operations, you should split it into its parts instead. This way, it is clear which of its components you are targeting.

                    You can do this with the destructuring syntax `fig, ax, plt = some_plot(...)` and then continue, for example with `$(F)!(ax, ...)`.
                    """
                )
            )
        end
        if args[1] isa AxisPlot
            throw(
                ArgumentError(
                    """
                    Tried plotting with `$(F)!` into an `AxisPlot` object, this is not allowed.

                    The `AxisPlot` object is returned by plotting functions not ending in `!` with
                    a `GridPosition` as the first argument, like `lines(fig[1, 2], ...)` or `scatter(fig[1, 2], ...)`.

                    It contains the new axis object, for example an `Axis`, `LScene` or `Axis3`, and the new plot object. For all further operations, you should split it into its parts instead. This way, it is clear which of its components you are targeting.

                    You can do this with the destructuring syntax `ax, plt = some_plot(fig[1, 2], ...)` and then continue, for example with `$(F)!(ax, ...)`.
                    """
                )
            )
        end
    end
    figarg, pargs = plot_args(args...)
    figkws = fig_keywords!(attributes)
    # we need to see if we plot into an existing axis before creating the plot
    # For axis specific converts.
    ax = create_axis_like!(figkws, figarg)
    # inserts global state from axis into plot attributes if they exist
    get!(attributes, :dim_conversions, get_conversions(ax))

    plot = Plot{default_plot_func(F, pargs)}(pargs, attributes)
    if ax isa Figure && !(plot isa PlotSpecPlot)
        error("You cannot plot into a figure without an axis. Use `plot(fig[1, 1], ...)` instead.")
    end
    plot!(ax, plot)
    return figurelike_return!(ax, plot)
end

@noinline function _create_plot!(F, attributes::Dict, scene::SceneLike, args...)
    conversion = get_conversions(scene)
    if !isnothing(conversion)
        get!(attributes, :dim_conversions, conversion)
    end
    plot = Plot{default_plot_func(F, args)}(args, attributes)
    plot!(scene, plot)
    return plot
end

figurelike_return(f::GridPosition, p::PlotSpecPlot) = p
figurelike_return(f::Figure, p::PlotSpecPlot) = FigureAxisPlot(f, nothing, p)

# Axis interface

Makie.can_be_current_axis(ax::AbstractAxis) = true

function update_state_before_display!(ax::AbstractAxis)
    reset_limits!(ax)
    return
end

plot!(fa::FigureAxis, plot) = plot!(fa.axis, plot)


function plot!(ax::AbstractAxis, plot::AbstractPlot)
    plot!(ax.scene, plot)
    if !isnothing(get_conversions(plot))
        connect_conversions!(ax.scene.conversions, get_conversions(plot))
    end

    # some area-like plots basically always look better if they cover the whole plot area.
    # adjust the limit margins in those cases automatically.
    needs_tight_limits(plot) && tightlimits!(ax)
    if is_open_or_any_parent(ax.scene)
        reset_limits!(ax)
    end
    return plot
end

function Base.delete!(ax::AbstractAxis, plot::AbstractPlot)
    delete!(ax.scene, plot)
    return ax
end

function Base.empty!(ax::AbstractAxis)
    while !isempty(ax.scene.plots)
        delete!(ax, ax.scene.plots[end])
    end
    return ax
end
