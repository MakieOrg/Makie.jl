mutable struct DataInspector2
    parent::Scene
    persistent_tooltips::Dict{UInt64, Tooltip}
    dynamic_tooltip::Tooltip

    last_mouseposition::Tuple{Float64, Float64}
    last_selection::UInt64
    update_counter::Vector{Int}

    inspector_attributes::Attributes
    tooltip_attributes::Attributes

    obsfuncs::Vector{Any}
    update_channel::Channel{Nothing}

    function DataInspector2(
            parent, persistent, dynamic, lastmp, lastsel, counter,
            inspector_attr, tooltip_attr, obsfuncs, channel
        )
        inspector = new(
            parent, persistent, dynamic, lastmp, lastsel, counter,
            inspector_attr, tooltip_attr, obsfuncs, channel
        )

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
        inspector_attr, Attributes(kwarg_dict),
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

    # TODO: remove priority, make compatible with 3D axis
    # persistent tooltip
    mouse_listener = on(event -> update_persistent_tooltips!(inspector), e.mousebutton, priority = typemax(Int))

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

    for (plot, idx) in pick_sorted(di.parent, mp, di.inspector_attributes.range[])
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
        l, r, b, t = di.inspector_attributes[:dodge_margins][]

        placement = :above
        placement = ifelse(py > max(0.5wy, wy - t), :below, placement)
        placement = ifelse(px < min(0.5wx, l),      :right, placement)
        placement = ifelse(px > max(0.5wx, wx - r), :left,  placement)

        return placement
    end

    element = pick_element(plot_stack(source_plot), source_index)
    isnothing(element) && return false

    # We need to grab transformations and space from the plot we grab the
    # position from
    position_element = get_position_element(element)
    isnothing(position_element) && return false

    # TODO: shift pos to desired depth (or is draw_on_top enough?)
    pos = get_tooltip_position(position_element)

    plot = get_plot(position_element)
    copy_local_model_transformations!(di.dynamic_tooltip, plot)

    formatter = di.inspector_attributes[:formatter][]
    label = get_tooltip_label(formatter, element, pos)

    # maybe also allow kwargs changes from plots?
    # kwargs = get_tooltip_attributes(element)

    px_pos = di.dynamic_tooltip.pixel_positions[][1]

    update!(
        di.dynamic_tooltip, to_ndim(Point3d, pos, 0), text = label, visible = true,
        placement = border_dodging_placement(di, px_pos),
        space = plot.space[]
        #; kwargs...
    )

    return true
end

function get_position_element(element::PlotElement)
    @assert !applicable(get_tooltip_position, PlotElement) "`get_tooltip_position()` must only exist for typed `PlotElement{<:SomePlot}`"
    while !isempty(element.plot_stack)
        if applicable(get_tooltip_position, element)
            return element
        else
            element = parent(element)
        end
    end
    return nothing
end

# Primitives (volume skipped)
function get_tooltip_position(element::PlotElement{<:Union{Image, Heatmap}})
    plot = get_plot(element)
    x = dimensional_element_getindex(plot.x[], element, 1)
    y = dimensional_element_getindex(plot.y[], element, 2)
    return Point2f(x, y)
end

function get_tooltip_position(
        element::PlotElement{<:Union{Scatter, MeshScatter, Lines, LineSegments, Text, Mesh, Surface}}
    )
    return element.positions
end

function get_tooltip_position(element::PlotElement{<:Voxels})
    return voxel_position(get_plot(element), Tuple(element.index.index)...)
end


function copy_local_model_transformations!(target::Transformable, source::Transformable)
    t = source.transformation
    transform!(target, translation = t.translation, rotation = t.rotation, scale = t.scale)
    return
end


function get_tooltip_label(formatter, element::PlotElement, pos)
    label = get(element, :inspector_label, automatic)

    if label isa String
        # TODO: Can this double as a formatting string? Seems difficult to handle
        # the various types that label data can be...
        return label
    elseif label isa Function
        return label(element, pos)
    elseif label === automatic
        return get_default_tooltip_label(formatter, element, pos)
    end
end

function get_default_tooltip_label(formatter, element, pos)
    data = get_default_tooltip_data(element, pos)
    return apply_tooltip_format(formatter, data)
end

get_default_tooltip_data(element, pos) = pos

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

    if !ispressed(e, di.inspector_attributes.persistent_tooltip_key[]) || !is_mouseinside(di.parent)
        return
    end

    mp = e.mouseposition[]
    for (plot, idx) in pick_sorted(di.parent, mp, 10)
        (parent_scene(plot) != di.parent) && continue

        if plot.inspectable[]
            element = pick_element(plot_stack(plot), idx)
            add_persistent_tooltip!(di, element)
            return Consume(true)
        elseif rootparent_plot(plot) isa Tooltip
            element = pick_element(plot_stack(plot), idx)
            remove_persistent_tooltip!(di, element)
            return Consume(true)
        end
    end

    return Consume(false)
end

function plot!(plot::Tooltip{<:Tuple{<:Vector{<:PlotElement}}})
    if isempty(plot.arg1[])
        error("tooltip(::Vector{PlotElement}) must not be initialized with an empty list.")
    end

    element = TrackedPlotElement(first(plot.arg1[]))

    # get list of inputs used for positions
    position_element = get_position_element(element)
    empty!(position_element)
    pos = get_tooltip_position(position_element)

    position_parent = get_plot(position_element)
    inputs = [plot.arg1, getproperty.(Ref(position_parent), get_accessed_fields(position_element))...]

    map!(plot, inputs, :element_positions) do elements, triggers...
        return map(elements) do element
            position_element = get_position_element(element)
            return get_tooltip_position(position_element)
        end
    end

    # get list of inputs used for labels
    empty!(element)
    get_tooltip_label(plot._formatter[], element, pos)

    parent_plot = get_plot(element)
    inputs = [
        plot._formatter, plot.arg1, plot.element_positions,
        getproperty.(Ref(parent_plot), get_accessed_fields(element))...
    ]

    map!(plot, inputs, :element_labels) do formatter, elements, positions, triggers...
        return get_tooltip_label.(Ref(formatter), elements, positions)
    end

    tooltip!(
        plot, Attributes(plot), plot.element_positions; text = plot.element_labels,
        transformation = position_parent.transformation,
        space = position_parent.space
    )
    return plot
end

function add_persistent_tooltip!(di::DataInspector2, element::PlotElement{PT}) where {PT}
    id = objectid(get_plot(element))
    if haskey(di.persistent_tooltips, id)
        tt = di.persistent_tooltips[id]
        elements = push!(tt.arg1[], element)
        update!(tt, arg1 = elements)
    else
        formatter = di.inspector_attributes[:formatter][]
        di.persistent_tooltips[id] = tooltip!(
            di.parent, PlotElement{PT}[element],
            _formatter = formatter; di.tooltip_attributes...
        )
    end
    return
end

function remove_persistent_tooltip!(di::DataInspector2, tooltip_element::PlotElement{<:Tooltip})
    tt = get_plot(tooltip_element)
    key = findfirst(==(tt), di.persistent_tooltips)

    # If we don't find the tooltip plot then we don't own it and shouldn't touch it
    if key !== nothing
        idx = tooltip_element.index.index[1]
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

# Overwrites
get_default_tooltip_data(element::PlotElement{<:Union{Image, Heatmap}}, pos) = element.image

function get_tooltip_position(element::PlotElement{<:BarPlot})
    return element.positions
end

function get_tooltip_position(element::PlotElement{<:Union{Arrows2D, Arrows3D}})
    return 0.5 * (element.startpoints + element.endpoints)
end
function get_default_tooltip_data(element::PlotElement{<:Union{Arrows2D, Arrows3D}}, pos)
    return pos, element.endpoints - element.startpoints
end

function get_tooltip_position(element::PlotElement{<:Band})
    return 0.5(element.lowerpoints + element.upperpoints)
end
function get_default_tooltip_data(element::PlotElement{<:Band}, pos)
    return element.upperpoints, element.lowerpoints
end

function get_default_tooltip_data(element::PlotElement{<:Contourf}, pos)
    return parent(element).color
end

get_default_tooltip_data(element::PlotElement{<:Spy}, pos) = parent(element).color
