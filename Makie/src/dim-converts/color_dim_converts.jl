# We need a container that we can share between plots that can be updated later.
# Somewhat analogous to DimConversions
mutable struct ColorDimConvert
    dim_convert::Union{Nothing, AbstractDimConversion}
    sync_graph::ComputeGraph
    sync_node::ComputePipeline.Computed
end

function ColorDimConvert()
    graph = ComputeGraph()
    # This edge will be modified to have inputs from multiple plot graphs. The
    # output will be used as a synchronization input for plot local dim convert
    # application
    map!(_dc_sync_callback, graph, Symbol[], :sync_update)
    return ColorDimConvert(nothing, graph, graph.sync_update)
end

# convenience for add_dim_converts
init_dim_conversion!(cdc::ColorDimConvert, value, ::Nothing) = init_dim_conversion!(cdc, value)
function init_dim_conversion!(cdc::ColorDimConvert, value, element_idx)
    isempty(value) && return
    return init_dim_conversion!(cdc::ColorDimConvert, first(value)[element_idx])
end

function init_dim_conversion!(cdc::ColorDimConvert, value)
    if isnothing(cdc.dim_convert)
        cdc.dim_convert = dim_conversion_from_args(value)
    end
    return
end

function register_color_dim_convert!(attr::ComputeGraph, cdc::ColorDimConvert)
    add_input!(attr, :color_dim_convert, cdc)
    map!(cdc -> cdc.dim_convert, attr, :color_dim_convert, :dim_convert_4)
    return
end

function register_cdc_synchronization!(attr::ComputeGraph, cdc::ColorDimConvert, source)
    # locally update dim convert in plot
    plot_id = objectid(attr)
    map!(attr, [:dim_convert_4, source], :dim_convert_4_update) do dc, color
        result = update_dim_conversion!(dc, color, plot_id)
        return ExplicitUpdate(result, result ? :force : :deny)
    end

    register_cdc_synchronization!(attr, cdc)

    return
end

function register_cdc_synchronization!(attr::ComputeGraph, cdc::ColorDimConvert)
    # shared node for all the update results - trigger this if update did something
    ComputePipeline.push_input!(cdc.sync_node.parent, attr.dim_convert_4_update)

    # pull from the synchronized output so one plot can pull dc updates from all plots
    add_input!(attr, :dim_convert_4_sync, cdc.sync_node)

    return attr.dim_convert_4_sync
end
