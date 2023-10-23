# Ideally we re-use Makie.PlotSpec, but right now we need a bit of special behaviour to make this work nicely.
# If the implementation stabilizes, we should think about refactoring PlotSpec to work for both use cases, and then just have one PlotSpec type.
@nospecialize
"""
    PlotSpec(plottype, args...; kwargs...)

Object encoding positional arguments (`args`), a `NamedTuple` of attributes (`kwargs`)
as well as plot type `P` of a basic plot.
"""
struct PlotSpec
    type::Symbol
    args::Vector{Any}
    kwargs::Dict{Symbol, Any}
    function PlotSpec(type::Symbol, args...; kwargs...)
        kw = Dict{Symbol,Any}()
        for (k, v) in kwargs
            # convert eagerly, so that we have stable types for matching later
            # E.g. so that PlotSpec(; color = :red) has the same type as PlotSpec(; color = RGBA(1, 0, 0, 1))
            kw[k] = convert_attribute(v, Key{k}(), Key{type}())
        end
        return new(type, Any[args...], kw)
    end
    PlotSpec(args...; kwargs...) = new(:plot, args...; kwargs...)
end
@specialize

Base.getindex(p::PlotSpec, i::Int) = getindex(p.args, i)
Base.getindex(p::PlotSpec, i::Symbol) = getproperty(p.kwargs, i)

to_plotspec(::Type{P}, args; kwargs...) where {P} = PlotSpec(plotkey(P), args...; kwargs...)

function to_plotspec(::Type{P}, p::PlotSpec; kwargs...) where {P}
    S = plottype(p)
    return PlotSpec(plotkey(plottype(P, S)), p.args...; p.kwargs..., kwargs...)
end

plottype(p::PlotSpec) = Combined{getfield(Makie, p.type)}

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

function PlotSpec(type::Symbol, ax::BlockSpec, args...; kwargs...)
    plot = PlotSpec(type, args...; kwargs...)
    push!(ax.plots, plot)
    return plot
end


"""
apply for return type PlotSpec
"""
function apply_convert!(P, attributes::Attributes, x::PlotSpec)
    args, kwargs = x.args, x.kwargs
    # Note that kw_args in the plot spec that are not part of the target plot type
    # will end in the "global plot" kw_args (rest)
    for (k, v) in pairs(kwargs)
        attributes[k] = v
    end
    return (plottype(plottype(x), P), (args...,))
end

function apply_convert!(P, ::Attributes, x::AbstractVector{PlotSpec})
    return (PlotList, (x,))
end

"""
apply for return type
    (args...,)
"""
apply_convert!(P, ::Attributes, x::Tuple) = (P, x)

function MakieCore.argtypes(plot::PlotSpec)
    args_converted = convert_arguments(plottype(plot), plot.args...)
    return MakieCore.argtypes(args_converted)
end

struct SpecApi end

function Base.getproperty(::SpecApi, field::Symbol)
    f = getfield(Makie, field)
    if f isa Function
        return (args...; kw...) -> PlotSpec(field, args...; kw...)
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
function compare_specs(a::PlotSpec, b::PlotSpec)
    a.type === b.type || return false
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
    any_different = false
    for i in eachindex(spec.args)
        # we should only call update_plot!, if compare_spec(spec_plot_got_created_from, spec) == true,
        # Which should guarantee, that args + kwargs have the same length and types!
        arg_obs = plot.args[i]
        if to_value(arg_obs) !== spec.args[i] # only update if different
            any_different = true
            arg_obs.val = spec.args[i]
        end
    end

    # Update attributes
    to_notify = Symbol[]
    for (attribute, new_value) in spec.kwargs
        old_attr = plot[attribute]
        # only update if different
        if old_attr[] !== new_value || old_attr[] != new_value
            @debug("updating kw $attribute")
            old_attr.val = new_value
            push!(to_notify, attribute)
        end
    end
    # We first update obs.val only to prevent dimension missmatch problems
    # We shouldn't have many since we only update if the types match, but I already run into a few regardless
    # TODO, have update!(plot, new_attributes), which doesn't run into this problem and
    # is also more efficient e.g. for WGLMakie, where every update sends a separate message via the websocket
    if any_different
        # It should be enough to notify first arg, since `convert_arguments` depends on all args
        notify(plot.args[1])
    end
    for attribute in to_notify
        notify(plot[attribute])
    end
end

"""
    plotlist!(
        [
            PlotSpec(:scatter, args...; kwargs...),
            PlotSpec(:lines, args...; kwargs...),
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

function Base.show(io::IO, ::MIME"text/plain", spec::PlotSpec)
    args = join(map(x -> string("::", typeof(x)), spec.args), ", ")
    kws = join([string(k, " = ", typeof(v)) for (k, v) in spec.kwargs], ", ")
    println(io, "P.", spec.type, "($args; $kws)")
    return
end

function Base.show(io::IO, spec::PlotSpec)
    args = join(map(x -> string("::", typeof(x)), spec.args), ", ")
    kws = join([string(k, " = ", typeof(v)) for (k, v) in spec.kwargs], ", ")
    println(io, "P.", spec.type, "($args; $kws)")
    return
end

function to_combined(ps::PlotSpec)
    P = plottype(ps)
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
    l = Base.ReentrantLock()
    on(scene, list_of_plotspecs; update=true) do plotspecs
        lock(l) do
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
end

function Makie.plot!(p::PlotList{<: Tuple{<: AbstractArray{PlotSpec}}})
    scene = Makie.parent_scene(p)
    update_plotspecs!(scene, p[1])
    return
end

function data_limits(p::PlotList)
    scene = Makie.parent_scene(p)
    return data_limits(filter(x -> !(x isa PlotList), scene.plots))
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
    plot_obs[] = spec.plots
    return
end

function update_fig!(fig, figure_obs)
    cached_blocks = Pair{BlockSpec,Tuple{Block,Observable}}[]
    l = Base.ReentrantLock()
    on(fig.scene, figure_obs; update=true) do figure
        lock(l) do
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
    end
    return fig
end
