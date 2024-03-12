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
    if conversions[i] === nothing
        return conversions.conversions[i] = value
    else
        error("Cannot set axis conversion for dimension $i, since it already has a conversion: $(conversions[i])")
    end
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

function convert_axis_dim(P, conversions::AxisConversions, dim::Int, value::Observable)
    conversion = conversions[dim]
    if !isnothing(conversion)
        return convert_axis_dim(conversion, value)
    end
    can_convert = MakieCore.can_axis_convert(P, conversion)
    if can_convert
        c = convert_from_args(value[])
        conversions[dim] = c
        return convert_axis_dim(c, value)
    end
    return value
end

## Interface to be overloaded for any AxisConversion type

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
function get_axis_convert(plot::Plot)
    if haskey(plot.kw, :dim_conversions)
        return to_value(plot.kw[:dim_conversions])
    else
        for elem in plot.plots
            x = get_axis_convert(elem)
            isnothing(x) || return x
        end
    end
    return nothing
end


function convert_from_args(values)
    return axis_conversion_type(MakieCore.get_element_type(values))
end

connect_conversion!(ax::AbstractAxis, obs::Observable, conversion, dim) = nothing

function connect_conversion!(ax::AbstractAxis, conversions::AxisConversions)
    for i in 1:3
        connect_conversion!(ax, conversions[i], conversions[i], i)
    end
end
