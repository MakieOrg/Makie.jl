module MakieDynamicQuantitiesExt

using Makie
import Makie as M
import DynamicQuantities as DQ

M.expand_dimensions(::PointBased, y::AbstractVector{<:DQ.UnionAbstractQuantity}) = (keys(y), y)
M.create_dim_conversion(::Type{<:DQ.UnionAbstractQuantity}) = M.DQConversion()
M.should_dim_convert(::Type{<:DQ.UnionAbstractQuantity}) = true

unit_string(quantity::DQ.UnionAbstractQuantity) = string(DQ.dimension(quantity))

#function unit_convert(::Automatic, x)
#    x
#end

function unit_convert(quantity::DQ.UnionAbstractQuantity, x::AbstractArray)
    # Note: unit_convert.(Ref(quantity), x) currently causes broadcasting error for `QuantityArray`s
    map(Base.Fix1(unit_convert, quantity), x)
end

function unit_convert(quantity::DQ.UnionAbstractQuantity, value)
    conv = DQ.ustrip(quantity, value)
    return float(conv)
end

"""
    DQConversion(unit=automatic; units_in_label=false)

Allows to plot arrays of DynamicQuantity objects into an axis.

# Arguments
- `units_in_label=true`: controls, whether plots are shown in the label_prefix of the axis labels, or in the tick labels

# Examples

```julia
using DynamicQuantities, CairoMakie

scatter(1:4, [1u"ns", 2u"ns", 3u"ns", 4u"ns"])
```

Fix unit to always use Meter & display unit in the xlabel:

```julia
dqc = Makie.DQConversion(us"m"; units_in_label=false)

scatter(1:4, [0.01u"km", 0.02u"km", 0.03u"km", 0.04u"km"]; axis=(dim2_conversion=dqc, xlabel="x (km)"))
```
"""
struct DQConversion <: Makie.AbstractDimConversion
    quantity::Observable{Any}
    units_in_label::Observable{Bool}
end

function M.DQConversion(quantity=M.automatic; units_in_label=true)
    return DQConversion(quantity, units_in_label)
end

needs_tick_update_observable(conversion::DQConversion) = conversion.quantity

function M.get_ticks(conversion::DQConversion, ticks, scale, formatter, vmin, vmax)
    quantity = conversion.quantity[]
    quantity isa M.Automatic && return [], []
    unit_str = unit_string(quantity)
    tick_vals, labels = M.get_ticks(ticks, scale, formatter, vmin, vmax)
    if conversion.units_in_label[]
        labels = labels .* unit_str
    end
    return tick_vals, labels
end

function M.convert_dim_value(conversion::DQConversion, attr, values, last_values)
    if conversion.quantity[] isa M.Automatic
        conversion.quantity[] = oneunit(first(values))
    end

    unit = conversion.quantity[]

    if !isempty(values)
        # try if conversion works, to through error if not!
        # Is there a function for this to check in DynamicQuantities?
        unit_convert(unit, first(values))
    end

    return unit_convert(conversion.quantity[], values)
end

# Can maybe be dropped? Keeping for correspondence with unitful-integration.jl
function M.convert_dim_value(conversion::DQConversion, values)
    return unit_convert(conversion.quantity[], values)
end

end # Module
