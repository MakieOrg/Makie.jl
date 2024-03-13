abstract type AxisConversion end

struct AxisConversions
    conversions::Vector{Union{Nothing,AxisConversion}}
    function AxisConversions()
        return new(Union{Nothing,AxisConversion}[nothing for x in 1:3])
    end
end

function Base.getindex(conversions::AxisConversions, i::Int)
    return conversions.conversions[i]
end

function Base.setindex!(conversions::AxisConversions, value, i::Int)
    isnothing(value) && return # ignore no conversions
    conversions[i] === value && return # ignore same conversion
    if conversions[i] === nothing
        # only set new conversion if there is none yet
        conversions.conversions[i] = value
        return
    else
        error("Cannot set axis conversion for dimension $i, since it already has a conversion: $(conversions[i])")
    end
end

function convert_axis_dim(P, conversions::AxisConversions, dim::Int, value::Observable)
    conversion = conversions[dim]
    if !isnothing(conversion)
        return convert_axis_dim(conversion, value)
    end
    can_convert = MakieCore.can_axis_convert(P, value[])
    if can_convert
        c = convert_from_args(value[])
        conversions[dim] = c
        return convert_axis_dim(c, value)
    end
    return value
end

## Interface to be overloaded for any AxisConversion type
function convert_axis_value(conversions::AxisConversions, dim::Int, value)
    if isnothing(conversions[dim])
        return value
    end
    return convert_axis_value(conversions[dim], value)
end

function convert_axis_value(conversions::AxisConversions, values...)
    return map(enumerate(values)) do (i, value)
        conversion = conversions[i]
        if isnothing(conversion)
            return value
        end
        return convert_axis_value(conversion, value)
    end
end

function convert_axis_value(axislike::AbstractAxis, dim::Int, value)
    return convert_axis_value(get_conversions(axislike), dim, value)
end

function convert_axis_value(conversion::AxisConversion, value)
    error("AxisConversion $(typeof(conversion)) not supported for value of type $(typeof(value))")
end

# Return instance of AxisConversion for a given type
axis_conversion_type(argument_eltype::DataType) = nothing

# The below is defined in MakieCore, to be accessible by `@recipe`
# MakieCore.can_axis_convert_type(::) = true


# Recursively gets the dim convert from the plot
# This needs to be recursive to allow recipes to use dim converst
# TODO, should a recipe always set the dim convert to it's parent?
get_conversions(any) = nothing
function get_conversions(ax::AbstractAxis)
    if hasproperty(ax, :scene)
        return ax.scene.conversions
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


function convert_from_args(values)
    return axis_conversion_type(MakieCore.get_element_type(values))
end

connect_conversion!(ax::AbstractAxis, conversion, dim) = nothing

function connect_conversion!(ax::AbstractAxis, conversions::AxisConversions)
    for i in 1:3
        connect_conversion!(ax, conversions[i], i)
    end
end

function merge_conversions!(conversions::AxisConversions, new_conversions::Nothing...)
    return
end

function merge_conversions!(conversions::AxisConversions, new_conversions::Union{Nothing, AxisConversion}...)
    for (i, c) in enumerate(new_conversions)
        conversions[i] = c
    end
end

function merge_conversions!(conversions::AxisConversions, new_conversions::AxisConversions)
    for (i, c) in enumerate(new_conversions.conversions)
        conversions[i] = c
    end
end

# If axis conversion has global state which needs an update of the tick values,
# This functions needs to be overloaded, returning an observable that updates
# When ticks need to be updated. The concrete value doesn't matterm, since the AxisConversion type will get passed to get_ticks regardless
#=
    obs = needs_tick_update_observable(dim_convert) # make sure we update tick calculation when needed
    ticks = map(obs, ...) do _, args...
        return get_ticks(dim_convert, args...)
    end
=#
needs_tick_update_observable(x) = nothing
