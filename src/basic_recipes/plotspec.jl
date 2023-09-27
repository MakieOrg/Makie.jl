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

function MakieCore.argtypes(plot::PlotSpec{P}) where {P}
    args_converted = convert_arguments(P, plot.args...)
    return MakieCore.argtypes(args_converted)
end

struct SpecApi end
function Base.getproperty(::SpecApi, field::Symbol)
    P = Combined{getfield(Makie, field)}
    return PlotSpec{P}
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
        if to_value(arg_obs) != spec.args[i] # only update if different
            @debug("updating arg $i")
            arg_obs[] = spec.args[i]
        end
    end
    # Update attributes
    for (attribute, new_value) in spec.kwargs
        if plot[attribute][] != new_value # only update if different
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

# TODO, make this work with Cycling and also with convert_arguments returning
# Vector{PlotSpec} so that one can write recipes like this:
quote
    Makie.convert_arguments(obj::MyType) = [
        obj.lineplot ? P.lines(obj.args...; obj.kwargs...) : P.scatter(obj.args...; obj.kw...)
    ]
end

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

function Makie.plot!(p::PlotList{<: Tuple{<: AbstractArray{<: PlotSpec}}})
    # Cache plots here so that we aren't re-creating plots every time;
    # if a plot still exists from last time, update it accordingly.
    # If the plot is removed from `plotspecs`, we'll delete it from here
    # and re-create it if it ever returns.
    cached_plots = Pair{PlotSpec, Combined}[]
    scene = Makie.parent_scene(p)
    on(p.plotspecs; update=true) do plotspecs
        used_plots = Set{Int}()
        for plotspec in plotspecs
            # we need to compare by types with compare_specs, since we can only update plots if the types of all attributes match
            idx = findfirst(x-> compare_specs(x[1], plotspec), cached_plots)
            if isnothing(idx)
                @debug("Creating new plot for spec")
                # Create new plot, store it into our `cached_plots` dictionary
                plot = plot!(scene, to_combined(plotspec))
                push!(p.plots, plot)
                push!(cached_plots, plotspec => plot)
                push!(used_plots, length(cached_plots))
            else
                @debug("updating old plot with spec")
                push!(used_plots, idx)
                plot = cached_plots[idx][2]
                update_plot!(plot, plotspec)
                cached_plots[idx] = plotspec => plot
            end
        end
        unused_plots = setdiff(1:length(cached_plots), used_plots)
        # Next, delete all plots that we haven't used
        # TODO, we could just hide them, until we reach some max_plots_to_be_cached, so that we re-create less plots.
        for idx in unused_plots
            _, plot = cached_plots[idx]
            delete!(scene, plot)
            filter!(x -> x !== plot, p.plots)
        end
        splice!(cached_plots, sort!(collect(unused_plots)))
    end
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
