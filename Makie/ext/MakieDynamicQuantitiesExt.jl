module MakieDynamicQuantitiesExt

import Makie as M
import DynamicQuantities as DQ

M.expand_dimensions(::M.PointBased, y::AbstractVector{<:DQ.UnionAbstractQuantity}) = (keys(y), y)
function M.expand_dimensions(::Union{M.ImageLike, M.GridBased}, data::AbstractMatrix{<:DQ.UnionAbstractQuantity})
    x, y = map(s -> (1.0f0, Float32(s)), size(data))
    return (x, y, data)
end
M.create_dim_conversion(::Type{<:DQ.UnionAbstractQuantity}) = M.DQConversion()

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
show_dim_convert_in_ticklabel(::M.DQConversion) = false
show_dim_convert_in_axis_label(::M.DQConversion) = true

function M.get_ticks(conversion::M.DQConversion, ticks, scale, formatter, vmin, vmax, show_in_label)
    quantity = conversion.quantity[]
    quantity isa M.Automatic && return [], []
    unit_str = unit_string(quantity)
    tick_vals, labels = M.get_ticks(ticks, scale, formatter, vmin, vmax)
    if show_in_label
        labels = labels .* unit_str
    end
    return tick_vals, labels
end

# TODO: implement `format` and `use_short_units`
function M.get_label_suffix(conversion::M.DQConversion)
    return conversion.quantity[] isa M.Automatic ? "" : unit_string(conversion.quantity[])
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

function M.reattach_unit(conversion::M.DQConversion, value)
    quantity = conversion.quantity[]
    return quantity isa M.Automatic ? value : value * quantity
end

end # Module
