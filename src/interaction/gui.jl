

"""
    default_printer(v)

Prints v rounded to three digits.  Here, `v` can be of any type accepted by `round`, which includes Real, Complex and many others.  To use your own custom datatype it is sufficient to define Base.round(x::NewType, r::RoundingMode).
"""
default_printer(v) = string(round(v, sigdigits=3))

"""
    sig_printer(v::Real)

Prints the first three significant digits of `v` in scientific notation.
```jldoctest
julia> -5:5 .|> exp .|> sig_printer
11-element Array{String,1}:
 "6.74e-03"
 "1.83e-02"
 "4.98e-02"
 "1.35e-01"
 "3.68e-01"
 "1.00e+00"
 "2.72e+00"
 "7.39e+00"
 "2.01e+01"
 "5.46e+01"
 "1.48e+02"
```
"""
sig_printer(v::Real) = @sprintf "%0.2e" v

"""
    Slider

TODO add function signatures
TODO add description
"""
@recipe(Slider) do scene
    Theme(
        value = 0,
        start = automatic,
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
        valueprinter = default_printer,
        raw = true,
        camera = campixel!
    )
end

convert_arguments(::Type{<: Slider}, x::AbstractRange) = (x,)

function range_label_bb(tplot, printer_func, range)
    bb = boundingbox(tplot, printer_func(first(range)))
    for elem in Iterators.drop(range, 1)
        bb = union(bb, boundingbox(tplot, printer_func(elem)))
    end
    bb
end

function find_closest(iter, val)
    last = first(iter)
    for (i, elem) in enumerate(iter)
        elem === val && return i
        last <= val && elem >= val && return i
        last = elem
    end
    error("$val isn't contained in $iter")
end

function plot!(slider::Slider)
    @extract(slider, (
        backgroundcolor, strokecolor, strokewidth, slidercolor, buttonstroke,
        buttonstrokecolor, buttonsize, buttoncolor, valueprinter,
        sliderlength, sliderheight, textcolor, textsize, position, start
    ))
    range = slider[1]
    val = slider[:value]
    p2f0 = lift(Point2f0, position)
    startval = start[] === automatic ? first(range[]) : start[]
    push!(val, startval)
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
    line = lift(sliderlength, sliderheight, p2f0, buttonsize) do w, h, p, bs
        [p .+ Point2f0(bs/2, h / 2), p .+ Point2f0(w - (bs/2), h / 2)]
    end

    linesegments!(slider, line, color = slidercolor)
    button = scatter!(
        slider, lift(x-> x[1:1], line),
        markersize = buttonsize, color = buttoncolor, strokewidth = buttonstroke,
        strokecolor = buttonstrokecolor
    ).plots[end]
    dragslider(slider, button)
    move!(slider, find_closest(range[], startval))
    slider
end

function dragslider(slider, button)
    mpos = mouse_in_scene(slider)
    drag_started = Ref(false)
    startpos = Base.RefValue(Vec(0.0, 0.0))
    range = slider[1]
    @extract slider (value, sliderlength)
    on(events(slider).mousedrag) do drag
        mpos = mouseposition(rootparent(slider))
        if drag == Mouse.down && mouseover(slider, button)
            startpos[] = mpos
            drag_started[] = true
        elseif drag == Mouse.pressed && drag_started[]
            diff = startpos[] .- mpos
            startpos[] = mpos
            spos = translation(button)[][1] - diff[1]
            l = sliderlength[] - button[:markersize][]
            if spos >= 0 && spos <= l
                idx = round(Int, ((spos / l) .* (length(range[]) - 1)) + 1)
                value[] = range[][idx]
                translate!(button, spos, 0, 0)
            end
        else
            drag_started[] = false
            startpos[] = Vec(0.0, 0.0)
        end
        return
    end
end

function move!(x::Slider, idx::Integer)
    r = x[1][]
    len = x[:sliderlength][] - x[:buttonsize][]
    x[:value] = r[idx]
    xpos = ((idx - 1) / (length(r) - 1)) * len
    translate!(x.plots[end], xpos, 0, 0)
    return
end

export move! # TODO move to AbstractPlotting?

"""
    Button

TODO add function signatures
TODO add description
"""
@recipe(Button) do scene
    Theme(
        dimensions = (40, 40),
        backgroundcolor = (:white, 0.4),
        strokecolor = (:black, 0.4),
        strokewidth = 1,
        textcolor = :black,
        textsize = 20,
        clicks = 0,
        position = (10, 10),
        padvalue = 0.15
    )
end

function button!(func::Function, scene::Scene, txt; camera = campixel!, kw_args...)
    b = button!(scene, txt; raw = true, camera = camera, kw_args...)[end]
    on(b[:clicks]) do clicks
        func(clicks)
        return
    end
    b
end


function plot!(splot::Button)
    @extract(splot, (
        backgroundcolor, strokecolor, strokewidth,
        dimensions, textcolor, clicks, textsize, position,
        padvalue
    ))
    txt = splot[1]
    lplot = text!(
        splot, txt,
        color = textcolor,
        textsize = textsize, position = position,
        align = (:bottom, :center)
    ).plots[end]
    bb = boundingbox(lplot)
    pad = mean(widths(bb)) .* padvalue[]
    poly!(splot, padrect(FRect2D(boundingbox(lplot)), pad), color = backgroundcolor, strokecolor = strokecolor, strokewidth = strokewidth)
    reverse!(splot.plots) # make poly first
    on(events(splot).mousebuttons) do mb
        if ispressed(mb, Mouse.left) && mouseover(parent_scene(splot), splot.plots...)
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


function textslider(range, label, scene = Scene(camera = campixel!); start = first(range), textalign = (:left, :center), textpos = (0, 50), kwargs...)
    t = text!(scene, "$label:", raw = true, position = textpos, align = textalign, kwargs...)[end]
    xp = widths(boundingbox(t))[1]
    s = slider!(scene, range, position = Point2f0(xp, 0), raw = true, start = start, kwargs...)[end]
    scene, s[:value]
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
    pos_cam = lift(pos_n, camera(parent).projectionview) do pos, pview
        to_world(parent, Point2f0(pos))
    end
    width_n = Node(Point2f0(width))
    hwidth = 30
    harea = lift(pos_cam, width_n) do p, wh
        IRect(1, wh[2] - hwidth + 1, wh[1] - 2, hwidth - 2)
    end
    parea = lift(pos_cam, width_n) do p, wh
        IRect(p, Point2f0(wh) .- Point2f0(0, hwidth - 1))
    end
    vis = Node(false)
    popup = Scene(parent, parea,
        visible = vis, raw = true, camera = campixel!,
        backgroundcolor = RGBAf0(0.95, 0.95, 0.95, 1.0)
    )
    header = Scene(popup, harea,
        backgroundcolor = RGBAf0(0.90, 0.90, 0.90, 1.0), visible = vis,
        raw = true, camera = campixel!
    )
    initialized = Ref(false)
    but = button!(header, "x", strokewidth = 0.0) do click
        if initialized[]
            vis[] = !vis[]
        else
            initialized[] = true
        end
        return
    end
    poly!(popup, lift(wh-> FRect(2, 2, (wh - 4)...), width_n), color = :white)
    scene2 = Scene(popup, theme = theme(popup))
    campixel!(scene2)
    Popup(scene2, vis, pos_n, width_n)
end

"""
    Colorswatch

TODO add function signatures
TODO add description
"""
function colorswatch(scene = Scene(camera = campixel!)) # TODO convert to Recipe?
    pop = popup(scene, (0, 0), (250, 300))
    sub_ui = pop.scene
    st, hsv_hue = textslider(1:360, "hue", sub_ui)
    colors = lift(hsv_hue) do V
        [HSV(V, 0, 0), HSV(V, 1, 0), HSV(V, 1, 1), HSV(V, 0, 1)]
    end
    S = 200
    colormesh = mesh!(
        sub_ui,
        # TODO implement decompose correctly to just have this be IRect(0, 0, S, S)
        [(0, 0), (S + 30, 0), (S + 30, S - 15), (0, S - 15)],
        [1, 2, 3, 3, 4, 1],
        color = colors, raw = true, shading = false
    )[end]
    color = Node(RGBAf0(0,0,0,1))
    sample_color(sub_ui, colormesh, hsv_hue) do c
        color[] = c
    end
    hbox!(sub_ui.plots)
    rect = IRect(0, 0, 50, 50)
    swatch = poly!(scene, rect, color = color, raw = true, visible = true)[end]
    pop.open[] = false
    on(scene.events.mousebuttons) do mb
        if ispressed(mb, Mouse.left)
            plot, idx = mouse_selection(scene)
            if plot in swatch.plots
                mpos = Point2f0(events(scene).mouseposition[])
                mpos = mpos .- Point2f0(minimum(pixelarea(scene)[]))
                pop.position[] = mpos .+ Point2f0(50, -50)
                pop.open[] = true
            end
        end
        return
    end
    hbox!(sub_ui.plots)
    translate!(sub_ui, 10, 0, 0)
    scene, color, pop
end
