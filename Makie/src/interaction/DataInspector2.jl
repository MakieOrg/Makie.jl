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

    function DataInspector2(parent, persistent, dynamic, lastmp, lastsel, counter, attr, obsfuncs, channel)
        inspector = new(parent, persistent, dynamic, lastmp, lastsel, counter, attr, obsfuncs, channel)
        finalizer(inspector) do inspector
            foreach(off, inspector.obsfuncs)
            empty!(inspector.obsfuncs)

            close(inspector.update_channel)

            foreach(tt -> delete!(inspector.parent, tt), values(inspector.persistent_tooltips))
            empty!(inspector.persistent_tooltips)

            delete!(inspector.parent, inspector.dynamic_tooltip)

            inspector.parent.data_inspector = nothing
            return
        end

        return inspector
    end
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
        formatter = pop!(kwarg_dict, :formatter, default_tooltip_formatter)
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

    tick_listener = on(e.tick) do tick
        is_interactive_tick = tick.state === RegularRenderTick ||
            tick.state === SkippedRenderTick

        if is_interactive_tick
            inspector.update_counter[1] += 1 # TODO: for performance checks, remove later
            empty_channel!(channel) # remove queued up hover requests
            put!(channel, nothing)
        end

        return
    end

    # persistent tooltip
    mouse_listener = on(event -> update_persistent_tooltips!(inspector), e.mousebutton)

    push!(inspector.obsfuncs, tick_listener, mouse_listener)

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

    pos = get_tooltip_position(element)
    # TODO: shift pos to desired depth (or is draw_on_top enough?)

    label = get_tooltip_label(di, element, pos)

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


function get_tooltip_position(element::PlotElement{PT}) where {PT <: Plot}
    converted = parent(element).attributes[:converted][]
    n_args = length(converted)
    if n_args == 1
        name = argument_names(PT, 1)[1]
        return getproperty(element, name)
    else
        names = argument_names(PT, n_args)
        p = Point.(getproperty.(Ref(element), names))
        return p
    end
end

function copy_local_model_transformations!(target::Transformable, source::Transformable)
    t = source.transformation
    transform!(target, translation = t.translation, rotation = t.rotation, scale = t.scale)
    return
end

function get_tooltip_label(di::DataInspector2, element::PlotElement, pos)
    label = get(element, :inspector_label, automatic)

    if label isa String
        # TODO: Can this double as a formatting string? Seems difficult to handle
        # the various types that label data can be...
        return label
    elseif label isa Function
        return label(element, pos)
    elseif label === automatic
        return get_default_tooltip_label(di, element, pos)
    end
end

function get_default_tooltip_label(di, element, pos)
    data = get_default_tooltip_label_data(element, pos)
    number_formatter = di.attributes[:formatter][]
    return apply_tooltip_format(number_formatter, data)
end

get_default_tooltip_label_data(element, pos) = pos

function apply_tooltip_format(fmt, data::Tuple)
    return mapreduce(x -> apply_tooltip_format(fmt, x), (a, b) -> "$a\n$b", data)
end

function apply_tooltip_format(fmt, data::VecTypes)
    return '(' * mapreduce(x -> apply_tooltip_format(fmt, x), (a, b) -> "$a, $b", data) * ')'
end

function apply_tooltip_format(fmt, c::RGB)
    return "RGB" * apply_tooltip_format(fmt, (red(c), green(c), blue(c)))
end

function apply_tooltip_format(fmt, c::RGBA)
    return "RGBA" * apply_tooltip_format(fmt, (red(c), green(c), blue(c), alpha(c)))
end

function apply_tooltip_format(fmt, c::Gray)
    return "Gray(" * apply_tooltip_format(fmt, gray(c)) * ')'
end

apply_tooltip_format(fmt::String, x::Number) = Format.format(fmt, x)
apply_tooltip_format(fmt::Function, x::Number) = fmt(x)

function default_tooltip_formatter(x)
    if 1e-3 < abs(x) < 1e-1
        return @sprintf("%0.6f", x)
    elseif 1e-1 < abs(x) < 1e3
        return @sprintf("%0.3f", x)
    elseif 1e3 < abs(x) < 1e5
        return @sprintf("%0.0f", x)
    elseif iszero(x)
        return "0"
    else
        return @sprintf("%0.3e", x)
    end
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
    pos = get_tooltip_position(element)
    get_tooltip_label(element, pos)

    inputs = [plot.arg1, getproperty.(Ref(parent_plot), get_accessed_fields(element))...]
    map!(plot, inputs, [:element_positions, :element_labels]) do elements, triggers...
        positions = get_tooltip_position.(elements)
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

get_tooltip_position(element::PlotElement{<:Mesh}) = element.positions
get_tooltip_position(element::PlotElement{<:Surface}) = element.positions

function get_tooltip_position(element::PlotElement{<:Union{Image, Heatmap}})
    plot = parent(element)
    x = dimensional_element_getindex(plot.x[], element, 1)
    y = dimensional_element_getindex(plot.y[], element, 2)
    return Point2f(x, y)
end

function get_tooltip_position(element::PlotElement{<:Voxels})
    return voxel_position(parent(element), Tuple(element.index)...)
end

function get_tooltip_position(element::PlotElement{<:Hist})
    barplot_element = PlotElement(parent(element).plots[1], element)
    return get_tooltip_position(barplot_element)
end

function get_tooltip_position(element::PlotElement{<:Poly})
    mesh_element = PlotElement(parent(element).plots[1], element)
    return get_tooltip_position(mesh_element)
end
