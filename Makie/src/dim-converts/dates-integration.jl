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

function locate_datetime_ticks(dtt::DateTimeTicks3, start_dt::DateTime, end_dt::DateTime)
    total_duration = end_dt - start_dt
    total_hours = total_duration / Hour(1)
    total_days = total_hours / 24
    
    # Handle edge case where duration is zero or negative
    if total_duration <= Millisecond(0)
        return start_dt:Millisecond(1):start_dt
    end
    
    # Define tick count acceptance range based on k_ideal or explicit k_min/k_max
    min_ticks = something(dtt.k_min, max(2, round(Int, dtt.k_ideal * 0.66)))
    max_ticks = something(dtt.k_max, round(Int, dtt.k_ideal * 1.33))
    @assert min_ticks <= dtt.k_ideal <= max_ticks
    
    # Helper function to check if tick count is acceptable
    # Prefer tick counts closer to k_ideal
    function is_acceptable_tick_count(tick_count)
        in_range = tick_count >= min_ticks && tick_count <= max_ticks
        # For better responsiveness, prefer tick counts closer to k_ideal
        # Accept if within range, but algorithm will try finer granularity if far from ideal
        return in_range
    end
    
    # 1. Try yearly ticks (for very long ranges)
    if total_days >= 365 * 2  # 2+ years
        step_years = max(1, round(Int, total_days / (dtt.k_ideal * 365)))
        
        # Use nice round step sizes: 1, 2, 5, 10, 25, 50, 100, 200, 500 years
        nice_steps = [1, 2, 5, 10, 25, 50, 100, 200, 500]
        step_years = nice_steps[argmin(abs.(nice_steps .- step_years))]
        step = Year(step_years)
        
        # Round start to a nice year boundary
        start_year = Dates.year(start_dt)
        if step_years >= 100
            # Round to nearest century
            rounded_year = (start_year ÷ 100) * 100
        elseif step_years >= 50
            # Round to nearest half-century
            rounded_year = (start_year ÷ 50) * 50
        elseif step_years >= 25
            # Round to nearest quarter-century
            rounded_year = (start_year ÷ 25) * 25
        elseif step_years >= 10
            # Round to nearest decade
            rounded_year = (start_year ÷ 10) * 10
        elseif step_years >= 5
            # Round to nearest 5-year boundary
            rounded_year = (start_year ÷ 5) * 5
        else
            # Use exact start year
            rounded_year = start_year
        end
        
        tick_start = DateTime(rounded_year, 1, 1)
        if tick_start < start_dt
            tick_start += step
        end
        
        tick_count = length(tick_start:step:end_dt)
        if is_acceptable_tick_count(tick_count)
            return tick_start:step:end_dt
        end
    end
    
    # 2. Try monthly ticks
    if total_days >= 58  # 2+ months
        step_months = max(1, round(Int, total_days / (dtt.k_ideal * 30)))
        nice_steps = [1, 2, 3, 4, 6, 12]
        step_months = nice_steps[argmin(abs.(nice_steps .- step_months))]
        step = Month(step_months)
        tick_start = DateTime(Dates.year(start_dt), Dates.month(start_dt), 1)
        if tick_start < start_dt
            tick_start += step
        end
        
        tick_count = length(tick_start:step:end_dt)
        if is_acceptable_tick_count(tick_count)
            return tick_start:step:end_dt
        end
    end
    
    # 3. Try daily ticks
    if total_days >= 2
        step_days = max(1, round(Int, total_days / dtt.k_ideal))
        nice_steps = [1, 2, 3, 7, 14, 30]  # Include weekly and bi-weekly options
        step_days = nice_steps[argmin(abs.(nice_steps .- step_days))]
        step = Day(step_days)
        tick_start = DateTime(Dates.Date(start_dt))
        if tick_start < start_dt
            tick_start += step
        end
        
        tick_count = length(tick_start:step:end_dt)
        if is_acceptable_tick_count(tick_count)
            return tick_start:step:end_dt
        end
    end
    
    # 4. Try hourly ticks
    if total_hours >= 2  # 2+ hours
        step_hours_calc = total_hours / dtt.k_ideal
        # Guard against very small step calculations that could cause overflow
        if step_hours_calc > 0 && isfinite(step_hours_calc)
            step_hours = max(1, round(Int, step_hours_calc))
            nice_steps = [1, 2, 3, 4, 6, 8, 12, 24]  # Include 24-hour option
            step_hours = nice_steps[argmin(abs.(nice_steps .- step_hours))]
            step = Hour(step_hours)
            
            # Count how many ticks this would give
            start_hour = Dates.hour(start_dt)
            rounded_hour = (start_hour ÷ step_hours) * step_hours
            tick_start = DateTime(Dates.Date(start_dt)) + Hour(rounded_hour)
            if tick_start < start_dt
                tick_start += step
            end
            
            tick_count = length(tick_start:step:end_dt)
            if is_acceptable_tick_count(tick_count)
                return tick_start:step:end_dt
            end
        end
    end
    
    # Try minute ticks
    total_minutes = total_hours * 60
    if total_minutes >= 2
        step_minutes_calc = total_minutes / dtt.k_ideal
        if step_minutes_calc > 0 && isfinite(step_minutes_calc)
            step_minutes = max(1, round(Int, step_minutes_calc))
            nice_steps = [1, 2, 5, 10, 15, 30]
            step_minutes = nice_steps[argmin(abs.(nice_steps .- step_minutes))]
            step = Minute(step_minutes)
            
            start_minute = Dates.minute(start_dt)
            rounded_minute = (start_minute ÷ step_minutes) * step_minutes
            tick_start = DateTime(Dates.Date(start_dt)) + Hour(Dates.hour(start_dt)) + Minute(rounded_minute)
            if tick_start < start_dt
                tick_start += step
            end
            
            tick_count = length(tick_start:step:end_dt)
            
            # If we get acceptable tick count and it's not too far below ideal, use minutes
            if is_acceptable_tick_count(tick_count)
                return tick_start:step:end_dt
            end
        end
    end
    
    # Try second ticks
    total_seconds = total_hours * 3600
    if total_seconds >= 2
        step_seconds_calc = total_seconds / dtt.k_ideal
        if step_seconds_calc > 0 && isfinite(step_seconds_calc)
            step_seconds = max(1, round(Int, step_seconds_calc))
            nice_steps = [1, 2, 5, 10, 15, 20, 30]
            step_seconds = nice_steps[argmin(abs.(nice_steps .- step_seconds))]
            step = Second(step_seconds)
            
            start_second = Dates.second(start_dt)
            rounded_second = (start_second ÷ step_seconds) * step_seconds
            tick_start = DateTime(Dates.Date(start_dt)) + Hour(Dates.hour(start_dt)) + 
                        Minute(Dates.minute(start_dt)) + Second(rounded_second)
            if tick_start < start_dt
                tick_start += step
            end
            
            tick_count = length(tick_start:step:end_dt)
            
            # Only use seconds if tick count is reasonable
            if is_acceptable_tick_count(tick_count)
                return tick_start:step:end_dt
            end
        end
    end
    
    # Fall back to millisecond ticks (with bounds checking)
    total_milliseconds = total_hours * 3600 * 1000
    if total_milliseconds > 0 && isfinite(total_milliseconds)
        step_milliseconds_calc = total_milliseconds / dtt.k_ideal
        if step_milliseconds_calc > 0 && isfinite(step_milliseconds_calc)
            step_milliseconds = max(1, round(Int, step_milliseconds_calc))
            nice_steps = [1, 2, 5, 10, 20, 50, 100, 200, 500]
            step_milliseconds = nice_steps[argmin(abs.(nice_steps .- step_milliseconds))]
            step = Millisecond(step_milliseconds)
            
            start_millisecond = Dates.millisecond(start_dt)
            rounded_millisecond = (start_millisecond ÷ step_milliseconds) * step_milliseconds
            tick_start = DateTime(Dates.Date(start_dt)) + Hour(Dates.hour(start_dt)) + 
                        Minute(Dates.minute(start_dt)) + Second(Dates.second(start_dt)) + 
                        Millisecond(rounded_millisecond)
            if tick_start < start_dt
                tick_start += step
            end
            
            tick_count = length(tick_start:step:end_dt)
            
            # If still too many ticks, fall back to a reasonable default
            if tick_count > max_ticks
                # Use hourly ticks as a safe fallback
                safe_step_hours = max(1, round(Int, total_hours / max_ticks))
                step = Hour(safe_step_hours)
                tick_start = DateTime(Dates.Date(start_dt))
                if tick_start < start_dt
                    tick_start += step
                end
                return tick_start:step:end_dt
            end
            
            return tick_start:step:end_dt
        end
    end
    
    error("Did not determine a format for vmin=$start_dt to vmax=$end_dt")
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
