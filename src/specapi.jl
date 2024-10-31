
using GridLayoutBase: GridLayoutBase

import GridLayoutBase: GridPosition, Side, ContentSize, GapSize, AlignMode, Inner, GridLayout, GridSubposition

function get_recipe_function(name::Symbol)
    if hasproperty(Makie, name)
        return getfield(Makie, name)
    else
        return nothing
    end
end

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
        type_str = string(type)
        if type_str[end] == '!'
            error("PlotSpec objects are supposed to be used without !, unless when using `S.$(type)(axis::P.Axis, args...; kwargs...)`")
        end
        if !isuppercase(type_str[1])
            func = get_recipe_function(type)
            func === nothing && error("PlotSpec need to be existing recipes or Makie plot objects. Found: $(type_str)")
            plot_type = Plot{func}
            type = plotsym(plot_type)
            @warn("PlotSpec objects are supposed to be title case. Found: $(type_str). Please use $(type) instead.")
        end
        kw = Dict{Symbol,Any}()
        for (k, v) in kwargs
            # convert eagerly, so that we have stable types for matching later
            # E.g. so that PlotSpec(; color = :red) has the same type as PlotSpec(; color = RGBA(1, 0, 0, 1))
            if v isa Cycled # special case for conversions needing a scene
                kw[k] = v
            elseif v isa Observable
                kw[k] = to_value(v)
                # error("PlotSpec are supposed to be used without Observables")
            else
                try
                    # Really unfortunate!
                    # Recipes don't have convert_attribute
                    # (e.g. band(...; color=:y))
                    # So on error we don't convert for now via try catch
                    # Since we also dont have an API to figure out if a convert is defined correctly
                    # TODO, I think we can do this more elegantly but will need a bit of a convert_attribute refactor
                    kw[k] = convert_attribute(v, Key{k}(), Key{type}())
                catch e
                    kw[k] = v
                end
            end
        end
        return new(type, Any[args...], kw)
    end
    PlotSpec(args...; kwargs...) = new(:plot, args...; kwargs...)
end


struct BlockSpec
    type::Symbol # Type as :Scatter, :BarPlot
    kwargs::Dict{Symbol,Any}
    plots::Vector{PlotSpec}
    then_funcs::Set{Function}
    then_observers::Set{ObserverFunction}
    function BlockSpec(type::Symbol, kwargs::Dict{Symbol,Any}, plots::Vector{PlotSpec}=PlotSpec[])
        return new(type, kwargs, plots, Set{Function}(), Set{ObserverFunction}())
    end
end

const GridLayoutPosition = Tuple{UnitRange{Int},UnitRange{Int},Side}

struct GridLayoutSpec
    content::Vector{Pair{GridLayoutPosition,Union{GridLayoutSpec,BlockSpec}}}

    size::Tuple{Int,Int}
    offsets::Tuple{Int,Int}

    colsizes::Vector{ContentSize}
    rowsizes::Vector{ContentSize}
    colgaps::Vector{GapSize}
    rowgaps::Vector{GapSize}
    alignmode::AlignMode
    tellheight::Bool
    tellwidth::Bool
    halign::Float64
    valign::Float64

    function GridLayoutSpec(content::AbstractVector{<:Pair};
                            colsizes=nothing,
                            rowsizes=nothing,
                            colgaps=nothing,
                            rowgaps=nothing,
                            alignmode::AlignMode=GridLayoutBase.Inside(),
                            tellheight::Bool=true,
                            tellwidth::Bool=true,
                            halign::Union{Symbol,Real}=:center,
                            valign::Union{Symbol,Real}=:center,)
        rowspan, colspan = foldl(content; init=(1:1, 1:1)) do (rows, cols), ((_rows, _cols, _...), _)
            return rangeunion(rows, _rows), rangeunion(cols, _cols)
        end

        content = map(content) do (position, x)
            p = Pair{GridLayoutPosition,Union{GridLayoutSpec,BlockSpec}}(to_gridposition(position, rowspan,
                                                                                         colspan), x)
            return p
        end

        nrows = length(rowspan)
        ncols = length(colspan)
        colsizes = GridLayoutBase.convert_contentsizes(ncols, colsizes)
        rowsizes = GridLayoutBase.convert_contentsizes(nrows, rowsizes)
        default_rowgap = Fixed(16) # TODO: where does this come from?
        default_colgap = Fixed(16) # TODO: where does this come from?
        colgaps = GridLayoutBase.convert_gapsizes(ncols - 1, colgaps, default_colgap)
        rowgaps = GridLayoutBase.convert_gapsizes(nrows - 1, rowgaps, default_rowgap)

        halign = GridLayoutBase.halign2shift(halign)
        valign = GridLayoutBase.valign2shift(valign)

        return new(content,
                   (nrows, ncols),
                   (rowspan[1] - 1, colspan[1] - 1),
                   colsizes,
                   rowsizes,
                   colgaps,
                   rowgaps,
                   alignmode,
                   tellheight,
                   tellwidth,
                   halign,
                   valign)
    end
end


const Layoutable = Union{GridLayout,Block}
const LayoutableSpec = Union{GridLayoutSpec,BlockSpec}
const LayoutEntry = Pair{GridLayoutPosition,LayoutableSpec}
# We use this to decide if we can re-use a plot.
# (nesting_level_in_layout, position_in_layout, spec)
const LayoutableKey = Tuple{Int,GridLayoutPosition,LayoutableSpec}

#####################
#### PlotSpec

PlotSpec(::Type{P}, args...; kwargs...) where {P <: Plot} = PlotSpec(plotsym(P), args...; kwargs...)
Base.getindex(p::PlotSpec, i::Int) = getindex(p.args, i)
Base.getindex(p::PlotSpec, i::Symbol) = getproperty(p.kwargs, i)

to_plotspec(::Type{P}, args; kwargs...) where {P} = PlotSpec(plotsym(P), args...; kwargs...)
function to_plotspec(::Type{P}, p::PlotSpec; kwargs...) where {P}
    S = plottype(p)
    return PlotSpec(plotsym(plottype(P, S)), p.args...; p.kwargs..., kwargs...)
end

plottype(p::PlotSpec) = getfield(Makie, p.type)

function Base.show(io::IO, ::MIME"text/plain", spec::PlotSpec)
    args = join(map(x -> string("::", typeof(x)), spec.args), ", ")
    kws = join([string(k, " = ", typeof(v)) for (k, v) in spec.kwargs], ", ")
    println(io, "S.", spec.type, "($args; $kws)")
    return
end

function Base.show(io::IO, spec::PlotSpec)
    args = join(map(x -> string("::", typeof(x)), spec.args), ", ")
    kws = join([string(k, " = ", typeof(v)) for (k, v) in spec.kwargs], ", ")
    println(io, "S.", spec.type, "($args; $kws)")
    return
end
####################
#### BlockSpec

function Base.setproperty!(p::BlockSpec, k::Symbol, v)
    p.kwargs[k] = v
end

function Base.getproperty(p::BlockSpec, k::Symbol)
    if k === :then
        return (f) -> push!(p.then_funcs, f)
    end
    k in fieldnames(BlockSpec) && return getfield(p, k)
    return p.kwargs[k]
end
Base.propertynames(p::BlockSpec) = Tuple(keys(p.kwargs))


function BlockSpec(typ::Symbol, args...; plots::Vector{PlotSpec}=PlotSpec[], kw...)
    attr = Dict{Symbol,Any}(kw)
    if typ == :Legend
        # TODO, this is hacky and works around the fact,
        # that legend gets its legend elements from the positional arguments
        # But we can only update them via legend.entrygroups
        defaults = block_defaults(:Legend, attr, nothing)
        entrygroups = to_entry_group(Attributes(defaults), args...)
        attr[:entrygroups] = entrygroups
        return BlockSpec(typ, attr, plots)
    else
        if typ == :Colorbar && !isempty(args)
            if length(args) == 1 && args[1] isa PlotSpec
                attr[:plotspec] = args[1]
                args = ()
            else
                error("Only one argument `arg::PlotSpec` is supported for S.Colorbar. Found: $(args)")
            end
        end
        if !isempty(args)
            error("BlockSpecs, with an exception for Legend and Colorbar, don't support positional arguments yet.")
        end
        return BlockSpec(typ, attr, plots)
    end
end

######################
#### GridLayoutSpec

GridLayoutSpec(v::AbstractVector; kwargs...) = GridLayoutSpec(reshape(v, :, 1); kwargs...)
function GridLayoutSpec(v::AbstractMatrix; kwargs...)
    indices = vec([Tuple(c) for c in CartesianIndices(v)])
    pairs = [LayoutEntry((i:i, j:j, GridLayoutBase.Inner()), v[i, j]) for (i, j) in indices]
    return GridLayoutSpec(pairs; kwargs...)
end

GridLayoutSpec(contents...; kwargs...) = GridLayoutSpec([contents...]; kwargs...)


@inline function is_different(a, b)
    # First check if they are the same object
    # This disallows mutating PlotSpec arguments in place
    a === b && return false
    # If they're not the same objcets, we see if they contain the same values
    a == b && return false
    return true
end

# We use this function to decide which plots to reuse + update instead of re-creating.
# Comparison based entirely of types inside args + kwargs.
# This will return false for the same plotspec with a new attribute
# E.g. `compare_spec(S.Scatter(1:4; color=:red), S.Scatter(1:4; marker=:circle))`
# While we could easily update this, we don't want to, since we're
# pessimistic about what's updatable and to avoid issues with
# Needing to reset attributes to their defaults, at the cost of re-creating more plots than necessary.
# TODO when focussing better performance, this is one of the first things we want to try
function distance_score(a::PlotSpec, b::PlotSpec, scores_dict)
    (a.type !== b.type) && return 100.0
    scores = Float64[
        distance_score(a.args, b.args, scores_dict),
        distance_score(a.kwargs, b.kwargs, scores_dict)
    ]
    return norm(scores)
end

function distance_score(a::Any, b::Any, scores)
    a === b && return 0.0
    a == b && return 0.0
    typeof(a) == typeof(b) && return 0.5
    return 100.0
end

_has_index(a::Tuple, i) = i <= length(a)
_has_index(a::AbstractVector, i) = checkbounds(Bool, a, i)
_has_index(a::Dict, i) = haskey(a, i)

function distance_score(a::T, b::T, scores_dict) where {T<:Union{AbstractVector,Tuple,Dict{Symbol,Any}}}
    a === b && return 0.0
    isempty(a) && isempty(b) && return 0.0
    all_keys = collect(union(keys(a), keys(b)))
    scores = map(all_keys) do key
        if _has_index(a, key) && _has_index(b, key)
            return distance_score(a[key], b[key], scores_dict)
        else
            return 1.0
        end
    end
    return norm(scores)
end

function distance_score(a::GridLayoutPosition, b::GridLayoutPosition, scores)
    a === b && return 0.0
    return norm(distance_score.(a, b, Ref(scores)))
end

function distance_score(a::BlockSpec, b::BlockSpec, scores_dict)
    a === b && return 0.0
    (a.type !== b.type) && return 100.0 # Cant update when types dont match
    get!(scores_dict, (a, b)) do
        scores = Float64[
            distance_score(a.kwargs, b.kwargs, scores_dict),
            distance_score(a.plots, b.plots, scores_dict),
            distance_score(a.then_funcs, b.then_funcs, scores_dict)
        ]
        return norm(scores)
    end
end

function distance_score(at::Tuple{Int,GP,BS}, bt::Tuple{Int,GP,BS},
                        scores_dict) where {GP<:GridLayoutPosition,BS<:BlockSpec}
    at === bt && return 0.0
    (anesting, ap, a) = at
    (bnesting, bp, b) = bt
    scores = Float64[
        abs(anesting - bnesting) * 2,
        distance_score(ap, bp, scores_dict) * 2,
        distance_score(a, b, scores_dict)
    ]
    return norm(scores)
end

function distance_score(at::Tuple{Int,GP,GridLayoutSpec}, bt::Tuple{Int,GP,GridLayoutSpec},
                        scores) where {GP<:GridLayoutPosition}
    at === bt && return 0.0
    anesting, ap, a = at
    bnesting, bp, b = bt
    get!(scores, (at, bt)) do
        anested = map(ac -> (anesting + 1, ac[1], ac[2]), a.content)
        bnested = map(bc -> (anesting + 1, bc[1], bc[2]), b.content)
        return norm([abs(anesting - bnesting),
                     distance_score(ap, bp, scores),
                     distance_score(anested, bnested, scores)])
    end
end

function find_min_distance(f, to_compare, list, scores, penalty=(key, score)-> score)
    isempty(list) && return -1
    minscore = 2.0
    idx = -1
    for key in keys(list)
        score = distance_score(to_compare, f(list[key], key), scores)
        score = penalty(key, score) # apply custom penalty
        if score ≈ 0.0 # shortcuircit for exact matches
            return key
        end
        if score < minscore
            minscore = score
            idx = key
        end
    end
    return idx
end

function find_layoutable(
        nest_pos_spec::LayoutableKey,
        layoutables::Vector{Pair{LayoutableKey, Tuple{Layoutable,Observable{Vector{PlotSpec}}}}},
        scores
    )
    idx = find_min_distance((x, _)-> first(x), nest_pos_spec, layoutables, scores)
    idx == -1 && return 0, nothing, nothing
    return (idx, layoutables[idx]...)
end

function find_reusable_plot(scene::Scene, plotspec::PlotSpec, plots::IdDict{PlotSpec,Plot}, scores)
    function penalty(key, score)
        # penalize plots with different parents
        # needs to be implemented via this penalty function, since parent scenes arent part of the spec
        plot = plots[key]
        move_to_penalty = ((!Makie.supports_move_to(plot)) * 100) + 1
        return norm(Float64[plot.parent !== scene, score]) * move_to_penalty
    end
    idx = find_min_distance((_, spec) -> spec, plotspec, plots, scores, penalty)
    idx == -1 && return nothing, nothing
    return plots[idx], idx
end

to_span(range::UnitRange{Int}, span::UnitRange{Int}) = (range.start < span.start || range.stop > span.stop) ? error("Range $range not completely covered by spanning range $span.") : range
to_span(range::Int, span::UnitRange{Int}) = (range < span.start || range > span.stop) ? error("Range $range not completely covered by spanning range $span.") : range:range
to_span(::Colon, span::UnitRange{Int}) = span
to_gridposition(rows_cols::Tuple{Any,Any}, rowspan, colspan) = to_gridposition((rows_cols..., Inner()), rowspan, colspan)
to_gridposition(rows_cols_side::Tuple{Any,Any,Any}, rowspan, colspan) = (to_span(rows_cols_side[1], rowspan), to_span(rows_cols_side[2], colspan), rows_cols_side[3])

rangeunion(r1, r2::UnitRange) = min(r1.start, r2.start):max(r1.stop, r2.stop)
rangeunion(r1, r2::Int) = min(r1.start, r2):max(r1.stop, r2)
rangeunion(r1, ::Colon) = r1



"""
See documentation for specapi.
"""
struct _SpecApi end
const SpecApi = _SpecApi()

function Base.getproperty(::_SpecApi, field::Symbol)
    field === :GridLayout && return GridLayoutSpec
    # TODO, we wanted to track all recipe names in a set
    # in MakieCore via the recipe macro, but due to precompilation & caching
    # It seems impossible to merge the recipes from all modules
    # Since precompilation will cache only MakieCore's state
    # And once everything is compiled, and MakieCore is loaded into a package
    # The names are loaded from cache and dont contain anything after MakieCore.
    func = get_recipe_function(field)
    if isnothing(func)
        error("$(field) neither a recipe, Makie plotting object or a Block (like Axis, Legend, etc).")
    elseif func isa Function
        sym = plotsym(Plot{func})
        if (sym === :plot) # fallback for plotsym, so not found!
            error("$(field) neither a recipe, Makie plotting object or a Block (like Axis, Legend, etc).")
        end
        @warn("PlotSpec objects are supposed to be title case. Found: $(field). Please use $(sym) instead.")
        return (args...; kw...) -> PlotSpec(sym, args...; kw...)
    elseif func <: Plot
        return (args...; kw...) -> PlotSpec(field, args...; kw...)
    elseif func <: Block
        return (args...; kw...) -> BlockSpec(field, args...; kw...)
    else
        error("$(field) not a valid Block or Plot function")
    end
end

function update_plot!(obs_to_notify, plot::AbstractPlot, oldspec::PlotSpec, spec::PlotSpec)
    # Update args in plot `input_args` list
    for i in eachindex(spec.args)
        # we should only call update_plot!, if compare_spec(spec_plot_got_created_from, spec) == true,
        # Which should guarantee, that args + kwargs have the same length and types!
        arg_obs = plot.args[i]
        prev_val = oldspec.args[i]
        if is_different(prev_val, spec.args[i]) # only update if different
            arg_obs.val = spec.args[i]
            push!(obs_to_notify, arg_obs)
        end
    end
    scene = parent_scene(plot)
    # Update attributes
    for (attribute, new_value) in spec.kwargs
        old_attr = plot[attribute]
        # only update if different
        if is_different(old_attr[], new_value)
            if new_value isa Cycled
                old_attr.val = to_color(scene, attribute, new_value)
            else
                @debug("updating kw $attribute")
                old_attr.val = new_value
            end
            push!(obs_to_notify, old_attr)
        end
    end

    reset_to_default = setdiff(keys(oldspec.kwargs), keys(spec.kwargs))
    filter!(x -> x != :cycle, reset_to_default) # dont reset cycle
    if !isempty(reset_to_default)
        for k in reset_to_default
            old_attr = plot[k]
            new_value = MakieCore.lookup_default(typeof(plot), parent_scene(plot), k)
            # In case of e.g. dim_conversions
            isnothing(new_value) && continue
            # only update if different
            if is_different(old_attr[], new_value)
                old_attr.val = new_value
                push!(obs_to_notify, old_attr)
            end
        end
    end
    # Cycling needs to be handled separately sadly,
    # since they're implicitely mutating attributes, e.g. if I re-use a plot
    # that has been on cycling position 2, and now I re-use it for the first plot in the list
    # it will need to change to the color of cycling position 1
    if haskey(plot, :cycle)
        cycle = get_cycle_for_plottype(plot.cycle[])
        uncycled = Set{Symbol}()
        for (attr_vec, _) in cycle.cycle
            for attr in attr_vec
                if !haskey(spec.kwargs, attr)
                    push!(uncycled, attr)
                end
            end
        end
        if !isempty(uncycled)
            # remove all attributes that don't need cycling
            for (attr_vec, _) in cycle.cycle
                filter!(x -> x in uncycled, attr_vec)
            end
            add_cycle_attribute!(plot, scene, cycle)
            append!(obs_to_notify, (plot[k] for k in uncycled))
        end
    end
    return
end


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
@recipe(PlotList, plotspecs) do scene
    Attributes()
end

function Base.propertynames(pl::PlotList)
    inner_pnames = if length(pl.plots) == 1
        Base.propertynames(pl.plots[1])
    else
        ()
    end
    return Tuple(unique([keys(pl.attributes)..., inner_pnames...]))
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
    if length(pl.plots) == 1
        setproperty!(pl.plots[1], property, value)
    else
        error("Can't set property $property on PlotList with multiple plots.")
    end
end

convert_arguments(::Type{<:AbstractPlot}, args::AbstractArray{<:PlotSpec}) = (args,)

plottype(::Type{<:Plot{F}}, ::Union{PlotSpec,AbstractVector{PlotSpec}}) where {F} = PlotList
plottype(::Type{<:Plot{F}}, ::Union{GridLayoutSpec,BlockSpec}) where {F} = Plot{plot}
plottype(::Type{<:Plot}, ::Union{GridLayoutSpec,BlockSpec}) = Plot{plot}


function to_plot_object(ps::PlotSpec)
    P = plottype(ps)
    return P((ps.args...,), copy(ps.kwargs))
end


function push_without_add!(scene::Scene, plot)
    MakieCore.validate_attribute_keys(plot)
    for screen in scene.current_screens
        Base.invokelatest(insert!, screen, scene, plot)
    end
end

function diff_plotlist!(
        scene::Scene, plotspecs::Vector{PlotSpec},
        obs_to_notify,
        plotlist::Union{Nothing,PlotList}=nothing,
        reusable_plots = IdDict{PlotSpec, Plot}(),
        new_plots = IdDict{PlotSpec,Plot}())
     # needed to be mutated
    empty!(scene.cycler.counters)
    # Global list of observables that need updating
    # Updating them all at once in the end avoids problems with triggering updates while updating
    # And at some point we may be able to optimize notify(list_of_observables)
    scores = IdDict{Any, Float64}()
    for plotspec in plotspecs
        # we need to compare by types with compare_specs, since we can only update plots if the types of all attributes match
        reused_plot, old_spec = find_reusable_plot(scene, plotspec, reusable_plots, scores)
        if isnothing(reused_plot)
            # Create new plot, store it into our `cached_plots` dictionary
            @debug("Creating new plot for spec")
            # Forward kw arguments from Plotlist
            if !isnothing(plotlist)
                merge!(plotspec.kwargs, plotlist.kw)
            end
            # This is all pretty much `push!(scene, plot)` / `plot!(scene, plotobject)`
            # But we want the scene to only contain one PlotList item with the newly created
            # Plots from the plotlist to only appear as children of the PlotList recipe
            # - so we dont push it to the scene if there's a plotlist.
            # This avoids e.g. double legend entries, due to having the children + plotlist in the same scene without being nested.
            plot_obj = to_plot_object(plotspec)
            connect_plot!(scene, plot_obj)
            if !isnothing(plotlist)
                push!(plotlist.plots, plot_obj)
            else
                push!(scene.plots, plot_obj)
            end
            push_without_add!(scene, plot_obj)
            new_plots[plotspec] = plot_obj
        else
            @debug("updating old plot with spec")
            # Delete the plots from reusable_plots, so that we don't re-use it multiple times!
            delete!(reusable_plots, old_spec)
            if reused_plot.parent !== scene
                @assert Makie.supports_move_to(reused_plot)
                move_to!(reused_plot, scene)
            end
            update_plot!(obs_to_notify, reused_plot, old_spec, plotspec)
            new_plots[plotspec] = reused_plot

        end
    end
    return new_plots
end

function update_plotspecs!(
        scene::Scene, list_of_plotspecs::Observable,
        plotlist::Union{Nothing,PlotList}=nothing,
        unused_plots=IdDict{PlotSpec,Plot}(),
        new_plots=IdDict{PlotSpec,Plot}(),
        own_plots=true
    )
    # Cache plots here so that we aren't re-creating plots every time;
    # if a plot still exists from last time, update it accordingly.
    # If the plot is removed from `plotspecs`, we'll delete it from here
    # and re-create it if it ever returns.
    obs_to_notify = Observable[]
    update_plotlist(spec::PlotSpec) = update_plotlist([spec])
    function update_plotlist(plotspecs)
        # Global list of observables that need updating
        # Updating them all at once in the end avoids problems with triggering updates while updating
        # And at some point we may be able to optimize notify(list_of_observables)
        empty!(scene.cycler.counters) # Reset Cycler
        # diff_plotlist! deletes all plots that get re-used from unused_plots
        # so, this will become our list of unused plots!
        diff_plotlist!(scene, plotspecs, obs_to_notify, plotlist, unused_plots, new_plots)
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
            @assert !any(x-> x in unused_plots, new_plots)
            empty!(unused_plots)
            merge!(unused_plots, new_plots)
            empty!(new_plots)
            # finally, notify all changes at once
        end
        foreach(notify, obs_to_notify)
        empty!(obs_to_notify)
        return
    end
    l = Base.ReentrantLock()
    on(scene, list_of_plotspecs; update=true) do plotspecs
        lock(l) do
            update_plotlist(plotspecs)
        end
        return
    end
    return
end

function Makie.plot!(p::PlotList{<: Tuple{<: Union{PlotSpec, AbstractArray{PlotSpec}}}})
    scene = Makie.parent_scene(p)
    update_plotspecs!(scene, p[1], p)
    return p
end

add_observer!(::BlockSpec, ::Nothing) = nothing
function add_observer!(block::BlockSpec, obs::ObserverFunction)
    push!(block.then_observers, obs)
    return
end

function add_observer!(block::BlockSpec, obs::AbstractVector{<:ObserverFunction})
    append!(block.then_observers, obs)
    return
end

function get_numeric_colors(plot::PlotSpec)
    if plot.type in [:Heatmap, :Image, :Surface]
        z = plot.args[end]
        if z isa AbstractMatrix{<:Real}
            return z
        end
    else
        if haskey(plot.kwargs, :color) && plot.kwargs[:color] isa AbstractArray{<:Real}
            return plot.kwargs[:color]
        end
    end
    return nothing
end

# TODO it's really hard to get from PlotSpec -> Plot object in the
# Colorbar constructor (to_layoutable),
# since the plot may not be created yet and may change when calling
# update_layoutable!. So for now, we manually extract the Colorbar arguments from the spec
# Which is a bit brittle and won't work for Recipes which overload the Colorbar api (extract_colormap)
# We hope to improve the situation after the observable refactor, which may bring us a bit closer to
# Being able to use the Plot object itself instead of a spec.
function extract_colorbar_kw(legend::BlockSpec, scene::Scene)
    if haskey(legend.kwargs, :plotspec)
        kw = copy(legend.kwargs)
        spec = pop!(kw, :plotspec)
        pt = plottype(spec)
        for k in [:colorrange, :colormap, :lowclip, :highclip]
            get!(kw, k) do
                haskey(spec.kwargs, k) && return spec.kwargs[k]
                if k === :colorrange
                    color = get_numeric_colors(spec)
                    if !isnothing(color)
                        return nan_extrema(color)
                    end
                else
                    MakieCore.lookup_default(pt, scene, k)
                end
            end
        end
        return kw
    else
        return legend.kwargs
    end
end

function to_layoutable(parent, position::GridLayoutPosition, spec::BlockSpec)
    BType = getfield(Makie, spec.type)
    fig = get_top_parent(parent)

    block = if spec.type === :Colorbar
        # We use the root scene to extract any theming
        # This means, we dont support a separate theme per scene
        # Which I think has been bitrotting anyways.
        kw = extract_colorbar_kw(spec, root(get_scene(fig)))
        BType(fig; kw...)
    else
        BType(fig; spec.kwargs...)
    end
    parent[position...] = block
    for func in spec.then_funcs
        observers = func(block)
        add_observer!(spec, observers)
    end
    return block
end

function to_layoutable(parent, position::GridLayoutPosition, spec::GridLayoutSpec)
    # TODO pass colsizes  etc
    gl = GridLayout(length(spec.rowsizes), length(spec.colsizes);
                    colsizes=spec.colsizes,
                    rowsizes=spec.rowsizes,
                    colgaps=spec.colgaps,
                    rowgaps=spec.rowgaps,
                    alignmode=spec.alignmode,
                    tellwidth=spec.tellwidth,
                    tellheight=spec.tellheight,
                    halign=spec.halign,
                    valign=spec.valign)
    parent[position...] = gl
    return gl
end

function update_layoutable!(block::T, plot_obs, old_spec::BlockSpec, spec::BlockSpec) where T <: Block
    unhide!(block)
    if spec.type === :Colorbar
        # To get plot defaults for Colorbar(specapi), we need a theme / scene
        # So we have to look up the kwargs here instead of the BlockSpec constructor.
        old_kw = extract_colorbar_kw(old_spec, root(block.blockscene))
        new_kw = extract_colorbar_kw(spec, root(block.blockscene))
    else
        old_kw = old_spec.kwargs
        new_kw = spec.kwargs
    end
    old_attr = keys(old_kw)
    new_attr = keys(new_kw)
    # attributes that have been set previously and need to get unset now
    reset_to_defaults = setdiff(old_attr, new_attr)
    if !isempty(reset_to_defaults)
        default_attrs = default_attribute_values(T, block.blockscene)
        for attr in reset_to_defaults
            setproperty!(block, attr, default_attrs[attr])
        end
    end
    # Attributes needing an update
    to_update = setdiff(new_attr, reset_to_defaults)
    for key in to_update
        val = new_kw[key]
        prev_val = to_value(getproperty(block, key))
        if is_different(val, prev_val)
            setproperty!(block, key, val)
        end
    end
    # Reset the cycler
    if hasproperty(block, :scene)
        empty!(block.scene.cycler.counters)
    end
    if T <: AbstractAxis
        plot_obs[] = spec.plots
        scene = get_scene(block)
        if any(needs_tight_limits, scene.plots)
            tightlimits!(block)
        end
    end
    for observer in old_spec.then_observers
        Observables.off(observer)
    end
    empty!(old_spec.then_observers)
    if hasproperty(spec, :xaxislinks)
        empty!(spec.xaxislinks)
    end
    if hasproperty(spec, :yaxislinks)
        empty!(spec.yaxislinks)
    end
    for func in spec.then_funcs
        observers = func(block)
        add_observer!(spec, observers)
    end
    return to_update, reset_to_defaults
end

function to_gl_key(key::Symbol)
    key === :colgaps && return :addedcolgaps
    key === :rowgaps && return :addedrowgaps
    return key
end

function update_layoutable!(layout::GridLayout, obs, old_spec::Union{GridLayoutSpec, Nothing}, spec::GridLayoutSpec)
    # Block updates until very end where all children etc got deleted!
    layout.block_updates = true
    keys = (:alignmode, :tellwidth, :tellheight, :halign, :valign)
    layout.size = spec.size
    layout.offsets = spec.offsets
    for k in keys
        # TODO! The gridlayout in the top parent figure has a padding from the Figure
        # Since in the SpecApi we can do nested specs with whole figure, we can't create the default there since
        # We don't know which GridLayout will be the main parent.
        # So for now, we just ignore the padding for the top level gridlayout, since we assume the padding in the figurespec is wrong!
        if layout.parent isa Figure && k == :alignmode
            continue
        end
        old_val = isnothing(old_spec) ? nothing : getproperty(old_spec, k)
        new_val = getproperty(spec, k)
        if is_different(old_val, new_val)
            value_obs = getfield(layout, k)
            if value_obs isa Observable
                value_obs[] = new_val
            end
        end
    end
    # TODO update colsizes  etc
    for field in [:size, :offsets, :colsizes, :rowsizes, :colgaps, :rowgaps]
        old_val = isnothing(old_spec) ? nothing : getfield(old_spec, field)
        new_val = getfield(spec, field)
        if is_different(old_val, new_val)
            setfield!(layout, to_gl_key(field), new_val)
        end
    end
    return
end


function update_gridlayout!(gridlayout::GridLayout, nesting::Int, oldgridspec::Union{Nothing, GridLayoutSpec},
                            gridspec::GridLayoutSpec, previous_contents, new_layoutables, global_unused_plots, new_plots)

    update_layoutable!(gridlayout, nothing, oldgridspec, gridspec)
    scores = IdDict{Any, Float64}()
    for (position, spec) in gridspec.content
        # we need to compare by types with compare_specs, since we can only update plots if the types of all attributes match

        idx, old_key, layoutable_obs = find_layoutable((nesting, position, spec), previous_contents, scores)
        if isnothing(layoutable_obs)
            @debug("Creating new content for spec")
            # Create new plot, store it into `new_layoutables`
            new_layoutable = to_layoutable(gridlayout, position, spec)
            obs = Observable(PlotSpec[])
            if new_layoutable isa AbstractAxis
                obs = Observable(spec.plots)
                scene = get_scene(new_layoutable)
                update_plotspecs!(scene, obs, nothing, global_unused_plots, new_plots, false)
                if any(needs_tight_limits, scene.plots)
                    tightlimits!(new_layoutable)
                end
                update_state_before_display!(new_layoutable)
            elseif new_layoutable isa GridLayout
                # Make sure all plots & blocks are inserted
                update_gridlayout!(new_layoutable, nesting + 1, spec, spec, previous_contents,
                                   new_layoutables, global_unused_plots, new_plots)
            end
            push!(new_layoutables, (nesting, position, spec) => (new_layoutable, obs))
        else
            @debug("updating old block with spec")
            # Make sure we don't double re-use a layoutable
            splice!(previous_contents, idx)
            (_, _, old_spec) = old_key
            (layoutable, plot_obs) = layoutable_obs
            gridlayout[position...] = layoutable
            if layoutable isa GridLayout
                update_gridlayout!(layoutable, nesting + 1, old_spec, spec, previous_contents,
                                   new_layoutables, global_unused_plots, new_plots)
            else
                update_layoutable!(layoutable, plot_obs, old_spec, spec)
                update_state_before_display!(layoutable)
            end
            # Carry over to cache it in new_layoutables
            push!(new_layoutables, (nesting, position, spec) => (layoutable, plot_obs))
        end
    end
end

get_layout!(fig::Figure) = fig.layout
get_layout!(gp::Union{GridSubposition,GridPosition}) = GridLayoutBase.get_layout_at!(gp; createmissing=true)


delete_layoutable!(block::Block) = delete!(block)
function delete_layoutable!(grid::GridLayout)
    gc = grid.layoutobservables.gridcontent[]
    if !isnothing(gc)
        GridLayoutBase.remove_from_gridlayout!(gc)
    end
    return
end

function update_gridlayout!(target_layout::GridLayout, layout_spec::GridLayoutSpec, unused_layoutables,
                            new_layoutables, unused_plots, new_plots)
    # For each update we look into `unused_layoutables` to see if we can re-use a layoutable (GridLayout/Block).
    # Every re-used layoutable and every newly created gets pushed into `new_layoutables`,
    # while it gets removed from `unused_layoutables`.
    empty!(new_layoutables)
    update_gridlayout!(
        target_layout, 1, nothing, layout_spec, unused_layoutables,
        new_layoutables, unused_plots, new_plots
    )

    foreach(unused_layoutables) do (p, (block, obs))
        # disconnect! all unused layoutables, so they dont show up anymore
        if block isa Block
            disconnect!(block)
        end
        return
    end
    layouts_to_update = Set{GridLayout}([target_layout])
    for (_, (content, _)) in new_layoutables
        if content isa GridLayout
            push!(layouts_to_update, content)
        else
            gc = GridLayoutBase.gridcontent(content)
            push!(layouts_to_update, gc.parent)
        end
    end
    for l in layouts_to_update
        l.block_updates = false
        GridLayoutBase.update!(l)
    end

    for (_, plot) in unused_plots
        delete!(plot.parent, plot)
    end
    # Transfer all new plots into unused_plots for the next update!
    @assert isempty(unused_plots) || !any(x -> x in unused_plots, new_plots)
    empty!(unused_plots)
    merge!(unused_plots, new_plots)
    empty!(new_plots)
    # finally, notify all changes at once

    # foreach(unused_layoutables) do (p, (block, obs))
    #     # Finally, disconnect all blocks that haven't been used!
    #     disconnect!(block)
    #     return
    # end
    # Finally transfer all new_layoutables into reusable_layoutables,
    # since in the next update they will be the once we re-use
    append!(unused_layoutables, new_layoutables)
    unique!(unused_layoutables)
    return
end

function update_fig!(fig::Union{Figure,GridPosition,GridSubposition}, layout_obs::Observable{GridLayoutSpec})
    # Global list of all layoutables. The LayoutableKey includes a nesting, so that we can keep even nested layouts in one global list.
    # Vector of Pairs should allow to have an identical key without overwriting the previous value
    unused_layoutables = Pair{LayoutableKey, Tuple{Layoutable,Observable{Vector{PlotSpec}}}}[]
    new_layoutables = Pair{LayoutableKey,Tuple{Layoutable,Observable{Vector{PlotSpec}}}}[]
    sizehint!(unused_layoutables, 50)
    sizehint!(new_layoutables, 50)
    l = Base.ReentrantLock()
    layout = get_layout!(fig)
    unused_plots = IdDict{PlotSpec,Plot}()
    new_plots = IdDict{PlotSpec,Plot}()
    on(get_topscene(fig), layout_obs; update=true) do layout_spec
        lock(l) do
            update_gridlayout!(layout, layout_spec, unused_layoutables, new_layoutables,
                               unused_plots, new_plots)
            return
        end
    end
    return fig
end

args_preferred_axis(::GridLayoutSpec) = FigureOnly

plot!(plot::Plot{MakieCore.plot,Tuple{GridLayoutSpec}}) = plot

function plot!(fig::Union{Figure, GridLayoutBase.GridPosition}, plot::Plot{MakieCore.plot,Tuple{GridLayoutSpec}})
    figure = fig isa Figure ? fig : get_top_parent(fig)
    connect_plot!(figure.scene, plot)
    update_fig!(fig, plot.converted[1])
    return fig
end
