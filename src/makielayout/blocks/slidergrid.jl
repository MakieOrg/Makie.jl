function initialize_block!(sg::SliderGrid, pairs::Pair...)

    sg.layout = GridLayout(bbox = sg.layoutobservables.suggestedbbox)
    sg.layout.parent = sg.blockscene
    

    default_format = string

    for (i, pair) in enumerate(pairs)
        label, range_and_maybe_format = pair
        if range_and_maybe_format isa Pair
            rng, format = range_and_maybe_format
        else
            rng = range_and_maybe_format
            format = string
        end
        Label(sg.layout[i, 1], label, halign = :left)
        slider = Slider(sg.layout[i, 2], range = rng)
        Label(sg.layout[i, 3], lift(format, slider.value), halign = :right)
    end

    # elements = broadcast(labels, ranges, formats) do label, range, format
    #     slider = Slider(scene; range = range, sliderkw...)
    #     label = Label(scene, label; halign = :left, labelkw...)
    #     valuelabel = Label(scene, lift(format, slider.value); halign = :right, valuekw...)
    #     (; slider = slider, label = label, valuelabel = valuelabel)
    # end

    # sliders = map(x -> x.slider, elements)
    # labels = map(x -> x.label, elements)
    # valuelabels = map(x -> x.valuelabel, elements)

    # layout = grid!(hcat(labels, sliders, valuelabels); layoutkw...)

    # sg
end