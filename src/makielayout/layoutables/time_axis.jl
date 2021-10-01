using GLMakie, Dates, Makie
using Unitful


struct TimeTicks
    time_unit
    time_range
    tickformatter
end
const UnitfulTimes = (
    typeof(1.0*u"d"), typeof(1.0*u"hr"), typeof(1.0*u"minute"),
    typeof(1.0*u"s"), typeof(1.0*u"ms"), typeof(1.0*u"μs"), typeof(1.0*u"ns"))

TimeUnits = Union{
    Number,  # No time units
    Nothing, # nothing yet
    UnitfulTimes...}

TimeTicks(ticks=Makie.automatic) = TimeTicks(Observable{Any}(nothing), Observable((Inf*u"ns", -Inf*u"ns")), ticks)
to_timeticks(ticks) = TimeTicks(ticks)
to_timeticks(ticks::TimeTicks) = ticks

struct TimeAxis
    axis::Axis
end

unit_symbol(::Type{T}) where T <: Unitful.AbstractQuantity = Unitful.unit(T)
unit_symbol(::Union{Number, Nothing}) = ""

function MakieLayout.get_ticks(ticks::TimeTicks, scale, formatter, vmin, vmax)
    tick_vals = MakieLayout.get_tickvalues(ticks.tickformatter, scale, vmin, vmax)
    unit = unit_symbol(ticks.time_unit[])
    labels = map(x-> string(x, unit), tick_vals)
    return tick_vals, labels
end

function TimeAxis(args...; xticks=TimeTicks(), yticks=TimeTicks(), kw...)
    ax = Axis(args...; xticks=to_timeticks(xticks), yticks=to_timeticks(yticks), kw...)
    return TimeAxis(ax)
end

unit_convert(::Nothing, range, x) = x
function unit_convert(::Type{T}, range, x) where T <: Unitful.AbstractQuantity
    return map(x) do x
        conv = convert(T, x)
        return Unitful.ustrip(conv)
    end
end

const TimeLike = Union{UnitfulTimes..., Period}

function best_unit(duration)
    # factor we fell comfortable to display as tick values
    val = 100
    duration < val * u"ns" && return typeof(1.0*u"ns")
    duration < val * u"μs" && return typeof(1.0*u"μs")
    duration < val * u"ms" && return typeof(1.0*u"ms")
    duration < val * u"s" && return typeof(1.0*u"s")
    duration < val * u"minute" && return typeof(1.0*u"minute")
    duration < val * u"hr" && return typeof(1.0*u"hr")
    return typeof(1.0*u"d")
end

function new_unit(unit, values, last_range)
    new_eltype = Union{}
    new_min = new_max = first(values)
    for elem in values
        new_eltype = promote_type(new_eltype, typeof(elem))
        new_min = min(elem, new_min)
        new_max = max(elem, new_max)
    end
    if new_eltype <: Union{Quantity, TimeLike}
        last_min, last_max = last_range
        new_range = (min(last_min, uconvert(u"ns", new_min)), max(last_max, uconvert(u"ns", new_max)))
        duration = new_range[2] - new_range[1]
        @show duration
        return best_unit(duration), new_range
    end

    new_eltype <: Number && isnothing(unit) && return (nothing, last_range)

    error("Plotting $(new_eltype) into an axis set to: $(unit_symbol(unit)). Please convert the data to $(unit_symbol(unit))")
    # isnothing(unit) && return new_eltype
    # return promote_type(new_eltype, unit)
end

function convert_times(ax::TimeAxis, x, y)
    xticks = ax.axis.xticks[]
    yticks = ax.axis.yticks[]

    xunit, xrange = new_unit(xticks.time_unit[], x[], xticks.time_range[])
    yunit, yrange = new_unit(yticks.time_unit[], y[], yticks.time_range[])

    xticks.time_unit[] = xunit
    xticks.time_range[] = xrange

    yticks.time_unit[] = yunit
    yticks.time_range[] = yrange

    xconv = map(unit_convert, xticks.time_unit, xticks.time_range, x)
    yconv = map(unit_convert, yticks.time_unit, yticks.time_range, y)

    return xconv, yconv
end

function Makie.plot!(
        ta::TimeAxis, P::Makie.PlotFunc,
        attributes::Makie.Attributes, args...)

    converted_args = convert_times(ta, convert.(Observable, args)...)

    return Makie.plot!(ta.axis, P, attributes, converted_args...)
end

function Makie.plot!(P::Makie.PlotFunc, ax::TimeAxis, args...; kw_attributes...)
    Makie.plot!(ax, P, Attributes(kw_attributes), args...)
end


begin
    f = Figure()
    ax = TimeAxis(f[1,1]; backgroundcolor=:white)
    scatter!(ax, rand(Second(1):Second(60):Second(20*60), 10), 1:10)
    f
end

begin
    scatter!(ax, rand(Hour(1):Hour(1):Hour(20), 10), 1:10)
    scatter!(ax, rand(10), 1:10)
end

begin
    f = Figure()
    ax = TimeAxis(f[1,1]; backgroundcolor=:white)
    scatter!(ax, u"ns" .* (1:10), u"d" .* rand(10) .* 10)
    f
end
