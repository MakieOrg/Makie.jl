abstract type AbstractDimConversion end

struct NoDimConversion <: AbstractDimConversion end

struct DimConversions
    conversions::NTuple{3, Observable{Union{Nothing, AbstractDimConversion}}}

    # DimConversions in the first plot of an axis might be discarded to replace
    # these with scene.compute
    sync_graph::ComputeGraph
    sync_nodes::NTuple{3, ComputePipeline.Computed}
end

function DimConversions(graph = ComputeGraph())
    conversions = map((1, 2, 3)) do i
        Observable{Union{Nothing, AbstractDimConversion}}(nothing)
    end
    sync_nodes = ntuple(3) do i
        name = Symbol(:sync_update_, i)
        map!(_dc_sync_callback, graph, Symbol[], name)
        graph[name]
    end
    return DimConversions(conversions, graph, sync_nodes)
end

# TODO: maybe better to use register_computation!() with @nospecialize here?
_dc_sync_callback(args...) = ExplicitUpdate(nothing, :force)

function register_dim_convert_synchronization!(attr, dc::DimConversions, sources)
    return map(enumerate(sources)) do (i, source)
        # shared node for all the update results - trigger this if update did something
        ComputePipeline.push_input!(dc.sync_nodes[i].parent, source)

        # pull from the synchronized output so one plot can pull dc updates from all plots
        name = Symbol(:dim_convert_, i, :_sync)
        add_input!(attr, name, dc.sync_nodes[i])

        return attr[name]
    end
end

####################

dim_observable(conversions::DimConversions, dim::Int) = conversions.conversions[dim]

function Base.getindex(conversions::DimConversions, i::Int)
    return conversions.conversions[i][]
end

function Base.setindex!(conversions::DimConversions, value::Observable, i::Int)
    return on(value; update = true) do val
        conversions[i] = val
    end
end

function needs_dimconvert(conversions::DimConversions)
    for i in 1:3
        if !(conversions[i] isa Union{Nothing, NoDimConversion})
            return true
        end
    end
    return false
end

function Base.setindex!(conversions::DimConversions, value, i::Int)
    isnothing(value) && return # ignore no conversions
    conversions[i] === value && return # ignore same conversion
    if isnothing(conversions[i])
        # only set new conversion if there is none yet
        conversions.conversions[i][] = value
        return
    else
        throw(ArgumentError("Cannot change dim conversion for dimension $i, since it already is set to a conversion: $(conversions[i])."))
    end
end


function convert_dim_value(conversions::DimConversions, dim::Int, value)
    if isnothing(conversions[dim])
        return value
    end
    return convert_dim_value(conversions[dim], value)
end


function convert_dim_value(axislike::AbstractAxis, dim::Int, value)
    return convert_dim_value(get_conversions(axislike), dim, value)
end

convert_dim_value(::NoDimConversion, value) = value
convert_dim_value(::Nothing, value) = value
function convert_dim_value(conversion::AbstractDimConversion, value)
    error("AbstractDimConversion $(typeof(conversion)) not supported for value of type $(typeof(value))")
end


# Interface

"""
    update_dim_conversion!(dim_convert, value, plot_id)

Interface function for updating dim conversions. This is called when arguments
of plots are updated to synchronize the changes.
"""
update_dim_conversion!(conv, values, plot_id) = update_dim_conversion!(conv, values)
function update_dim_conversion!(conv, values)
    str = "The dim_conversion interface now includes \
    `update_dim_conversion!($conv, values[, plot_id])` for updating the dim \
    conversion based on updated argument `values` of a plot. Not implementing \
    this function may result in the dim convert being behind.
    "
    @warn str
    Base.show_backtrace(stdout, Base.backtrace())
    return true
end

# convert_dim_value(conv, attr, value, last_value) = value
function convert_dim_value(conv, attr, value)
    if applicable(convert_dim_value, conv, attr, value, nothing)
        Base.depwarn("`convert_dim_value(dim_convert, attr, value, last)` is deprecated. Implement `convert_dim_value(dim_convert, [attr,] value)` instead", :convert_dim_value)
        return convert_dim_value(conv, attr, value, nothing)
    end
    return convert_dim_value(conv, value)
end

# Helpers

function update_dim_conversion!(conv, values::AbstractArray{<:VecTypes}, plot_id, element_index::Integer)
    dim_view = [v[element_index] for v in values]
    return update_dim_conversion!(conv, dim_view, plot_id)
end
function update_dim_conversion!(conv, values::VecTypes, plot_id, element_index::Integer)
    return update_dim_conversion!(conv, values[element_index], plot_id)
end

update_dim_conversion!(::Nothing, values) = false
update_dim_conversion!(::NoDimConversion, values) = false

function convert_dim_value(conv, plot_id, points::AbstractArray{<:VecTypes}, element_index::Integer)
    isempty(points) && return Float64[]
    dim_value = [p[element_index] for p in points]
    return convert_dim_value(conv, plot_id, dim_value)
end

function convert_dim_value(conv, plot_id, point::VecTypes, element_index::Integer)
    return convert_dim_value(conv, plot_id, point[element_index])
end



# Return instance of AbstractDimConversion for a given type
create_dim_conversion(argument_eltype) = NoDimConversion()
should_dim_convert() = nothing
function convert_dim_observable(::NoDimConversion, value::Observable, deregister)
    return value
end

# get_ticks needs overloading for Dim Conversion
# Which gets ignored for no conversion/nothing
function get_ticks(::Union{Nothing, NoDimConversion}, ticks, scale, formatter, vmin, vmax, show_in_label)
    return get_ticks(ticks, scale, formatter, vmin, vmax)
end

show_dim_convert_in_ticklabel(dc::Union{AbstractDimConversion, Nothing}, ::Automatic) = show_dim_convert_in_ticklabel(dc)
show_dim_convert_in_ticklabel(::Union{AbstractDimConversion, Nothing}) = false
show_dim_convert_in_ticklabel(::Union{AbstractDimConversion, Nothing}, option::Bool) = option

# Should this trigger an error or just return ""?
"""
    add_label_suffix(label, dim_convert, format)

Adds a suffix to `label` based on the given `dim_convert` and formatter `format`.

## Extension

This function is meant to be extended by dim converts. It should generate a
suffix, e.g. a unit like "m", apply the formatter which default adds brackets
"[m]" and then merge it with `label` "\$label [m]".

The `label` is the `x/y/zlabel` set by the user in the parent axis. The `format`
is also set in the parent axis via `x/y/zlabel_suffix`. It may be a function,
formatting string or a string replacing the suffix. It can be applied with
`Makie.apply_format(str, format)` for strings and RichText.

Alternatively you can also implement:
- `get_label_suffix(label, dim_convert, format)` which should return just the suffix in
    as a type that can be merged with `label`. The merging then happens in Makie.
- `get_label_suffix(label, dim_convert)` which leaves the format application to Makie.
- `get_label_suffix(dim_convert)` which avoids specialization on label types. This
    should only ever return a plain String.
"""
function add_label_suffix(label, dc, format)
    return add_label_suffix(label, get_label_suffix(label, dc, format))
end

"""
    get_label_suffix(label, dim_convert, format)
    get_label_suffix(label, dim_convert)
    get_label_suffix(dim_convert)

Returns a label suffix based on the given `dim_convert`.

## Extension

This function or `add_label_suffix` is meant to be extended for new dim converts.
Methods that include `label` should use it to return a label-compatible string
type. I.e. RichText or String for RichText, LaTeXString or String for LaTeXString.
Methods with `format` should apply its formatting, either with `Makie.apply_format`
or manually.
"""
get_label_suffix(label, dc, format) = apply_format(get_label_suffix(label, dc), format)
get_label_suffix(label, dc) = get_label_suffix(dc)::String
get_label_suffix(dc) = error("No axis label suffix defined for conversion $dc.")
get_label_suffix(dc::Union{Nothing, NoDimConversion}) = ""

function add_label_suffix(label::Union{String, LaTeXString}, formatted::Union{String, LaTeXString})
    return isempty(label) ? formatted : latexstring(label, " ", formatted)
end
function add_label_suffix(label::Union{String, RichText}, formatted::Union{String, RichText})
    return isempty(label) ? formatted : rich(label, " ", formatted)
end
function add_label_suffix(label::String, formatted::String)
    return isempty(label) ? formatted : label * ' ' * formatted
end
# TODO: Can we merge RichText + LaTeXString?

# Don't default to generating a suffix for no dim conversion.
# TODO: Maybe allow option cases to go through though so `suffix` can be used w/o dimconverts?
show_dim_convert_in_axis_label(::Union{Nothing, NoDimConversion}, ::Automatic) = false

show_dim_convert_in_axis_label(dc::AbstractDimConversion, ::Automatic) = show_dim_convert_in_axis_label(dc)
show_dim_convert_in_axis_label(::AbstractDimConversion) = true
show_dim_convert_in_axis_label(::Union{AbstractDimConversion, Nothing}, option::Bool) = option

# Recursively gets the dim convert from the plot
# This needs to be recursive to allow recipes to use dim convert
# TODO, should a recipe always set the dim convert to it's parent?
get_conversions(any) = nothing

function get_conversions(ax::AbstractAxis)
    if hasproperty(ax, :scene)
        return get_conversions(ax.scene)
    else
        return nothing
    end
end

function get_conversions(plot::Plot)
    if haskey(plot.kw, :dim_conversions)
        return to_value(plot.kw[:dim_conversions])
    else
        for elem in plot.plots
            x = get_conversions(elem)
            isnothing(x) || return x
        end
    end
    return nothing
end

# For e.g. Axis attributes
function get_conversions(attr::Union{Attributes, Dict, NamedTuple})
    conversions = DimConversions()
    for i in 1:3
        dim_sym = Symbol("dim$(i)_conversion")
        if haskey(attr, dim_sym)
            conversions[i] = to_value(attr[dim_sym])
        end
    end
    return conversions
end

function dim_conversion_from_args(values)
    return create_dim_conversion(get_element_type(values))
end

function connect_conversions!(new_conversions::DimConversions, ax::AbstractAxis)
    for i in 1:3
        dim_sym = Symbol("dim$(i)_conversion")
        if hasproperty(ax, dim_sym)
            # merge
            ax_conversion = getproperty(ax, dim_sym)
            new_conversions[i] = ComputePipeline.get_observable!(ax_conversion, use_deepcopy = false)
            # update in case new_conversions has a new conversion
            setproperty!(ax, dim_sym, new_conversions[i])
            deregister = Ref{Any}(nothing)
            # if the conversion changes, update the axis as well.
            # This should only ever happen once, since conversions are mutable after setting it to a new value
            deregister[] = on(dim_observable(new_conversions, i)) do val
                setproperty!(ax, dim_sym, new_conversions[i])
                off(deregister[])
            end
        end
    end
    return
end

function connect_conversions!(conversions::DimConversions, new_conversions::DimConversions)
    # TODO: Can we avoid this?
    conversions === new_conversions && return

    for i in 1:3
        conversions[i] = new_conversions.conversions[i]
    end

    for i in 1:3
        source_edge = new_conversions.sync_nodes[i].parent
        target_edge = conversions.sync_nodes[i].parent

        # make every input of source trigger target instead
        inputs = vcat(target_edge.inputs, source_edge.inputs)
        ComputePipeline.modify_edge!(target_edge, inputs = inputs)

        # make every node connected to the source output listen to the target
        # output instead (keeping the output of target edge the same)
        for dep in source_edge.dependents
            ComputePipeline.modify_edge!(dep, inputs = target_edge.outputs)
        end

        # We moved all the inputs and output to the target_edge so we can now
        # delete the source edge
        delete!(source_edge)

        # This assumes new_conversions will be replaced by conversions
    end

    return
end

# If axis conversion has global state which needs an update of the tick values,
# This functions needs to be overloaded, returning an observable that updates
# When ticks need to be updated. The concrete value doesn't matterm, since the AbstractDimConversion type will get passed to get_ticks regardless
#=
    obs = needs_tick_update_observable(dim_convert) # make sure we update tick calculation when needed
    ticks = map(obs, ...) do _, args...
        return get_ticks(dim_convert, args...)
    end
=#
needs_tick_update_observable(x) = nothing

function needs_tick_update_observable(conversion::ComputePipeline.Computed)
    return needs_tick_update_observable(ComputePipeline.get_observable!(conversion, use_deepcopy = false))
end

function needs_tick_update_observable(conversion::Observable)
    if isnothing(conversion[])
        # At any point, conversion may change from nothing to an actual AbstractDimConversion
        # so we need to listen for that change and then listen to the updates from that conversion.
        # This should only ever happen once, since you can only change a conversion once, IFF it was nothing.
        tick_update = Observable{Any}(nothing)
        deregister = Ref{Any}(nothing)
        deregister[] = on(conversion) do conversion
            if !isnothing(conversion)
                obs = needs_tick_update_observable(conversion)
                if !isnothing(obs)
                    connect!(tick_update, obs)
                end
                # this one doesn't need to listen anymore, since this update can only happen once
                off(deregister[])
            end
        end
        return tick_update
    else
        return needs_tick_update_observable(conversion[])
    end
end

function init_dim_conversion!(conversions::DimConversions, dim, value, element_idx)
    return init_dim_conversion!(conversions, dim, value)
end

function init_dim_conversion!(conversions::DimConversions, dim, value::VecTypes, element_idx)
    return init_dim_conversion!(conversions, dim, value[element_idx])
end

function init_dim_conversion!(conversions::DimConversions, dim, points::AbstractArray{<:VecTypes}, element_idx)
    isempty(points) && return
    return init_dim_conversion!(conversions, dim, first(points)[element_idx])
end

function init_dim_conversion!(conversions::DimConversions, dim, value)
    conversion = conversions[dim]
    if conversion isa Union{Nothing, NoDimConversion}
        c = dim_conversion_from_args(value)
        return conversions[dim] = c
    end
    return
end

function convert_dim_observable(conversions::DimConversions, dim::Int, value::Observable, deregister)
    conversion = conversions[dim]
    if !(conversion isa Union{Nothing, NoDimConversion})
        return convert_dim_observable(conversion, value, deregister)
    end
    c = dim_conversion_from_args(value[])
    conversions[dim] = c
    return convert_dim_observable(c, value, deregister)
end
