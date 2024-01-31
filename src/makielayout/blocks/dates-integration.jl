# Some code to try to handle date types in Makie plots
# Currently only handles `Date` and `Day`.
"""
    number_to_date(::Type{T}, i::Int)

Attempts to reconstruct a Dates type by inverting `Dates.value(obj::T)`.
"""
number_to_date(::Type{Time}, i) = Time(Nanosecond(round(Int64, i)))
number_to_date(::Type{Date}, i) = Date(Dates.UTInstant{Day}(Day(round(Int64, i))))
number_to_date(::Type{DateTime}, i) = DateTime(Dates.UTM(round(Int64, i)))

date_to_number(::Type{T}, value::Dates.AbstractTime) where T = Float64(Dates.value(value))

# Allow to plot quantities into a Time unit axis
function date_to_number(::Type{Time}, value::Unitful.Quantity)
    isnan(value) && return NaN
    ns = Nanosecond(round(u"ns", value))
    return Float64(Dates.value(Time(ns)))
end


"""
    DateTimeConversion(type=Automatic; k_min=automatic, k_max=automatic, k_ideal=automatic)

Creates conversion & conversions for Date, DateTime and Time. For other time units one should use `UnitfulTicks`, which work with e.g. Seconds.

For DateTimes `PlotUtils.optimize_datetime_ticks` is used for getting the conversion, otherwise `WilkinsonTicks` are used on the integer representation of the date.

# Arguments

- `type=automatic`: when left at automatic, the first plot into the axis will determine the type. Otherwise, one can set this to `Time`, `Date`, or `DateTime`.
- `k_min=automatic`: gets passed to `PlotUtils.optimize_datetime_ticks` for DateTimes, and otherwise to `WilkinsonTicks`.
- `k_max=automatic`: gets passed to `PlotUtils.optimize_datetime_ticks` for DateTimes, and otherwise to `WilkinsonTicks`.
- `k_ideal=automatic`: will be ignored for DateTime, and passed to `WilkinsonTicks` for Time / Date.

# Examples

```julia
date_time = DateTime("2021-10-27T11:11:55.914")
date_time_range = range(date_time, step=Week(5), length=10)
# Automatically chose xticks as DateTeimeTicks:
scatter(date_time_range, 1:10)

# explicitely chose DateTimeConversion and use it to plot unitful values into it and display in the `Time` format:
using Unitful
yticks = DateTimeConversion(Time)
scatter(1:4, (1:4) .* u"s", axis=(yticks=yticks,))
```
"""
struct DateTimeConversion
    # first element in tuple is the time type we converted from, which can be:
    # Time, Date, DateTime
    # Second entry in tuple is a value we use to normalize the number range,
    # so that they fit into float32
    type::Observable{Tuple{DataType, Int64}}
    k_min::Union{Automatic, Int}
    k_max::Union{Automatic, Int}
    k_ideal::Union{Automatic, Int}
    function DateTimeConversion(type=Automatic; k_min=automatic, k_max=automatic, k_ideal=automatic)
        obs = Observable{Tuple{DataType,Int64}}((type, 0))
        return new(obs, k_min, k_max, k_ideal)
    end
end

dim_conversion_type(::Type{<: Dates.TimeType}) = DateTimeConversion()

function convert_axis_dim(conversion::DateTimeConversion, values::Observable)
    eltype = get_element_type(values[])
    T, mini = conversion.type[]
    if T <: Automatic
        new_type = eltype
        init_vals = date_to_number.(T, values[])
        # TODO update minimum in connect! on limit change!
        conversion.type[] = (new_type, Makie.nan_extrema(init_vals)[1])
    elseif T != eltype
        if !(T <: Time && eltype <: Unitful.Quantity)
            error("Plotting unit $(eltype) into axis with type $(T) not supported.")
        end
    end

    return map(values, conversion.type) do vals, (T, mini)
        return date_to_number.(T, vals) .- mini
    end
end

function get_ticks(conversion::DateTimeConversion, ticks, scale, formatter, vmin, vmax)
    if !(formatter isa Automatic)
        error("You can't use a formatter with DateTime conversion")
    end

    if scale != identity
        error("$(scale) scale not supported for DateTimeConversion")
    end

    T, mini = conversion.type[]

    # When automatic, we haven't actually plotted anything yet, so no unit chosen
    # in that case, we can't really have any conversion
    T <: Automatic && return [], []

    if T <: DateTime
        k_min = conversion.k_min isa Automatic ? 2 : conversion.k_min
        k_max = conversion.k_max isa Automatic ? 3 : conversion.k_max
        conversion, dates = PlotUtils.optimize_datetime_ticks(
                Float64(vmin) + mini,
                Float64(vmax) + mini;
                k_min=k_min, k_max=k_max)
        return conversion .- mini, dates
    else
        # TODO implement proper conversion for Time Date
        k_min = conversion.k_min isa Automatic ? 3 : conversion.k_min
        k_max = conversion.k_max isa Automatic ? 6 : conversion.k_max
        k_ideal = conversion.k_ideal isa Automatic ? 6 : conversion.k_ideal
        formatter = WilkinsonTicks(k_ideal; k_min=k_min, k_max=k_max)
        tickvalues = get_tickvalues(formatter, scale, vmin, vmax)
        dates = number_to_date.(T, round.(Int64, tickvalues .+ mini))
        return tickvalues, string.(dates)
    end
end
