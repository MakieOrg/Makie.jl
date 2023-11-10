
using GridLayoutBase: GridLayoutBase

import GridLayoutBase: GridPosition, Side, ContentSize, GapSize, AlignMode, Inner, GridLayout, GridSubposition

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
        if string(type)[end] == '!'
            error("PlotSpec objects are supposed to be used without !, unless when using `S.$(type)(axis::P.Axis, args...; kwargs...)`")
        end
        kw = Dict{Symbol,Any}()
        for (k, v) in kwargs
            # convert eagerly, so that we have stable types for matching later
            # E.g. so that PlotSpec(; color = :red) has the same type as PlotSpec(; color = RGBA(1, 0, 0, 1))
            if v isa Cycled # special case for conversions needing a scene
                kw[k] = v
            elseif v isa Observable
                error("PlotSpec are supposed to be used without Observables")
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
    kwargs::Dict{Symbol,Any}
    plots::Vector{PlotSpec}
end

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
        if !isempty(args)
            error("BlockSpecs, with an exception for Legend, don't support positional arguments yet.")
        end
        return BlockSpec(typ, attr, plots)
    end
end



const GridLayoutPosition = Tuple{UnitRange{Int},UnitRange{Int},Side}

to_span(range::UnitRange{Int}, span::UnitRange{Int}) = (range.start < span.start || range.stop > span.stop) ? error("Range $range not completely covered by spanning range $span.") : range
to_span(range::Int, span::UnitRange{Int}) = (range < span.start || range > span.stop) ? error("Range $range not completely covered by spanning range $span.") : range:range
to_span(::Colon, span::UnitRange{Int}) = span
to_gridposition(rows_cols::Tuple{Any,Any}, rowspan, colspan) = to_gridposition((rows_cols..., Inner()), rowspan, colspan)
to_gridposition(rows_cols_side::Tuple{Any,Any,Any}, rowspan, colspan) = (to_span(rows_cols_side[1], rowspan), to_span(rows_cols_side[2], colspan), rows_cols_side[3])

rangeunion(r1, r2::UnitRange) = min(r1.start, r2.start):max(r1.stop, r2.stop)
rangeunion(r1, r2::Int) = min(r1.start, r2):max(r1.stop, r2)
rangeunion(r1, r2::Colon) = r1

struct GridLayoutSpec
    content::Vector{Pair{GridLayoutPosition,Union{GridLayoutSpec,BlockSpec}}}
    colsizes::Vector{ContentSize}
    rowsizes::Vector{ContentSize}
    colgaps::Vector{GapSize}
    rowgaps::Vector{GapSize}
    alignmode::AlignMode
    tellheight::Bool
    tellwidth::Bool
    halign::Float64
    valign::Float64

    function GridLayoutSpec(
            content::AbstractVector{<:Pair};
            colsizes = nothing,
            rowsizes = nothing,
            colgaps = nothing,
            rowgaps = nothing,
            alignmode::AlignMode = GridLayoutBase.Inside(),
            tellheight::Bool = true,
            tellwidth::Bool = true,
            halign::Union{Symbol,Real} = :center,
            valign::Union{Symbol,Real} = :center,
        )

        rowspan, colspan = foldl(content; init = (1:1, 1:1)) do (rows, cols), ((_rows, _cols, _...), _)
            rangeunion(rows, _rows), rangeunion(cols, _cols)
        end

        content = map(content) do (position, x)
            p = Pair{GridLayoutPosition,Union{GridLayoutSpec,BlockSpec}}(to_gridposition(position, rowspan, colspan), x)
            return p
        end

        nrows = length(rowspan)
        ncols = length(colspan)
        colsizes = GridLayoutBase.convert_contentsizes(ncols, colsizes)
        rowsizes = GridLayoutBase.convert_contentsizes(nrows, rowsizes)
        default_rowgap = Fixed(30) # TODO: where does this come from?
        default_colgap = Fixed(30) # TODO: where does this come from?
        colgaps = GridLayoutBase.convert_gapsizes(ncols - 1, colgaps, default_colgap)
        rowgaps = GridLayoutBase.convert_gapsizes(nrows - 1, rowgaps, default_rowgap)

        halign = GridLayoutBase.halign2shift(halign)
        valign = GridLayoutBase.valign2shift(valign)

        return new(
            content,
            colsizes,
            rowsizes,
            colgaps,
            rowgaps,
            alignmode,
            tellheight,
            tellwidth,
            halign,
            valign,
        )
    end
end

const LayoutEntry = Pair{GridLayoutPosition,Union{GridLayoutSpec,BlockSpec}}

function GridLayoutSpec(v::AbstractVector; kwargs...)
    GridLayoutSpec(reshape(v, :, 1); kwargs...)
end

function GridLayoutSpec(v::AbstractMatrix; kwargs...)
    indices = vec([Tuple(c) for c in CartesianIndices(v)])
    pairs = [
        LayoutEntry((i:i, j:j, GridLayoutBase.Inner()), v[i, j]) for (i, j) in indices
    ]
    GridLayoutSpec(pairs; kwargs...)
end

Figure(pairs::Pair{Any, BlockSpec}...) = FigureSpec(pairs...)
# Figure(::Vector{BlockScpec}) = FigureSpec(GridLayoutSpec([(i, 1) => b for b in blocks]))
# Figure(::Matrix{BlockScpe}) = FigureSpec(pairs...)

struct FigureSpec
    layout::GridLayoutSpec
    kw::Dict{Symbol, Any}
end

function FigureSpec(blocks::Array; padding=theme(:figure_padding)[], kw...)
    return FigureSpec(GridLayoutSpec(blocks; alignmode=Outside(padding)), Dict{Symbol,Any}(kw))
end

function FigureSpec(blocks::Union{BlockSpec, GridLayoutSpec}...; padding=theme(:figure_padding)[], kw...)
    return FigureSpec(GridLayoutSpec(collect(blocks); alignmode=Outside(padding)), Dict{Symbol,Any}(kw))
end
FigureSpec(gls::GridLayoutSpec; kw...) = FigureSpec(gls, Dict{Symbol,Any}(kw))



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

"""
See documentation for specapi.
"""
struct _SpecApi end
const SpecApi = _SpecApi()

function Base.getproperty(::_SpecApi, field::Symbol)
    field === :Figure && return FigureSpec
    field === :GridLayout && return GridLayoutSpec
    # TODO, we wanted to track all recipe names in a set
    # in MakieCore via the recipe macro, but due to precompilation & caching
    # It seems impossible to merge the recipes from all modules
    # Since precompilation will cache only MakieCore's state
    # And once everything is compiled, and MakieCore is loaded into a package
    # The names are loaded from cache and dont contain anything after MakieCore.
    fname = Symbol(replace(string(field), "!" => ""))
    func = getfield(Makie, fname)
    if func isa Function
        return (args...; kw...) -> PlotSpec(field, args...; kw...)
    elseif func <: Block
        return (args...; kw...) -> BlockSpec(field, args...; kw...)
    else
        # TODO better error!
        error("$(field) not a valid Block or Plot function")
    end
end


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

@inline function is_different(a, b)
    # First check if they are the same object
    # This disallows mutating PlotSpec arguments in place
    a === b && return false
    # If they're not the same objcets, we see if they contain the same values
    a == b && return false
    return true
end

function update_plot!(plot::AbstractPlot, spec::PlotSpec)
    # Update args in plot `input_args` list
    any_different = false
    for i in eachindex(spec.args)
        # we should only call update_plot!, if compare_spec(spec_plot_got_created_from, spec) == true,
        # Which should guarantee, that args + kwargs have the same length and types!
        arg_obs = plot.args[i]
        if is_different(to_value(arg_obs), spec.args[i]) # only update if different
            any_different = true
            arg_obs.val = spec.args[i]
        end
    end

    # Update attributes
    to_notify = Symbol[]
    for (attribute, new_value) in spec.kwargs
        old_attr = plot[attribute]
        # only update if different
        if is_different(old_attr[], new_value)
            if new_value isa Cycled
                old_attr.val = to_color(parent_scene(plot), attribute, new_value)
            else
                @debug("updating kw $attribute")
                old_attr.val = new_value
            end
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

convert_arguments(::Type{<:AbstractPlot}, args::AbstractArray{<:PlotSpec}) = (args,)
plottype(::AbstractVector{PlotSpec}) = PlotList

# Since we directly plot into the parent scene (hacky), we need to overload these
Base.insert!(::MakieScreen, ::Scene, ::PlotList) = nothing

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

function to_combined(ps::PlotSpec)
    P = plottype(ps)
    return P((ps.args...,), copy(ps.kwargs))
end

function update_plotspecs!(scene::Scene, list_of_plotspecs::Observable, plotlist::Union{Nothing, PlotList}=nothing)
    # Cache plots here so that we aren't re-creating plots every time;
    # if a plot still exists from last time, update it accordingly.
    # If the plot is removed from `plotspecs`, we'll delete it from here
    # and re-create it if it ever returns.
    l = Base.ReentrantLock()
    cached_plots = IdDict{PlotSpec,Combined}()
    on(scene, list_of_plotspecs; update=true) do plotspecs
        lock(l) do
            old_plots = copy(cached_plots) # needed for set diff
            previoues_plots = copy(cached_plots) # needed to be mutated
            empty!(cached_plots)
            empty!(scene.cycler.counters)
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
                    if !isnothing(plotlist)
                        push!(plotlist.plots, plot)
                    end
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
                if !isnothing(plotlist)
                    filter!(x -> x !== plot, plotlist.plots)
                end
                delete!(scene, plot)
            end
            return
        end
    end
end

function Makie.plot!(p::PlotList{<: Tuple{<: AbstractArray{PlotSpec}}})
    scene = Makie.parent_scene(p)
    update_plotspecs!(scene, p[1], p)
    return
end

## BlockSpec

function compare_layout_slot((anesting, ap, a)::Tuple{Int,GP,BlockSpec}, (bnesting, bp, b)::Tuple{Int,GP,BlockSpec}) where {GP<:GridLayoutPosition}
    anesting !== bnesting && return false
    a.type !== b.type && return false
    ap !== bp && return false
    return true
end

function compare_layout_slot((anesting, ap, a)::Tuple{Int,GP, GridLayoutSpec}, (bnesting, bp, b)::Tuple{Int,GP, GridLayoutSpec}) where {GP <: GridLayoutPosition}
    return anesting === bnesting
end

compare_layout_slot(a, b) = false # types dont match

function to_grid_content(parent, position::GridLayoutPosition, spec::BlockSpec)
    BType = getfield(Makie, spec.type)
    # TODO forward kw
    block = BType(get_top_parent(parent); spec.kwargs...)
    parent[position...] = block
    return block
end

function to_grid_content(parent, position::GridLayoutPosition, spec::GridLayoutSpec)
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

function update_grid_content!(block::T, plot_obs, old_spec::BlockSpec, spec::BlockSpec) where T <: Block
    old_attr = keys(old_spec.kwargs)
    new_attr = keys(spec.kwargs)
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
        val = spec.kwargs[key]
        prev_val = to_value(getproperty(block, key))
        if is_different(val, prev_val)
            setproperty!(block, key, val)
        end
    end
    # Reset the cycler
    if hasproperty(block, :scene)
        empty!(block.scene.cycler.counters)
    end
    plot_obs[] = spec.plots
    return
end

function to_gl_key(key::Symbol)
    key === :colgaps && return :addedcolgaps
    key === :rowgaps && return :addedrowgaps
    return key
end


function update_grid_content!(layout::GridLayout, obs, old_spec::Union{GridLayoutSpec, Nothing}, spec::GridLayoutSpec)
    # Block updates until very end where all children etc got deleted!
    layout.block_updates = true
    keys = (:alignmode, :tellwidth, :tellheight, :halign, :valign)
    layout.size = (length(spec.rowsizes), length(spec.colsizes))
    for k in keys
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
    for field in [:colsizes, :rowsizes, :colgaps, :rowgaps]
        old_val = isnothing(old_spec) ? nothing : getfield(old_spec, field)
        new_val = getfield(spec, field)
        if is_different(old_val, new_val)
            setfield!(layout, to_gl_key(field), new_val)
        end
    end
    layout.size = (length(spec.rowsizes), length(spec.colsizes))
    return
end

function update_gridlayout!(gridlayout::GridLayout, nesting::Int, oldgridspec::Union{Nothing, GridLayoutSpec},
                            gridspec::GridLayoutSpec, used_specs, cached_contents)
    update_grid_content!(gridlayout, nothing, oldgridspec, gridspec)
    for (position, spec) in gridspec.content
        # we need to compare by types with compare_specs, since we can only update plots if the types of all attributes match
        idx = findfirst(x -> compare_layout_slot(x[1], (nesting, position, spec)), cached_contents)
        if isnothing(idx)
            @debug("Creating new content for spec")
            # Create new plot, store it into our `cached_contents` dictionary
            content = to_grid_content(gridlayout, position, spec)
            obs = Observable(PlotSpec[])
            if content isa AbstractAxis
                obs = Observable(spec.plots)
                scene = get_scene(content)
                update_plotspecs!(scene, obs)
                update_state_before_display!(content)
            elseif content isa GridLayout
                update_gridlayout!(content, nesting + 1, spec, spec, used_specs, cached_contents)
            end
            push!(cached_contents, (nesting, position, spec) => (content, obs))
            push!(used_specs, length(cached_contents))
        else
            @debug("updating old block with spec")
            push!(used_specs, idx)
            (_, _, old_spec), (content, plot_obs) = cached_contents[idx]
            if content isa GridLayout
                update_gridlayout!(content, nesting + 1, old_spec, spec, used_specs, cached_contents)
            else
                update_grid_content!(content, plot_obs, old_spec, spec)
                update_state_before_display!(content)
            end
            cached_contents[idx] = (nesting, position, spec) => (content, plot_obs)
        end
    end
    gridlayout.block_updates = false
    GridLayoutBase.update!(gridlayout)
end

get_layout(fig::Figure) = fig.layout
get_layout(gp::Union{GridSubposition,GridPosition}) = GridLayoutBase.get_layout_at!(gp; createmissing=true)

function update_fig!(fig::Union{Figure,GridPosition,GridSubposition}, figure_obs::Observable{FigureSpec})
    # cached_contents = Pair{Tuple{Tuple{Int,GridLayoutPosition},Union{GridLayoutSpec,BlockSpec}},
                        #    Tuple{Union{GridLayout,Block},Observable}}[]
    cached_contents = Pair[]
    l = Base.ReentrantLock()
    pfig = fig isa Figure ? fig : get_top_parent(fig)
    on(pfig.scene, figure_obs; update=true) do figure
        lock(l) do
            used_specs = Set{Int}()
            layout = get_layout(fig)
            update_gridlayout!(layout, 1, nothing, figure.layout, used_specs,
                               cached_contents)
            unused_contents = setdiff(1:length(cached_contents), used_specs)
            # Next, delete all plots that we haven't used
            # TODO, we could just hide them, until we reach some max_plots_to_be_cached, so that we re-create less plots.
            layouts_to_trim = Set{GridLayout}()
            for idx in unused_contents
                _, (block, obs) = cached_contents[idx]
                if block isa GridLayout
                    push!(layouts_to_trim, block)
                else
                    gc = GridLayoutBase.gridcontent(block)
                    push!(layouts_to_trim, gc.parent)
                end
                delete!(block)
                Observables.clear(obs)
            end
            splice!(cached_contents, sort!(collect(unused_contents)))
            foreach(trim!, layouts_to_trim)
            layout.block_updates = false
            GridLayoutBase.update!(layout)
            for (_, (content, _)) in cached_contents
                if content isa GridLayout
                    layout.block_updates = false
                    GridLayoutBase.update!(content)
                end
            end
            return
        end
    end
    return fig
end

args_preferred_axis(::FigureSpec) = FigureOnly

plot!(plot::Combined{MakieCore.plot,Tuple{Makie.FigureSpec}}) = plot

function plot!(fig::Union{Figure, GridLayoutBase.GridPosition}, plot::Combined{MakieCore.plot,Tuple{Makie.FigureSpec}})
    figure = fig isa Figure ? fig : get_top_parent(fig)
    connect_plot!(figure.scene, plot)
    update_fig!(fig, plot[1])
    return fig
end

function apply_convert!(P, attributes::Attributes, x::FigureSpec)
    return (Combined{plot}, (x,))
end

MakieCore.argtypes(::FigureSpec) = Tuple{Nothing}
