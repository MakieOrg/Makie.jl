"""
    number_to_date(::Type{T}, i::Int)

Attempts to reconstruct a Dates type by inverting `Dates.value(obj::T)`.
"""
number_to_date(::Type{Time}, i) = Time(Nanosecond(round(Int64, Float64(i)))) # TODO, lossless TwicePrecision -> Nanosecond
number_to_date(::Type{Date}, i) = Date(Dates.UTInstant{Day}(Day(round(Int64, Float64(i)))))
number_to_date(::Type{DateTime}, i) = DateTime(Dates.UTM(round(Int64, Float64(i))))

date_to_number(::Type{DateTime}, value::Dates.DateTime) = Dates.value(value)
date_to_number(::Type{DateTime}, value::Dates.Date) = Dates.value(Dates.DateTime(value))

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
should_dim_convert(::Type{<:Dates.AbstractTime}) = true


function convert_dim_value(conversion::DateTimeConversion, value::Dates.TimeType)
    return date_to_number(conversion.type[], value)
end

function convert_dim_value(conversion::DateTimeConversion, value::AbstractArray)
    return date_to_number.(conversion.type[], value)
end

function convert_dim_value(conversion::DateTimeConversion, attr, values, previous_values)
    T = conversion.type[]
    eltype = get_element_type(values)
    if T <: Automatic
        new_type = eltype
        new_type = new_type === Date ? DateTime : new_type
        conversion.type[] = new_type
    elseif T != eltype
        if !(T <: Time && eltype <: Unitful.Quantity)
            error("Plotting unit $(eltype) into axis with type $(T) not supported.")
        end
    end
    return date_to_number.(conversion.type[], values)
end

function get_ticks(conversion::DateTimeConversion, ticks, scale, formatter, vmin, vmax)
    error("$(scale) scale not supported for DateTimeConversion")
end

function get_ticks(conversion::DateTimeConversion, ticks, scale::typeof(identity), formatter, vmin, vmax)
    T = conversion.type[]

    # When automatic, we haven't actually plotted anything yet, so no unit chosen
    # in that case, we can't really have any conversion
    T <: Automatic && return [], []

    vmin_date = number_to_date(T, vmin)
    vmax_date = number_to_date(T, vmax)

    dateticks, labels = get_datetime_ticks(ticks, formatter, vmin_date, vmax_date)

    # dateticks isa AbstractVector{<:T} || error("DateTimeConversion ticks were returned as $(typeof(dateticks)) but they should match conversion type $T")

    return date_to_number.(T, dateticks), labels
end

function get_datetime_ticks(ticks, formatter, vmin, vmax)
    values = get_datetime_tickvalues(ticks, vmin, vmax)
    labels = get_datetime_ticklabels(values, formatter)
    return values, labels
end

function get_datetime_ticks(ticks::Tuple{Any,Any}, formatter::Automatic, vmin, vmax)
    return ticks[1], ticks[2]
end

function get_datetime_ticks(ticks::Automatic, formatter, vmin::DateTime, vmax::DateTime)
    vmin_dt = DateTime(vmin)
    vmax_dt = DateTime(vmax)
    datenumbers, labels = PlotUtils.optimize_datetime_ticks(date_to_number(DateTime, vmin_dt), date_to_number(DateTime, vmax_dt); k_min=3, k_max=5)
    dates = number_to_date.(DateTime, datenumbers)
    if formatter !== automatic
        labels = get_datetime_ticklabels(dates, formatter)
    end
    return dates, labels
end

function get_datetime_tickvalues(ticks::AbstractVector{<:Union{Date,DateTime}}, vmin::DateTime, vmax::DateTime)
    return ticks
end

function get_datetime_ticklabels(values::AbstractVector{<:Union{Date,DateTime,Time}}, formatter::Automatic)
    return string.(values)
end

function get_datetime_ticklabels(values::AbstractVector{<:Union{Date,DateTime,Time}}, formatter::Function)
    return formatter(values)
end

function get_datetime_ticklabels(values::AbstractVector{<:DateTime}, formatter::String)
    fmt = Dates.DateFormat(formatter)
    return [Dates.format(v, fmt) for v in values]
end

function get_datetime_ticklabels(values::AbstractVector{<:DateTime}, formatter::Dates.DateFormat)
    return [Dates.format(v, formatter) for v in values]
end