# Ideally we re-use Makie.PlotSpec, but right now we need a bit of special behaviour to make this work nicely.
# If the implementation stabilizes, we should think about refactoring PlotSpec to work for both use cases, and then just have one PlotSpec type.
@nospecialize
"""
    PlotSpec{P<:AbstractPlot}(args...; kwargs...)

Object encoding positional arguments (`args`), a `NamedTuple` of attributes (`kwargs`)
as well as plot type `P` of a basic plot.
"""
struct PlotSpec{P<:AbstractPlot}
    args::Vector{Any}
    kwargs::Dict{Symbol, Any}
    function PlotSpec{P}(args...; kwargs...) where {P<:AbstractPlot}
        kw = Dict{Symbol,Any}()
        for (k, v) in kwargs
            # convert eagerly, so that we have stable types for matching later
            # E.g. so that PlotSpec(; color = :red) has the same type as PlotSpec(; color = RGBA(1, 0, 0, 1))
            kw[k] = convert_attribute(v, Key{k}(), Key{plotkey(P)}())
        end
        return new{P}(Any[args...], kw)
    end
    PlotSpec(args...; kwargs...) = new{Combined{plot}}(args...; kwargs...)
end
@specialize

Base.getindex(p::PlotSpec, i::Int) = getindex(p.args, i)
Base.getindex(p::PlotSpec, i::Symbol) = getproperty(p.kwargs, i)

to_plotspec(::Type{P}, args; kwargs...) where {P} = PlotSpec{P}(args...; kwargs...)

function to_plotspec(::Type{P}, p::PlotSpec{S}; kwargs...) where {P,S}
    return PlotSpec{plottype(P, S)}(p.args...; p.kwargs..., kwargs...)
end

plottype(::PlotSpec{P}) where {P} = P

struct BlockSpec
    type::Symbol
    position::Tuple{Any,Any}
    kwargs::Dict{Symbol,Any}
    plots::Vector{PlotSpec}
end

function BlockSpec(typ::Symbol, pos::Tuple{Any,Any}, plots::PlotSpec...; kw...)
    return BlockSpec(typ, pos, Dict{Symbol,Any}(kw), [plots...])
end

struct FigureSpec
    blocks::Vector{BlockSpec}
    kw::Dict{Symbol, Any}
end

FigureSpec(blocks::BlockSpec...; kw...) = FigureSpec([blocks...], Dict{Symbol,Any}(kw))

struct FigurePosition
    f::FigureSpec
    position::Tuple{Any,Any}
end

function Base.getindex(f::FigureSpec, arg1, arg2)
    return FigurePosition(f, (arg1, arg2))
end

function BlockSpec(typ::Symbol, pos::FigurePosition, plots::PlotSpec...; kw...)
    block = BlockSpec(typ, pos.position, Dict{Symbol,Any}(kw), [plots...])
    push!(pos.f.blocks, block)
    return block
end

function PlotSpec{T}(ax::BlockSpec, args...; kwargs...) where {T <: AbstractPlot}
    plot = PlotSpec{T}(args...; kwargs...)
    push!(ax.plots, plot)
    return plot
end


"""
apply for return type PlotSpec
"""
function apply_convert!(P, attributes::Attributes, x::PlotSpec{S}) where {S}
    args, kwargs = x.args, x.kwargs
    # Note that kw_args in the plot spec that are not part of the target plot type
    # will end in the "global plot" kw_args (rest)
    for (k, v) in pairs(kwargs)
        attributes[k] = v
    end
    return (plottype(S, P), (args...,))
end

function apply_convert!(P, ::Attributes, x::AbstractVector{<:PlotSpec})
    return (PlotList, (x,))
end

"""
apply for return type
    (args...,)
"""
apply_convert!(P, ::Attributes, x::Tuple) = (P, x)

function MakieCore.argtypes(plot::PlotSpec{P}) where {P}
    args_converted = convert_arguments(P, plot.args...)
    return MakieCore.argtypes(args_converted)
end

struct SpecApi end
function Base.getproperty(::SpecApi, field::Symbol)
    f = getfield(Makie, field)
    if f isa Function
        P = Combined{getfield(Makie, field)}
        return PlotSpec{P}
    elseif f <: Block
        return (args...; kw...) -> BlockSpec(field, args...; kw...)
    elseif f <: Figure
        return FigureSpec
    else
        error("$(field) is not a Makie plot function, nor a block or figure type")
    end
end

const PlotspecApi = SpecApi()

# comparison based entirely of types inside args + kwargs
compare_specs(a::PlotSpec{A}, b::PlotSpec{B}) where {A, B} = false

function compare_specs(a::PlotSpec{T}, b::PlotSpec{T}) where {T}
    length(a.args) == length(b.args) || return false
    all(i-> typeof(a.args[i]) == typeof(b.args[i]), 1:length(a.args)) || return false

    length(a.kwargs) == length(b.kwargs) || return false
    ka = keys(a.kwargs)
    kb = keys(b.kwargs)
    ka == kb || return false
    all(k -> typeof(a.kwargs[k]) == typeof(b.kwargs[k]), ka) || return false
    return true
end

function update_plot!(plot::AbstractPlot, spec::PlotSpec)
    # Update args in plot `input_args` list
    for i in eachindex(spec.args)
        # we should only call update_plot!, if compare_spec(spec_plot_got_created_from, spec) == true,
        # Which should guarantee, that args + kwargs have the same length and types!
        arg_obs = plot.args[i]
        if to_value(arg_obs) !== spec.args[i] # only update if different
            @debug("updating arg $i")
            arg_obs[] = spec.args[i]
        end
    end
    # Update attributes
    for (attribute, new_value) in spec.kwargs
        if plot[attribute][] !== new_value # only update if different
            @debug("updating kw $attribute")
            plot[attribute] = new_value
        end
    end
end

"""
    plotlist!(
        [
            PlotSpec{SomePlotType}(args...; kwargs...),
            PlotSpec{SomeOtherPlotType}(args...; kwargs...),
        ]
    )

Plots a list of PlotSpec's, which can be an observable, making it possible to create efficiently animated plots with the following API:

## Example
```julia
using GLMakie
import Makie.PlotspecApi as P

fig = Figure()
ax = Axis(fig[1, 1])
plots = Observable([P.heatmap(0 .. 1, 0 .. 1, Makie.peaks()), P.lines(0 .. 1, sin.(0:0.01:1); color=:blue)])
pl = plot!(ax, plots)
display(fig)

# Updating the plot dynamically
plots[] = [P.heatmap(0 .. 1, 0 .. 1, Makie.peaks()), P.lines(0 .. 1, sin.(0:0.01:1); color=:red)]
plots[] = [
    P.image(0 .. 1, 0 .. 1, Makie.peaks()),
    P.poly(Rect2f(0.45, 0.45, 0.1, 0.1)),
    P.lines(0 .. 1, sin.(0:0.01:1); linewidth=10, color=Makie.resample_cmap(:viridis, 101)),
]

plots[] = [
    P.surface(0..1, 0..1, Makie.peaks(); colormap = :viridis, translation = Vec3f(0, 0, -1)),
]
```
"""
@recipe(PlotList, plotspecs) do scene
    Attributes()
end

convert_arguments(::Type{<:AbstractPlot}, args::AbstractArray{<:PlotSpec}) = (args,)
plottype(::AbstractVector{<:PlotSpec}) = PlotList

# Since we directly plot into the parent scene (hacky), we need to overload these
Base.insert!(::MakieScreen, ::Scene, ::PlotList) = nothing

function Base.show(io::IO, ::MIME"text/plain", spec::PlotSpec{P}) where {P}
    args = join(map(x -> string("::", typeof(x)), spec.args), ", ")
    kws = join([string(k, " = ", typeof(v)) for (k, v) in spec.kwargs], ", ")
    println(io, "P.", plotfunc(P), "($args; $kws)")
end

function Base.show(io::IO, spec::PlotSpec{P}) where {P}
    args = join(map(x -> string("::", typeof(x)), spec.args), ", ")
    kws = join([string(k, " = ", typeof(v)) for (k, v) in spec.kwargs], ", ")
    return println(io, "P.", plotfunc(P), "($args; $kws)")
end

function to_combined(ps::PlotSpec{P}) where {P}
    return P((ps.args...,), copy(ps.kwargs))
end

function update_plotspecs!(
        scene::Scene,
        list_of_plotspecs::Observable,
        cached_plots=IdDict{PlotSpec, Combined}())
    # Cache plots here so that we aren't re-creating plots every time;
    # if a plot still exists from last time, update it accordingly.
    # If the plot is removed from `plotspecs`, we'll delete it from here
    # and re-create it if it ever returns.
    on(list_of_plotspecs; update=true) do plotspecs
        old_plots = copy(cached_plots) # needed for set diff
        previoues_plots = copy(cached_plots) # needed to be mutated
        empty!(cached_plots)
        for plotspec in plotspecs
            # we need to compare by types with compare_specs, since we can only update plots if the types of all attributes match
            reused_plot = nothing
            for (spec, plot) in previoues_plots
                if compare_specs(spec, plotspec)
                    reused_plot = plot
                    delete!(previoues_plots, spec)
                    break
                end
            end
            if isnothing(reused_plot)
                @debug("Creating new plot for spec")
                # Create new plot, store it into our `cached_plots` dictionary
                plot = plot!(scene, to_combined(plotspec))
                cached_plots[plotspec] = plot
            else
                @debug("updating old plot with spec")
                update_plot!(reused_plot, plotspec)
                cached_plots[plotspec] = reused_plot
            end
        end
        unused_plots = setdiff(values(old_plots), values(cached_plots))
        # Next, delete all plots that we haven't used
        # TODO, we could just hide them, until we reach some max_plots_to_be_cached, so that we re-create less plots.
        for plot in unused_plots
            delete!(scene, plot)
        end
        return
    end
end

function Makie.plot!(p::PlotList{<: Tuple{<: AbstractArray{<: PlotSpec}}})
    scene = Makie.parent_scene(p)
    update_plotspecs!(scene, p[1])
    return
end

# Prototype for Pluto + Ijulia integration with Observable(ListOfPlots)
function Base.showable(::Union{MIME"juliavscode/html",MIME"text/html"}, ::Observable{<: AbstractVector{<:PlotSpec}})
    return true
end

function Base.show(io::IO, m::Union{MIME"juliavscode/html",MIME"text/html"},
                   plotspec::Observable{<:AbstractVector{<:PlotSpec}})
    f = plot(plotspec)
    show(io, m, f)
    return
end


## BlockSpec

function compare_block(a::BlockSpec, b::BlockSpec)
    a.type === b.type || return false
    a.position === b.position || return false
    return true
end

function to_block(fig::Figure, spec::BlockSpec)
    BType = getfield(Makie, spec.type)
    return BType(fig[spec.position...]; spec.kwargs...)
end

function update_block!(block::Block, plot_obs, spec::BlockSpec)
    for (key, value) in spec.kwargs
        setproperty!(block, key, value)
    end
    return plot_obs[] = spec.plots
end

function update_fig(fig, figure_obs)
    cached_blocks = Pair{BlockSpec,Tuple{Block,Observable}}[]
    on(figure_obs; update=true) do figure
        used_specs = Set{Int}()
        for spec in figure.blocks
            # we need to compare by types with compare_specs, since we can only update plots if the types of all attributes match
            idx = findfirst(x -> compare_block(x[1], spec), cached_blocks)
            if isnothing(idx)
                @debug("Creating new block for spec")
                # Create new plot, store it into our `cached_blocks` dictionary
                block = to_block(fig, spec)
                if block isa AbstractAxis
                    obs = Observable(spec.plots)
                    scene = get_scene(block)
                    update_plotspecs!(scene, obs)
                else
                    obs = Observable([])
                end
                push!(cached_blocks, spec => (block, obs))
                push!(used_specs, length(cached_blocks))
                Makie.update_state_before_display!(block)
            else
                @debug("updating old block with spec")
                push!(used_specs, idx)
                block, plot_obs = cached_blocks[idx][2]
                update_block!(block, plot_obs, spec)
            end
        end
        unused_plots = setdiff(1:length(cached_blocks), used_specs)
        # Next, delete all plots that we haven't used
        # TODO, we could just hide them, until we reach some max_plots_to_be_cached, so that we re-create less plots.
        for idx in unused_plots
            _, (block, obs) = cached_blocks[idx]
            delete!(block)
            Makie.Observables.clear(obs)
        end
        return splice!(cached_blocks, sort!(collect(unused_plots)))
    end
    return fig
end
