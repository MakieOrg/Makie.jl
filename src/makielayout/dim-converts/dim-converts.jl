abstract type AbstractDimConversion end

struct DimConversions
    conversions::NTuple{3,Observable{Union{Nothing,AbstractDimConversion}}}
    function DimConversions()
        conversions = map((1, 2, 3)) do i
            Observable{Union{Nothing,AbstractDimConversion}}(nothing)
        end
        return new(conversions)
    end
end

dim_observable(conversions::DimConversions, dim::Int) = conversions.conversions[dim]

function Base.getindex(conversions::DimConversions, i::Int)
    return conversions.conversions[i][]
end

function Base.setindex!(conversions::DimConversions, value::Observable, i::Int)
    on(value; update=true) do val
        conversions[i] = val
    end
end

function Base.setindex!(conversions::DimConversions, value, i::Int)
    isnothing(value) && return # ignore no conversions
    conversions[i] === value && return # ignore same conversion
    if conversions[i] === nothing
        # only set new conversion if there is none yet
        conversions.conversions[i][] = value
        return
    else
        error("Cannot set axis conversion for dimension $i, since it already has a conversion: $(conversions[i])")
    end
end

function convert_axis_dim(conversions::DimConversions, dim::Int, value::Observable)
    conversion = conversions[dim]
    if !isnothing(conversion)
        return convert_axis_dim(conversion, value)
    end
    c = dim_conversion_from_args(value[])
    conversions[dim] = c
    return convert_axis_dim(c, value)
end

## Interface to be overloaded for any AbstractDimConversion type
function convert_dim_value(conversions::DimConversions, dim::Int, value)
    if isnothing(conversions[dim])
        return value
    end
    return convert_dim_value(conversions[dim], value)
end


function convert_dim_value(axislike::AbstractAxis, dim::Int, value)
    return convert_dim_value(get_conversions(axislike), dim, value)
end

function convert_dim_value(conversion::AbstractDimConversion, value)
    error("AbstractDimConversion $(typeof(conversion)) not supported for value of type $(typeof(value))")
end

# Return instance of AbstractDimConversion for a given type
create_dim_conversion(argument_eltype::DataType) = nothing

# The below is defined in MakieCore, to be accessible by `@recipe`
# MakieCore.should_dim_convert(eltype) = false


# Recursively gets the dim convert from the plot
# This needs to be recursive to allow recipes to use dim converst
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
        dim_sym = Symbol("convert_dim_$i")
        if haskey(attr, dim_sym)
            conversions[i] = to_value(attr[dim_sym])
        end
    end
    return conversions
end

function dim_conversion_from_args(values)
    return create_dim_conversion(MakieCore.get_element_type(values))
end

function connect_conversions!(new_conversions::DimConversions, ax::AbstractAxis)
    for i in 1:3
        dim_sym = Symbol("convert_dim_$i")
        if hasproperty(ax, dim_sym)
            # merge
            ax_conversion = getproperty(ax, dim_sym)
            new_conversions[i] = ax_conversion
            # update in case new_conversions has a new conversion
            getproperty(ax, dim_sym)[] = new_conversions[i]
            deregister = nothing
            # if the conversion changes, update the axis as well.
            # This should only ever happen once, since conversions are mutable after setting it to a new value
            deregister = on(dim_observable(new_conversions, i)) do val
                getproperty(ax, dim_sym)[] = val
                off(deregister)
            end
        end
    end
end

function connect_conversions!(conversions::DimConversions, new_conversions::DimConversions)
    for i in 1:3
        conversions[i] = new_conversions.conversions[i]
    end
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

function needs_tick_update_observable(conversion::Observable)
    if isnothing(conversion[])
        # At any point, conversion may change from nothing to an actual AbstractDimConversion
        # so we need to listen for that change and then listen to the updates from that conversion.
        # This should only ever happen once, since you can only change a conversion once, IFF it was nothing.
        tick_update = Observable{Any}(nothing)
        deregister = nothing
        deregister = on(conversion) do conversion
            if !isnothing(conversion)
                connect!(tick_update, needs_tick_update_observable(conversion))
                # this one doesn't need to listen anymore, since this update can only happen once
                off(deregister)
            end
        end
        return tick_update
    else
        return needs_tick_update_observable(conversion[])
    end
end
