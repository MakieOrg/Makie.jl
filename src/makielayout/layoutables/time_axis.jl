using Dates, Unitful

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
    return Float64(ustrip(Unitful.upreferred(conv)))
end

function convert_from_preferred(unit, value)
    unitful = upreferred(unit) * value
    in_target_unit = uconvert(unit, unitful)
    return Float64(ustrip(in_target_unit))
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
        min_unit = best_unit(Quantity(new_min))
        max_unit = best_unit(Quantity(new_max))
        return max_unit
    end

    new_eltype <: Number && isnothing(unit) && return nothing

    error("Plotting $(new_eltype) into an axis set to: $(unit_symbol(unit)). Please convert the data to $(unit_symbol(unit))")
end

function unit_convert(ticks::TimeTicks, values)
    unit = new_unit(ticks.time_unit[], values[])
    ticks.time_unit[] = unit
    return map(unit_convert, ticks.time_unit, values)
end

function unit_convert(ticks, values)
    return values
end

function axis_convert(ax::TimeAxis, x, y)
    xconv = unit_convert(ax.axis.xticks[], x)
    yconv = unit_convert(ax.axis.yticks[], y)
    return xconv, yconv
end

function Makie.plot!(
        ta::TimeAxis, P::Makie.PlotFunc,
        attributes::Makie.Attributes, args...)

    converted_args = axis_convert(ta, convert.(Observable, args)...)
    return Makie.plot!(ta.axis, P, attributes, converted_args...)
end

function Makie.plot!(P::Makie.PlotFunc, ax::TimeAxis, args...; kw_attributes...)
    Makie.plot!(ax, P, Attributes(kw_attributes), args...)
end

export TimeAxis
