function free(sg::SliderGrid)
    foreach(delete!, sg.sliders)
    foreach(delete!, sg.valuelabels)
    foreach(delete!, sg.labels)
    return
end

_default_format(x) = string(x)
_default_format(x::AbstractFloat) = string(round(x, sigdigits = 3))
_default_format(t::Tuple) = string("(", join(map(_default_format, t), ", "), ")")

extract_label_range_format(pair::Pair) = pair[1], _extract_range_format(pair[2])...
_extract_range_format(p::Pair) = (p...,)
_extract_range_format(x) = (x, _default_format)

function _sample_value_label_extent!(slider, valuelabel, dim::Int)
    maxextent = 0.0
    a = first(slider.range[])
    b = last(slider.range[])
    if slider isa IntervalSlider
        initial = slider.interval[]
        for (v1, v2) in ((a, a), (a, b), (b, b))
            set_close_to!(slider, v1, v2)
            extent = GridLayoutBase.computedbboxobservable(valuelabel)[].widths[dim]
            maxextent = max(maxextent, extent)
        end
        set_close_to!(slider, initial...)
    else
        initial_value = slider.value[]
        for frac in (0.0, 0.5, 1.0)
            fracvalue = a + frac * (b - a)
            set_close_to!(slider, fracvalue)
            extent = GridLayoutBase.computedbboxobservable(valuelabel)[].widths[dim]
            maxextent = max(maxextent, extent)
        end
        set_close_to!(slider, initial_value)
    end
    return maxextent
end

function initialize_block!(sg::SliderGrid, nts::NamedTuple...)
    sg.sliders = Union{Slider, IntervalSlider}[]
    sg.valuelabels = Label[]
    sg.labels = Label[]

    # Orientation is fixed at construction time; changing `horizontal` later
    # does not rebuild the grid.
    horizontal = sg.horizontal[]

    for (i, nt) in enumerate(nts)
        label = haskey(nt, :label) ? nt.label : ""
        range = nt.range
        format = haskey(nt, :format) ? nt.format : _default_format
        slider_type = haskey(nt, :type) ? nt.type : Slider
        remaining_pairs = filter(pair -> pair[1] ∉ (:label, :range, :format, :type, :horizontal), pairs(nt))
        # Force child slider orientation to match the grid.
        slider_kwargs = (; remaining_pairs..., horizontal = horizontal)

        if horizontal
            label_align = (halign = :left,)
            value_align = (halign = :right,)
            label_slot = sg.layout[i, 1]
            slider_slot = sg.layout[i, 2]
            value_slot = sg.layout[i, 3]
        else
            label_align = (halign = :center,)
            value_align = (halign = :center,)
            label_slot = sg.layout[1, i]
            slider_slot = sg.layout[2, i]
            value_slot = sg.layout[3, i]
        end

        l = Label(label_slot, label; label_align...)
        slider = slider_type(slider_slot; range = range, slider_kwargs...)
        value_observable = slider isa IntervalSlider ? slider.interval : slider.value
        vl = Label(
            value_slot,
            lift(x -> apply_format(x, format), value_observable); value_align...
        )
        push!(sg.valuelabels, vl)
        push!(sg.sliders, slider)
        push!(sg.labels, l)
    end

    on(sg.value_column_width) do value_column_width
        if horizontal
            if value_column_width === automatic
                maxwidth = 0.0
                for (slider, valuelabel) in zip(sg.sliders, sg.valuelabels)
                    maxwidth = max(maxwidth, _sample_value_label_extent!(slider, valuelabel, 1))
                end
                colsize!(sg.layout, 3, maxwidth)
            else
                colsize!(sg.layout, 3, value_column_width)
            end
        else
            # In vertical mode, `value_column_width` sets the value-label row height
            # (same attribute kept for compatibility; see docs).
            if value_column_width === automatic
                maxheight = 0.0
                for (slider, valuelabel) in zip(sg.sliders, sg.valuelabels)
                    maxheight = max(maxheight, _sample_value_label_extent!(slider, valuelabel, 2))
                end
                rowsize!(sg.layout, 3, maxheight)
            else
                rowsize!(sg.layout, 3, value_column_width)
            end
        end
    end
    notify(sg.value_column_width)
    return
end
