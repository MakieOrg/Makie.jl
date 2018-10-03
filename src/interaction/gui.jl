
default_printer(v) = string(round(v, digits=3))
@recipe(Slider) do scene
    Theme(
        value = 0,
        position = (0, 0),
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
convert_arguments(::Type{<: Slider}, x::AbstractRange) = (x,)

function range_label_bb(tplot, printer_func, range)
    bb = boundingbox(tplot, printer_func(first(range)))
    for elem in Iterators.drop(range, 1)
        bb = union(bb, boundingbox(tplot, printer_func(elem)))
    end
    bb
end

function textslider(ui, range, label)
    t = text!(ui, "$label:", raw = true, position = (0, 50), align = (:left, :center))[end]
    xp = widths(boundingbox(t))[1]
    s = slider!(ui, range, position = Point2f0(xp, 0), raw = true)[end]
    # AbstractPlotting.vbox([t, s])
    s[:value]
end

function plot!(slider::Slider)
    @extract(slider, (
        backgroundcolor, strokecolor, strokewidth, slidercolor, buttonstroke,
        buttonstrokecolor, buttonsize, buttoncolor, valueprinter,
        sliderlength, sliderheight, textcolor, textsize, position
    ))
    range = slider[1]
    val = slider[:value]
    p2f0 = lift(Point2f0, position)
    push!(val, first(to_value(range)))
    label = lift((v, f)-> f(v), val, valueprinter)
    lplot = text!(
        slider, label,
        textsize = textsize,
        align = (:left, :center), color = textcolor,
        position = lift((w, h, p)-> p .+ Point2f0(w, h/2), sliderlength, sliderheight, p2f0)
    ).plots[end]
    lbb = lift(range_label_bb, Node(lplot), valueprinter, range)
    bg_rect = lift(sliderlength, sliderheight, lbb, p2f0) do w, h, bb, p
        FRect(p, w + 10 + widths(bb)[1], h)
    end
    poly!(
        slider, bg_rect,
        color = backgroundcolor, linecolor = strokecolor,
        linewidth = strokewidth
    )
    line = lift(sliderlength, sliderheight, p2f0) do w, h, p
        [p .+ Point2f0(10, h / 2), p .+ Point2f0(w - 10, h / 2)]
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
    on(events(slider).mousedrag) do drag
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
@recipe(Button) do scene
    Theme(
        dimensions = (40, 40),
        backgroundcolor = (:white, 0.4),
        strokecolor = (:black, 0.4),
        strokewidth = 1,
        textcolor = :black,
        clicks = 0
    )
end

function button(func::Function, scene::Scene, txt; kw_args...)
    b = button!(scene, txt; raw = true, kw_args...)[end]
    on(b[:clicks]) do clicks
        func(clicks)
        return
    end
    b
end

function plot!(splot::Button)
    @extract(splot, (
        backgroundcolor, strokecolor, strokewidth,
        dimensions, textcolor, clicks
    ))
    txt = splot[1]
    lplot = text!(
        splot, txt,
        align = (:center, :center), color = textcolor,
        textsize = 15,
        position = map((wh)-> Point2f0(wh./2), dimensions)
    ).plots[end]
    lbb = boundingbox(lplot) # on purpose static so we hope text won't become too long?
    on(events(splot).mousebuttons) do mb
        if ispressed(mb, Mouse.left) && mouseover(parent(splot), lplot)
            clicks[] = clicks[] + 1
        end
        return
    end
    splot
end

window_open(scene::Scene) = getscreen(scene) != nothing && isopen(getscreen(scene))

function playbutton(f, scene, range, rate = (1/30))
    b = button!(scene, "▶", raw = true)[end]
    isplaying = Ref(false)
    play_idx = Ref(1)
    on(b[:clicks]) do x
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



struct Popup
    scene::Scene
    open::Node
    position::Node{Point2f0}
    width::Node{Point2f0}
end

function sample_color(f, ui, colormesh, v)
    mpos = ui.events.mouseposition
    sub = Scene(ui, transformation = Transformation(), px_area = pixelarea(ui), theme = theme(ui))
    select = scatter!(
        sub, lift((p, a)-> [Point2f0(p) .- minimum(a)], mpos, pixelarea(sub)),
        markersize = 15, color = (:white, 0.2), strokecolor = :white,
        strokewidth = 6, visible = lift(identity, theme(ui, :visible)), raw = true
    )[end]
    onany(mpos, ui.events.mousebuttons) do mp, mb
        bb = FRect2D(boundingbox(colormesh))
        mp = Point2f0(mp) .- minimum(pixelarea(sub)[])
        if Point2f0(mp) in bb
            select[:visible] = true
            if ispressed(mb, Mouse.left)
                sv = (Point2f0(mp) .- minimum(bb)) ./ widths(bb)
                f(RGBAf0(HSV(v[], sv[1], sv[2])))
            end
        else
            select[:visible] = false
        end
        return
    end
end



function popup(parent, position, width)
    pos_n = Node(Point2f0(position))
    width_n = Node(Point2f0(width))
    harea = lift(pos_n, width_n) do p, wh
        IRect(0, wh[2] - 20, wh[1], 20)
    end
    parea = lift(pos_n, width_n) do p, wh
        IRect(Point2f0(p), Point2f0(wh))
    end
    popup = Scene(parent, parea)
    popup.camera_controls[] = EmptyCamera()
    campixel!(popup)
    theme(popup)[:visible] = Node(false)
    header = Scene(popup, harea,
        backgroundcolor = :gray,
    )
    header.camera_controls[] = EmptyCamera()
    campixel!(header)
    theme(popup)[:plot] = Theme(raw = true, camera = campixel!)
    theme(header)[:plot] = Theme(raw = true, camera = campixel!)
    theme(header)[:visible] = theme(popup, :visible)
    initialized = Ref(false)
    but = button(header, "x") do click
        if initialized[]
            theme(popup, :visible)[] = !theme(popup, :visible)[]
        else
            initialized[] = true
        end
        return
    end
    translate!(but, width_n[][1] - 30, -10, 120)
    # on(width_n) do wh
    #     translate!(but, wh[1] - 30, -10, 120)
    # end
    poly!(header, lift(r-> FRect(0, 0, widths(r)), harea), color = (:gray, 0.1))
    poly!(popup, lift(wh-> FRect(2, 2, (wh - 4)...), width_n), color = :white, strokecolor = :black, strokewidth = 2)
    scene2 = Scene(popup, theme = theme(popup))
    scene2.camera_controls[] = EmptyCamera()
    campixel!(scene2)
    Popup(scene2, theme(popup, :visible), pos_n, width_n)
end


function mouse_selection end
export mouse_selection

function colorswatch(ui)
    pop = popup(ui, (0, 50), (250, 300))
    sub_ui = pop.scene
    hsv_hue = textslider(sub_ui, 1:360, "hue")
    colors = lift(hsv_hue) do V
        [HSV(V, 0, 0), HSV(V, 1, 0), HSV(V, 1, 1), HSV(V, 0, 1)]
    end
    S = 200
    colormesh = mesh!(
        sub_ui,
        # TODO implement decompose correctly to just have this be IRect(0, 0, S, S)
        [(0, 0), (S, 0), (S, S), (0, S)],
        [1, 2, 3, 3, 4, 1],
        color = colors, raw = true, shading = false
    )[end]
    color = Node(RGBAf0(0,0,0,1))
    sample_color(sub_ui, colormesh, hsv_hue) do c
        color[] = c
    end
    hbox!(sub_ui.plots)
    rect = IRect(0, 0, 50, 50)
    swatch = poly!(ui, rect, color = color, raw = true, visible = true)[end]
    pop.open[] = false
    on(ui.events.mousebuttons) do mb
        if ispressed(mb, Mouse.left)
            plot, idx = mouse_selection(ui)
            if plot in swatch.plots
                pop.position[] = Point2f0(events(ui).mouseposition[]) .+ Point2f0(0, 50)
                pop.open[] = true
            end
        end
        return
    end
    hbox!(sub_ui.plots)
    translate!(sub_ui, 10, 0, 0)
    color, pop
end
