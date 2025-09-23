using GridLayoutBase: GridLayoutBase

import GridLayoutBase: GridPosition, Side, ContentSize, GapSize, AlignMode, Inner, GridLayout, GridSubposition

function symbol_to_specable(sym::Symbol)
    block = symbol_to_block(sym)
    isnothing(block) || return block
    return symbol_to_plot(sym)
end

deref(x) = x
deref(x::Base.RefValue) = x[]

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
            func = hasproperty(Makie, type) ? getproperty(Makie, type) : nothing
            func === nothing && error("PlotSpec need to be existing recipes or Makie plot objects. Found: $(type_str)")
            plot_type = Plot{func}
            type = plotsym(plot_type)
            @warn("PlotSpec objects are supposed to be title case. Found: $(type_str). Please use $(type) instead.")
        end
        kw = Dict{Symbol, Any}()
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
                    kw[k] = deref(convert_attribute(v, Key{k}(), Key{type}()))
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
    kwargs::Dict{Symbol, Any}
    plots::Vector{PlotSpec}
    then_funcs::Set{Function}
    then_observers::Set{ObserverFunction}
    function BlockSpec(type::Symbol, kwargs::Dict{Symbol, Any}, plots::Vector{PlotSpec} = PlotSpec[])
        return new(type, kwargs, plots, Set{Function}(), Set{ObserverFunction}())
    end
end

const GridLayoutPosition = Tuple{UnitRange{Int}, UnitRange{Int}, Side}

struct GridLayoutSpec
    content::Vector{Pair{GridLayoutPosition, Union{GridLayoutSpec, BlockSpec}}}

    size::Tuple{Int, Int}
    offsets::Tuple{Int, Int}

    colsizes::Vector{ContentSize}
    rowsizes::Vector{ContentSize}
    colgaps::Vector{GapSize}
    rowgaps::Vector{GapSize}
    alignmode::AlignMode
    tellheight::Bool
    tellwidth::Bool
    halign::Float64
    valign::Float64
    xaxislinks::Vector{Vector{BlockSpec}}
    yaxislinks::Vector{Vector{BlockSpec}}

    function GridLayoutSpec(
            content::AbstractVector{<:Pair};
            colsizes = nothing,
            rowsizes = nothing,
            colgaps = nothing,
            rowgaps = nothing,
            alignmode::AlignMode = GridLayoutBase.Inside(),
            tellheight::Bool = true,
            tellwidth::Bool = true,
            halign::Union{Symbol, Real} = :center,
            valign::Union{Symbol, Real} = :center,
            xaxislinks = Vector{BlockSpec}[],
            yaxislinks = Vector{BlockSpec}[],
        )
        rowspan, colspan = foldl(content; init = (1:1, 1:1)) do (rows, cols), ((_rows, _cols, _...), _)
            return rangeunion(rows, _rows), rangeunion(cols, _cols)
        end

        content = map(content) do (position, x)
            p = Pair{GridLayoutPosition, Union{GridLayoutSpec, BlockSpec}}(
                to_gridposition(
                    position, rowspan,
                    colspan
                ), x
            )
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

        to_nested(v::AbstractVector{BlockSpec}) = Vector{BlockSpec}[v]
        to_nested(v::AbstractVector{<:AbstractVector{<:BlockSpec}}) = v

        return new(
            content,
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
            valign,
            to_nested(xaxislinks),
            to_nested(yaxislinks),
        )
    end
end


const Layoutable = Union{GridLayout, Block}
const LayoutableSpec = Union{GridLayoutSpec, BlockSpec}
const LayoutEntry = Pair{GridLayoutPosition, LayoutableSpec}
# We use this to decide if we can reuse a plot.
# (nesting_level_in_layout, position_in_layout, spec)
const LayoutableKey = Tuple{Int, GridLayoutPosition, LayoutableSpec}

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

plottype(p::PlotSpec) = symbol_to_plot(p.type)

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
    return p.kwargs[k] = v
end

function Base.getproperty(p::BlockSpec, k::Symbol)
    if k === :then
        return (f) -> push!(p.then_funcs, f)
    end
    k in fieldnames(BlockSpec) && return getfield(p, k)
    return p.kwargs[k]
end
Base.propertynames(p::BlockSpec) = Tuple(keys(p.kwargs))


function BlockSpec(typ::Symbol, args...; plots::Vector{PlotSpec} = PlotSpec[], kw...)
    attr = Dict{Symbol, Any}(kw)
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
function distance_score(a::PlotSpec, b::PlotSpec, scores_dict; maxscore = Inf)
    return hypot(
        distance_score(a.args, b.args, scores_dict; maxscore),
        distance_score(a.kwargs, b.kwargs, scores_dict; maxscore)
    )
end

function distance_score(a::Any, b::Any, scores; maxscore = Inf)
    a === b && return 0.0
    a == b && return 0.0
    typeof(a) == typeof(b) && return 0.01
    return 100.0
end

_has_index(a::Tuple, i) = i <= length(a)
_has_index(a::AbstractVector, i) = checkbounds(Bool, a, i)
_has_index(a::Dict, i) = haskey(a, i)

function distance_score(a::T, b::T, scores_dict; maxscore = Inf) where {T <: AbstractVector{<:Union{Colorant, Real, Point, Vec}}}
    a === b && return 0.0
    a == b && return 0.0
    return 0.1 # we can always update a vector of colors/reals/vecs
end

function distance_score(a::T, b::T, scores_dict; maxscore = Inf) where {T <: Dict{Symbol, Any}}
    a === b && return 0.0
    isempty(a) && isempty(b) && return 0.0
    all_keys = collect(union(keys(a), keys(b)))
    score = 0.0
    for key in all_keys
        score > maxscore && break
        if _has_index(a, key) && _has_index(b, key)
            score = hypot(score, distance_score(a[key], b[key], scores_dict; maxscore))
        else
            score = hypot(score, 1)
        end
    end
    return score
end

function distance_score(a::T, b::T, scores_dict; maxscore = Inf) where {T <: Union{Tuple, AbstractVector}}
    a === b && return 0.0
    isempty(a) && isempty(b) && return 0.0
    common_keys = max(firstindex(a), firstindex(b)):min(lastindex(a), lastindex(b))
    n_different_keys = abs(firstindex(a) - firstindex(b)) + abs(lastindex(a) - lastindex(b))
    score = √n_different_keys
    for key in common_keys
        score > maxscore && break
        score = hypot(score, distance_score(a[key], b[key], scores_dict; maxscore))
    end
    return score
end

function distance_score(a::GridLayoutPosition, b::GridLayoutPosition, scores; maxscore = Inf)
    a === b && return 0.0
    return norm(distance_score.(a, b, Ref(scores); maxscore = Inf))
end

function distance_score(a::BlockSpec, b::BlockSpec, scores_dict; maxscore = Inf)
    a === b && return 0.0
    (a.type !== b.type) && return 100.0 # Can't update when types dont match
    return get!(scores_dict, (a, b)) do
        hypot(
            # keyword arguments are cheap to change
            distance_score(a.kwargs, b.kwargs, scores_dict; maxscore = maxscore / 0.1) * 0.1,
            # Creating plots in a new axis is expensive, so we rather move the axis around
            distance_score(a.plots, b.plots, scores_dict; maxscore),
        )
    end
end

function distance_score(
        at::Tuple{Int, GP, BS}, bt::Tuple{Int, GP, BS},
        scores_dict; maxscore = Inf
    ) where {GP <: GridLayoutPosition, BS <: BlockSpec}
    at === bt && return 0.0
    (anesting, ap, a) = at
    (bnesting, bp, b) = bt
    return hypot(
        abs(anesting - bnesting) * 0.5,
        distance_score(ap, bp, scores_dict; maxscore = maxscore / 0.5) * 0.5,
        distance_score(a, b, scores_dict; maxscore)
    ) |> Float64
end

function distance_score(
        at::Tuple{Int, GP, GridLayoutSpec}, bt::Tuple{Int, GP, GridLayoutSpec},
        scores; maxscore = Inf
    ) where {GP <: GridLayoutPosition}
    at === bt && return 0.0
    anesting, ap, a = at
    bnesting, bp, b = bt
    return get!(scores, (at, bt)) do
        anested = map(ac -> (anesting + 1, ac[1], ac[2]), a.content)
        bnested = map(bc -> (anesting + 1, bc[1], bc[2]), b.content)
        return norm(
            [
                abs(anesting - bnesting),
                distance_score(ap, bp, scores; maxscore),
                distance_score(anested, bnested, scores; maxscore),
            ]
        )
    end
end

_typeof(x) = typeof(x)
_typeof(spec::BlockSpec) = spec.type
_typeof(spec::PlotSpec) = spec.type

function find_min_distance(f, to_compare, list, scores, penalty = (key, score) -> score)
    isempty(list) && return -1
    minscore = 2.0
    idx = -1
    for key in keys(list)
        comparison = f(list[key], key)
        # We can always just match plots of the same type
        _typeof(comparison) !== _typeof(to_compare) && continue
        score = distance_score(to_compare, comparison, scores; maxscore = minscore)
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
        layoutables::Vector{Pair{LayoutableKey, Tuple{Layoutable, Observable{Vector{PlotSpec}}}}},
        scores
    )
    idx = find_min_distance((x, _) -> first(x), nest_pos_spec, layoutables, scores)
    idx == -1 && return 0, nothing, nothing
    return (idx, layoutables[idx]...)
end

function find_reusable_plot(scene::Scene, plotspec::PlotSpec, plots::Vector{Pair{PlotSpec, Plot}}, scores)
    idx = find_min_distance(plotspec, plots, scores) do (spec, p), _
        return spec
    end
    idx == -1 && return nothing, nothing, nothing
    return plots[idx][2], plots[idx][1], idx
end

to_span(range::UnitRange{Int}, span::UnitRange{Int}) = (range.start < span.start || range.stop > span.stop) ? error("Range $range not completely covered by spanning range $span.") : range
to_span(range::Int, span::UnitRange{Int}) = (range < span.start || range > span.stop) ? error("Range $range not completely covered by spanning range $span.") : range:range
to_span(::Colon, span::UnitRange{Int}) = span
to_gridposition(rows_cols::Tuple{Any, Any}, rowspan, colspan) = to_gridposition((rows_cols..., Inner()), rowspan, colspan)
to_gridposition(rows_cols_side::Tuple{Any, Any, Any}, rowspan, colspan) = (to_span(rows_cols_side[1], rowspan), to_span(rows_cols_side[2], colspan), rows_cols_side[3])

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
    # The names are loaded from cache and dont contain anything after
    func = symbol_to_specable(field)
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

function update_plot!(plot::AbstractPlot, oldspec::PlotSpec, spec::PlotSpec)
    oldspec.type === spec.type || error("PlotSpec type $(spec.type) does not match plot type $(plot.type).")
    # Update args in plot `input_args` list
    updates = Dict{Symbol, Any}()
    for i in eachindex(spec.args)
        # we should only call update_plot!, if compare_spec(spec_plot_got_created_from, spec) == true,
        # Which should guarantee, that args + kwargs have the same length and types!
        prev_val = oldspec.args[i]
        if is_different(prev_val, spec.args[i]) # only update if different
            updates[Symbol(:arg, i)] = spec.args[i]
        end
    end
    scene = parent_scene(plot)
    # Update attributes
    for (attribute, new_value) in spec.kwargs
        old_attr = plot[attribute]
        # only update if different
        if is_different(old_attr[], new_value)
            updates[attribute] = new_value
        end
    end

    reset_to_default = setdiff(keys(oldspec.kwargs), keys(spec.kwargs))
    filter!(x -> x != :cycle, reset_to_default) # dont reset cycle
    if !isempty(reset_to_default)
        for k in reset_to_default
            old_attr = plot[k][]
            new_value = lookup_default(typeof(plot), parent_scene(plot), k)
            # In case of e.g. dim_conversions
            isnothing(new_value) && continue
            # only update if different
            if is_different(old_attr, new_value)
                updates[k] = new_value
            end
        end
    end
    update!(plot, updates)
    return updates
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

is_atomic_plot(plot::PlotList) = false # is never atomic

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

convert_arguments(::Type{<:AbstractPlot}, args::AbstractArray{<:PlotSpec}) = (args,)

plottype(::Type{<:Plot{F}}, ::Union{PlotSpec, AbstractVector{PlotSpec}}) where {F} = PlotList
plottype(::Type{<:Plot{F}}, ::Union{GridLayoutSpec, BlockSpec}) where {F} = Plot{plot}
plottype(::Type{<:Plot}, ::Union{GridLayoutSpec, BlockSpec}) = Plot{plot}


function to_plot_object(ps::PlotSpec)
    P = plottype(ps)
    return P((ps.args...,), copy(ps.kwargs))
end


function push_without_add!(scene::Scene, plot)
    validate_attribute_keys(plot)
    for screen in scene.current_screens
        Base.invokelatest(insert!, screen, scene, plot)
    end
    return
end

function plot_cycle_index(specs, spec::PlotSpec, plot::Plot)
    cycle = plot.cycle[]
    isnothing(cycle) && return 0
    syms = [s for ps in attrsyms(cycle) for s in ps]
    pos = 1
    for p in specs
        p === spec && return pos
        if haskey(p.kwargs, :cycle) && !isnothing(p.kwargs[:cycle]) && plotfunc(p) === plotfunc(spec)
            is_cycling = any(syms) do x
                return haskey(p.kwargs, x) && isnothing(p[x])
            end
            if is_cycling
                pos += 1
            end
        end
    end
    # not inserted yet
    return pos
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
        if isnothing(reused_plot)
            # Create new plot, store it into our `cached_plots` dictionary
            @debug("Creating new plot for spec")

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
            # Delete the plots from reusable_plots, so that we don't reuse it multiple times!
            delete!(reusable_plots, old_spec)
            deleteat!(reusable_plots_sorted, idx)
            # Update the position of the plot!
            pos = plot_cycle_index(plotspecs, plotspec, reused_plot)
            if pos != reused_plot.cycle_index[]
                reused_plot.cycle_index = pos
            end
            update_plot!(reused_plot, old_spec, plotspec)
            new_plots[plotspec] = reused_plot

        end
    end
    return new_plots
end

function update_plotspecs!(
        scene::Scene, list_of_plotspecs::Observable,
        plotlist::Union{Nothing, PlotList} = nothing,
        unused_plots = IdDict{PlotSpec, Plot}(),
        new_plots = IdDict{PlotSpec, Plot}(),
        own_plots = true
    )
    # Cache plots here so that we aren't re-creating plots every time;
    # if a plot still exists from last time, update it accordingly.
    # If the plot is removed from `plotspecs`, we'll delete it from here
    # and re-create it if it ever returns.
    update_plotlist(spec::PlotSpec) = update_plotlist([spec])
    function update_plotlist(plotspecs)
        # Global list of observables that need updating
        # Updating them all at once in the end avoids problems with triggering updates while updating
        # And at some point we may be able to optimize notify(list_of_observables)
        # diff_plotlist! deletes all plots that get reused from unused_plots
        # so, this will become our list of unused plots!
        diff_plotlist!(scene, plotspecs, plotlist, unused_plots, new_plots)
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
    l = Base.ReentrantLock()
    on(scene, list_of_plotspecs; update = true) do plotspecs
        lock(l) do
            update_plotlist(plotspecs)
        end
        return
    end
    return
end

function Makie.plot!(p::PlotList{<:Tuple{<:Union{PlotSpec, AbstractArray{PlotSpec}}}})
    scene = Makie.parent_scene(p)
    arg_obs = ComputePipeline.get_observable!(p.converted; use_deepcopy = false)
    obs = map(first, arg_obs)
    update_plotspecs!(scene, obs, p)
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
                    lookup_default(pt, scene, k)
                end
            end
        end
        return kw
    else
        return legend.kwargs
    end
end

function to_layoutable(parent, position::GridLayoutPosition, spec::BlockSpec)
    BType = symbol_to_block(spec.type)
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
    gl = GridLayout(
        length(spec.rowsizes), length(spec.colsizes);
        colsizes = spec.colsizes,
        rowsizes = spec.rowsizes,
        colgaps = spec.colgaps,
        rowgaps = spec.rowgaps,
        alignmode = spec.alignmode,
        tellwidth = spec.tellwidth,
        tellheight = spec.tellheight,
        halign = spec.halign,
        valign = spec.valign
    )
    parent[position...] = gl
    return gl
end

function update_layoutable!(block::T, plot_obs, old_spec::BlockSpec, spec::BlockSpec) where {T <: Block}
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
    if T <: AbstractAxis
        plot_obs[] = spec.plots
        score = distance_score(old_spec.plots, spec.plots, Dict())
        if score >= 1.0
            scene = get_scene(block)
            if any(needs_tight_limits, scene.plots)
                tightlimits!(block)
            end
        end
    end
    for observer in old_spec.then_observers
        Observables.off(observer)
    end
    empty!(old_spec.then_observers)

    for func in spec.then_funcs
        observers = func(block)
        add_observer!(spec, observers)
    end
    unhide!(block) # in case we hid it before
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

function replace_links!(axis_links::Vector, new_links::Set)
    Set(axis_links) == new_links && return false
    empty!(axis_links)
    append!(axis_links, new_links)
    return true
end

function update_axis_links!(gridspec, all_layoutables)
    # axes that should be linked
    axes = Dict{BlockSpec, Axis}()
    for ((_, _, ax_spec), (ax_object, _)) in all_layoutables
        if ax_spec isa BlockSpec && ax_spec.type === :Axis
            axes[ax_spec] = ax_object
        end
    end

    for (spec, ax) in axes
        empty!(ax.xaxislinks)
        empty!(ax.yaxislinks)
    end

    for linkgroup in gridspec.xaxislinks
        for linked in linkgroup
            append!(axes[linked].xaxislinks, [axes[spec] for spec in linkgroup])
        end
    end
    for linkgroup in gridspec.yaxislinks
        for linked in linkgroup
            append!(axes[linked].yaxislinks, [axes[spec] for spec in linkgroup])
        end
    end

    for (spec, ax) in axes
        unique!(ax.xaxislinks)
        unique!(ax.yaxislinks)
    end

    return
end

get_type(x::BlockSpec) = x.type
get_type(::GridLayoutSpec) = :GridLayout

function update_gridlayout!(
        gridlayout::GridLayout, nesting::Int, oldgridspec::Union{Nothing, GridLayoutSpec},
        gridspec::GridLayoutSpec, previous_contents, new_layoutables
    )

    update_layoutable!(gridlayout, nothing, oldgridspec, gridspec)
    scores = IdDict{Any, Float64}()
    for (position, spec) in gridspec.content
        # we need to compare by types with compare_specs, since we can only update plots if the types of all attributes match

        idx, old_key, layoutable_obs = find_layoutable((nesting, position, spec), previous_contents, scores)
        if isnothing(layoutable_obs)
            @debug("Creating new block for spec: $(get_type(spec))")
            # Create new plot, store it into `new_layoutables`
            new_layoutable = to_layoutable(gridlayout, position, spec)
            obs = Observable(PlotSpec[])
            if new_layoutable isa AbstractAxis
                obs = Observable(spec.plots)
                scene = get_scene(new_layoutable)
                update_plotspecs!(scene, obs)
                if any(needs_tight_limits, scene.plots)
                    tightlimits!(new_layoutable)
                end
                update_state_before_display!(new_layoutable)
            elseif new_layoutable isa GridLayout
                # Make sure all plots & blocks are inserted
                update_gridlayout!(
                    new_layoutable, nesting + 1, spec, spec, previous_contents,
                    new_layoutables
                )
            end
            push!(new_layoutables, (nesting, position, spec) => (new_layoutable, obs))
        else
            @debug("updating old block with spec: $(get_type(spec))")
            # Make sure we don't double reuse a layoutable
            splice!(previous_contents, idx)
            (a_, oldpos, old_spec) = old_key
            (layoutable, plot_obs) = layoutable_obs
            gridlayout[position...] = layoutable
            if layoutable isa GridLayout
                update_gridlayout!(
                    layoutable, nesting + 1, old_spec, spec, previous_contents,
                    new_layoutables
                )
            else
                update_layoutable!(layoutable, plot_obs, old_spec, spec)
                # update_state_before_display!(layoutable)
            end
            # Carry over to cache it in new_layoutables
            push!(new_layoutables, (nesting, position, spec) => (layoutable, plot_obs))
        end
    end
    update_axis_links!(gridspec, new_layoutables)
    return
end

get_layout!(fig::Figure) = fig.layout
get_layout!(gp::Union{GridSubposition, GridPosition}) = GridLayoutBase.get_layout_at!(gp; createmissing = true)


delete_layoutable!(block::Block) = delete!(block)
function delete_layoutable!(grid::GridLayout)
    gc = grid.layoutobservables.gridcontent[]
    if !isnothing(gc)
        GridLayoutBase.remove_from_gridlayout!(gc)
    end
    return
end

function update_gridlayout!(
        target_layout::GridLayout, layout_spec::GridLayoutSpec, unused_layoutables,
        new_layoutables
    )
    # For each update we look into `unused_layoutables` to see if we can reuse a layoutable (GridLayout/Block).
    # Every reused layoutable and every newly created gets pushed into `new_layoutables`,
    # while it gets removed from `unused_layoutables`.
    empty!(new_layoutables)
    update_gridlayout!(
        target_layout, 1, nothing, layout_spec, unused_layoutables,
        new_layoutables
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

    # finally, notify all changes at once

    # foreach(unused_layoutables) do (p, (block, obs))
    #     # Finally, disconnect all blocks that haven't been used!
    #     disconnect!(block)
    #     return
    # end
    # Finally transfer all new_layoutables into reusable_layoutables,
    # since in the next update they will be the once we reuse
    append!(unused_layoutables, new_layoutables)
    unique!(unused_layoutables)
    return
end

function update_fig!(fig::Union{Figure, GridPosition, GridSubposition}, layout_obs::Observable{GridLayoutSpec})
    # Global list of all layoutables. The LayoutableKey includes a nesting, so that we can keep even nested layouts in one global list.
    # Vector of Pairs should allow to have an identical key without overwriting the previous value
    unused_layoutables = Pair{LayoutableKey, Tuple{Layoutable, Observable{Vector{PlotSpec}}}}[]
    new_layoutables = Pair{LayoutableKey, Tuple{Layoutable, Observable{Vector{PlotSpec}}}}[]
    sizehint!(unused_layoutables, 50)
    sizehint!(new_layoutables, 50)
    l = Base.ReentrantLock()
    layout = get_layout!(fig)
    on(get_topscene(fig), layout_obs; update = true) do layout_spec
        lock(l) do
            update_gridlayout!(layout, layout_spec, unused_layoutables, new_layoutables)
            return
        end
    end
    return fig
end

args_preferred_axis(::GridLayoutSpec) = FigureOnly

plot!(plot::Plot{plot, Tuple{GridLayoutSpec}}) = plot

function plot!(fig::Union{Figure, GridLayoutBase.GridPosition}, plot::Plot{plot, Tuple{GridLayoutSpec}})
    figure = fig isa Figure ? fig : get_top_parent(fig)
    connect_plot!(figure.scene, plot)
    obs = ComputePipeline.get_observable!(plot.converted; use_deepcopy = false)
    grid = map(first, obs)
    update_fig!(fig, grid)
    return fig
end
