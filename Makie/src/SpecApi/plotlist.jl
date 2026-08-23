

"""
    plotlist!(
        [
            PlotSpec(:Scatter, args...; kwargs...),
            PlotSpec(:Lines, args...; kwargs...),
        ]
    )

Plots a list of PlotSpec's, which can be an observable, making it possible to create efficiently animated plots with the following API:

## Example
```julia
using GLMakie
import Makie.SpecApi as S

fig = Figure()
ax = Axis(fig[1, 1])
plots = Observable([S.heatmap(0 .. 1, 0 .. 1, Makie.peaks()), S.lines(0 .. 1, sin.(0:0.01:1); color=:blue)])
pl = plot!(ax, plots)
display(fig)

# Updating the plot dynamically
plots[] = [S.heatmap(0 .. 1, 0 .. 1, Makie.peaks()), S.lines(0 .. 1, sin.(0:0.01:1); color=:red)]
plots[] = [
    S.image(0 .. 1, 0 .. 1, Makie.peaks()),
    S.poly(Rect2f(0.45, 0.45, 0.1, 0.1)),
    S.lines(0 .. 1, sin.(0:0.01:1); linewidth=10, color=Makie.resample_cmap(:viridis, 101)),
]

plots[] = [
    S.surface(0..1, 0..1, Makie.peaks(); colormap = :viridis, translation = Vec3f(0, 0, -1)),
]
```
"""
@recipe PlotList (plotspecs,) begin end
# Note: PlotList currently replaces the default plot initialization with hard-
# coded default attributes and plot.plotspecs as the name for :converted_1.
# If these are changed the PlotList() method below needs to be updated!

is_atomic_plot(plot::PlotList) = false # is never atomic
validate_attribute_keys(::PlotList) = true

function Base.propertynames(pl::PlotList)
    inner_pnames = if length(pl.plots) == 1
        Base.propertynames(pl.plots[1])
    else
        ()
    end
    return Tuple(unique([keys(pl.attributes.inputs)..., inner_pnames...]))
end

function Base.getproperty(pl::PlotList, property::Symbol)
    hasfield(typeof(pl), property) && return getfield(pl, property)
    haskey(pl.attributes, property) && return pl.attributes[property]
    if length(pl.plots) == 1
        return getproperty(pl.plots[1], property)
    else
        error("Can't get property $property on PlotList with multiple plots.")
    end
end

function Base.setproperty!(pl::PlotList, property::Symbol, value)
    hasfield(typeof(pl), property) && return setfield!(pl, property, value)
    property === :model && return setproperty!(pl.attributes, property, value)
    if haskey(pl.attributes, property)
        return setproperty!(pl.attributes, property, value)
    end
    return if length(pl.plots) == 1
        setproperty!(pl.plots[1], property, value)
    else
        error("Can't set property $property on PlotList with multiple plots.")
    end
end

plottype(::Type{<:Plot{F}}, ::Union{PlotSpec, AbstractVector{PlotSpec}}) where {F} = PlotList
plottype(::Type{<:Plot{F}}, ::Union{GridLayoutSpec, BlockSpec}) where {F} = Plot{plot}
plottype(::Type{<:Plot}, ::Union{GridLayoutSpec, BlockSpec}) = Plot{plot}

function to_plot_object(ps::PlotSpec)
    P = plottype(ps)
    attr = copy(ps.kwargs)
    get!(attr, :force_dimconverts, false)
    return P((ps.args...,), attr)
end


function push_without_add!(scene::Scene, plot)
    validate_attribute_keys(plot)
    for screen in scene.current_screens
        Base.invokelatest(insert!, screen, scene, plot)
    end
    return
end

function diff_plotlist!(
        scene::Scene, plotspecs::Vector{PlotSpec},
        plotlist::Union{Nothing, PlotList} = nothing,
        reusable_plots = IdDict{PlotSpec, Plot}(),
        new_plots = IdDict{PlotSpec, Plot}()
    )
    # Global list of observables that need updating
    # Updating them all at once in the end avoids problems with triggering updates while updating
    # And at some point we may be able to optimize notify(list_of_observables)
    scores = IdDict{Any, Float64}()
    reusable_plots_sorted = [Pair{PlotSpec, Plot}(k, v) for (k, v) in reusable_plots]
    sort!(reusable_plots_sorted, by = ((k, v),) -> v.cycle_index[], rev = true)
    for (i, plotspec) in enumerate(plotspecs)
        # we need to compare by types with compare_specs, since we can only update plots if the types of all attributes match
        reused_plot, old_spec, idx = find_reusable_plot(scene, plotspec, reusable_plots_sorted, scores)
        # Forward kw arguments from Plotlist
        if !isnothing(plotlist)
            merge!(plotspec.kwargs, plotlist.kw)
        end
        # Use plotlist as parent so connect_plot! computes the correct
        # cycle_index via plot_cycle_index(::PlotList, ::Plot).
        parent = isnothing(plotlist) ? scene : plotlist
        if isnothing(reused_plot)
            @debug("Creating new plot for spec")
            plot_obj = to_plot_object(plotspec)
            # connect_plot! sets cycle_index correctly.
            # We don't push to scene.plots when there's a plotlist — the scene should
            # only contain the PlotList itself, to avoid e.g. double legend entries.
            connect_plot!(parent, plot_obj)
            if !isnothing(plotlist)
                push!(plotlist.plots, plot_obj)
            else
                push!(scene.plots, plot_obj)
            end
            push_without_add!(scene, plot_obj)
            new_plots[plotspec] = plot_obj
        else
            @debug("updating old plot with spec")
            delete!(reusable_plots, old_spec)
            deleteat!(reusable_plots_sorted, idx)
            update_plot!(reused_plot, old_spec, plotspec)
            new_plots[plotspec] = reused_plot
        end
    end
    if !isempty(reusable_plots)
        # To keep consistency when removing and adding back plots, decrement the
        # cycle counters of each unused plot in the parent scene.
        # Only do this when the spec plots are the latest plots affecting cycling
        # so that we don't reuse indices that other (newer) plots are using.
        lookup = scene.compute[:cycle_counters][]::Dict{Symbol, Int}
        for (spec, plot) in reusable_plots_sorted
            name = spec.type
            if haskey(lookup, name) && lookup[name] == plot.cycle_index[]
                lookup[name] -= 1
            end
        end
    end
    return new_plots
end

# Cache plots here so that we aren't re-creating plots every time;
# if a plot still exists from last time, update it accordingly.
# If the plot is removed from `plotspecs`, we'll delete it from here
# and re-create it if it ever returns.
function _update_plotlist(plotspecs, scene, plotlist, unused_plots, new_plots, own_plots)
    specs = ifelse(isa(plotspecs, PlotSpec), [plotspecs], plotspecs)
    # Global list of observables that need updating
    # Updating them all at once in the end avoids problems with triggering updates while updating
    # And at some point we may be able to optimize notify(list_of_observables)
    # diff_plotlist! deletes all plots that get reused from unused_plots
    # so, this will become our list of unused plots!
    diff_plotlist!(scene, specs, plotlist, unused_plots, new_plots)
    # Next, delete all plots that we haven't used
    # TODO, we could just hide them, until we reach some max_plots_to_be_cached, so that we re-create less plots.
    if own_plots
        for (_, plot) in unused_plots
            if !isnothing(plotlist)
                filter!(x -> x !== plot, plotlist.plots)
            end
            delete!(scene, plot)
        end
        # Transfer all new plots into unused_plots for the next update!
        @assert !any(x -> x in unused_plots, new_plots)
        empty!(unused_plots)
        merge!(unused_plots, new_plots)
        empty!(new_plots)
    end
    return
end

function update_plotspecs!(
        scene::Scene, list_of_plotspecs::Observable,
        plotlist::Union{Nothing, PlotList} = nothing,
        unused_plots = IdDict{PlotSpec, Plot}(),
        new_plots = IdDict{PlotSpec, Plot}(),
        own_plots = true
    )
    l = Base.ReentrantLock()
    on(scene, list_of_plotspecs; update = true) do plotspecs
        @lock l begin
            _update_plotlist(plotspecs, scene, plotlist, unused_plots, new_plots, own_plots)
        end
        return
    end
    return
end

# Explicitly only handle `plotlist!(parent, PlotSpec[], kwargs...)`
# i.e. no plotlist!(parent, attributes, ...) or plotlist!(parent, graph, ...)
# Anything else falls back onto Plot{Func}, maybe should error instead?
function PlotList(user_args::Tuple{Vector{PlotSpec}}, user_attributes::Union{Dict, NamedTuple})
    isempty(user_args) && throw(ArgumentError("Failed to construct plot: No plot arguments given."))

    graph = ComputeGraph()

    # Arguments - Assumptions:
    # - no expand_dimensions
    # - no convert_arguments
    # - no dim converts apply here (skip :dim_converted outputs)
    # - fixed to type Vector{PlotSpec}
    add_input!(graph, :arg1, user_args[1])
    map!(x -> (x,), graph, :arg1, :args) # needed for default axis
    ComputePipeline.alias!(graph, :args, :converted) # needed for default axis
    map!(first, graph, :converted, :plotspecs)

    return build_plotlist(graph, user_attributes)
end

function build_plotlist(graph::ComputeGraph, user_attributes)
    # Attributes
    # We assume there a no default attributes
    # TODO: Forwarding was already kind of broken, so how should it work?
    # - (current) only initial attribute values are forwarded and they overwrite
    # - should Spec attributes beat plotlist attributes?
    # - should plotlist attributes update but the static after spec -> plot?
    # - should plotlist attribute dynamically update child plot attributes?
    for (k, v) in user_attributes
        add_input!(compute_identity, graph, k, v)
    end

    return Plot{plotlist, Vector{PlotSpec}}(user_attributes, graph)
end

function connect_plot!(parent::SceneLike, plot::PlotList)
    # Finish plot init
    plot.parent = parent
    handle_transformation!(plot, parent)

    # connect SpecApi logic
    scene = Makie.parent_scene(parent)
    obs = ComputePipeline.get_observable!(plot.plotspecs; use_deepcopy = false)
    update_plotspecs!(scene, obs, plot)

    return
end

# Catch any other plot call initiated with a PlotSpec
# This may not be reasonable to all plots...? Should at least catch `Plot{plot}`
function Plot{Func}(user_args::Tuple{Vector{PlotSpec}}, user_attributes::Union{Dict, NamedTuple}) where {Func}
    return PlotList(user_args, user_attributes)
end

# maybe useful?
function Plot{Func}(user_args::Tuple{PlotSpec}, user_attributes::Union{Dict, NamedTuple}) where {Func}
    return PlotList(([user_args[1]],), user_attributes)
end
