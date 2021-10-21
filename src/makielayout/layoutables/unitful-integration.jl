
using Dates, Unitful, Observables

const UNIT_POWER_OF_TENS = sort!(collect(keys(Unitful.prefixdict)))

const TIME_UNIT_NAMES = [:yr, :wk, :d, :hr, :minute, :s, :ds, :cs, :ms, :μs, :ns, :ps, :fs, :as, :zs, :ys]

base_unit(q::Quantity) = base_unit(typeof(q))
base_unit(::Type{Quantity{NumT, DimT, U}}) where {NumT, DimT, U} = base_unit(U)
base_unit(::Type{Unitful.FreeUnits{U, DimT, nothing}}) where {DimT, U} = U[1]
base_unit(::Unitful.FreeUnits{U, DimT, nothing}) where {DimT, U} = U[1]
base_unit(x::Unitful.Unit) = x

unit_string(::Type{T}) where T <: Unitful.AbstractQuantity = string(Unitful.unit(T))
unit_string(unit::Type{<: Unitful.FreeUnits}) = string(unit())
unit_string(unit::Unitful.FreeUnits) = unit_string(base_unit(unit))
unit_string(unit::Unitful.Unit) = string(unit)
unit_string(::Union{Number, Nothing}) = ""

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

    error("Plotting $(new_eltype) into an axis set to: $(unit_string(unit)). Please convert the data to $(unit_string(unit))")
end

to_free_unit(unit::Unitful.FreeUnits, _) = unit
to_free_unit(unit::Unitful.FreeUnits, ::Quantity) = unit
to_free_unit(unit::Unitful.FreeUnits, ::Quantity{T, Dim, Unitful.FreeUnits{U, Dim, nothing}}) where {T, Dim, U} = unit
function to_free_unit(unit, ::Quantity{T, Dim, Unitful.FreeUnits{U, Dim, nothing}}) where {T, Dim, U}
    return Unitful.FreeUnits{(unit,), Dim, nothing}()
end

to_free_unit(unit::Unitful.FreeUnits) = unit
function to_free_unit(unit::Unitful.Unit{Sym, Dim}) where {Sym, Dim}
    return Unitful.FreeUnits{(unit,), Dim, nothing}()
end


get_all_base10_units(value) = get_all_base10_units(base_unit(value))

function get_all_base10_units(value::Unitful.Unit{Sym, Unitful.𝐋}) where {Sym}
    return Unitful.Unit{Sym, Unitful.𝐋}.(UNIT_POWER_OF_TENS, value.power)
end

function get_all_base10_units(value::Unitful.Unit)
    # TODO, why does nothing work in a generic way in Unitful!?
    return [value]
end

function get_all_base10_units(::Unitful.Unit{Sym, Unitful.𝐓}) where {Sym, Dim}
    return getfield.((Unitful,), TIME_UNIT_NAMES)
end

ustrip_to_unit(unit, value) = Float64(ustrip(uconvert(unit, value)))

function best_unit(min, max)
    middle = (min + max) / 2.0
    all_units = get_all_base10_units(middle)
    current_unit = unit(middle)
    # TODO start from current unit!?
    value, index = findmin(all_units) do unit
        raw_value = ustrip(uconvert(to_free_unit(unit, middle), middle))
        return abs(raw_value - 100)
    end
    return all_units[index]
end

unit_convert(::Nothing, x) = x

function unit_convert(unit::T, x::AbstractArray) where T <: Union{Type{<:Unitful.AbstractQuantity}, Unitful.FreeUnits, Unitful.Unit}
    return unit_convert.((unit,), x)
end

function unit_convert(unit::T, value) where T <: Union{Type{<:Unitful.AbstractQuantity}, Unitful.FreeUnits, Unitful.Unit}
    conv = uconvert(to_free_unit(unit, value), value)
    return Float64(ustrip(Unitful.upreferred(conv)))
end

convert_from_preferred(::Nothing, value) = value

function convert_from_preferred(unit, value)
    uf = to_free_unit(unit)
    unitful = upreferred(uf) * value
    in_target_unit = uconvert(uf, unitful)
    return Float64(ustrip(in_target_unit))
end

convert_to_preferred(::Nothing, value) = value
convert_to_preferred(unit, value) = ustrip(upreferred(to_free_unit(unit) * value))

# Overload conversion functions for Axis, to properly display units

struct UnitfulTicks
    unit
    tickformatter
    units_in_label
end

UnitfulTicks(ticks=Makie.automatic; units_in_label=false) = UnitfulTicks(Observable{Any}(nothing), ticks, units_in_label)

label_postfix(ticks::UnitfulTicks) = map(x-> string("(", unit_string(x), ")"), ticks.unit)

function MakieLayout.get_ticks(ticks::UnitfulTicks, scale, formatter, vmin, vmax)
    unit = ticks.unit[]
    vmin_tu = convert_from_preferred(unit, vmin)
    vmax_tu = convert_from_preferred(unit, vmax)
    unit_str = unit_string(unit)
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

ticks_from_type(::Type{<: Union{Period, Unitful.Quantity, Unitful.Units}}) = UnitfulTicks()

function convert_axis_dim(ticks::UnitfulTicks, values::Observable, limits::Observable)
    unit = new_unit(ticks.unit[], values[], limits[])
    ticks.unit[] = unit
    return map(unit_convert, ticks.unit, values)
end
