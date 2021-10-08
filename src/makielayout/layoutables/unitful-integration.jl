
using Dates, Unitful, Observables

const UNIT_POWER_OF_TENS = sort!(collect(keys(Unitful.prefixdict)))

const TIME_UNIT_NAMES = [:yr, :wk, :d, :hr, :minute, :s, :ds, :cs, :ms, :μs, :ns, :ps, :fs, :as, :zs, :ys]

base_unit(q::Quantity) = base_unit(typeof(q))
base_unit(::Type{Quantity{NumT, DimT, U}}) where {NumT, DimT, U} = base_unit(U)
base_unit(::Type{Unitful.FreeUnits{U, DimT, nothing}}) where {DimT, U} = U[1]
base_unit(::Unitful.FreeUnits{U, DimT, nothing}) where {DimT, U} = U[1]

function to_free_unit(unit, ::Quantity{T, Dim, Unitful.FreeUnits{U, Dim, nothing}}) where {T, Dim, U}
    return Unitful.FreeUnits{(unit,), Dim, nothing}()
end

get_all_base10_units(value) = get_all_base10_units(base_unit(value))

function get_all_base10_units(value::Unitful.Unit{Sym, Dim}) where {Sym, Dim}
    return Unitful.Unit{Sym, Dim}.(UNIT_POWER_OF_TENS, value.power)
end

function get_all_base10_units(::Unitful.Unit{Sym, Unitful.𝐓}) where {Sym, Dim}
    return getfield.((Unitful,), TIME_UNIT_NAMES)
end

ustrip_to_unit(unit, value) = Float64(ustrip(uconvert(unit, value)))

function best_unit(min, max)
    middle = (min + max) / 2.0
    all_units = get_all_base10_units(middle)
    current_unit = unit(middle)
    # Jeez, what a heuristic... TODO, do better!
    short_enough(value) = (1 < abs(value) < 999) || ((0 < abs(value) < 1.0) && abs(value) > 0.001)

    # Prefer current unit if short enough
    short_enough(ustrip(middle)) && return current_unit
    # TODO start from current unit!?
    for unit in all_units
        raw_value = ustrip(uconvert(unit, middle))
        if short_enough(raw_value)
            return unit
        end
    end
    return current_unit
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

function eltype_extrema(values)
    isempty(values) && return (eltype(values), nothing)

    new_eltype = typeof(first(values))
    new_min = new_max = first(values)

    for elem in Iterators.drop(values, 1)
        new_eltype = promote_type(new_eltype, typeof(elem))
        new_min = min(elem, new_min)
        new_max = max(elem, new_max)
    end
    return new_eltype, (new_min, new_max)
end

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
        return best_unit(qmin, qmax)
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
