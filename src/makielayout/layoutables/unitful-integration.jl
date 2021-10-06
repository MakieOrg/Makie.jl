
using Dates, Unitful, Observables

const UNIT_POWER_OF_TENS = sort!(collect(keys(Unitful.prefixdict)))

const TIME_UNIT_NAMES = [:yr, :wk, :d, :hr, :minute, :s, :ds, :cs, :ms, :μs, :ns, :ps, :fs]

base_unit(q::Quantity) = base_unit(typeof(q))
base_unit(::Type{Quantity{NumT, DimT, U}}) where {NumT, DimT, U} = base_unit(U)
base_unit(::Type{Unitful.FreeUnits{U, DimT, nothing}}) where {DimT, U} = U[1]
base_unit(::Unitful.FreeUnits{U, DimT, nothing}) where {DimT, U} = U[1]

function unit_in_middle(unit1::Unitful.Unit{Sym, Dim}, unit2::Unitful.Unit{Sym, Dim}) where {Sym, Dim}
    unit1 == unit2 && return Unitful.FreeUnits{(unit1,), Dim , nothing}()
    base10 = UNIT_POWER_OF_TENS
    idx1 = findfirst(==(Unitful.tens(unit1)), base10)
    isnothing(idx1) && error("Invalid base 10 $(Unitful.tens(unit1))")
    idx2 = findfirst(==(Unitful.tens(unit2)), base10)
    isnothing(idx2) && error("Invalid base 10 $(Unitful.tens(unit2))")
    middle = (idx1 + idx2) ÷ 2
    return Unitful.Unit{Sym, Dim}(base10[middle], unit1.power)
end

# Overload for irregular times
function unit_in_middle(unit1::Unitful.Unit{Sym1, Unitful.𝐓}, unit2::Unitful.Unit{Sym2, Unitful.𝐓}) where {Sym1, Sym2}
    unit1 == unit2 && return Unitful.FreeUnits{(unit1,), Unitful.𝐓 , nothing}()
    idx1 = findfirst(==(Symbol(unit1)), TIME_UNIT_NAMES)
    isnothing(idx1) && error("Unknown time unit $(unit1)")
    idx2 = findfirst(==(Symbol(unit2)), TIME_UNIT_NAMES)
    isnothing(idx2) && error("Unknown time unit $(unit2)")
    middle = (idx1 + idx2) ÷ 2
    return getfield(Unitful, TIME_UNIT_NAMES[middle])
end

function unit_in_middle(unit1, unit2)
    bu1 = base_unit(unit1)
    bu2 = base_unit(unit2)
    return unit_in_middle(bu1, bu2)
end


function to_free_unit(unit, ::Quantity{T, Dim, Unitful.FreeUnits{U, Dim, nothing}}) where {T, Dim, U}
    return Unitful.FreeUnits{(unit,), Dim, nothing}()
end

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

function best_unit(value)
    # factor we fell comfortable to display as tick values
    best_unit = to_free_unit(base_unit(value), value)
    raw_value = ustrip(value)
    while true
        if abs(raw_value) > 999
            _best_unit = to_free_unit(next_bigger_unit(best_unit), value)
        elseif abs(raw_value) > 0 && abs(raw_value) < 0.001
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

struct TimeTicks
    time_unit
    tickformatter
    units_in_label
end

TimeTicks(ticks=Makie.automatic; units_in_label=false) = TimeTicks(Observable{Any}(nothing), ticks, units_in_label)

to_timeticks(ticks) = TimeTicks(ticks)
to_timeticks(ticks::TimeTicks) = ticks

unit_convert(::Nothing, x) = x

function unit_convert(unit::T, x::AbstractArray) where T <: Union{Type{<:Unitful.AbstractQuantity}, Unitful.FreeUnits}
    return unit_convert.(unit, x)
end

function unit_convert(unit::T, value) where T <: Union{Type{<:Unitful.AbstractQuantity}, Unitful.FreeUnits}
    conv = uconvert(unit, value)
    return Float64(ustrip(Unitful.upreferred(conv)))
end

function convert_axis_dim(ticks::TimeTicks, values::Observable, limits::Observable)
    unit = new_unit(ticks.time_unit[], values[], limits[])
    ticks.time_unit[] = unit
    return ticks, map(unit_convert, ticks.time_unit, values)
end

ticks_from_type(::Type{<: Union{Period, Unitful.Quantity, Unitful.Units}}) = TimeTicks()

function new_unit(unit, values, existing_limits)
    new_eltype, extrema = eltype_extrema(values)
    # empty vector case:
    isnothing(extrema) && return nothing
    new_min, new_max = extrema
    if new_eltype <: Union{Quantity, Period}

        qmin = Quantity(new_min)
        qmax = Quantity(new_max)
        if unit isa Unitful.Units
            # limits are in preferred units when `unit` is already set to a Quantity unit
            # In that case, we can update the limits with the new range:
            qmin = min(qmin, existing_limits[1] * upreferred(unit))
            qmax = min(qmax, existing_limits[2] * upreferred(unit))
        end
        middle = (Quantity(new_min) + qmax) / 2.0
        # get the unit that works best for the middle of the range
        return best_unit(middle)
    end

    new_eltype <: Number && isnothing(unit) && return nothing

    error("Plotting $(new_eltype) into an axis set to: $(unit_symbol(unit)). Please convert the data to $(unit_symbol(unit))")
end

unit_symbol(::Type{T}) where T <: Unitful.AbstractQuantity = string(Unitful.unit(T))
unit_symbol(unit::Type{<: Unitful.FreeUnits}) = string(unit())
unit_symbol(unit::Unitful.FreeUnits) = string(unit)
unit_symbol(::Union{Number, Nothing}) = ""

convert_from_preferred(::Nothing, value) = value

function convert_from_preferred(unit, value)
    unitful = upreferred(unit) * value
    in_target_unit = uconvert(unit, unitful)
    return Float64(ustrip(in_target_unit))
end

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
        labels = MakieLayout.get_ticklabels(formatter, tick_vals)
        if !ticks.units_in_label
            labels = labels .* unit_str
        end
        return tick_vals_preferred, labels
    end
end
# TimeUnits = (:yr, :wk, :d, :hr, :minute, :s, :ds, :cs, :ms, :μs, :ns, :ps, :fs)
# TimeUnitsBig = map(TimeUnits[2:end]) do unit
#     next_bigger_unit(1.0 * getfield(Unitful, unit))
# end

# @test string.(TimeUnitsBig) == string.(TimeUnits[1:end-1])

# TimeUnitsSmaller = map(TimeUnits[1:end-1]) do unit
#     next_smaller_unit(1.0 * getfield(Unitful, unit))
# end

# @test string.(TimeUnitsSmaller) == string.(TimeUnits[2:end])

# PrefixFactors = last.(sort(collect(Unitful.prefixdict), by=first))
# MeterUnits = getfield.((Unitful,), Symbol.(PrefixFactors .* "m"))
# MeterUnits = map(MeterUnits[2:end]) do unit
#     next_bigger_unit(1.0 * unit)
# end

# TimeUnits = (:yr, :wk, :d, :hr, :minute, :s, :ds, :cs, :ms, :μs, :ns, :ps, :fs)
# UnitfulTimes = map(TimeUnits) do unit_name
#     Quantity{T,  Unitful.𝐓, typeof(getfield(Unitful, unit_name))} where T
# end
# TimeUnits2 = Union{UnitfulTimes...}
# const TimeLike = Union{UnitfulTimes..., Period}
