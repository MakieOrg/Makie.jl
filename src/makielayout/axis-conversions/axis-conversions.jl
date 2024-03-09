abstract type AxisConversion end

struct AxisConversions{N}
    conversions::Vector{Union{Nothing,AxisConversion}}
    function AxisConversions{N}(n::Int) where {N}
        return new{N}(Union{Nothing,AxisConversion}[nothing for x in 1:n])
    end
end

function Base.getindex(conversions::AxisConversions, i::Int)
    return conversions.conversions[i]
end

function Base.setindex!(conversions::AxisConversions, value, i::Int)
    return conversions.conversions[i] = value
end

function convert_axis_value(conversions::AxisConversions{N}, values::Vararg{Any,N}) where N
    return map(enumerate(values)) do (i, value)
        conversion = conversions[i]
        if isnothing(conversion)
            return value
        end
        return convert_axis_value(conversion, value)
    end
end

## Interface to be overloaded for any AxisConversion type

function convert_axis_value(conversion::AxisConversion, value)
    error("AxisConversion $(typeof(conversion)) not supported for value of type $(typeof(value))")
end

# Return instance of AxisConversion for a given type
axis_conversion_type(argument_eltype::DataType) = automatic

# The below is defined in MakieCore, to be accessible by `@recipe`
# MakieCore.can_axis_convert_type(::) = true


# Recursively gets the dim convert from the plot
# This needs to be recursive to allow recipes to use dim converst
# TODO, should a recipe always set the dim convert to it's parent?
function get_axis_convert(plot::Plot, dim::Symbol)
    if haskey(plot.kw, dim)
        return to_value(plot.kw[dim])
    elseif haskey(plot, dim)
        return to_value(plot[dim])
    else
        for elem in plot.plots
            x = get_axis_convert(elem, dim)
            isnothing(x) || return x
        end
    end
    return nothing
end
