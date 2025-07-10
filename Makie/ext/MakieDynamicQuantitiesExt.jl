module MakieDynamicQuantitiesExt

import Makie as M
import DynamicQuantities as DQ

M.expand_dimensions(::M.PointBased, y::AbstractVector{<:DQ.UnionAbstractQuantity}) = (keys(y), y)
M.create_dim_conversion(::Type{<:DQ.UnionAbstractQuantity}) = M.DQConversion()
M.should_dim_convert(::Type{<:DQ.UnionAbstractQuantity}) = true

unit_string(quantity::DQ.UnionAbstractQuantity) = string(DQ.dimension(quantity))

#function unit_convert(::Automatic, x)
#    x
#end

function unit_convert(quantity::DQ.UnionAbstractQuantity, x::AbstractArray)
    # Note: unit_convert.(Ref(quantity), x) currently causes broadcasting error for `QuantityArray`s
    return map(Base.Fix1(unit_convert, quantity), x)
end

function unit_convert(quantity::DQ.UnionAbstractQuantity, value)
    conv = DQ.ustrip(quantity, DQ.uexpand(value))
    return float(conv)
end

needs_tick_update_observable(conversion::M.DQConversion) = conversion.quantity

function M.get_ticks(conversion::M.DQConversion, ticks, scale, formatter, vmin, vmax)
    quantity = conversion.quantity[]
    quantity isa M.Automatic && return [], []
    unit_str = unit_string(quantity)
    tick_vals, labels = M.get_ticks(ticks, scale, formatter, vmin, vmax)
    if conversion.units_in_label[]
        labels = labels .* unit_str
    end
    return tick_vals, labels
end

function M.convert_dim_value(conversion::M.DQConversion, attr, values, last_values)
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
function M.convert_dim_value(conversion::M.DQConversion, values)
    return unit_convert(conversion.quantity[], values)
end

end # Module
