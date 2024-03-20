using Dates, Observables
import Unitful
using Unitful: Quantity, @u_str, uconvert, ustrip, upreferred

const SupportedUnits = Union{Period,Unitful.Quantity,Unitful.Units}

axis_conversion_type(::Type{<:SupportedUnits}) = UnitfulConversion()
MakieCore.can_axis_convert_type(::Type{<:SupportedUnits}) = true

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

unit_string_long(unit) = unit_string_long(base_unit(unit))
unit_string_long(::Unitful.Unit{Sym, D}) where {Sym, D} = string(Sym)

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

function new_unit(unit, values)
    new_eltype, extrema = eltype_extrema(values)
    # empty vector case:
    isnothing(extrema) && return nothing
    new_min, new_max = extrema
    if new_eltype <: Union{Quantity, Period}
        qmin = Quantity(new_min)
        qmax = Quantity(new_max)
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
    # By only returning this one value, we simply don't chose any different unit as a fallback
    return [value]
end

function get_all_base10_units(x::Unitful.Unit{Sym, Unitful.𝐓}) where {Sym}
    return getfield.((Unitful,), TIME_UNIT_NAMES)
end

ustrip_to_unit(unit, value) = Float64(ustrip(uconvert(unit, value)))

function best_unit(min, max)
    middle = (min + max) / 2.0
    all_units = get_all_base10_units(middle)
    _, index = findmin(all_units) do unit
        raw_value = abs(ustrip(uconvert(to_free_unit(unit, middle), middle)))
        # We want the unit that displays the value with the smallest number possible, but not something like 1.0e-19
        # So, for fractions between 0..1, we use inv to penalize really small fractions
        positive = raw_value < 1.0 ? (inv(raw_value) + 100) : raw_value
        return positive
    end
    return all_units[index]
end

unit_convert(::Automatic, x) = x

function unit_convert(unit::T, x::AbstractArray) where T <: Union{Type{<:Unitful.AbstractQuantity}, Unitful.FreeUnits, Unitful.Unit}
    return unit_convert.(Ref(unit), x)
end

# We always convert to preferred unit!
function unit_convert(unit::T, value) where T <: Union{Type{<:Unitful.AbstractQuantity}, Unitful.FreeUnits, Unitful.Unit}
    conv = uconvert(to_free_unit(unit, value), value)
    return Float64(ustrip(conv))
end

convert_from_preferred(::Automatic, value) = value

function convert_from_preferred(unit, value)
    unitful = to_free_unit(unit) * value
    return unitful
end

function convert_from_preferred_striped(unit, value)
    unitful = convert_from_preferred(unit, value)
    return Float64(ustrip(unitful))
end

convert_to_preferred(::Automatic, value) = value
convert_to_preferred(unit, value) = ustrip(to_free_unit(unit) * value)

# Overload conversion functions for Axis, to properly display units

"""
    UnitfulConversion(unit=automatic; units_in_label=false, short_label=false, conversion=Makie.automatic)

Allows to plot arrays of unitful objects into an axis.

# Arguments

- `unit=automatic`: sets the unit as conversion target. If left at automatic, the best unit will be chosen for all plots + values plotted to the axis (e.g. years for long periods, or km for long distances, or nanoseconds for short times).
- `units_in_label=false`: controls, whether plots are shown in the label_prefix of the axis labels, or in the tick labels

# Examples

```julia
using Unitful, CairoMakie

# UnitfulConversion will get chosen automatically:
scatter(1:4, [1u"ns", 2u"ns", 3u"ns", 4u"ns"])

# fix unit to always use Meter & display unit in the xlabel postfix
convert = UnitfulConversion(u"m"; units_in_label=true)
scatter(1:4, [0.01u"km", 0.02u"km", 0.03u"km", 0.04u"km"]; axis=(y_dim_convert=convert,))
```
"""
struct UnitfulConversion <: AxisConversion
    unit::Observable{Any}
    automatic_units::Bool
    units_in_label::Observable{Bool}
    extrema::Dict{UInt64, Tuple{Any, Any}}
end

function UnitfulConversion(unit=automatic; units_in_label=false)
    extrema = Dict{UInt64, Tuple{Any, Any}}()
    return UnitfulConversion(unit, unit isa Automatic, units_in_label, extrema)
end

needs_tick_update_observable(conversion::UnitfulConversion) = conversion.unit

function connect_conversion!(ax::AbstractAxis, conversion::UnitfulConversion, dim)
    if conversion.automatic_units
        on(ax.blockscene, ax.finallimits) do limits
            unit = conversion.unit[]
            # Only time & length units are tested/supported right now
            if !(unit isa Automatic) && Unitful.dimension(unit) in (Unitful.𝐓, Unitful.𝐋)
                mini, maxi = getindex.(extrema(limits), dim)
                t(v) = to_free_unit(unit) * v
                new_unit = best_unit(t(mini), t(maxi))
                if new_unit != unit
                    conversion.unit[] = new_unit
                end
            end
        end
    end
end

function get_ticks(conversion::UnitfulConversion, ticks, scale, formatter, vmin, vmax)
    unit = conversion.unit[]
    unit isa Automatic && return [], []
    vmin_tu = convert_from_preferred_striped(unit, vmin)
    vmax_tu = convert_from_preferred_striped(unit, vmax)
    unit_str = unit_string(unit)
    tick_vals = get_tickvalues(ticks, scale, vmin_tu, vmax_tu)
    tick_vals_preferred = convert_to_preferred.((unit,), tick_vals)

    labels = get_ticklabels(formatter, tick_vals)
    if !conversion.units_in_label[]
        labels = labels .* unit_str
    end
    return tick_vals_preferred, labels
end

function convert_axis_dim(conversion::UnitfulConversion, values::Observable)
    if conversion.unit[] isa Automatic
        unit = new_unit(conversion.unit[], values[])
        conversion.unit[] = unit
    end
    return map(conversion.unit, values) do unit, values
        if conversion.automatic_units
            unit = new_unit(unit, values)
            conversion.unit[] = unit
        end
        unit_convert(unit, values)
    end
end

function convert_axis_value(conversion::UnitfulConversion, value::SupportedUnits)
    return unit_convert(conversion.unit[], value)
end
