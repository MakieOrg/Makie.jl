mutable struct DataInspector2
    parent::Scene
    persistent_tooltips::Dict{UInt64, Tooltip}
    dynamic_tooltip::Tooltip

    last_mouseposition::Tuple{Float64, Float64}
    last_selection::UInt64
    update_counter::Vector{Int}

    attributes::Attributes

    obsfuncs::Vector{Any}
    update_channel::Channel{Nothing}
end

function DataInspector2(obj; blocking = false, kwargs...)
    parent = get_scene(obj)
    if !isnothing(parent.data_inspector)
        return parent.data_inspector
    end

    kwarg_dict = Dict{Symbol, Any}(kwargs)

    inspector_attr = Attributes(
        range = pop!(kwarg_dict, :range, 10),
        persistent_tooltip_key = pop!(kwarg_dict, :persistent_tooltip_key, Keyboard.left_shift & Mouse.left),
        dodge_margins = to_lrbt_padding(pop!(kwarg_dict, :dodge_margins, 30)),
    )

    # defaults for plot attrib
    get!(kwarg_dict, :draw_on_top, true)

    tt = tooltip!(
        obj, Point3d(0), text = "", visible = false,
        xautolimits = false, yautolimits = false, zautolimits = false;
        kwarg_dict...
    )
    register_projected_positions!(tt, input_name = :converted_1, output_name = :pixel_positions)

    inspector = DataInspector2(
        parent, Dict{UInt64, Tooltip}(), tt,
        (0.0, 0.0), UInt64(0), [0, 0, 0],
        inspector_attr,
        Any[], Channel{Nothing}(Inf)
    )

    parent.data_inspector = inspector

    e = events(parent)

    # dynamic tooltip

    # We delegate the hover processing to another channel,
    # So that we can skip queued up updates with empty_channel!
    # And also not slow down the processing of e.mouseposition/e.scroll
    channel = Channel{Nothing}(blocking ? 0 : Inf) do ch
        while isopen(ch)
            take!(ch) # wait for event
            if isopen(parent)
                update_tooltip!(inspector)
            end
        end
    end
    inspector.update_channel = channel

    listeners = on(e.tick) do tick
        is_interactive_tick = tick.state === RegularRenderTick ||
            tick.state === SkippedRenderTick

        if is_interactive_tick
            inspector.update_counter[1] += 1 # TODO: for performance checks, remove later
            empty_channel!(channel) # remove queued up hover requests
            put!(channel, nothing)
        end

        return
    end
    push!(inspector.obsfuncs, listeners)

    # persistent tooltip
    on(event -> update_persistent_tooltips!(inspector), e.mousebutton)

    return inspector
end


# dynamic tooltips

function update_tooltip!(di::DataInspector2)
    e = events(di.parent)
    mp = e.mouseposition[]

    # TODO: This is not enough. We'd need to check if anything in the scene
    # changed - i.e. scene.viewport, camera matrices, any of the renderobjects...
    # This update wont change state, ignore it
    # mp == di.last_mouseposition && return

    # Mouse outside relevant area, hide tooltip
    if !is_mouseinside(di.parent)
        update!(di.dynamic_tooltip, visible = false)
        return
    end

    di.update_counter[2] += 1 # TODO: for performance checks, remove later
    di.last_mouseposition = mp

    for (plot, idx) in pick_sorted(di.parent, mp, di.attributes.range[])
        # Areas of scenes can overlap so we need to make sure the plot is
        # actually in the correct scene
        if parent_scene(plot) == di.parent && plot.inspectable[]
            di.update_counter[3] += 1 # TODO: for performance checks, remove later
            if update_tooltip!(di, plot, idx)
                return
            end
        end
    end

    # Did not find inspectable plot, hide tooltip
    update!(di.dynamic_tooltip, visible = false)

    return
end

function update_tooltip!(di::DataInspector2, source_plot::Plot, source_index::Integer)
    function border_dodging_placement(di::DataInspector2, proj_pos)
        wx, wy = widths(viewport(di.parent)[])
        px, py = proj_pos
        l, r, b, t = di.attributes[:dodge_margins][]

        placement = :above
        placement = ifelse(py > max(0.5wy, wy - t), :below, placement)
        placement = ifelse(px < min(0.5wx, l),      :right, placement)
        placement = ifelse(px > max(0.5wx, wx - r), :left,  placement)

        return placement
    end

    element = pick_element(plot_stack(source_plot), source_index)

    if isnothing(element)
        return false
    end

    # TODO: Should we extract plot from PlotElement?
    pos = get_position(element)
    # TODO: shift pos to desired depth

    label = get_tooltip_label(element, pos)

    # maybe also allow kwargs changes from plots?
    # kwargs = get_tooltip_attributes(element)

    copy_local_model_transformations!(di.dynamic_tooltip, parent(element))

    px_pos = di.dynamic_tooltip.pixel_positions[][1]

    update!(
        di.dynamic_tooltip, to_ndim(Point3d, pos, 0), text = label, visible = true,
        placement = border_dodging_placement(di, px_pos)
        #; kwargs...
    )

    return true
end


function get_position(element::PlotElement{PT}) where {PT <: Plot}
    converted = parent(element).attributes[:converted][]
    n_args = length(converted)
    if n_args == 1
        name = argument_names(PT, 1)[1]
        return to_ndim(Point3d, getproperty(element, name), 0)
    else
        names = argument_names(PT, n_args)
        p = Point.(getproperty.(Ref(element), names))
        return to_ndim(Point3d, p, 0)
    end
end

function get_tooltip_label(element::PlotElement, pos)
    label = get(element, :inspector_label, automatic)
    if label isa String
        return Format.format(label, pos...)
    elseif label isa Function
        return label(element)
    elseif label === automatic
        return get_default_tooltip_label(element, pos)
    end
end

function copy_local_model_transformations!(target::Transformable, source::Transformable)
    t = source.transformation
    transform!(target, translation = t.translation, rotation = t.rotation, scale = t.scale)
    return
end


# persistent tooltips

function update_persistent_tooltips!(di::DataInspector2)
    e = events(di.parent)

    if !ispressed(e, di.attributes.persistent_tooltip_key[]) || !is_mouseinside(di.parent)
        return
    end

    mp = e.mouseposition[]
    for (plot, idx) in pick_sorted(di.parent, mp, 10)
        (parent_scene(plot) != di.parent) && continue

        if plot.inspectable[]
            element = pick_element(plot_stack(plot), idx)
            add_persistent_tooltip!(di, element)
            return
        elseif rootparent_plot(plot) isa Tooltip
            element = pick_element(plot_stack(plot), idx)
            remove_persistent_tooltip!(di, element)
            return
        end
    end

    return
end

function plot!(plot::Tooltip{<:Tuple{<:Vector{<:PlotElement}}})
    if isempty(plot.arg1[])
        error("tooltip(::Vector{PlotElement}) must not be initialized with an empty list.")
    end

    element = TrackedPlotElement(first(plot.arg1[]))
    parent_plot = parent(element)

    empty!(element)
    pos = get_position(element)
    get_tooltip_label(element, pos)

    inputs = [plot.arg1, getproperty.(Ref(parent_plot), get_accessed_fields(element))...]
    map!(plot, inputs, [:element_positions, :element_labels]) do elements, triggers...
        positions = get_position.(elements)
        labels = get_tooltip_label.(elements, positions)
        # TODO: add z shift to labels
        return positions, labels
    end

    tooltip!(
        plot, Attributes(plot), plot.element_positions; text = plot.element_labels,
        transformation = parent_plot.transformation
    )
    return plot
end

function add_persistent_tooltip!(di::DataInspector2, element::PlotElement{PT}) where {PT}
    id = objectid(parent(element))
    if haskey(di.persistent_tooltips, id)
        tt = di.persistent_tooltips[id]
        elements = push!(tt.arg1[], element)
        update!(tt, arg1 = elements)
    else
        di.persistent_tooltips[id] = tooltip!(di.parent, PlotElement{PT}[element])
    end
    return
end

function remove_persistent_tooltip!(di::DataInspector2, tooltip_element::PlotElement{<:Tooltip})
    tt = parent(tooltip_element)
    key = findfirst(==(tt), di.persistent_tooltips)

    # If we don't find the tooltip plot then we don't own it and shouldn't touch it
    if key !== nothing
        idx = tooltip_element.index[1]
        elements = tt.arg1[]
        deleteat!(elements, idx)

        if length(elements) == 0
            tt = pop!(di.persistent_tooltips, key)
            delete!(di.parent, tt)
        else
            update!(tt, arg1 = elements)
        end
    end

    return
end


################################################################################

function get_default_tooltip_label(e, pos::VecTypes)
    parts = showoff_minus(pos)
    return '(' * join(parts, ", ") * ')'
end

get_default_tooltip_label(e, p) = "Failed to construct label for $e, $p"

################################################################################

get_position(element::PlotElement{<:Mesh}) = element.positions
get_position(element::PlotElement{<:Surface}) = element.positions

function get_position(element::PlotElement{<:Union{Image, Heatmap}})
    plot = parent(element)
    x = dimensional_element_getindex(plot.x[], element, 1)
    y = dimensional_element_getindex(plot.y[], element, 2)
    return Point2f(x, y)
end

function get_position(element::PlotElement{<:Voxels})
    return voxel_position(parent(element), Tuple(element.index)...)
end

function get_position(element::PlotElement{<:Hist})
    barplot_element = PlotElement(parent(element).plots[1], element)
    return get_position(barplot_element)
end

function get_position(element::PlotElement{<:Poly})
    mesh_element = PlotElement(parent(element).plots[1], element)
    return get_position(mesh_element)
end
