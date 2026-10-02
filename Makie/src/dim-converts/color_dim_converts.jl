# We need a container that we can share between plots that can be updated later.
# Somewhat analogous to DimConversions
mutable struct ColorDimConvert
    dim_convert::Union{Nothing, AbstractDimConversion}
    update::Observable{Nothing}
end
ColorDimConvert() = ColorDimConvert(nothing, Observable(nothing))

# Here:
# nothing - not locked in
# NoDimConversion - locked in to values
# any other AbstractDimConversion - locked in to conversion

# convenience for add_dim_converts
function update_dim_conversion!(cdc::ColorDimConvert, value, element_idx)
    isempty(value) && return
    return update_dim_conversion!(cdc::ColorDimConvert, first(value)[element_idx])
end

function update_dim_conversion!(cdc::ColorDimConvert, value)
    if isnothing(cdc.dim_convert)
        cdc.dim_convert = dim_conversion_from_args(value)
        x = needs_tick_update_observable(cdc.dim_convert)
        if x isa Observable
            on(_ -> notify(cdc.update), x)
        end
    end
    return
end

function register_color_dim_convert!(attr::ComputeGraph, cdc::ColorDimConvert)
    add_input!(attr, :color_dim_convert, cdc)
    map!(cdc -> cdc.dim_convert, attr, :color_dim_convert, :resolved_cdc)
    on(_ -> notify(attr.color_dim_convert), cdc.update)
    return
end
