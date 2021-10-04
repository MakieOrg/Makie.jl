using GLMakie, Dates, Makie
using Unitful

struct TimeTicks
    time_unit
    tickformatter
end

TimeUnits = (:yr, :wk, :d, :hr, :minute, :s, :ms, :μs, :ns, :fs)

UnitfulTimes2 = map(TimeUnits) do unit_name
    Quantity{T, Unitful.𝐓, Unitful.FreeUnits{(getfield(Unitful, unit_name),), Unitful.𝐋, nothing}} where T <: Number
end

TimeUnits2 = Union{UnitfulTimes...}

TimeTicks(ticks=Makie.automatic) = TimeTicks(Observable{Any}(nothing), ticks)
to_timeticks(ticks) = TimeTicks(ticks)
to_timeticks(ticks::TimeTicks) = ticks

struct TimeAxis
    axis::Axis
end

unit_symbol(::Type{T}) where T <: Unitful.AbstractQuantity = string(Unitful.unit(T))
unit_symbol(::Union{Number, Nothing}) = ""

unit_convert(::Nothing, range, x) = x

function unit_convert(::Type{T}, x::AbstractArray) where T
    return unit_convert.(T, x)
end

function unit_convert(::Type{T}, value) where T <: Unitful.AbstractQuantity
    conv = convert(T, value)
    preferred_unitless = conv / unit(Unitful.preferunits(conv))
    return convert(Float64, preferred_unitless)
end

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

const TimeLike = Union{UnitfulTimes..., Period}



function new_unit(unit, values, last_range)
    new_eltype = Union{}
    new_min = new_max = first(values)
    for elem in values
        new_eltype = promote_type(new_eltype, typeof(elem))
        new_min = min(elem, new_min)
        new_max = max(elem, new_max)
    end
    if new_eltype <: Union{Quantity, Period}
        duration = new_max - new_min
        return best_unit(duration)
    end

    new_eltype <: Number && isnothing(unit) && return (nothing, last_range)

    error("Plotting $(new_eltype) into an axis set to: $(unit_symbol(unit)). Please convert the data to $(unit_symbol(unit))")
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
    # scatter!(ax, rand(10), 1:10) # should error!
end

begin
    f = Figure()
    ax = TimeAxis(f[1,1]; backgroundcolor=:white)
    ax.finallimits
    scatter!(ax, u"ns" .* (1:10), u"d" .* rand(10) .* 10)
    f
end

base_unit(q::Quantity) = base_unit(typeof(q))
base_unit(::Type{Quantity{NumT, DimT, U}}) where {NumT, DimT, U} = base_unit(U)
base_unit(::Type{Unitful.FreeUnits{U, DimT, nothing}}) where {DimT, U} = U[1]

function next_smaller_unit(::Quantity{T, Dim, Unitful.FreeUnits{U, Dim, nothing}}) where {T, Dim, U}
    next_smaller_unit(U[1])
end

function next_smaller_unit(::Unitful.FreeUnits{U, Dim, nothing}) where {Dim, U}
    next_smaller_unit(U[1])
end

function next_smaller_unit(unit::Unitful.Unit{USym, Dim}) where {USym, Dim}
    return next_smaller_unit_generic(unit)
end

function next_bigger_unit(::Quantity{T, Dim, Unitful.FreeUnits{U, Dim, nothing}}) where {T, Dim, U}
    next_bigger_unit(U[1])
end

function next_bigger_unit(::Unitful.FreeUnits{U, Dim, nothing}) where {Dim, U}
    next_bigger_unit(U[1])
end

function next_bigger_unit(unit::Unitful.Unit{USym, Dim}) where {USym, Dim}
    return next_bigger_unit_generic(unit)
end

function next_bigger_unit_generic(unit::Unitful.Unit{USym, Dim}) where {USym, Dim}
    next = (unit.tens >= 3 || unit.tens <= -6) ? 3 : 1
    abs(next) > 24 && return unit
    return Unitful.Unit{USym, Dim}(unit.tens + next, unit.power)
end

function next_smaller_unit_generic(unit::Unitful.Unit{USym, Dim}) where {USym, Dim}
    next = (unit.tens >= 6 || unit.tens <= -3) ? 3 : 1
    abs(next) > 24 && return unit
    return Unitful.Unit{USym, Dim}(unit.tens - next, unit.power)
end

function next_bigger_unit(unit::Unitful.Unit{USym, Unitful.𝐓}) where {USym}
    irregular = (:Year, :Week, :Day, :Hour, :Minute, :Second)
    if USym === :Second && unit.tens < 0
        return next_bigger_unit_generic(unit)
    else
        idx = findfirst(==(USym), irregular)
        idx == 1 && return unit
        return Unitful.Unit{irregular[idx - 1], Unitful.𝐓}(0, 1//1)
    end
end

function next_smaller_unit(unit::Unitful.Unit{USym, Unitful.𝐓}) where {USym}
    USym === :Second && return next_smaller_unit_generic(unit)
    irregular = (:Year, :Week, :Day, :Hour, :Minute)
    idx = findfirst(==(USym), irregular)
    if isnothing(idx)
        error("What unit is this: $(unit)!?")
    else
        idx == length(irregular) && return Unitful.Unit{:Second, Unitful.𝐓}(0, 1//1)
        return Unitful.Unit{irregular[idx + 1], Unitful.𝐓}(0, 1//1)
    end
end

function to_free_unit(unit, value::Quantity{T, Dim, Unitful.FreeUnits{U, Dim, nothing}}) where {T, Dim, U}
    return Unitful.FreeUnits{(unit,), Dim, nothing}()
end

function unit_convert(unit, value::Quantity{T, Dim, Unitful.FreeUnits{U, Dim, nothing}}) where {T, Dim, U}
    return uconvert(to_free_unit(unit, value), value)
end

function _best_unit(value)
    # factor we fell comfortable to display as tick values
    best_unit = to_free_unit(base_unit(value), value)
    raw_value = ustrip(value)
    while true
        if abs(raw_value) > 100
            _best_unit = to_free_unit(next_bigger_unit(best_unit), value)
        elseif abs(raw_value) < 0.001
            _best_unit = to_free_unit(next_smaller_unit(best_unit), value)
        else
            return best_unit
        end
        if _best_unit == best_unit
            return best_unit # we reached max unit
        else
            best_unit = _best_unit
            raw_value = ustrip(uconvert(best_unit, value))
        end
    end
end

TimeUnits = (:yr, :wk, :d, :hr, :minute, :s, :ds, :cs, :ms, :μs, :ns, :ps, :fs)
TimeUnitsBig = map(TimeUnits[2:end]) do unit
    next_bigger_unit(1.0 * getfield(Unitful, unit))
end

@test string.(TimeUnitsBig) == string.(TimeUnits[1:end-1])

TimeUnitsSmaller = map(TimeUnits[1:end-1]) do unit
    next_smaller_unit(1.0 * getfield(Unitful, unit))
end

@test string.(TimeUnitsSmaller) == string.(TimeUnits[2:end])

PrefixFactors = last.(sort(collect(Unitful.prefixdict), by=first))
MeterUnits = getfield.((Unitful,), Symbol.(PrefixFactors .* "m"))
MeterUnits = map(MeterUnits[2:end]) do unit
    next_bigger_unit(1.0 * unit)
end
