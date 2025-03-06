using Dates, Observables
import Unitful
using Unitful: Quantity, LogScaled, @u_str, uconvert, ustrip

const SupportedUnits = Union{Period,Unitful.Quantity,Unitful.LogScaled,Unitful.Units}

expand_dimensions(::PointBased, y::AbstractVector{<:SupportedUnits}) = (keys(y), y)
create_dim_conversion(::Type{<:SupportedUnits}) = UnitfulConversion()
MakieCore.should_dim_convert(::Type{<:SupportedUnits}) = true

const UNIT_POWER_OF_TENS = sort!(collect(keys(Unitful.prefixdict)))
const TIME_UNIT_NAMES = [:yr, :wk, :d, :hr, :minute, :s, :ds, :cs, :ms, :μs, :ns, :ps, :fs, :as, :zs, :ys]

# Quantity
base_unit(q::Quantity) = base_unit(typeof(q))
base_unit(::Type{Quantity{NumT, DimT, U}}) where {NumT, DimT, U} = base_unit(U)
base_unit(x::Type{Unitful.FreeUnits{U, DimT, nothing}}) where {DimT, U} = U[1]
base_unit(::Unitful.FreeUnits{U, DimT, nothing}) where {DimT, U} = U[1]

# LogScaled
base_unit(q::LogScaled) = base_unit(typeof(q))
base_unit(::Type{Unitful.Gain{Unitful.LogInfo{N, B, P}, :?, Tval}}) where {N, B, P, Tval<:Real} = N
base_unit(::Type{Unitful.Gain{Unitful.LogInfo{N, B, P}, :?}}) where {N, B, P} = N
base_unit(::Type{Unitful.Level{Unitful.LogInfo{N, B, P}, S, T}}) where {N, B, P, S, T} = N
base_unit(::Type{Unitful.Level{Unitful.LogInfo{N, B, P}, S}}) where {N, B, P, S} = N
base_unit(x::Type{Unitful.MixedUnits{T, Unitful.FreeUnits{(), Unitful.NoDims, nothing}}}) where {T<:LogScaled} = base_unit(T)
base_unit(::Unitful.MixedUnits{T, Unitful.FreeUnits{(), Unitful.NoDims, nothing}}) where {T<:LogScaled} = base_unit(T)
#base_unit(x::Symbol) = string(x)
#base_unit(x::String) = x

base_unit(x::Unitful.Unit) = x
base_unit(x::Period) = base_unit(Quantity(x))

unit_string(::Type{T}) where T <: Unitful.AbstractQuantity = string(Unitful.unit(T))
unit_string(unit::Type{<: Unitful.FreeUnits}) = string(unit())
unit_string(unit::Unitful.FreeUnits) = string(unit)
unit_string(unit::Unitful.Unit) = string(unit)
unit_string(::Union{Number, Nothing}) = ""
unit_string(::Type{T}) where T <: Unitful.LogScaled = string(Unitful.logunit(T))
unit_string(unit::Unitful.MixedUnits) = string(unit)

unit_string_long(unit) = unit_string_long(base_unit(unit))
unit_string_long(::Unitful.Unit{Sym, D}) where {Sym, D} = string(Sym)

is_compound_unit(x::Period) = is_compound_unit(Quantity(x))
is_compound_unit(::Quantity{T, D, U}) where {T, D, U} = is_compound_unit(U)
is_compound_unit(::Unitful.FreeUnits{U}) where {U} = length(U) != 1
is_compound_unit(::Type{<: Unitful.FreeUnits{U}}) where {U} = length(U) != 1
is_compound_unit(::LogScaled) = false

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

function get_all_base10_units(value)
    get_all_base10_units(base_unit(value))
end

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

function best_unit(min, max)
    middle = (min + max) * 0.5
    all_units = if middle isa LogScaled
        # Use given LogScaled unit
        return [base_unit(middle)]
    else
        get_all_base10_units(middle)
    end
    _, index = findmin(all_units) do unit
        raw_value = abs(unit_convert(unit, middle))
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

Fix unit to always use Meter & display unit in the ylabel:
```julia
uc = Makie.UnitfulConversion(u"m"; units_in_label=false)
scatter(1:4, [0.01u"km", 0.02u"km", 0.03u"km", 0.04u"km"]; axis=(dim2_conversion=uc, ylabel="y (m)"))
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
    #conversion.extrema[value_obs.id] = promote(Quantity.(extrema)...)
    conversion.extrema[value_obs.id] = if eltype <: Gain
        extrema
    else
        promote(Quantity.(extrema)...)
    end
    imini, imaxi = extrema
    for (mini, maxi) in values(conversion.extrema)
        imini = min(imini, mini)
        imaxi = max(imaxi, maxi)
    end
    # If a unit only consists off of one element, e.g. "mm" or "J", try to find
    # the best prefix. Otherwise (e.g. "kg/m^3") use the unit as is and don't
    # change it.
    if is_compound_unit(imini)
        if conversion.unit[] === automatic
            new_unit = Unitful.unit(0.5 * Quantity(imini + imaxi))
        else
            return
        end
    else
        new_unit = best_unit(imini, imaxi)
    end
    if new_unit != conversion.unit[]
        conversion.unit[] = new_unit
    end
end

needs_tick_update_observable(conversion::UnitfulConversion) = conversion.unit

# TODO: Convert the unit to rich text arguments instead of parsing the string
# TODO: Could also consider UnitfulLatexify?
function unit_string_to_rich(str::String)
    chunks = split(str, '^')
    output = Any[string(chunks[1])]
    for chunk in chunks[2:end] # each chunk starts after a ^
        pieces = split(chunk, ' ')
        push!(output, superscript(string(pieces[1]))) # pieces[1] is immediately after ^
        push!(output, join(pieces[2:end])) # rest is before the next ^
    end
    return rich(output...)
end

function get_ticks(conversion::UnitfulConversion, ticks, scale, formatter, vmin, vmax)
    unit = conversion.unit[]
    unit isa Automatic && return [], []
    unit_str = unit_string(unit)
    rich_unit_str = unit_string_to_rich(unit_str)
    tick_vals = get_tickvalues(ticks, scale, vmin, vmax)
    labels = get_ticklabels(formatter, tick_vals)
    if conversion.units_in_label[]
        labels = map(lbl -> rich(lbl, rich_unit_str), labels)
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
