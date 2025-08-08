mutable struct DataInspector2
    parent::Scene
    persistent_tooltips::Dict{UInt64, Tooltip}
    dynamic_tooltip::Tooltip

    last_mouseposition::Tuple{Float64, Float64}
    last_selection::UInt64
    update_counter::Vector{Int}
end

function DataInspector2(obj)
    tt = tooltip!(
        obj, Point2f(0), text = "", visible = false,
        xautolimits = false, yautolimits = false, zautolimits = false
    )

    di = DataInspector2(get_scene(obj), Dict{UInt64, Tooltip}(), tt, (0.0, 0.0), UInt64(0), [0, 0, 0])

    e = events(di.parent)

    on(tick -> update_tooltip!(di, tick), e.tick)

    on(e.mousebutton) do event
        if ispressed(e, Keyboard.left_shift & Mouse.left) && is_mouseinside(di.parent)
            mp = e.mouseposition[]
            for (plot, idx) in pick_sorted(di.parent, mp, 10)
                if parent_scene(plot) == di.parent
                    if plot.inspectable[]
                        element = pick_element(plot_stack(plot), idx)
                        add_persistent_tooltip!(di, element)
                        break
                    elseif plot isa Tooltip
                        element = pick_element(plot_stack(plot), idx)
                        remove_persistent_tooltip!(di, element)
                    end
                end
            end
        end
    end

    return di
end

function update_tooltip!(di::DataInspector2, tick::Tick)
    e = events(di.parent)
    mp = e.mouseposition[]

    is_interactive_tick = tick.state === RegularRenderTick || tick.state === SkippedRenderTick
    mouse_moved = mp != di.last_mouseposition

    di.update_counter[1] += 1 # TODO: for performance checks, remove later

    if is_interactive_tick && mouse_moved
        processed = false

        if is_mouseinside(di.parent)
            di.update_counter[2] += 1 # TODO: for performance checks, remove later
            di.last_mouseposition = mp

            # inspector.attributes.range[]
            for (plot, idx) in pick_sorted(di.parent, mp, 10)

                # plt belong to scene
                plot_in_scene = parent_scene(plot) == di.parent
                if plot_in_scene && plot.inspectable[]
                    di.update_counter[3] += 1 # TODO: for performance checks, remove later
                    processed =  true
                    update_tooltip!(di, plot, idx)
                    break
                end
            end
        end

        if !processed
            update!(di.dynamic_tooltip, visible = false)
        end
    end

    return
end

function update_tooltip!(di::DataInspector2, source_plot::Plot, source_index::Integer)
    element = pick_element(plot_stack(source_plot), source_index)

    # TODO: Should we extract plot from PlotElement?
    pos = get_position(element)
    # TODO: shift pos to desired depth

    label = get_tooltip_label(element, pos)

    # maybe also allow kwargs changes from plots?
    # kwargs = get_tooltip_attributes(element)

    copy_local_model_transformations!(di.dynamic_tooltip, parent(element))

    update!(di.dynamic_tooltip, pos, text = label, visible = true) #; kwargs...
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
    label = element.inspector_label
    if label isa String
        return Format.format(label, pos...)
    elseif label isa Function
        return label(element)
    elseif label === automatic
        return "TODO: default label"
    end
end

function copy_local_model_transformations!(target::Transformable, source::Transformable)
    t = source.transformation
    transform!(target, translation = t.translation, rotation = t.rotation, scale = t.scale)
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

function remove_persistent_tooltip!(di::DataInspector2, element::PlotElement{<:Tooltip})
    key = findfirst(==(parent(element)), di.persistent_tooltips)
    if key !== nothing
        tt = pop!(di.persistent_tooltips, key)
        delete!(di.parent, tt)
    end
    return
end