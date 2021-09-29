using GLMakie, Dates, Makie

struct TimeTicks
    time_unit
    time_range
    tickformatter
end

TimeTicks(ticks=Makie.automatic) = TimeTicks(Observable{Any}(nothing), Observable{Any}((Inf, -Inf)), ticks)
to_timeticks(ticks) = TimeTicks(ticks)
to_timeticks(ticks::TimeTicks) = ticks

struct TimeAxis
    axis::Axis
end

unit_symbol(::Type{Hour}) = "Hr"
unit_symbol(::Type{Second}) = "s"
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
unit_convert(::Type{T}, range, x) where T <: Period = map(x-> convert(T, x).value, x)

function new_unit(unit, values)
    new_eltype = mapreduce(typeof, promote_type, values)
    new_eltype <: Number && isnothing(unit) && return nothing
    isnothing(unit) && return new_eltype
    return promote_type(new_eltype, unit)
end

function convert_times(ax::TimeAxis, x, y)
    xticks = ax.axis.xticks[]
    yticks = ax.axis.yticks[]

    xticks.time_unit[] = new_unit(xticks.time_unit[], x[])
    yticks.time_unit[] = new_unit(yticks.time_unit[], y[])

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


f = Figure()
ax = TimeAxis(f[1,1]; backgroundcolor=:white)
scatter!(ax, rand(Hour(1):Hour(1):Hour(20), 10), 1:10)
scatter!(ax, rand(Second(1):Second(60*60):Second(20*60*60), 10), 1:10)
f
