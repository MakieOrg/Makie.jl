"""
    number_to_date(::Type{T}, i::Int)

Attempts to reconstruct a Dates type by inverting `Dates.value(obj::T)`.
"""
number_to_date(::Type{Time}, i) = Time(Nanosecond(round(Int64, Float64(i)))) # TODO, lossless TwicePrecision -> Nanosecond
number_to_date(::Type{Date}, i) = Date(Dates.UTInstant{Day}(Day(round(Int64, Float64(i)))))
number_to_date(::Type{DateTime}, i) = DateTime(Dates.UTM(round(Int64, Float64(i))))

date_to_number(::Type{T}, value::Dates.AbstractTime) where {T} = Dates.value(value)
date_to_number(value::Dates.AbstractTime) = Dates.value(value)

# Allow to plot quantities into a Time unit axis
function date_to_number(::Type{Time}, value::Unitful.Quantity)
    isnan(value) && return NaN
    nanis = Nanosecond(round(u"ns", value))
    return Dates.value(Time(nanis))
end

"""
    DateTimeConversion(type=Automatic; k_min=automatic, k_max=automatic, k_ideal=automatic)

Creates conversion and conversions for Date, DateTime and Time. For other time units one should use `UnitfulConversion`, which work with e.g. Seconds.

For DateTimes `PlotUtils.optimize_datetime_ticks` is used for getting the conversion, otherwise `axis.(x/y)ticks` are used on the integer representation of the date.

# Arguments

- `type=automatic`: when left at automatic, the first plot into the axis will determine the type. Otherwise, one can set this to `Time`, `Date`, or `DateTime`.

# Examples

```julia
date_time = DateTime("2021-10-27T11:11:55.914")
date_time_range = range(date_time, step=Week(5), length=10)
# Automatically chose xticks as DateTeimeTicks:
scatter(date_time_range, 1:10)

# explicitly chose DateTimeConversion and use it to plot unitful values into it and display in the `Time` format:
using Makie.Unitful
conversion = Makie.DateTimeConversion(Time)
scatter(1:4, (1:4) .* u"s", axis=(dim2_conversion=conversion,))
```
"""
struct DateTimeConversion <: AbstractDimConversion
    # first element in tuple is the time type we converted from, which can be:
    # Time, Date, DateTime
    # Second entry in tuple is a value we use to normalize the number range,
    # so that they fit into float32
    type::Observable{DataType}
    function DateTimeConversion(type = Automatic)
        obs = Observable{DataType}(type; ignore_equal_values = true)
        return new(obs)
    end
end

expand_dimensions(::PointBased, y::AbstractVector{<:Dates.AbstractTime}) = (keys(y), y)
needs_tick_update_observable(conversion::DateTimeConversion) = conversion.type
create_dim_conversion(::Type{<:Dates.AbstractTime}) = DateTimeConversion()
MakieCore.should_dim_convert(::Type{<:Dates.AbstractTime}) = true


function convert_dim_value(conversion::DateTimeConversion, value::Dates.TimeType)
    return date_to_number(conversion.type[], value)
end

function convert_dim_value(conversion::DateTimeConversion, value::AbstractArray)
    return date_to_number.(conversion.type[], value)
end

function convert_dim_observable(conversion::DateTimeConversion, values::Observable, deregister)
    T = conversion.type[]
    eltype = MakieCore.get_element_type(values[])
    if T <: Automatic
        new_type = eltype
        conversion.type[] = new_type
    elseif T != eltype
        if !(T <: Time && eltype <: Unitful.Quantity)
            error("Plotting unit $(eltype) into axis with type $(T) not supported.")
        end
    end
    result = map(values, conversion.type) do vals, T
        return date_to_number.(T, vals)
    end
    append!(deregister, result.inputs)
    return result
end

function get_ticks(conversion::DateTimeConversion, ticks, scale, formatter, vmin, vmax)

    if scale != identity
        error("$(scale) scale not supported for DateTimeConversion")
    end
    T = conversion.type[]
    # When automatic, we haven't actually plotted anything yet, so no unit chosen
    # in that case, we can't really have any conversion
    T <: Automatic && return [], []

    if T <: DateTime
        if ticks isa WilkinsonTicks
            k_min = ticks.k_min
            k_max = ticks.k_max
        else
            k_min = 2
            k_max = 3
        end
        conversion, dates = PlotUtils.optimize_datetime_ticks(vmin, vmax; k_min = k_min, k_max = k_max)
        return conversion, dates
    else
        # TODO implement proper ticks for Time Date
        tickvalues = get_tickvalues(formatter, scale, vmin, vmax)
        dates = number_to_date.(T, round.(Int64, tickvalues))
        return tickvalues, string.(dates)
    end
end
