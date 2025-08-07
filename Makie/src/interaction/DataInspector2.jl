mutable struct DataInspector2
    parent::Scene
    persistent_tooltips::Vector{Tooltip}
    dynamic_tooltip::Tooltip

    last_mouseposition::Tuple{Float64, Float64}
    last_selection::UInt64
end

function DataInspector2(obj)
    tt = tooltip!(
        obj, Point2f(0), text = "", visible = false,
        xautolimits = false, yautolimits = false, zautolimits = false
    )

    di = DataInspector2(get_scene(obj), Tooltip[], tt, (0.0, 0.0), UInt64(0))

    on(tick -> update_tooltip!(di, tick), events(di.parent).tick)

    return di
end

function update_tooltip!(di::DataInspector2, tick::Tick)
    e = events(di.parent)
    mp = e.mouseposition[]

    is_interactive_tick = tick.state === RegularRenderTick || tick.state === SkippedRenderTick
    mouse_moved = mp != di.last_mouseposition

    if is_interactive_tick && mouse_moved
        processed = false

        if is_mouseinside(di.parent)
            di.last_mouseposition = mp

            # inspector.attributes.range[]
            for (plot, idx) in pick_sorted(di.parent, mp, 10)

                # plt belong to scene
                plot_in_scene = parent_scene(plot) == di.parent
                if plot_in_scene && plot.inspectable[]
                    processed =  true
                    update_tooltip!(di, plot, idx)
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
    pos = get_position(parent(element), element)
    # TODO: shift pos to desired depth

    label = get_tooltip_label(parent(element), element, pos)

    # maybe also allow kwargs changes from plots?
    # kwargs = get_tooltip_attributes(element)

    copy_local_model_transformations!(di.dynamic_tooltip, parent(element))

    update!(di.dynamic_tooltip, pos, text = label, visible = true) #; kwargs...
end

function get_position(plot::PT, element::PlotElement) where {PT <: Plot}
    converted = plot.attributes[:converted][]
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

function get_tooltip_label(plot::Plot, element::PlotElement, pos)
    label = plot.inspector_label[]
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