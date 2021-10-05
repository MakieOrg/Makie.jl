using GLMakie, Dates, Makie
using Unitful
include("unitful-integration.jl")

struct TimeTicks
    time_unit
    tickformatter
end

TimeTicks(ticks=Makie.automatic) = TimeTicks(Observable{Any}(nothing), ticks)
to_timeticks(ticks) = TimeTicks(ticks)
to_timeticks(ticks::TimeTicks) = ticks

struct TimeAxis
    axis::Axis
end

unit_symbol(::Type{T}) where T <: Unitful.AbstractQuantity = string(Unitful.unit(T))
unit_symbol(unit::Type{<: Unitful.FreeUnits}) = string(unit())
unit_symbol(unit::Unitful.FreeUnits) = string(unit)
unit_symbol(::Union{Number, Nothing}) = ""

unit_convert(::Nothing, x) = x

function unit_convert(unit::T, x::AbstractArray) where T <: Union{Type{<:Unitful.AbstractQuantity}, Unitful.FreeUnits}
    return unit_convert.(unit, x)
end

function unit_convert(unit::T, value) where T <: Union{Type{<:Unitful.AbstractQuantity}, Unitful.FreeUnits}
    conv = uconvert(unit, value)
    return ustrip(Unitful.upreferred(conv))
end

function convert_from_preferred(unit, value)
    unitful = upreferred(unit) * value
    in_target_unit = uconvert(unit, unitful)
    return ustrip(in_target_unit)
end
convert_from_preferred(::Nothing, value) = value

convert_to_preferred(::Nothing, value) = value
convert_to_preferred(unit, value) = ustrip(upreferred(unit * value))

function MakieLayout.get_ticks(ticks::TimeTicks, scale, formatter, vmin, vmax)
    unit = ticks.time_unit[]
    vmin_tu = convert_from_preferred(unit, vmin)
    vmax_tu = convert_from_preferred(unit, vmax)
    unit_str = unit_symbol(unit)
    tick_vals = MakieLayout.get_tickvalues(ticks.tickformatter, scale, vmin_tu, vmax_tu)
    tick_vals_preferred = convert_to_preferred.((unit,), tick_vals)
    if isnothing(unit)
        return tick_vals_preferred, MakieLayout.get_ticklabels(formatter, tick_vals)
    else
        labels = MakieLayout.get_ticklabels(formatter, tick_vals) .* unit_str
        return tick_vals_preferred, labels
    end
end

function TimeAxis(args...; xticks=TimeTicks(), yticks=TimeTicks(), kw...)
    ax = Axis(args...; xticks=to_timeticks(xticks), yticks=to_timeticks(yticks), kw...)
    return TimeAxis(ax)
end

function new_unit(unit, values)
    isempty(values) && return unit

    new_eltype = typeof(first(values))
    new_min = new_max = first(values)

    for elem in Iterators.drop(values, 1)
        new_eltype = promote_type(new_eltype, typeof(elem))
        new_min = min(elem, new_min)
        new_max = max(elem, new_max)
    end

    if new_eltype <: Union{Quantity, Period}
        duration = new_max - new_min
        return best_unit(Quantity(duration))
    end

    new_eltype <: Number && isnothing(unit) && return nothing

    error("Plotting $(new_eltype) into an axis set to: $(unit_symbol(unit)). Please convert the data to $(unit_symbol(unit))")
end

function convert_times(ax::TimeAxis, x, y)
    xticks = ax.axis.xticks[]
    yticks = ax.axis.yticks[]

    xunit = new_unit(xticks.time_unit[], x[])
    yunit = new_unit(yticks.time_unit[], y[])

    xticks.time_unit[] = xunit
    yticks.time_unit[] = yunit

    xconv = map(unit_convert, xticks.time_unit, x)
    yconv = map(unit_convert, yticks.time_unit, y)

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
    ax.axis.finallimits
    scatter!(ax, u"ns" .* (1:10), u"d" .* rand(10) .* 10)
    f
end

begin
    f = Figure()
    ax = TimeAxis(f[1,1]; backgroundcolor=:white)
    scatter!(ax, u"km" .* (1:10), u"d" .* rand(10) .* 10)
    f
end
