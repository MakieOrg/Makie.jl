# Ideally we re-use Makie.PlotSpec, but right now we need a bit of special behaviour to make this work nicely.
# If the implementation stabilizes, we should think about refactoring PlotSpec to work for both use cases, and then just have one PlotSpec type.
struct PlotDescription{P<:AbstractPlot}
    args::Vector{Any}
    kwargs::Dict{Symbol, Any}
end

@nospecialize
function PlotDescription{P}(args...; kwargs...) where {P<:AbstractPlot}
    kw = Dict{Symbol, Any}()
    for (k, v) in kwargs
        # convert eagerly, so that we have stable types for matching later
        # E.g. so that PlotDescription(; color = :red) has the same type as PlotDescription(; color = RGBA(1, 0, 0, 1))
        kw[k] = convert_attribute(v, Key{k}(), Key{plotkey(P)}())
    end
    return PlotDescription{P}(Any[args...], kw)
end
@specialize

struct SpecApi end
function Base.getproperty(::SpecApi, field::Symbol)
    P = Combined{getfield(Makie, field)}
    return PlotDescription{P}
end

const PlotspecApi = SpecApi()

# comparison based entirely of types inside args + kwargs
compare_specs(a::PlotDescription{A}, b::PlotDescription{B}) where {A, B} = false
function compare_specs(a::PlotDescription{T}, b::PlotDescription{T}) where {T}
    length(a.args) == length(b.args) || return false
    all(i-> typeof(a.args[i]) == typeof(b.args[i]), 1:length(a.args)) || return false

    length(a.kwargs) == length(b.kwargs) || return false
    ka = keys(a.kwargs)
    kb = keys(b.kwargs)
    ka == kb || return false
    all(k -> typeof(a.kwargs[k]) == typeof(b.kwargs[k]), ka) || return false
    return true
end

function update_plot!(plot::AbstractPlot, spec::PlotDescription)
    # Update args in plot `input_args` list
    for i in eachindex(spec.args)
        # we should only call update_plot!, if compare_spec(spec_plot_got_created_from, spec) == true,
        # Which should guarantee, that args + kwargs have the same length and types!
        arg_obs = plot.input_args[i]
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
            PlotDescription{SomePlotType}(args...; kwargs...),
            PlotDescription{SomeOtherPlotType}(args...; kwargs...),
        ]
    )

Plots a list of PlotDescription's, which can be an observable, making it possible to create efficiently animated plots with the following API:

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

Makie.convert_arguments(::Type{<:AbstractPlot}, args::AbstractArray{<:PlotDescription}) = (args,)
Makie.plottype(::AbstractArray{<:PlotDescription}) = PlotList
Makie.plottype(::Type{Any}, ::AbstractArray{<:PlotDescription}) = PlotList
Makie.plottype(::Type{<: PlotList}, ::AbstractArray{<:PlotDescription}) = PlotList

# Since we directly plot into the parent scene (hacky), we need to overload these
Makie.Base.insert!(screen::MakieScreen, scene::Scene, x::PlotList) = nothing

# TODO, make this work with Cycling and also with convert_arguments returning
# Vector{PlotDescription} so that one can write recipes like this:
quote
    Makie.convert_arguments(obj::MyType) = [
        obj.lineplot ? P.lines(obj.args...; obj.kwargs...) : P.scatter(obj.args...; obj.kw...)
    ]
end

function Makie.plot!(p::PlotList{<: Tuple{<: AbstractArray{<: PlotDescription}}})
    # Cache plots here so that we aren't re-creating plots every time;
    # if a plot still exists from last time, update it accordingly.
    # If the plot is removed from `plotspecs`, we'll delete it from here
    # and re-create it if it ever returns.
    cached_plots = Pair{PlotDescription, Combined}[]
    scene = Makie.parent_scene(p)
    on(p.plotspecs; update=true) do plotspecs
        used_plots = Set{Int}()
        for plotspec in plotspecs
            # we need to compare by types with compare_specs, since we can only update plots if the types of all attributes match
            idx = findfirst(x-> compare_specs(x[1], plotspec), cached_plots)
            if isnothing(idx)
                @debug("Creating new plot for spec")
                # Create new plot, store it into our `cached_plots` dictionary
                plot = plot!(scene,
                    typeof(plotspec).parameters[1],
                    Attributes(plotspec.kwargs),
                    plotspec.args...,
                )
                push!(cached_plots, plotspec => plot)
                push!(used_plots, length(cached_plots))
            else
                println("updating old plot with spec")
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
            spec, plot = cached_plots[idx]
            delete!(scene, plot)
        end
        splice!(cached_plots, sort!(collect(unused_plots)))
    end
end

function Base.showable(::Union{MIME"juliavscode/html",MIME"text/html"}, ::Observable{<: AbstractVector{<:PlotDescription}})
    return true
end

function Base.show(io::IO, m::Union{MIME"juliavscode/html",MIME"text/html"},
                   plotspec::Observable{<:AbstractVector{<:PlotDescription}})
    f = plot(plotspec)
    show(io, m, f)
    return
end
