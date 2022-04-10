function block_docs(::Type{SliderGrid})
    """
    A grid of horizontal `Slider`s, where each slider has one name label on the left,
    and a value label on the right.

    ## Constructors

    ```julia
    SliderGrid(fig_or_scene, pairs::Pair...; kwargs...)
    ```

    ## Examples

    ```julia
    sg = SliderGrid(fig[1, 1],
        "Amplitude" => 0:10,
        "Frequency" => 0:0.5:50 => "{:.1f}Hz",
        "Phase" => 0:0.01:2pi => x -> string(round(x, digits = 4)))
    ```

    Working with slider values:

    ```julia
    on(sg.sliders[1].value) do val
        # do something with `val`
    end
    ```
    """
end

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