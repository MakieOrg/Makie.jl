
using Dates, Observables
import Unitful
using Unitful: Quantity, @u_str

const UNIT_POWER_OF_TENS = sort!(collect(keys(Unitful.prefixdict)))

const TIME_UNIT_NAMES = [:yr, :wk, :d, :hr, :minute, :s, :ds, :cs, :ms, :μs, :ns, :ps, :fs, :as, :zs, :ys]

base_unit(q::Quantity) = base_unit(typeof(q))
base_unit(::Type{Quantity{NumT, DimT, U}}) where {NumT, DimT, U} = base_unit(U)
base_unit(::Type{Unitful.FreeUnits{U, DimT, nothing}}) where {DimT, U} = U[1]
base_unit(x::Unitful.FreeUnits{U, DimT, nothing}) where {DimT, U} = U[1]
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
        # I think values are easiest to read between 0-100, so we want values close to 50
        return abs(positive - 50)
    end
    return all_units[index]
end

unit_convert(::Automatic, x) = x

function unit_convert(unit::T, x::AbstractArray) where T <: Union{Type{<:Unitful.AbstractQuantity}, Unitful.FreeUnits, Unitful.Unit}
    return unit_convert.((unit,), x)
end

# We always convert to preferred unit!
function unit_convert(unit::T, value) where T <: Union{Type{<:Unitful.AbstractQuantity}, Unitful.FreeUnits, Unitful.Unit}
    conv = uconvert(to_free_unit(unit, value), value)
    return Float64(ustrip(Unitful.upreferred(conv)))
end

convert_from_preferred(::Automatic, value) = value

function convert_from_preferred(unit, value)
    uf = to_free_unit(unit)
    unitful = upreferred(uf) * value
    return uconvert(uf, unitful)
end

function convert_from_preferred_striped(unit, value)
    unitful = convert_from_preferred(unit, value)
    return Float64(ustrip(unitful))
end

convert_to_preferred(::Automatic, value) = value
convert_to_preferred(unit, value) = ustrip(upreferred(to_free_unit(unit) * value))

# Overload conversion functions for Axis, to properly display units

"""
    UnitfulTicks(unit=automatic; units_in_label=false, short_label=false, ticks=Makie.automatic)

Allows to plot arrays of unitful objects into an axis.

# Arguments

- `unit=automatic`: sets the unit as conversion target. If left at automatic, the best unit will be chosen for all plots + values plotted to the axis (e.g. years for long periods, or km for long distances, or nanoseconds for short times).
- `units_in_label=false`: controls, whether plots are shown in the label_prefix of the axis labels, or in the tick labels
- `short_label=false`: uses short or long label in axis label (when appended to ticks, short form is always used)
- `ticks=automatic`: per default, Makie.automatic ticks are used (Which fallback to [`WilkinsonTicks`](@ref)). One can pass Another algorithm here explicitely (e.g. `WilkinsonTicks(3; k_min=2)`, [`LinearTicks`](@ref) etc)

# Examples

```julia
using Unitful, CairoMakie

# UnitfulTicks will get chosen automatically:
scatter(1:4, [1u"ns", 2u"ns", 3u"ns", 4u"ns"])

# fix unit to always use Meter & display unit in the xlabel postfix
yticks = UnitfulTicks(u"m"; units_in_label=true)
scatter(1:4, [0.01u"km", 0.02u"km", 0.03u"km", 0.04u"km"]; axis=(yticks=yticks,))
```
"""
struct UnitfulTicks
    parent::Base.RefValue{Axis}
    unit::Observable{Any}
    automatic_units::Bool
    tickformatter
    units_in_label::Observable{Bool}
    short_label::Observable{Bool}
end

function UnitfulTicks(unit=automatic; units_in_label=false, short_label=false, ticks=Makie.automatic)
    return UnitfulTicks(Base.RefValue{Axis}(), unit, unit isa Automatic, ticks, units_in_label, short_label)
end

function Observables.connect!(ax::Axis, ticks_obs::Observable, ticks::UnitfulTicks, dim)
    if isassigned(ticks.parent)
        @warn("Connecting tick object to multiple axes results in shared state! If not desired, use a distinct object for each axis")
    end
    ticks.parent[] = ax
    if ticks.automatic_units
        on(ax.finallimits) do limits
            unit = ticks.unit[]
            # Only time & length units are tested/supported right now
            if !(unit isa Automatic) && Unitful.dimension(unit) in (Unitful.𝐓, Unitful.𝐋)
                mini, maxi = getindex.(extrema(limits), dim)
                t(v) = upreferred(to_free_unit(unit)) * v
                new_unit = best_unit(t(mini), t(maxi))
                ticks.unit[] = new_unit
                # Make sure ticks get rerendered
                notify(ticks_obs)
            end
        end
    end
end

function label_postfix(ticks::UnitfulTicks)
    return map(ticks.unit, ticks.units_in_label, ticks.short_label) do unit, in_label, short
        in_label || return ""
        unit isa Automatic && return ""
        unit_str = short ? unit_string(unit) : unit_string_long(unit)
        return string(" in ", unit_str)
    end
end

function get_ticks(ticks::UnitfulTicks, scale, formatter, vmin, vmax)
    unit = ticks.unit[]
    unit isa Automatic && return [], []

    vmin_tu = convert_from_preferred_striped(unit, vmin)
    vmax_tu = convert_from_preferred_striped(unit, vmax)
    unit_str = unit_string(unit)
    tick_vals = get_tickvalues(ticks.tickformatter, scale, vmin_tu, vmax_tu)
    tick_vals_preferred = convert_to_preferred.((unit,), tick_vals)

    labels = get_ticklabels(formatter, tick_vals)
    if !ticks.units_in_label[]
        labels = labels .* unit_str
    end
    return tick_vals_preferred, labels
end

ticks_from_type(::Type{<: Union{Period, Unitful.Quantity, Unitful.Units}}) = UnitfulTicks()

function convert_axis_dim(ticks::UnitfulTicks, values::Observable)
    if ticks.unit[] isa Automatic
        unit = new_unit(ticks.unit[], values[])
        ticks.unit[] = unit
    end
    return map(unit_convert, ticks.unit, values)
end
