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

function DataInspector2(obj; kwargs...)
    tt = tooltip!(
        obj, Point3f(0), text = "", visible = false,
        xautolimits = false, yautolimits = false, zautolimits = false,
        draw_on_top = true
    )
    register_projected_positions!(tt, input_name = :converted_1, output_name = :pixel_positions)


    di = DataInspector2(
        get_scene(obj), Dict{UInt64, Tooltip}(), tt,
        (0.0, 0.0), UInt64(0), [0, 0, 0],
        Attributes(),
        Any[], Channel{Nothing}(Inf)
    )

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
                    elseif rootparent_plot(plot) isa Tooltip
                        element = pick_element(plot_stack(plot), idx)
                        remove_persistent_tooltip!(di, element)
                        break
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
    function border_dodging_placement(di::DataInspector2, proj_pos)
        wx, wy = widths(viewport(di.parent)[])
        px, py = proj_pos

        placement = py < 0.75wy ? (:above) : (:below)
        px < 0.25wx && (placement = :right)
        px > 0.75wx && (placement = :left)

        return placement
    end

    element = pick_element(plot_stack(source_plot), source_index)

    # TODO: Should we extract plot from PlotElement?
    pos = get_position(element)
    # TODO: shift pos to desired depth

    label = get_tooltip_label(element, pos)

    # maybe also allow kwargs changes from plots?
    # kwargs = get_tooltip_attributes(element)

    copy_local_model_transformations!(di.dynamic_tooltip, parent(element))

    px_pos = di.dynamic_tooltip.pixel_positions[][1]

    update!(
        di.dynamic_tooltip, pos, text = label, visible = true,
        placement = border_dodging_placement(di, px_pos)
        #; kwargs...
    )
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

function get_position(element::PlotElement{<:Hist})
    barplot_element = PlotElement(parent(element).plots[1], element)
    return get_position(barplot_element)
end
