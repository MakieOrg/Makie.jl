"""
    abstract type AbstractDimConversion

Parent type of all dim converts.

To define a new dim convert one needs to define

```julia
struct MyDimConvert <: AbstractDimConversion
    ...
end
```

And implement the following interface functions:
- `create_dim_conversion(eltype) = MyDimConvert(...)` creates the dim convert for
    a set of types specified through dispatch.
- `update_dim_conversion(dc::MyDimConvert, values[, plot_id])` updates the dim
    convert based on new `values`. Returns `true` if the dim convert changed to
    notify other plots of those changes.
- `convert_dim_value(dc::MyDimConvert, [plot_id,], values)` converts `values`
    according to the current state of the dim convert and returns them.

For compatibility with `Axis` a dim convert must further implement:
- `get_ticks(dc::MyDimConvert, ticks, scale, formatter, vmin, vmax, show_in_label)`
    to generate ticks for the given dim convert.

For compatibility with axis labels a dim convert must implement one of:
- `get_label_suffix(dc::MyDimConvert)` to define the suffix used in axis labels
- `get_label_suffix(label, dc)` ... that is compatible with the `label` type
- `get_label_suffix(label, dc, formatter)` ... and formatted by `formatter`
- `add_label_suffix(label, dc, formatter)` to define the complete label with
    the suffix added and the `formatter` applied

Optionally the following functions can be extended:
- `show_dim_convert_in_ticklabel(::MyDimConvert) = false` to set whether suffixes
    are added to tick labels by default
- `show_dim_convert_in_axis_label(::MyDimConvert) = true` to set whether suffixes
    are added to axis label by default
"""
abstract type AbstractDimConversion end

struct NoDimConversion <: AbstractDimConversion end

################################################################################
# Extension Interface (<: AbstractDimConversion)
################################################################################

"""
    create_dim_conversion(argument_eltype)

Defines which `dim_convert::AbstractDimConversion` is used for a given argument
element type.
"""
create_dim_conversion(argument_eltype) = NoDimConversion()

"""
    update_dim_conversion!(dim_convert, values[, plot_id])

Interface function for updating dim conversions.

This is called with the `values` relevant to the given `dim_convert` whenever
those are updated. An implementation should update the `dim_convert` if
necessary and `return true` if changes have been made.

If needed, the `plot_id` can be used as a unique identifier of the plot from
which the `values` are sourced.
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

"""
    convert_dim_value(dim_convert::AbstractDimConversion, [plot_id::UInt64], values)

Interface function for converting `values` according to the given `dim_convert`.
This is called after `update_dim_conversion!` with a `dim_convert` that is
synchronized over all plots using that dim convert.

If needed, the `plot_id` can be used as a unique identifier of the plot from
which the `values` are sourced. (This matches `update_dim_conversion!`.)
"""
function convert_dim_value(conv, attr, value)
    if applicable(convert_dim_value, conv, attr, value, nothing)
        Base.depwarn("`convert_dim_value(dim_convert, attr, value, last)` is deprecated. Implement `convert_dim_value(dim_convert, [attr,] value)` instead", :convert_dim_value)
        return convert_dim_value(conv, attr, value, nothing)
    end
    return convert_dim_value(conv, value)
end
function convert_dim_value(conversion::AbstractDimConversion, value)
    error("AbstractDimConversion $(typeof(conversion)) not supported for value of type $(typeof(value))")
end

################################################################################
# Extension Interface (Axis ticks, labels, etc)
################################################################################

# get_ticks needs overloading for Dim Conversion
# Which gets ignored for no conversion/nothing
"""
    get_ticks(dim_convert, ticks, scale, formatter, vmin, vmax, show_in_label)

Interface function for generating ticks for a specific `dim_convert`.
"""
function get_ticks(::Union{Nothing, NoDimConversion}, ticks, scale, formatter, vmin, vmax, show_in_label)
    return get_ticks(ticks, scale, formatter, vmin, vmax)
end

# Should this trigger an error or just return ""?
"""
    add_label_suffix(label, dim_convert, format)

Adds a suffix to `label` based on the given `dim_convert` and formatter `format`.

## Extension

This function or `get_label_suffix` is meant to be extended by dim converts. It
should generate a suffix, e.g. a unit like "m", apply the formatter which default
adds brackets "[m]" and then merge it with `label` "\$label [m]".

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


"""
    show_dim_convert_in_ticklabel(dim_convert)

Interface function for setting whether dim convert suffixes appear in tick labels
by default. Users can overwrite this through axis settings.

If not implemented `false` is chosen as the default.

A method of `show_dim_convert_in_ticklabel(dim_convert, ::Bool)` can be added to
overwrite the users choice.
"""
show_dim_convert_in_ticklabel(dc::Union{AbstractDimConversion, Nothing}, ::Automatic) = show_dim_convert_in_ticklabel(dc)
show_dim_convert_in_ticklabel(::Union{AbstractDimConversion, Nothing}) = false
show_dim_convert_in_ticklabel(::Union{AbstractDimConversion, Nothing}, option::Bool) = option

"""
    show_dim_convert_in_axis_label(dim_convert)

Interface function for setting whether dim convert suffixes appear in axis labels
by default. Users can overwrite this through axis settings.

If not implemented `true` is chosen as the default.

A method of `show_dim_convert_in_axis_label(dim_convert, ::Bool)` can be added to
overwrite the users choice.
"""
show_dim_convert_in_axis_label(dc::AbstractDimConversion, ::Automatic) = show_dim_convert_in_axis_label(dc)
show_dim_convert_in_axis_label(::AbstractDimConversion) = true
show_dim_convert_in_axis_label(::Union{AbstractDimConversion, Nothing}, option::Bool) = option


################################################################################
# NoDimConversion, Nothing

# update_dim_conversion!(::Nothing, values) = false
update_dim_conversion!(::Union{Nothing, NoDimConversion}, values) = false


convert_dim_value(::Union{Nothing, NoDimConversion}, value) = value
# convert_dim_value(::Nothing, value) = value

get_label_suffix(dc::Union{Nothing, NoDimConversion}) = ""

# Don't default to generating a suffix for no dim conversion.
# TODO: Maybe allow option cases to go through though so `suffix` can be used w/o dimconverts?
show_dim_convert_in_axis_label(::Union{Nothing, NoDimConversion}, ::Automatic) = false

################################################################################
# argument_dims interfacing
################################################################################

function update_dim_conversion!(conv, values::AbstractArray{<:VecTypes}, plot_id, element_index::Integer)
    dim_view = [v[element_index] for v in values]
    return update_dim_conversion!(conv, dim_view, plot_id)
end
function update_dim_conversion!(conv, values::VecTypes, plot_id, element_index::Integer)
    return update_dim_conversion!(conv, values[element_index], plot_id)
end

function convert_dim_value(conv, plot_id, points::AbstractArray{<:VecTypes}, element_index::Integer)
    isempty(points) && return Float64[]
    dim_value = [p[element_index] for p in points]
    return convert_dim_value(conv, plot_id, dim_value)
end

function convert_dim_value(conv, plot_id, point::VecTypes, element_index::Integer)
    return convert_dim_value(conv, plot_id, point[element_index])
end

################################################################################
# Plot Interface/general setup
################################################################################

struct DimConversions
    # DimConversions in the first plot of an axis might be discarded to replace
    # these with scene.compute
    sync_graph::ComputeGraph
    sync_nodes::NTuple{3, ComputePipeline.Computed}
end

# TODO: is this worth it?
const DIM_CONVERT_NAMES = (:dim_convert_1, :dim_convert_2, :dim_convert_3, :dim_convert_4)

# TODO: maybe better to use register_computation!() with @nospecialize here?
_dc_sync_callback(args...) = ExplicitUpdate(nothing, :force)

# 1. Construct DimConversions
# This is constructed with a temporary ComputeGraph() for `f, a, p = plot(...)`
# calls. Otherwise this is constructed once by scene and passed around.
function DimConversions(graph = ComputeGraph())
    sync_nodes = ntuple(3) do i
        name = Symbol("sync_update_$i")
        map!(_dc_sync_callback, graph, Symbol[], name)
        graph[name]
    end
    return DimConversions(graph, sync_nodes)
end

# 1.5 check if the plot needs to use dim converts due to them being defined in the scene
needs_dimconvert(conversions::DimConversions) = any(i -> needs_dimconvert(conversions, i), 1:3)

function needs_dimconvert(conversions::DimConversions, dim)
    graph = conversions.sync_graph
    name = DIM_CONVERT_NAMES[dim]
    # DimConversions can be initialized by Axis to have dim_convert_$i = nothing
    return haskey(graph, name) && !isa(get_input(graph[name]).value, Union{Nothing, NoDimConversion})
end

# dim converts are connected as a 1:1 chain, so we can trace back to the input (in axis or scene).
get_input(node::ComputePipeline.Computed) = get_input(node.parent)
get_input(input::ComputePipeline.Input) = input
get_input(edge::ComputePipeline.ComputeEdge) = get_input(only(edge.inputs))

# 2. initialize dim_converts in DimConversions
function init_dim_conversion!(conversions::DimConversions, dim, values)
    dc = dim_conversion_from_args(values)
    init_dim_conversion!(conversions, dim, dc)
    return
end

function init_dim_conversion!(conversions::DimConversions, dim, values, element_idx)
    dc = dim_conversion_from_args(values, element_idx)
    init_dim_conversion!(conversions, dim, dc)
    return
end

function init_dim_conversion!(::DimConversions, dim, ::Nothing)
    error("dim_conversion_from_args() should always return a dim convert")
end

function init_dim_conversion!(conversions::DimConversions, dim, dc::AbstractDimConversion)
    name = DIM_CONVERT_NAMES[dim]

    if !haskey(conversions.sync_graph, name)
        add_input!(conversions.sync_graph, name, dc)
    elseif isnothing(get_input(conversions.sync_graph[name]).value)
        # ^ avoid resolve to not lock in `nothing` (from axis)
        get_input(conversions.sync_graph[name])[] = dc
    end

    # lock in dim convert
    conversions.sync_graph[name][]

    return
end

dim_conversion_from_args(values) = create_dim_conversion(get_element_type(values))
dim_conversion_from_args(values, dim) = create_dim_conversion(get_element_type(values, dim))

get_element_type(::T) where {T} = T
get_element_type(t::Tuple) = get_element_type(first(t))
function get_element_type(arr::AbstractArray{T}) where {T}
    if isempty(arr)
        return T
    elseif T == Any
        return mapreduce(typeof, promote_type, arr)
    else
        return T
    end
end

get_element_type(x, idx) = typeof(x[idx])
get_element_type(::Type{T}, idx) where {T} = T # What should this be?

get_element_type(::Colorant{T}, idx) where {T} = T
get_element_type(::VecTypes{N, T}, idx) where {N, T} = T
get_element_type(t::Tuple, idx) = typeof(t[idx])

get_element_type(::Type{<:Colorant{T}}, idx) where {T} = T
get_element_type(::Type{<:VecTypes{N, T}}, idx) where {N, T} = T
get_element_type(T::Type{<:Tuple}, idx) = fieldtypes(T)[idx]

function get_element_type(arr::AbstractArray{T}, dim) where {T}
    if isempty(arr)
        return get_element_type(T, dim)
    elseif T == Any
        return mapreduce(x -> typeof(x[dim]), promote_type, arr)
    else
        return get_element_type(first(arr), dim)
    end
end

# 3. Let the plot grab the dim_converts it needs and implement `update_dim_conversion!()` callbacks
# ...

# 4. Feed the `update_dim_conversion` results back to DimConversions for synchronization
# across all plots that share DimConversions.
function register_dim_convert_synchronization!(attr, dc::DimConversions, sources)
    return map(sources) do (i, source)
        # shared node for all the update results - trigger this if update did something
        ComputePipeline.push_input!(dc.sync_nodes[i].parent, source)

        # pull from the synchronized output so one plot can pull dc updates from all plots
        name = Symbol(:dim_convert_, i, :_sync)
        add_input!(attr, name, dc.sync_nodes[i])

        return attr[name]
    end
end

# 5. Let the plot implement convert_dim_value() computations to resolve dim converts
# ...

########################################
# Connecting plot - scene - axis
########################################

# Connect the dim converts of an axis with those of the underlying scene
# and add synchronization nodes to the axis
function connect_conversions!(new_conversions::DimConversions, ax::AbstractAxis)
    for i in 1:3
        dim_sym = Symbol("dim$(i)_conversion")
        if hasproperty(ax, dim_sym)
            name = DIM_CONVERT_NAMES[i]
            ax_node = ax.attributes[dim_sym]

            if haskey(new_conversions.sync_graph, name)
                # plot initialized dim_convert first - merge with axis
                dc_node = new_conversions.sync_graph[name]
                if isnothing(ax_node[]) && !isnothing(dc_node[])
                    ax.attributes[dim_sym] = local_value
                end

                # connect scene dim_convert_$i to axis dim$i_conversion
                ComputePipeline.replace_input!(compute_identity, ax_node, dc_node)
            else
                # axis is first to initialize
                add_input!(new_conversions.sync_graph, name, ax_node)
            end
        end
    end
    return
end

# Connect axis ticks to dim converts (so they can add categories, for example)

# TODO: maybe it makes sense to split xticks -> xtickvalues, xticklabels early?
with_tickvalues(func, ticks::Tuple, fallback = nothing) = func(ticks[1])
with_tickvalues(func, ticks::AbstractVector, fallback = nothing) = func(ticks)
with_tickvalues(func, ticks::Categorical, fallback = nothing) = func(ticks)
with_tickvalues(func, ticks, fallback = nothing) = fallback

function register_dim_convert_synchronization!(
        ax::AbstractAxis;
        ticks = [:xticks, :yticks, :zticks],
        dim_converts = [:dim1_conversion, :dim2_conversion, :dim3_conversion],
        local_updates = [:local_dc_update1, :local_dc_update2, :local_dc_update3],
        dims = 1:3
    )
    axis_id = objectid(ax.attributes)

    for (dc_name, ticks_name, update_name) in zip(dim_converts, ticks, local_updates)
        hasproperty(ax, dc_name) || continue

        # Allows ticks to initialize dim[i]_conversion at any time
        on(ax.attributes[ticks_name], update = true) do ticks
            if isnothing(ax.attributes[dc_name][]) # if not set yet
                with_tickvalues(ticks) do tickvalues # and we have tickvalues
                    dc = dim_conversion_from_args(tickvalues)
                    if !isa(dc, AbstractDimConversion)
                        error("dim_conversion_from_args() should always return a dim convert, but returned $dc for $(typeof(tickvalues))")
                    end
                    update!(ax, dc_name => dc)
                end
            end
            return
        end

        # Allow ticks to update dim converts, e.g. add more categories
        map!(ax, [dc_name, ticks_name], update_name) do dc, ticks
            changed = with_tickvalues(ticks, false) do tickvalues
                update_dim_conversion!(dc, tickvalues, axis_id)
            end
            return ExplicitUpdate(changed, changed ? :force : :deny)
        end
    end

    # Connect synchronized nodes
    sources = [i => ax.attributes[name] for (i, name) in zip(dims, local_updates) if hasproperty(ax, name)]
    register_dim_convert_synchronization!(ax.attributes, ax.scene.conversions, sources)

    return
end

# Connect a plot's local DimConversions (new_conversions) to a scenes DimConversions
# (conversions). This should only be relevant for `f, a, p = plot()` calls
function connect_conversions!(conversions::DimConversions, new_conversions::DimConversions)
    # If we still hit this just return immediately
    @assert conversions !== new_conversions

    for i in 1:3
        name = DIM_CONVERT_NAMES[i]
        # @assert !haskey(conversions.sync_graph, name) "Shouldn't be overwriting a scene with initialized dim converts"

        if haskey(new_conversions.sync_graph, name)
            source_dc = new_conversions.sync_graph[name]

            if haskey(conversions.sync_graph, name)
                get_input(conversions.sync_graph[name])[] = source_dc[]
            else
                add_input!(conversions.sync_graph, name, source_dc[])
            end

            # move dependencies
            for dep in source_dc.parent.dependents
                ComputePipeline.modify_edge!(dep, inputs = [conversions.sync_graph[name]])
            end
        end
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

################################################################################

"""
    update_sync_convert_dim_value(dim_convert, plot_id, value)

Updates the given `dim_convert` based on the given `value` and `plot_id`,
synchronizes with other sources and then converts the given `value`.

**Warning**: Calling this from a compute edge may cause issues/error.

**Warning**: Using this means that other dim_convert sources can not pull updates
from `values` into the dim convert before resolving their own values. This may
cause information from `values` to be 1 frame/update behind.
"""
function update_sync_convert_dim_value(sync_node::Computed, dc::Union{Nothing, AbstractDimConversion}, plot_id, values)
    # apply changes from values to dim convert
    changed = update_dim_conversion!(dc, values, plot_id)
    # notify other sources of changed dim converts
    changed && notify(sync_node)
    # pull in changes from other sources
    sync_node[]
    # and finally convert
    return convert_dim_value(dc, plot_id, values)
end

function update_sync_convert_dim_value(ax::AbstractAxis, dim::Int, value)
    name = DIM_CONVERT_NAMES[dim]
    plot_id = objectid(ax)
    dc = ax.scene.compute[name][]
    sync_node = ax.scene.compute[Symbol("sync_update_$dim")]
    return update_sync_convert_dim_value(sync_node, dc, plot_id, value)
end

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
            add_input!(conversions.sync_graph, DIM_CONVERT_NAMES[i], to_value(attr[dim_sym]))
        end
    end
    return conversions
end

function Base.getindex(conv::DimConversions, i::Integer)
    if haskey(conv.sync_graph, DIM_CONVERT_NAMES[i])
        return conv.sync_graph[DIM_CONVERT_NAMES[i]][]
    else
        return nothing
    end
end
