function free(sg::SliderGrid)
    foreach(delete!, sg.sliders)
    foreach(delete!, sg.valuelabels)
    foreach(delete!, sg.labels)
    return
end

_default_format(x) = string(x)
_default_format(x::AbstractFloat) = string(round(x, sigdigits = 3))

extract_label_range_format(pair::Pair) = pair[1], _extract_range_format(pair[2])...
_extract_range_format(p::Pair) = (p...,)
_extract_range_format(x) = (x, _default_format)

function initialize_block!(sg::SliderGrid, nts::NamedTuple...)
    sg.sliders = Slider[]
    sg.valuelabels = Label[]
    sg.labels = Label[]

    for (i, nt) in enumerate(nts)
        label = haskey(nt, :label) ? nt.label : ""
        range = nt.range
        format = haskey(nt, :format) ? nt.format : _default_format
        remaining_pairs = filter(pair -> pair[1] ∉ (:label, :range, :format), pairs(nt))
        l = Label(sg.layout[i, 1], label, halign = :left)
        slider = Slider(sg.layout[i, 2]; range = range, remaining_pairs...)
        vl = Label(
            sg.layout[i, 3],
            lift(x -> apply_format(x, format), slider.value), halign = :right
        )
        push!(sg.valuelabels, vl)
        push!(sg.sliders, slider)
        push!(sg.labels, l)
    end

    on(sg.value_column_width, update = true) do value_column_width
        if value_column_width === automatic
            maxwidth = 0.0
            for (slider, valuelabel) in zip(sg.sliders, sg.valuelabels)
                initial_value = slider.value[]
                a = first(slider.range[])
                b = last(slider.range[])
                for frac in (0.0, 0.5, 1.0)
                    fracvalue = a + frac * (b - a)
                    set_close_to!(slider, fracvalue)
                    labelwidth = GridLayoutBase.computedbboxobservable(valuelabel)[].widths[1]
                    maxwidth = max(maxwidth, labelwidth)
                end
                set_close_to!(slider, initial_value)
            end
            colsize!(sg.layout, 3, maxwidth)
        else
            colsize!(sg.layout, 3, value_column_width)
        end
    end
    return
end
