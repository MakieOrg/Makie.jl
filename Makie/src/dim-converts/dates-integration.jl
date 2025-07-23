"""
    number_to_date(::Type{T}, i::Int)

Attempts to reconstruct a Dates type by inverting `Dates.value(obj::T)`.
"""
number_to_date(::Type{Time}, i) = Time(Nanosecond(round(Int64, Float64(i)))) # TODO, lossless TwicePrecision -> Nanosecond
number_to_date(::Type{Date}, i) = Date(Dates.UTInstant{Day}(Day(round(Int64, Float64(i)))))
number_to_date(::Type{DateTime}, i) = DateTime(Dates.UTM(round(Int64, Float64(i))))

date_to_number(::Type{DateTime}, value::Dates.DateTime) = Dates.value(value)
date_to_number(::Type{DateTime}, value::Dates.Date) = Dates.value(Dates.DateTime(value))

date_to_number(::Type{Time}, value::Dates.Time) = Dates.value(value)

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

- `type=automatic`: when left at automatic, the first plot into the axis will determine the type. Otherwise, one can set this to `Time` or `DateTime`.

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
    elseif T != eltype && !(T === DateTime && eltype === Date)
        if !(T <: Time && eltype <: Unitful.Quantity)
            error("Plotting unit $(eltype) into axis with type $(T) not supported.")
        end
    end
    return date_to_number.(conversion.type[], values)
end

function get_ticks(conversion::DateTimeConversion, ticks, scale, formatter, vmin, vmax)
    T = conversion.type[]

    # When automatic, we haven't actually plotted anything yet, so no unit chosen
    # in that case, we can't really have any conversion
    T <: Automatic && return [], []

    # Time can only be between 0:00:00 and 23:59:59 (plus nanoseconds)
    # but through expansion of limits (for visual purposes) we can easily
    # get floats outside of the valid range. But these do pass through conversion
    # by wrapping to the adjacent day's time. So we clamp vmin and vmax
    # to the valid range instead, there cannot be Time data outside of those anyway.
    if T === Time
        vmin = max(vmin, zero(vmin))
        vmax = min(vmax, date_to_number(Time, Time(Nanosecond(-1))))
    end

    vmin_date = number_to_date(T, vmin)
    vmax_date = number_to_date(T, vmax)

    # limits are expanded with float fractions which can let them land in-between
    # milliseconds, so we pick the milliseconds that result in tighter limits,
    # otherwise we can get vmin and vmax outside of the actual axis
    if date_to_number(T, vmin_date) < vmin
        vmin_date = vmin_date + Millisecond(1)
    end
    if date_to_number(T, vmax_date) > vmax
        vmax_date = vmax_date - Millisecond(1)
    end

    dateticks, labels = get_ticks(ticks, scale, formatter, vmin_date, vmax_date)

    return date_to_number.(T, dateticks), labels
end

function get_ticks(ticks, scale, formatter, vmin::DateTime, vmax::DateTime)
    values = get_tickvalues(ticks, vmin, vmax)
    labels = get_ticklabels(values, formatter)
    return values, labels
end

function get_ticks(ticks::Tuple{Any, Any}, formatter::Automatic, vmin::DateTime, vmax::DateTime)
    return ticks[1], ticks[2]
end

struct DateTimeTicks
    y::DateFormat
    ym::DateFormat
    ymd::DateFormat
    ymdHM::DateFormat
    ymdHMS::DateFormat
    ymdHMSs::DateFormat
    HM::DateFormat
    HMS::DateFormat
    HMSs::DateFormat
    M::DateFormat
    MS::DateFormat
    MSs::DateFormat
    S::DateFormat
    Ss::DateFormat
    s::DateFormat
    k_ideal::Int
end

"""
    DateTimeTicks(k_ideal::Int)

A tick finder that tries to locate around `k_ideal` equally spaced ticks
in a `DateTime` interval. The ticks are formatted such that neighboring ticks
omit redundant information. For example, two neighboring ticks that lie
in the same minute would only show the time up to the minute once, and the second
otherwise.
"""
function DateTimeTicks(k_ideal::Int = 5)
    return DateTimeTicks(
        dateformat"yyyy",
        dateformat"yyyy-mm",
        dateformat"yyyy-mm-dd",
        DateFormat("H:MM\nyyyy-mm-dd"),
        DateFormat("H:MM:SS\nyyyy-mm-dd"),
        DateFormat("H:MM:SS.sss\nyyyy-mm-dd"),
        dateformat"H:MM",
        dateformat"H:MM:SS",
        dateformat"H:MM:SS.sss",
        dateformat":MM",
        dateformat":M:SS",
        dateformat":M:SS.sss",
        dateformat":SS",
        dateformat":SS.sss",
        dateformat".sss",
        k_ideal,
    )
end

function get_ticks(::Automatic, scale, formatter, vmin::DateTime, vmax::DateTime)
    return get_ticks(DateTimeTicks(), scale, formatter, vmin, vmax)
end

function get_ticks(::Automatic, scale, formatter, vmin::Time, vmax::Time)
    # for now, take a shortcut and compute time ticks as datetime ticks on the same day where the day part is omitted in the dateformat
    dtt = DateTimeTicks(
        dateformat"yyyy",
        dateformat"yyyy-mm",
        dateformat"yyyy-mm-dd",
        # these three are changed
        dateformat"H:MM",
        dateformat"H:MM:SS",
        dateformat"H:MM:SS.sss",
        #
        dateformat"H:MM",
        dateformat"H:MM:SS",
        dateformat"H:MM:SS.sss",
        dateformat":MM",
        dateformat":M:SS",
        dateformat":M:SS.sss",
        dateformat":SS",
        dateformat":SS.sss",
        dateformat".sss",
        5,
    )
    dvmin = DateTime(0, 1, 1, Dates.hour(vmin), Dates.minute(vmin), Dates.second(vmin), Dates.millisecond(vmin))
    dvmax = DateTime(0, 1, 1, Dates.hour(vmax), Dates.minute(vmax), Dates.second(vmax), Dates.millisecond(vmax))
    datetimes, labels = get_ticks(dtt, scale, formatter, dvmin, dvmax)
    return Time.(datetimes), labels
end

function get_ticks(d::DateTimeTicks, scale, formatter, vmin::DateTime, vmax::DateTime)
    datetimes, kind = locate_datetime_ticks(d, vmin, vmax)
    if formatter === automatic
        labels = datetime_range_ticklabels(d, datetimes, kind)
    else
        labels = get_ticklabels(datetimes, formatter)
    end
    return datetimes, labels
end

function get_tickvalues(ticks::AbstractVector{<:Union{Date, DateTime}}, scale, vmin::DateTime, vmax::DateTime)
    return ticks
end

function get_ticklabels(values::AbstractVector{<:Union{Date, DateTime, Time}}, formatter::Automatic)
    return string.(values)
end

function get_ticklabels(values::AbstractVector{<:Union{Date, DateTime, Time}}, formatter::Function)
    return formatter(values)
end

function get_ticklabels(values::AbstractVector{<:DateTime}, formatter::String)
    fmt = Dates.DateFormat(formatter)
    return [Dates.format(v, fmt) for v in values]
end

function get_ticklabels(values::AbstractVector{<:DateTime}, formatter::Dates.DateFormat)
    return [Dates.format(v, formatter) for v in values]
end

extractor(::Type{Year}) = year
extractor(::Type{Month}) = month
extractor(::Type{Day}) = day
extractor(::Type{Hour}) = hour
extractor(::Type{Minute}) = minute
extractor(::Type{Second}) = second
extractor(::Type{Millisecond}) = millisecond

# assumes these are rounded to the given type already
stepdiff(::Type{Year}, from, to) = year(to) - year(from)
stepdiff(::Type{Month}, from, to) = 12 * stepdiff(Year, from, to) + (month(to) - month(from))
stepdiff(T::Type{<:Union{Day, Hour, Minute, Second, Millisecond}}, from, to) = (to - from) / T(1)


function locate_datetime_ticks(dtt::DateTimeTicks, start::DateTime, stop::DateTime)
    k_ideal = dtt.k_ideal
    if stop <= start
        return [start], :millisecond
    end
    ticks_year, cost_year = _ticks(Year, start, stop, k_ideal)
    ticks_month, cost_month = _ticks(Month, start, stop, k_ideal)
    ticks_day, cost_day = _ticks(Day, start, stop, k_ideal)
    ticks_hour, cost_hour = _ticks(Hour, start, stop, k_ideal)
    ticks_minute, cost_minute = _ticks(Minute, start, stop, k_ideal)
    ticks_second, cost_second = _ticks(Second, start, stop, k_ideal)
    ticks_millisecond, cost_millisecond = _ticks(Millisecond, start, stop, k_ideal)

    costs = (cost_year, cost_month, cost_day, cost_hour, cost_minute, cost_second, cost_millisecond)
    # for same costs, earlier (bigger) step is preferred
    i = argmin(costs)
    return if i == 1
        collect(ticks_year), :year
    elseif i == 2
        collect(ticks_month), :month
    elseif i == 3
        collect(ticks_day), :day
    elseif i == 4
        collect(ticks_hour), :hour
    elseif i == 5
        collect(ticks_minute), :minute
    elseif i == 6
        collect(ticks_second), :second
    elseif i == 7
        collect(ticks_millisecond), :millisecond
    else
        error("unreachable reached")
    end
end

stepsizes(::Type{Month}) = (1, 2, 3, 4, 5, 6)
stepsizes(::Type{Day}) = (1, 2, 3, 4, 5, 7, 10, 15, 20, 25, 30)
stepsizes(::Type{Hour}) = (1, 2, 3, 4, 5, 6, 12)
stepsizes(::Type{Minute}) = (1, 2, 3, 4, 5, 10, 15, 20, 30)
stepsizes(::Type{Second}) = (1, 2, 3, 4, 5, 10, 15, 20, 30)
stepsizes(::Type{Millisecond}) = (1, 2, 3, 4, 5, 10, 20, 25, 50, 100, 200, 300, 400, 500)

parent_type(::Type{Month}) = Year
parent_type(::Type{Day}) = Month
parent_type(::Type{Hour}) = Day
parent_type(::Type{Minute}) = Hour
parent_type(::Type{Second}) = Minute
parent_type(::Type{Millisecond}) = Second

function _ticks(steptype::Type, start::DateTime, stop::DateTime, k_ideal::Int)
    start_ceiled = ceil(start, steptype)

    start_float = Float64(extractor(steptype)(start_ceiled))
    offset = 0.0
    start_float_adjusted = start_float

    # for steps other than Year we check if there's a step of the parent
    # size within the limits, if so, we calculate float ticks relative to that.
    # For example, if we cross a second in the millisecond range in steps of 3,
    # we don't want 999, 1002 but 1000, 1003, so we don't divide the float values
    # relative to the start floored to the parent, but to the first parent step.
    if steptype !== Year
        start_ceiled_parent = ceil(start, parent_type(steptype))
        if start_ceiled_parent <= stop
            negative = -stepdiff(steptype, start_ceiled, start_ceiled_parent)
            offset = negative - start_float
            start_float_adjusted = negative
        end
    end

    diff = stepdiff(steptype, start_ceiled, stop)
    empty_range = start:steptype(1):start
    diff <= 0 && return empty_range, Inf
    stop_float = start_float_adjusted + diff
    start_float_adjusted == stop_float && return empty_range, Inf
    ticks = best_ticks(steptype, start_float_adjusted, stop_float, k_ideal)
    ticks = ticks .- offset # remove offset
    cost = _cost(ticks, k_ideal)
    step_float = ticks isa AbstractRange ? ticks.step : ticks[2] - ticks[1]
    step = steptype(Int(step_float))
    # ticks can be out of bounds sometimes... need to work around that
    first_inrange_index = findfirst(>=(start_float), ticks)
    tickrange = (start_ceiled - steptype(start_float) + steptype(ticks[first_inrange_index])):step:stop
    return tickrange, cost
end

function _cost(range, k_ideal)
    return abs(length(range) - (k_ideal - 0.5))
end

function best_ticks(steptype::Type{<:Union{Month, Day, Hour, Minute, Second, Millisecond}}, start, stop, k_ideal)
    return best_ticks(start, stop, stepsizes(steptype), k_ideal)
end

function best_ticks(steptype::Type{Year}, start, stop, k_ideal)
    w = WilkinsonTicks(k_ideal)
    tv = get_tickvalues(w, start, stop)
    if !all(isinteger, tv)
        return Int(start):1:Int(stop)
    else
        step = max(1, tv[2] - tv[1])
        return tv[1]:step:tv[end]
    end
end

function best_ticks(start, stop, stepsizes, k_ideal)
    function _range(start, stop, step)
        from = cld(start, step) * step
        to = fld(stop, step) * step
        return from:step:to
    end
    return argmin(_range(start, stop, step) for step in stepsizes) do rng
        _cost(rng, k_ideal)
    end
end

function datetime_range_ticklabels(tickobj::DateTimeTicks, datetimes::Vector{<:DateTime}, kind::Symbol)::Vector{String}
    # Handle edge cases
    if length(datetimes) <= 1
        return string.(datetimes)
    end

    n_ticks = length(datetimes)

    if kind in (:year, :month, :day)
        # For daily+ steps, show only dates (no times) if all times are midnight
        all_midnight = all(dt -> (Dates.hour(dt) == 0 && Dates.minute(dt) == 0 && Dates.second(dt) == 0 && Dates.millisecond(dt) == 0), datetimes)

        if all_midnight
            if all(dt -> Dates.day(dt) == 1, datetimes)
                if kind === :year
                    if all(dt -> Dates.month(dt) == 1, datetimes)
                        # Years only
                        return [Dates.format(dt, tickobj.y) for dt in datetimes]
                    else
                        return [Dates.format(dt, tickobj.ym) for dt in datetimes]
                    end
                elseif kind === :month
                    return [Dates.format(dt, tickobj.ym) for dt in datetimes]
                else
                    return [Dates.format(dt, tickobj.ymd) for dt in datetimes]
                end
            end
            # Full date format
            return [Dates.format(dt, tickobj.ymd) for dt in datetimes]
        else
            # Mixed date and time - show full datetime
            return [Dates.format(dt, tickobj.ymdHMS) for dt in datetimes]
        end
    elseif kind === :hour
        # Hourly steps - use multi-line format: time on top, date below when it changes
        ticklabels = Vector{String}(undef, n_ticks)
        prev_date = nothing

        for (i, dt) in enumerate(datetimes)
            current_date = Dates.Date(dt)

            if i == 1 || current_date != prev_date
                # Show date below time when date changes or for first tick
                ticklabels[i] = Dates.format(dt, tickobj.ymdHM)
            else
                # Same date as previous tick, show only time
                ticklabels[i] = Dates.format(dt, tickobj.HM)
            end
            prev_date = current_date
        end
        return ticklabels
    elseif kind === :minute
        # Minute-level steps
        ticklabels = Vector{String}(undef, n_ticks)
        prev_date = nothing
        prev_hour = nothing

        for (i, dt) in enumerate(datetimes)
            current_date = Dates.Date(dt)
            current_hour = Dates.hour(dt)

            if i == 1 || current_date != prev_date
                # Show date below time when date changes or for first tick
                ticklabels[i] = Dates.format(dt, tickobj.ymdHM)
            elseif current_hour != prev_hour
                # Same date but different hour, show hour:minute
                ticklabels[i] = Dates.format(dt, tickobj.HM)
            else
                # Same date and hour, show only minutes
                ticklabels[i] = Dates.format(dt, tickobj.M)
            end
            prev_date = current_date
            prev_hour = current_hour
        end
        return ticklabels
    elseif kind === :second
        ticklabels = Vector{String}(undef, n_ticks)
        prev_date = nothing
        prev_hour = nothing
        prev_minute = nothing

        for (i, dt) in enumerate(datetimes)
            current_date = Dates.Date(dt)
            current_hour = Dates.hour(dt)
            current_minute = Dates.minute(dt)

            if i == 1 || current_date != prev_date
                # Show date below time when date changes or for first tick
                ticklabels[i] = Dates.format(dt, tickobj.ymdHMS)
            elseif current_hour != prev_hour
                # Same date but different hour, show hour:minute
                ticklabels[i] = Dates.format(dt, tickobj.HMS)
            elseif current_minute != prev_minute
                ticklabels[i] = Dates.format(dt, tickobj.MS)
            else
                ticklabels[i] = Dates.format(dt, tickobj.S)
            end
            prev_date = current_date
            prev_hour = current_hour
            prev_minute = current_minute
        end
        return ticklabels
    elseif kind === :millisecond
        # milliseconds
        ticklabels = Vector{String}(undef, n_ticks)
        prev_date = nothing
        prev_hour = nothing
        prev_minute = nothing
        prev_second = nothing

        for (i, dt) in enumerate(datetimes)
            current_date = Dates.Date(dt)
            current_hour = Dates.hour(dt)
            current_minute = Dates.minute(dt)
            current_second = Dates.second(dt)

            if i == 1 || current_date != prev_date
                # Show date below time when date changes or for first tick
                ticklabels[i] = Dates.format(dt, tickobj.ymdHMSs)
            elseif current_hour != prev_hour
                ticklabels[i] = Dates.format(dt, tickobj.HMSs)
            elseif current_minute != prev_minute
                # Same hour but different minute
                ticklabels[i] = Dates.format(dt, tickobj.MSs)
            elseif current_second != prev_second
                ticklabels[i] = Dates.format(dt, tickobj.Ss)
            else
                # Same second, show only milliseconds (for sub-second steps)
                ticklabels[i] = Dates.format(dt, tickobj.s)
            end
            prev_date = current_date
            prev_hour = current_hour
            prev_minute = current_minute
            prev_second = current_second
        end
        return ticklabels
    else
        error("invalid kind $kind")
    end
end
