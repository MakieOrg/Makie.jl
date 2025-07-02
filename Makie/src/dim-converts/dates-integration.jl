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

Base.@kwdef struct DateTimeTicks3
    y::DateFormat = dateformat"yyyy"
    ym::DateFormat = dateformat"yyyy-mm"
    ymd::DateFormat = dateformat"yyyy-mm-dd"
    ymdHM::DateFormat = DateFormat("H:MM\nyyyy-mm-dd")
    ymdHMS::DateFormat = DateFormat("H:MM:SS\nyyyy-mm-dd")
    ymdHMSs::DateFormat = DateFormat("H:MM:SS.sss\nyyyy-mm-dd")
    HM::DateFormat = dateformat"H:MM"
    HMS::DateFormat = dateformat"H:MM:SS"
    HMSs::DateFormat = dateformat"H:MM:SS.sss"
    M::DateFormat = dateformat":MM"
    MS::DateFormat = dateformat":M:SS"
    MSs::DateFormat = dateformat":M:SS.sss"
    S::DateFormat = dateformat":SS"
    Ss::DateFormat = dateformat":SS.sss"
    s::DateFormat = dateformat".sss"
    k_ideal::Int = 5
    k_min::Union{Nothing,Int} = nothing
    k_max::Union{Nothing,Int} = nothing
end


function get_datetime_ticks(::Automatic, formatter, vmin::DateTime, vmax::DateTime)
    return get_datetime_ticks(DateTimeTicks3(), formatter, vmin, vmax)
end

function get_datetime_ticks(d::DateTimeTicks3, formatter, vmin, vmax)
    datetimerange = locate_datetime_ticks(d, vmin, vmax)
    if formatter === automatic
        labels = datetime_range_ticklabels(d, datetimerange)
    else
        labels = get_datetime_ticklabels(datetimerange, formatter)
    end
    return datetimerange, labels
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

extractor(::Type{Year}) = year
extractor(::Type{Month}) = month
extractor(::Type{Day}) = day
extractor(::Type{Hour}) = hour
extractor(::Type{Minute}) = minute
extractor(::Type{Second}) = second
extractor(::Type{Millisecond}) = millisecond

parent_type(::Type{Month}) = Year
parent_type(::Type{Day}) = Month
parent_type(::Type{Hour}) = Day
parent_type(::Type{Minute}) = Hour
parent_type(::Type{Second}) = Minute
parent_type(::Type{Millisecond}) = Second

# assumes these are rounded to the given type already
stepdiff(::Type{Year}, from, to) = year(to) - year(from)
stepdiff(::Type{Month}, from, to) = 12 * stepdiff(Year, from, to) + (month(to) - month(from))
stepdiff(T::Type{<:Union{Day,Hour,Minute,Second,Millisecond}}, from, to) = (to - from) / T(1)

get_Q(::Type{<:Union{Year,Millisecond}}) = [(1.0, 1.0), (5.0, 0.9), (2.0, 0.7), (2.5, 0.5), (3.0, 0.2)] # Makie default
get_Q(::Type{Month}) = [(12.0, 2.5), (6.0, 1.5), (3.0, 1.2), (2.0, 0.7), (1.0, 1.0)]
get_Q(::Type{Day}) = [(7.0, 2.5), (5.0, 1.5), (1.0, 1.0), (2.0, 0.7), (3.0, 0.2)]
get_Q(::Type{Hour}) = [(24.0, 2.5), (12.0, 1.5), (6.0, 1.0), (1.0, 1.0), (2.0, 0.7), (3.0, 0.2)]
get_Q(::Type{<:Union{Minute,Second}}) = [(60.0, 2.5), (30.0, 1.7), (15.0, 1.5), (5.0, 1.0), (1.0, 1.0), (2.0, 0.7), (3.0, 0.2)]

function locate_datetime_ticks(dtt::DateTimeTicks3, start::DateTime, stop::DateTime)
    k_ideal = dtt.k_ideal
    k_min = something(dtt.k_min, max(1, floor(Int, k_ideal * 0.66)))
    k_max = something(dtt.k_max, ceil(Int, k_ideal * 1.33))
    @assert stop > start
    ticks = _ticks(Year, start, stop; k_ideal, k_min, k_max)
    ticks !== nothing && return ticks
    ticks = _ticks(Month, start, stop; k_ideal, k_min, k_max)
    ticks !== nothing && return ticks
    ticks = _ticks(Day, start, stop; k_ideal, k_min, k_max)
    ticks !== nothing && return ticks
    ticks = _ticks(Hour, start, stop; k_ideal, k_min, k_max)
    ticks !== nothing && return ticks
    ticks = _ticks(Minute, start, stop; k_ideal, k_min, k_max)
    ticks !== nothing && return ticks
    ticks = _ticks(Second, start, stop; k_ideal, k_min, k_max)
    ticks !== nothing && return ticks
    ticks = _ticks(Millisecond, start, stop; k_ideal, k_min, k_max)
    ticks !== nothing && return ticks
    fallback = start:Millisecond(1):stop
    length(fallback) < dtt.k_max || error("Fallback in milliseconds was too long: $fallback")
    return fallback
end

function _ticks(steptype, start::DateTime, stop::DateTime; k_ideal, k_min, k_max)
    start_ceiled = ceil(start, steptype)
    start_float = Float64(extractor(steptype)(start_ceiled))
    start_floored_to_parent = steptype === Year ? DateTime(0) : floor(start_ceiled, parent_type(steptype))
    diff = stepdiff(steptype, start, stop)
    diff <= 0 && return nothing
    stop_float = start_float + diff
    ticks = Makie.get_tickvalues(
        Makie.WilkinsonTicks(k_ideal; k_min, k_max, Q = get_Q(steptype)),
        start_float,
        stop_float,
    )
    length(ticks) < 2 && return nothing
    step_float = ticks[2] - ticks[1]
    isinteger(step_float) || return nothing
    step = steptype(Int(step_float))
    # ticks can be out of bounds sometimes... need to work around that
    first_inrange_index = findfirst(>=(start_float), ticks)
    tickrange = start_floored_to_parent + steptype(ticks[first_inrange_index]):step:stop
    steptype !== Millisecond && length(tickrange) < k_min && return nothing # fall back to next granularity if too few ticks are found once out of bounds are removed
    return tickrange
end

function datetime_range_ticklabels(tickobj::DateTimeTicks3, datetimes::AbstractRange{<:DateTime})::Vector{String}
    # Handle edge cases
    if length(datetimes) <= 1
        return string.(datetimes)
    end
    
    step_value = datetimes.step
    n_ticks = length(datetimes)
    
    if step_value isa Union{Dates.Day,Dates.Week,Dates.Month,Dates.Year}
        # For daily+ steps, show only dates (no times) if all times are midnight
        all_midnight = all(dt -> (Dates.hour(dt) == 0 && Dates.minute(dt) == 0 && Dates.second(dt) == 0 && Dates.millisecond(dt) == 0), datetimes)

        if all_midnight
            if all(dt -> Dates.day(dt) == 1, datetimes)
                if step_value isa Dates.Year
                    if all(dt -> Dates.month(dt) == 1, datetimes)
                        # Years only
                        return [Dates.format(dt, tickobj.y) for dt in datetimes]
                    else
                        return [Dates.format(dt, tickobj.ym) for dt in datetimes]
                    end
                elseif step_value isa Dates.Month
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
    elseif step_value isa Hour
        # Hourly steps - use multi-line format: time on top, date below when it changes
        ticklabels = Vector{String}(undef, n_ticks)
        prev_date = nothing
        
        for (i, dt) in enumerate(datetimes)
            current_date = Dates.Date(dt)
            time_part = Dates.format(dt, tickobj.HM)
            
            if i == 1 || current_date != prev_date
                # Show date below time when date changes or for first tick
                date_part = Dates.format(dt, tickobj.ymd)
                ticklabels[i] = time_part * "\n" * date_part
            else
                # Same date as previous tick, show only time
                ticklabels[i] = time_part
            end
            prev_date = current_date
        end
        return ticklabels
    elseif step_value isa Minute
        # Minute-level steps
        ticklabels = Vector{String}(undef, n_ticks)
        prev_date = nothing
        prev_hour = nothing
        
        for (i, dt) in enumerate(datetimes)
            current_date = Dates.Date(dt)
            current_hour = Dates.hour(dt)
            
            if i == 1 || current_date != prev_date
                # Show date below time when date changes or for first tick
                time_part = Dates.format(dt, tickobj.HM)
                date_part = Dates.format(dt, tickobj.ymd)
                ticklabels[i] = time_part * "\n" * date_part
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
    else
        # Second-level or sub-second steps
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
                if step_value isa Second
                    time_part = Dates.format(dt, tickobj.HMS)
                else
                    # Show milliseconds for sub-second steps
                    time_part = Dates.format(dt, tickobj.HMSs)
                end
                date_part = Dates.format(dt, tickobj.ymd)
                ticklabels[i] = time_part * "\n" * date_part
            elseif current_hour != prev_hour
                # Same date but different hour
                if step_value isa Second
                    ticklabels[i] = Dates.format(dt, tickobj.HMS)
                else
                    ticklabels[i] = Dates.format(dt, tickobj.HMSs)
                end
            elseif current_minute != prev_minute
                # Same hour but different minute
                if step_value isa Second
                    ticklabels[i] = Dates.format(dt, tickobj.MS)
                else
                    ticklabels[i] = Dates.format(dt, tickobj.MSs)
                end
            elseif step_value isa Second || current_second != prev_second
                # Different second, or using second-level steps
                if step_value isa Second
                    ticklabels[i] = Dates.format(dt, tickobj.S)
                else
                    ticklabels[i] = Dates.format(dt, tickobj.Ss)
                end
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
    end
end
