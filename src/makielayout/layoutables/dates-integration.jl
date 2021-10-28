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
function date_to_number(::Type{Time}, value::Unitful.Quantity) where T
    isnan(value) && return NaN
    ns = Nanosecond(round(u"ns", value))
    return Float64(Dates.value(Time(ns)))
end


"""
    DateTimeTicks(type=Automatic; k_min=automatic, k_max=automatic, k_ideal=automatic)

Creates ticks & conversions for Date, DateTime and Time. For other time units one should use `UnitfulTicks`, which work with e.g. Seconds.

For DateTimes `PlotUtils.optimize_datetime_ticks` is used for getting the ticks, otherwise `WilkinsonTicks` are used on the integer representation of the date.

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

# explicitely chose DateTimeTicks and use it to plot unitful values into it and display in the `Time` format:
using Unitful
yticks = DateTimeTicks(Time)
scatter(1:4, (1:4) .* u"s", axis=(yticks=yticks,))
```
"""
struct DateTimeTicks
    parent::Base.RefValue{Axis}
    # first element in tuple is the time type we converted from, which can be:
    # Time, Date, DateTime
    # Second entry in tuple is a value we use to normalize the number range,
    # so that they fit into float32
    type::Observable{Tuple{<: Type{<: Union{Time, Date, DateTime, Automatic}}, Int64}}
    k_min::Union{Automatic, Int}
    k_max::Union{Automatic, Int}
    k_ideal::Union{Automatic, Int}
    function DateTimeTicks(type=Automatic; k_min=automatic, k_max=automatic, k_ideal=automatic)
        obs = Observable{Tuple{Any, Float64}}((type, 0))
        return new(Base.RefValue{Axis}(), obs, k_min, k_max, k_ideal)
    end
end

ticks_from_type(::Type{<: Dates.TimeType}) = DateTimeTicks()

function convert_axis_dim(ticks::DateTimeTicks, values::Observable, limits)
    eltype = get_element_type(values[])
    T, mini = ticks.type[]
    new_type = T <: Automatic ? eltype : T

    init_vals = date_to_number.(T, values[])

    ticks.type[] = (new_type, Makie.nan_extrema(init_vals)[1])

    converted = map(values, ticks.type) do vals, (T, mini)
        return date_to_number.(T, vals) .- mini
    end
    return converted
end

function MakieLayout.get_ticks(ticks::DateTimeTicks, scale, formatter, vmin, vmax)
    if !(formatter isa Automatic)
        error("You can't use a formatter with DateTime ticks")
    end
    if scale != identity
        error("$(scale) scale not supported for DateTimeTicks")
    end

    T, mini = ticks.type[]

    # When automatic, we haven't actually plotted anything yet, so no unit chosen
    # in that case, we can't really have any ticks
    T <: Automatic && return [], []

    if T <: DateTime

        k_min = ticks.k_min isa Automatic ? 2 : ticks.k_min
        k_max = ticks.k_max isa Automatic ? 3 : ticks.k_max
        ticks, dates = PlotUtils.optimize_datetime_ticks(
                Float64(vmin) + mini,
                Float64(vmax) + mini;
                k_min=k_min, k_max=k_max)
        return ticks .- mini, dates
    else
        # TODO implement proper ticks for Time Date
        k_min = ticks.k_min isa Automatic ? 3 : ticks.k_min
        k_max = ticks.k_max isa Automatic ? 6 : ticks.k_max
        k_ideal = ticks.k_ideal isa Automatic ? 6 : ticks.k_ideal
        formatter = WilkinsonTicks(k_ideal; k_min=k_min, k_max=k_max)
        tickvalues = get_tickvalues(formatter, scale, vmin, vmax)
        dates = number_to_date.(T, round.(Int64, tickvalues .+ mini))
        return tickvalues, string.(dates)
    end
end
