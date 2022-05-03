function block_docs(::Type{SliderGrid})
    """
    A grid of horizontal `Slider`s, where each slider has one name label on the left,
    and a value label on the right.

    Each `NamedTuple` you pass specifies one `Slider`. You always have to pass `range`
    and `label`, and optionally a `format` for the value label. Beyond that, you can set
    any keyword that `Slider` takes, such as `startvalue`.

    The `format` keyword can be a `String` with Formatting.jl style, such as "{:.2f}Hz", or
    a function.

    ## Constructors

    ```julia
    SliderGrid(fig_or_scene, nts::NamedTuple...; kwargs...)
    ```

    ## Examples

    ```julia
    sg = SliderGrid(fig[1, 1],
        (label = "Amplitude", range = 0:0.1:10, startvalue = 5),
        (label = "Frequency", range = 0:0.5:50, format = "{:.1f}Hz", startvalue = 10),
        (label = "Phase", range = 0:0.01:2pi,
            format = x -> string(round(x/pi, digits = 2), "π"))
    )
    ```

    Working with slider values:

    ```julia
    on(sg.sliders[1].value) do val
        # do something with `val`
    end
    ```
    """
end

function initialize_block!(sg::SliderGrid, nts::NamedTuple...)

    default_format(x) = string(x)
    default_format(x::AbstractFloat) = string(round(x, sigdigits = 3))

    sg.sliders = Slider[]
    sg.valuelabels = Label[]
    sg.labels = Label[]

    extract_label_range_format(pair::Pair) = pair[1], extract_range_format(pair[2])...
    extract_range_format(p::Pair) = (p...,)
    extract_range_format(x) = (x, default_format)

    for (i, nt) in enumerate(nts)
        label = nt.label
        range = nt.range
        format = haskey(nt, :format) ? nt.format : default_format
        remaining_pairs = filter(pair -> pair[1] ∉ (:label, :range, :format), pairs(nt))
        l = Label(sg.layout[i, 1], label, halign = :left)
        slider = Slider(sg.layout[i, 2]; range = range, remaining_pairs...)
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