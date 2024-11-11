using Dates, Observables
import Unitful
using Unitful: Quantity, @u_str, uconvert, ustrip

const SupportedUnits = Union{Period,Unitful.Quantity,Unitful.Units}

expand_dimensions(::PointBased, y::AbstractVector{<:SupportedUnits}) = (keys(y), y)
create_dim_conversion(::Type{<:SupportedUnits}) = UnitfulConversion()
MakieCore.should_dim_convert(::Type{<:SupportedUnits}) = true

const UNIT_POWER_OF_TENS = sort!(collect(keys(Unitful.prefixdict)))
const TIME_UNIT_NAMES = [:yr, :wk, :d, :hr, :minute, :s, :ds, :cs, :ms, :μs, :ns, :ps, :fs, :as, :zs, :ys]

unit_string(unit::Unitful.FreeUnits) = string(unit)
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

unit_convert(::Automatic, x) = x

function unit_convert(unit::T, x::AbstractArray) where T <: Union{Type{<:Unitful.AbstractQuantity}, Unitful.FreeUnits, Unitful.Unit}
    return unit_convert.(Ref(unit), x)
end

# We always convert to preferred unit!
function unit_convert(unit::T, value) where T <: Union{Type{<:Unitful.AbstractQuantity}, Unitful.FreeUnits, Unitful.Unit}
    conv = uconvert(to_free_unit(unit, value), value)
    return Float64(ustrip(conv))
end


# Overload conversion functions for Axis, to properly display units

"""
    UnitfulConversion(unit=automatic; units_in_label=false)

Allows to plot arrays of unitful objects into an axis.

# Arguments

- `unit=automatic`: sets the unit as conversion target. If left at automatic, the best unit will be chosen for all plots + values plotted to the axis (e.g. years for long periods, or km for long distances, or nanoseconds for short times).
- `units_in_label=true`: controls, whether plots are shown in the label_prefix of the axis labels, or in the tick labels

# Examples

```julia
using Unitful, CairoMakie

# UnitfulConversion will get chosen automatically:
scatter(1:4, [1u"ns", 2u"ns", 3u"ns", 4u"ns"])
```

Fix unit to always use Meter & display unit in the xlabel:
```julia
uc = Makie.UnitfulConversion(u"m"; units_in_label=false)
scatter(1:4, [0.01u"km", 0.02u"km", 0.03u"km", 0.04u"km"]; axis=(dim2_conversion=uc, xlabel="x (km)"))
```
"""
struct UnitfulConversion <: AbstractDimConversion
    unit::Observable{Any}
    automatic_units::Bool
    units_in_label::Observable{Bool}
    extrema::Dict{String, Tuple{Any, Any}}
end

function UnitfulConversion(unit=automatic; units_in_label=true)
    extrema = Dict{String,Tuple{Any,Any}}()
    return UnitfulConversion(unit, unit isa Automatic, units_in_label, extrema)
end

function update_extrema!(conversion::UnitfulConversion, value_obs::Observable)
    conversion.automatic_units || return
    eltype, extrema = eltype_extrema(value_obs[])

    # convert to initial unit (that isn't automatic/unset)
    if (conversion.unit[] != automatic) && (Unitful.dimension(extrema[1]) == Unitful.dimension(conversion.unit[]))
        pextrema = uconvert.(conversion.unit[], extrema)
    else
        pextrema = promote(Quantity.(extrema)...)
    end

    conversion.extrema[value_obs.id] = pextrema
    imini, imaxi = extrema
    for (mini, maxi) in values(conversion.extrema)
        imini = min(imini, mini)
        imaxi = max(imaxi, maxi)
    end
    new_unit = Unitful.unit(0.5 * Quantity(imini + imaxi))
    if new_unit != conversion.unit[]
        conversion.unit[] = new_unit
    end
end

needs_tick_update_observable(conversion::UnitfulConversion) = conversion.unit

function get_ticks(conversion::UnitfulConversion, ticks, scale, formatter, vmin, vmax)
    unit = conversion.unit[]
    unit isa Automatic && return [], []
    unit_str = unit_string(unit)
    tick_vals = get_tickvalues(ticks, scale, vmin, vmax)
    labels = get_ticklabels(formatter, tick_vals)
    if conversion.units_in_label[]
        labels = labels .* unit_str
    end
    return tick_vals, labels
end

function convert_dim_observable(conversion::UnitfulConversion, value_obs::Observable, deregister)
    result = map(conversion.unit, value_obs; ignore_equal_values=true) do unit, values
        if !isempty(values)
            # try if conversion works, to through error if not!
            # Is there a function for this to check in Unitful?
            unit_convert(unit, values[1])
        end
        update_extrema!(conversion, value_obs)
        return unit_convert(conversion.unit[], values)
    end
    append!(deregister, result.inputs)
    return result
end

function convert_dim_value(conversion::UnitfulConversion, value::SupportedUnits)
    return unit_convert(conversion.unit[], value)
end
