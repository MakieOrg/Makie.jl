struct Button
    value::Node{Bool}
    text::Node{String}
    visual::AbstractPlot
end

function Button(scene::Scene, txt::String)
    butt = Combined{:Button}(scene, Attributes(), txt)
    tvis = text!(butt, txt)
    value = node(:button_value, false)
    onclick(butt) do val
        value[] = val
    end
    Button(value, txt, butt)
end


default_printer(v) = string(round(v, 3))
@recipe(Slider) do scene
    Theme(
        value = 0,
        sliderlength = 200,
        sliderheight = 50,
        backgroundcolor = (:gray, 0.01),
        strokecolor = (:black, 0.4),
        strokewidth = 1,
        textcolor = :black,
        slidercolor = (:gray, 0.6),
        buttoncolor = :white,
        buttonsize = 15,
        buttonstroke = 1.5,
        textsize = 15,
        buttonstrokecolor = :black,
        valueprinter = default_printer
    )
end

mouseover() = error("not implemented")
export mouseover
convert_arguments(::Type{<: Slider}, x::Range) = (x,)

function range_label_bb(tplot, printer_func, range)
    bb = boundingbox(tplot, printer_func(first(range)))
    for elem in Iterators.drop(range, 1)
        bb = union(bb, boundingbox(tplot, printer_func(elem)))
    end
    bb
end
function plot!(slider::Slider)
    @extract(slider, (
        backgroundcolor, strokecolor, strokewidth, slidercolor, buttonstroke,
        buttonstrokecolor, buttonsize, buttoncolor, valueprinter,
        sliderlength, sliderheight, textcolor, textsize
    ))
    range = slider[1]
    val = slider[:value]
    push!(val, first(value(range)))
    label = lift((v, f)-> f(v), val, valueprinter)
    lplot = text!(
        slider, label,
        textsize = textsize,
        align = (:left, :center), color = textcolor,
        position = map((w, h)-> Point2f0(w, h/2), sliderlength, sliderheight)
    ).plots[end]
    lbb = lift(range_label_bb, Node(lplot), valueprinter, range)
    bg_rect = lift(sliderlength, sliderheight, lbb) do w, h, bb
        FRect(0, 0, w + 10 + widths(bb)[1], h)
    end
    poly!(
        slider, bg_rect,
        color = backgroundcolor, linecolor = strokecolor,
        linewidth = strokewidth
    )
    line = lift(sliderlength, sliderheight) do w, h
        Point2f0[(10, h / 2), (w - 10, h / 2)]
    end

    linesegments!(slider, line, color = slidercolor)
    button = scatter!(
        slider, map(x-> x[1:1], line),
        markersize = buttonsize, color = buttoncolor, strokewidth = buttonstroke,
        strokecolor = buttonstrokecolor
    ).plots[end]
    dragslider(slider, button)
end

function dragslider(slider, button)
    mpos = events(slider).mouseposition
    drag_started = Ref(false)
    startpos = Base.RefValue((0.0, 0.0))
    range = slider[1]
    @extract slider (value, sliderlength)
    foreach(events(slider).mousedrag) do drag
        if drag == Mouse.down && mouseover(slider, button)
            startpos[] = mpos[]
            drag_started[] = true
        elseif drag == Mouse.pressed && drag_started[]
            diff = startpos[] .- mpos[]
            startpos[] = mpos[]
            spos = translation(button)[][1] - diff[1]
            l = sliderlength[] - 17.5
            if spos >= 0 && spos <= l
                idx = round(Int, ((spos / l) .* (length(range[]) - 1)) + 1)
                value[] = range[][idx]
                translate!(button, spos, 0, 0)
            end
        else
            drag_started[] = false
            startpos[] = (0.0, 0.0)
        end
        return
    end
end

function move!(x::Slider, idx::Integer)
    r = x[1][]
    len = x[:sliderlength][]
    x[:value] = r[idx]
    xpos = ((idx - 1) / (length(r) - 1)) * len
    translate!(x.plots[end], xpos, 0, 0)
    return
end
export move!

function button(func, scene, txt; kw_args...)
    b = button(scene, txt; kw_args...)
    foreach(b[:clicks]) do clicks
        func(clicks)
        return
    end
    b
end
function button(scene, txt; kw_args...)
    attributes, rest = merged_get!(:slider, scene, kw_args) do
        Theme(
            dimensions = (40, 40),
            backgroundcolor = (:white, 0.4),
            strokecolor = (:black, 0.4),
            strokewidth = 1,
            textcolor = :black,
        )
    end
    attributes[:clicks] = Signal(0)
    @extract(attributes, (
        backgroundcolor, strokecolor, strokewidth,
        dimensions, textcolor, clicks
    ))
    splot = Combined{:Button}(scene, attributes, node(:range, range))
    lplot = text!(
        splot, txt,
        align = (:center, :center), color = textcolor,
        textsize = 15,
        position = map((wh)-> Point2f0(wh./2), dimensions)
    )
    lbb = data_limits(lplot) # on purpose static so we hope text won't become too long?
    bg_rect = map(dimensions) do wh
        IRect(0, 0, Vec(wh))
    end
    p = poly!(
        splot, bg_rect,
        color = backgroundcolor, linecolor = strokecolor,
        linewidth = strokewidth
    )
    foreach(scene.events.mousebuttons) do mb
        if ispressed(mb, Mouse.left) && mouseover(scene, lplot, p.plots...)
            clicks[] = clicks[] + 1
        end
        return
    end
    splot
end

window_open(scene::Scene) = getscreen(scene) != nothing && isopen(getscreen(scene))

function playbutton(f, scene, range, rate = (1/30))
    b = button(scene, "▶ ")
    isplaying = Ref(false)
    play_idx = Ref(1)
    foreach(b[:clicks]) do x
        if !isplaying[] && x > 0 # check that this isn't before any clicks
            isplaying[] = true
            @async begin
                b.plots[1][1][] = "𝅛𝅛"
                tstart = time()
                while (isplaying[] && window_open(scene))
                    if time() - tstart >= rate
                        f(range[play_idx[]])
                        play_idx[] = mod1(play_idx[] + 1, length(range))
                        tstart = time()
                        force_update!()
                    end
                    yield()
                end
                isplaying[] = false
            end
        else
            b.plots[1][1][] = "▶ "
            isplaying[] = false
        end
        nothing
    end
    b
end
