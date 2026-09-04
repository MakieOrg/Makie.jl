using Dates, Observables
import Unitful
using Unitful: Quantity, LogScaled, @u_str, uconvert, ustrip
using Latexify

const SupportedUnits = Union{Period, Unitful.Quantity, Unitful.LogScaled, Unitful.Units}

expand_dimensions(::PointBased, y::AbstractVector{<:SupportedUnits}) = (keys(y), y)
create_dim_conversion(::Type{<:SupportedUnits}) = UnitfulConversion()

base_unit(q::Quantity) = base_unit(typeof(q))
base_unit(::Type{Quantity{NumT, DimT, U}}) where {NumT, DimT, U} = base_unit(U)
base_unit(::Type{Unitful.FreeUnits{U, DimT, nothing}}) where {DimT, U} = U[1]
base_unit(::Unitful.FreeUnits{U, DimT, nothing}) where {DimT, U} = U[1]
base_unit(x::Unitful.Unit) = x
base_unit(x::Period) = base_unit(Quantity(x))

unit_string(::Type{T}) where {T <: Unitful.AbstractQuantity} = string(Unitful.unit(T))
unit_string(unit::Type{<:Unitful.FreeUnits}) = string(unit())
unit_string(unit::Unitful.FreeUnits) = string(unit)
unit_string(unit::Unitful.Unit) = string(unit)
unit_string(::Union{Number, Nothing}) = ""
unit_string(unit::T) where {T <: Unitful.MixedUnits} = string(unit)
unit_string(unit::Unitful.LogScaled) = ""

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

to_unit(x::LogScaled) = Unitful.logunit(x)
to_unit(x::Quantity{NumT, DimT, U}) where {NumT <: LogScaled, DimT, U} = Unitful.logunit(NumT) * U()
to_unit(x) = Unitful.unit(x)

unit_convert(::Automatic, x) = x

function unit_convert(unit::T, x::Tuple) where {T <: Union{Type{<:Unitful.AbstractQuantity}, Unitful.FreeUnits, Unitful.Unit}}
    return unit_convert.(Ref(unit), x)
end

function unit_convert(unit::Unitful.MixedUnits, x::Tuple)
    return unit_convert.(Ref(unit), x)
end

function unit_convert(unit::T, x::AbstractArray) where {T <: Union{Type{<:Unitful.AbstractQuantity}, Unitful.FreeUnits, Unitful.Unit}}
    return unit_convert.(Ref(unit), x)
end

unit_convert(unit::Unitful.MixedUnits, x::AbstractArray) = unit_convert.(Ref(unit), x)

# We always convert to preferred unit!
function unit_convert(unit::T, value) where {T <: Union{Type{<:Unitful.AbstractQuantity}, Unitful.FreeUnits, Unitful.Unit}}
    conv = uconvert(to_free_unit(unit, value), value)
    return float(ustrip(conv))
end

unit_convert(unit::T, value) where {T <: Union{Unitful.MixedUnits, Quantity{<:Unitful.LogScaled, DimT, U}}} where {DimT, U} = Float64(ustrip(value))

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
end

UnitfulConversion() = UnitfulConversion(automatic)

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

show_dim_convert_in_ticklabel(::UnitfulConversion) = false
show_dim_convert_in_axis_label(::UnitfulConversion) = true

function get_ticks(conversion::UnitfulConversion, ticks, scale, formatter, vmin, vmax, show_in_label)
    unit = conversion.unit[]
    unit isa Automatic && return [], []
    unit_str = unit_string(unit)
    rich_unit_str = unit_string_to_rich(unit_str)
    tick_vals, labels = get_ticks(ticks, scale, formatter, vmin, vmax)
    if show_in_label
        labels = map(lbl -> rich(lbl, rich_unit_str), labels)
    end
    return tick_vals, labels
end

function get_label_suffix(::Union{RichText, String}, conversion::UnitfulConversion, format)
    unit = conversion.unit[]
    unit isa Automatic && return ""
    ustr = unit_string(unit)
    str = unit_string_to_rich(ustr)
    return apply_format(str, format)
end

function get_label_suffix(::LaTeXString, conversion::UnitfulConversion, format)
    unit = conversion.unit[]
    unit isa Automatic && return ""
    return apply_format(latexify(unit), format)
end

function update_dim_conversion!(conversion::UnitfulConversion, values)
    if !isempty(values)
        if conversion.unit[] === automatic
            conversion.unit[] = to_unit(first(values))
            return true
        end
    end
    return false
end

function convert_dim_value(dc::UnitfulConversion, values)
    return unit_convert(dc.unit[], values)
end
