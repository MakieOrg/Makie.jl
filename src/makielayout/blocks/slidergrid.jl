function initialize_block!(sg::SliderGrid, pairs::Pair...)

    default_format(x) = string(x)
    default_format(x::AbstractFloat) = string(round(x, sigdigits = 3))

    sg.sliders = Slider[]
    sg.valuelabels = Label[]
    sg.labels = Label[]

    extract_label_range_format(pair::Pair) = pair[1], extract_range_format(pair[2])...
    extract_range_format(p::Pair) = (p...,)
    extract_range_format(x) = (x, default_format)

    for (i, pair) in enumerate(pairs)
        label, range, format = extract_label_range_format(pair)
        l = Label(sg.layout[i, 1], label, halign = :left)
        slider = Slider(sg.layout[i, 2], range = range)
        vl = Label(sg.layout[i, 3],
            lift(x -> apply_format(x, format), slider.value), halign = :right)
        push!(sg.valuelabels, vl)
        push!(sg.sliders, slider)
        push!(sg.labels, l)
    end

    on(sg.value_column_width) do value_column_width
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
    notify(sg.value_column_width)
    return
end