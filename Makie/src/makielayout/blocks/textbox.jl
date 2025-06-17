using InteractiveUtils: clipboard


function initialize_block!(tbox::Textbox)

    topscene = tbox.blockscene

    scenearea = lift(topscene, tbox.layoutobservables.computedbbox) do bb
        Rect(round.(Int, bb.origin), round.(Int, bb.widths))
    end

    scene = Scene(topscene, scenearea, camera = campixel!)

    cursorindex = Observable(0)
    setfield!(tbox, :cursorindex, cursorindex)

    bbox = lift(Rect2f ∘ Makie.zero_origin, topscene, scenearea)

    roundedrectpoints = lift(roundedrectvertices, topscene, scenearea, tbox.cornerradius, tbox.cornersegments)

    tbox.displayed_string[] = isnothing(tbox.stored_string[]) ? tbox.placeholder[] : tbox.stored_string[]

    displayed_is_valid = lift(topscene, tbox.displayed_string, tbox.validator, ignore_equal_values = true) do str, validator
        return validate_textbox(str, validator)::Bool
    end

    hovering = Observable(false)
    realbordercolor = Observable{RGBAf}()

    map!(
        topscene, realbordercolor, tbox.bordercolor, tbox.bordercolor_focused,
        tbox.bordercolor_focused_invalid, tbox.bordercolor_hover, tbox.focused, displayed_is_valid, hovering
    ) do bc, bcf, bcfi, bch, focused, valid, hovering
        c = if focused
            valid ? bcf : bcfi
        else
            hovering ? bch : bc
        end
        return to_color(c)
    end

    realboxcolor = Observable{RGBAf}()
    map!(
        topscene, realboxcolor, tbox.boxcolor, tbox.boxcolor_focused,
        tbox.boxcolor_focused_invalid, tbox.boxcolor_hover, tbox.focused, displayed_is_valid, hovering
    ) do bc, bcf, bcfi, bch, focused, valid, hovering

        c = if focused
            valid ? bcf : bcfi
        else
            hovering ? bch : bc
        end
        return to_color(c)
    end

    box = poly!(
        topscene, roundedrectpoints, strokewidth = tbox.borderwidth,
        strokecolor = realbordercolor,
        color = realboxcolor, inspectable = false
    )

    displayed_chars = lift(ds -> [c for c in ds], topscene, tbox.displayed_string)

    realtextcolor = Observable{RGBAf}()
    map!(
        topscene, realtextcolor, tbox.textcolor, tbox.textcolor_placeholder, tbox.focused,
        tbox.stored_string, tbox.displayed_string
    ) do tc, tcph, foc, cont, disp
        # the textbox has normal text color if it's focused
        # if it's defocused, the displayed text has to match the stored text in order
        # to be normal colored
        return to_color(foc || cont == disp ? tc : tcph)
    end

    t = Label(
        scene, text = tbox.displayed_string, bbox = bbox, halign = :left, valign = :top,
        width = Auto(true), height = Auto(true), color = realtextcolor,
        fontsize = tbox.fontsize, padding = tbox.textpadding
    )

    textplot = t.blockscene.plots[1]
    # Manually add positions without considering transformations to prevent
    # infinite loop from translate!() in on(cursorpoints)
    displayed_charbbs = map(textplot.positions, fast_glyph_boundingboxes_obs(textplot)) do pos, bbs
        return [Rect2f(bb) + Point2f(pos[1]) for bb in bbs]
    end

    cursorsize = Observable(Vec2f(1, tbox.fontsize[]))
    cursorpoints = lift(topscene, cursorindex, displayed_charbbs; ignore_equal_values = true) do ci, bbs

        textplot = t.blockscene.plots[1]

        hadvances = Float32[]
        broadcast_foreach(textplot.glyph_extents[], textplot.text_scales[]) do ex, sc
            hadvance = ex.hadvance * sc[1]
            push!(hadvances, hadvance)
        end

        if ci > length(bbs)
            # correct cursorindex if it's outside of the displayed charbbs range
            ci = cursorindex[] = length(bbs)
        end

        line_ps = if 0 < ci < length(bbs)
            leftline(bbs[ci + 1])
        elseif ci == 0
            leftline(bbs[1])
        else
            leftline(bbs[ci]) .+ (Point2f(hadvances[ci], 0),)
        end

        # could this be done statically as
        # max_height = font.height / font.units_per_EM * fontsize
        max_height = abs(line_ps[1][2] - line_ps[2][2])
        if !(cursorsize[][2] ≈ max_height)
            cursorsize[] = Vec2f(1, max_height)
        end

        return 0.5 * (line_ps[1] + line_ps[2])
    end

    cursor = scatter!(
        scene, cursorpoints, marker = Rect, color = tbox.cursorcolor,
        markersize = cursorsize, inspectable = false
    )

    on(cursorpoints) do cpts
        typeof(tbox.width[]) <: Number || return

        # translate scene to keep cursor within box
        rel_cursor_pos = cpts[1][1] + scene.transformation.translation[][1]
        offset = if rel_cursor_pos <= 0
            -rel_cursor_pos
        elseif rel_cursor_pos < tbox.width[]
            0
        else
            tbox.width[] - rel_cursor_pos
        end
        translate!(Accum, scene, offset, 0, 0)

        # don't let right side of box be empty if length of text exceeds box width
        offset = tbox.width[] - right(displayed_charbbs[][end])
        scene.transformation.translation[][1] < offset < 0 && translate!(scene, offset, 0, 0)
    end

    tbox.cursoranimtask = nothing

    on(topscene, t.layoutobservables.reporteddimensions) do dims
        tbox.layoutobservables.autosize[] = dims.inner
    end

    # trigger text for autosize
    t.text = tbox.displayed_string[]

    # trigger bbox
    tbox.layoutobservables.suggestedbbox[] = tbox.layoutobservables.suggestedbbox[]

    mouseevents = addmouseevents!(scene)

    onmouseleftdown(mouseevents) do state
        focus!(tbox)

        if tbox.displayed_string[] == tbox.placeholder[]
            tbox.displayed_string[] = " "
            cursorindex[] = 0
            return Consume(true)
        elseif tbox.displayed_string[] == " "
            return Consume(true)
        end

        if typeof(tbox.width[]) <: Number
            pos = state.data .- scene.transformation.translation[][1:2]
        else
            pos = state.data
        end
        closest_charindex = argmin(
            [sum((pos .- center(bb)) .^ 2) for bb in displayed_charbbs[]]
        )
        # set cursor to index of closest char if right of center, or previous char if left of center
        cursorindex[] = if (pos .- center(displayed_charbbs[][closest_charindex]))[1] > 0
            closest_charindex
        else
            closest_charindex - 1
        end

        return Consume(true)
    end

    onmouseover(mouseevents) do state
        hovering[] = true
        return Consume(false)
    end

    onmouseout(mouseevents) do state
        hovering[] = false
        return Consume(false)
    end

    onmousedownoutside(mouseevents) do state
        if tbox.reset_on_defocus[]
            reset_to_stored()
        end
        defocus!(tbox)
        return Consume(false)
    end

    function insertchar!(c, index)
        if displayed_chars[] == [' ']
            empty!(displayed_chars[])
            index = 1
        end
        newchars = [displayed_chars[][1:(index - 1)]; c; displayed_chars[][index:end]]
        tbox.displayed_string[] = join(newchars)
        return cursorindex[] = index
    end

    function appendchar!(c)
        return insertchar!(c, length(tbox.displayed_string[]))
    end

    function removechar!(index)
        newchars = [displayed_chars[][1:(index - 1)]; displayed_chars[][(index + 1):end]]

        if isempty(newchars)
            newchars = [' ']
        end

        if cursorindex[] >= index
            cursorindex[] = max(0, cursorindex[] - 1)
        end

        return tbox.displayed_string[] = join(newchars)
    end

    on(topscene, events(scene).unicode_input; priority = 60) do char
        if tbox.focused[] && is_allowed(char, tbox.restriction[])
            insertchar!(char, cursorindex[] + 1)
            return Consume(true)
        end
        return Consume(false)
    end

    function reset_to_stored()
        cursorindex[] = 0
        return if isnothing(tbox.stored_string[])
            tbox.displayed_string[] = tbox.placeholder[]
        else
            tbox.displayed_string[] = tbox.stored_string[]
        end
    end

    function cursor_forward()
        return if tbox.displayed_string[] != " "
            cursorindex[] = min(length(tbox.displayed_string[]), cursorindex[] + 1)
        end
    end

    function cursor_backward()
        return cursorindex[] = max(0, cursorindex[] - 1)
    end


    on(topscene, events(scene).keyboardbutton; priority = 60) do event
        if tbox.focused[]
            ctrl_v = (Keyboard.left_control | Keyboard.right_control) & Keyboard.v
            if ispressed(scene, ctrl_v)
                local content::String = ""
                try
                    content = clipboard()
                catch err
                    @warn "Accessing the clipboard failed: $err"
                    return Consume(false)
                end

                if all(char -> is_allowed(char, tbox.restriction[]), content)
                    foreach(char -> insertchar!(char, cursorindex[] + 1), content)
                    return Consume(true)
                else
                    return Consume(false)
                end
            end

            if event.action != Keyboard.release
                key = event.key
                if key == Keyboard.backspace
                    removechar!(cursorindex[])
                elseif key == Keyboard.delete
                    removechar!(cursorindex[] + 1)
                elseif key == Keyboard.enter || key == Keyboard.kp_enter
                    # don't do anything for invalid input which should stay red
                    if displayed_is_valid[]
                        # submit the written text
                        tbox.stored_string[] = tbox.displayed_string[]
                        if tbox.defocus_on_submit[]
                            defocus!(tbox)
                        end
                    end
                elseif key == Keyboard.escape
                    if tbox.reset_on_defocus[]
                        reset_to_stored()
                    end
                    defocus!(tbox)
                elseif key == Keyboard.right
                    cursor_forward()
                elseif key == Keyboard.left
                    cursor_backward()
                end
            end
            return Consume(true)
        end

        return Consume(false)
    end
    return tbox
end

function validate_textbox(str, validator::Function)
    return validator(str)
end

function validate_textbox(str, T::Type)
    return !isnothing(tryparse(T, str))
end

function validate_textbox(str, validator::Regex)
    m = match(validator, str)
    # check that the validator matches the whole string
    return !isnothing(m) && m.match == str
end

function is_allowed(char, restriction::Nothing)
    return true
end

function is_allowed(char, restriction::Function)
    return allowed::Bool = restriction(char)
end

"""
    reset!(tb::Textbox)
Resets the stored_string of the given `Textbox` to `nothing` without triggering listeners, and resets the `Textbox` to the `placeholder` text.
"""
function reset!(tb::Textbox)
    tb.stored_string.val = nothing
    tb.displayed_string = tb.placeholder[]
    defocus!(tb)
    return nothing
end

"""
    set!(tb::Textbox, string::String)
Sets the stored_string of the given `Textbox` to `string`, triggering listeners of `tb.stored_string`.
"""
function set!(tb::Textbox, string::String)
    return if validate_textbox(string, tb.validator[])
        unsafe_set!(tb, string)
    else
        error("Invalid string \"$(string)\" for textbox.")
    end
end

"""
    unsafe_set!(tb::Textbox, string::String)
Sets the stored_string of the given `Textbox` to `string`, ignoring the possibility that it might not pass the validator function.
"""
function unsafe_set!(tb::Textbox, string::String)
    tb.displayed_string = string
    tb.stored_string = string
    return nothing
end

"""
    focus!(tb::Textbox)
Focuses an `Textbox` and makes it ready to receive keyboard input.
"""
function focus!(tb::Textbox)
    if !tb.focused[]
        tb.focused = true

        cursoranim = Animations.Loop(
            Animations.Animation(
                [0, 1.0],
                [Colors.alphacolor(COLOR_ACCENT[], 0), Colors.alphacolor(COLOR_ACCENT[], 1)],
                Animations.sineio(n = 2, yoyo = true, postwait = 0.2)
            ),
            0.0, 0.0, 1000
        )

        if !isnothing(tb.cursoranimtask)
            Animations.stop(tb.cursoranimtask)
            tb.cursoranimtask = nothing
        end

        tb.cursoranimtask = Animations.animate_async(cursoranim; fps = 30) do t, color
            tb.cursorcolor = color
        end
    end
    return nothing
end

"""
    defocus!(tb::Textbox)
Defocuses a `Textbox` so it doesn't receive keyboard input.
"""
function defocus!(tb::Textbox)

    if tb.displayed_string[] in (" ", "")
        tb.displayed_string[] = tb.placeholder[]
    end

    if !isnothing(tb.cursoranimtask)
        Animations.stop(tb.cursoranimtask)
        tb.cursoranimtask = nothing
    end
    tb.cursorcolor = :transparent
    tb.focused = false
    return nothing
end
