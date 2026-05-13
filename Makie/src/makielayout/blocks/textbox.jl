function initialize_block!(tbox::Textbox)

    topscene = tbox.blockscene

    scenearea = lift(topscene, tbox.layoutobservables.computedbbox) do bb
        Rect(round.(Int, bb.origin), round.(Int, bb.widths))
    end

    scene = Scene(topscene, scenearea, camera = campixel!)

    bbox = lift(Rect2f ∘ Makie.zero_origin, topscene, scenearea)
    roundedrectpoints = lift(roundedrectvertices, topscene, scenearea, tbox.cornerradius, tbox.cornersegments)

    # Initial displayed_string. Empty means "show the placeholder."
    if isnothing(tbox.displayed_string[])
        tbox.displayed_string[] = isnothing(tbox.stored_string[]) ? "" : tbox.stored_string[]
    end

    displayed_is_valid = lift(topscene, tbox.displayed_string, tbox.validator, ignore_equal_values = true) do str, validator
        return validate_textbox(str, validator)::Bool
    end

    hovering = Observable(false)

    # ── Box background + border ──────────────────────────────────────────────
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

    poly!(
        topscene, roundedrectpoints, strokewidth = tbox.borderwidth,
        strokecolor = realbordercolor,
        color = realboxcolor, inspectable = false,
    )

    # ── Text colour: real text vs placeholder ────────────────────────────────
    realtextcolor = lift(topscene, tbox.textcolor, tbox.textcolor_placeholder, tbox.focused, tbox.displayed_string, tbox.stored_string) do tc, tcph, foc, disp, stored
        # The text reads as "active" (regular color) when focused, or when the
        # displayed string already matches what's stored.
        return foc || disp == stored ? to_color(tc) : to_color(tcph)
    end

    # Position the editor at the top-left of the inner area, accounting for textpadding.
    text_origin = lift(topscene, scenearea, tbox.textpadding) do area, padding
        # padding = (left, right, bottom, top); text uses (:left, :top) align so we anchor at the top-left
        l, _r, _b, t = padding
        return Point2f(l, widths(area)[2] - t)
    end

    # Placeholder is rendered as a separate text! that's visible whenever
    # the editor has no content. It stays visible after focus and only goes
    # away once the user types the first character.
    placeholder_visible = lift(s -> isempty(s), tbox.displayed_string)
    placeholder_plot = text!(
        scene, text_origin; text = tbox.placeholder,
        align = (:left, :top), color = tbox.textcolor_placeholder,
        font = tbox.font, fontsize = tbox.fontsize,
        visible = placeholder_visible, inspectable = false,
    )

    # ── The editable text itself ─────────────────────────────────────────────
    et = editabletext!(
        scene, tbox.displayed_string;
        position = text_origin,
        align = (:left, :top),
        focused = tbox.focused,
        color = realtextcolor,
        font = tbox.font,
        fontsize = tbox.fontsize,
        cursor_color = tbox.cursorcolor,
        space = :pixel,
        multiline = false,
        manage_focus = false,            # Textbox drives focus (see below)
        input_filter = c -> is_allowed(c, tbox.restriction[]),
        on_submit = (text) -> begin
            if displayed_is_valid[]
                tbox.stored_string[] = text
                tbox.defocus_on_submit[] && defocus!(tbox)
            end
        end,
    )
    setfield!(tbox, :editor, et)

    # Sync displayed_string ↔ the editor's text. Passing the Observable to the
    # recipe wires the forward direction (`tb.displayed_string` → editor text);
    # this listener carries internal edits back out.
    on(et.text) do t
        if tbox.displayed_string[] != t
            tbox.displayed_string[] = t
        end
        return
    end

    # ── Autosize ─────────────────────────────────────────────────────────────
    # Listen on the *inputs* (displayed_string, font, fontsize, padding) rather
    # than on the rendered bbox observable; reading the bbox inside the callback
    # avoids the layout-feedback cycle (autosize → scenearea → text_origin →
    # text plot bbox) that listening directly to the bbox would cause.
    text_plot = only(p for p in et.plots if p isa Makie.Text)
    onany(topscene, tbox.displayed_string, tbox.placeholder, tbox.fontsize, tbox.font, tbox.textpadding) do disp, ph, fs, _fnt, padding
        l, r, b, t = padding
        # Width from the rendered text bbox (placeholder while empty, real text
        # once typed). Height is computed from line count + font metrics so an
        # empty trailing line (`disp` ends with `\n`) still grows the textbox.
        # Using a position-independent bbox here avoids registering a second
        # projected pipeline and the layout feedback cycle.
        plot = isempty(disp) ? placeholder_plot : text_plot
        bbs = Makie.fast_string_boundingboxes(plot)
        text_w = if isempty(bbs) || !isfinite(minimum(bbs[1])[1])
            Float32(fs) * 0.5f0
        else
            Float32(widths(bbs[1])[1])
        end
        # n_lines counts visible lines including a trailing empty line.
        sample = isempty(disp) ? ph : disp
        n_lines = count(==('\n'), sample) + 1
        font_obj = plot.selected_font[]::Makie.NativeFont
        line_h = Float32(font_obj.height / font_obj.units_per_EM * fs)
        text_h = Float32(n_lines) * line_h
        tbox.layoutobservables.autosize[] = (text_w + l + r, text_h + b + t)
        return
    end

    # ── Hover tracking ───────────────────────────────────────────────────────
    mouseevents = addmouseevents!(scene)
    onmouseover(mouseevents) do _
        hovering[] = true
        return Consume(false)
    end
    onmouseout(mouseevents) do _
        hovering[] = false
        return Consume(false)
    end

    # ── Focus on click ───────────────────────────────────────────────────────
    # Listen at priority 70, *above* EditableText's priority 60, so we set
    # `focused` before the recipe inspects it (the recipe runs in
    # `manage_focus = false` mode and only places a cursor when already focused).
    on(topscene, events(scene).mousebutton, priority = 70) do event
        event.button == Mouse.left || return Consume(false)
        if event.action == Mouse.press
            inside = Makie.is_mouseinside(scene)
            if inside
                tbox.focused[] || focus!(tbox)
            else
                if tbox.focused[]
                    tbox.reset_on_defocus[] && _reset_to_stored!(tbox)
                    defocus!(tbox)
                end
            end
        end
        return Consume(false)
    end

    # ── Reset on Escape ──────────────────────────────────────────────────────
    on(topscene, events(scene).keyboardbutton, priority = 70) do event
        # Higher priority than EditableText (60) so we get to handle escape
        # *and* let it pass through to the recipe's defocus path.
        if tbox.focused[] && event.action == Keyboard.press && event.key == Keyboard.escape
            if tbox.reset_on_defocus[]
                _reset_to_stored!(tbox)
            end
            # EditableText also defocuses on escape; we let it through.
        end
        return Consume(false)
    end

    # ── Horizontal scroll when content exceeds the visible width ─────────────
    # The inner `scene` holds the editor; translating it horizontally keeps the
    # caret in view as the user types or moves past the right edge. We compute
    # the caret's position in *text-layout* coordinates from the glyph data so
    # the listener is invariant to the scene translation it produces — listening
    # on the rendered caret plot would be a feedback loop because
    # `markerspace_positions` depend on the scene's model matrix.
    function _caret_layout_x()
        head = isempty(et.cursors[]) ? 0 : et.cursors[][1].head
        origins = text_plot.glyph_origins[]
        head <= 0 && return 0.0f0
        if head < length(origins)
            return Float32(origins[head + 1][1])
        elseif head == length(origins) && !isempty(origins)
            extents = text_plot.glyph_extents[]
            scales = text_plot.text_scales[]
            return Float32(origins[end][1] + extents[end].hadvance * scales[end][1])
        else
            return 0.0f0
        end
    end

    onany(topscene, et.cursors, text_plot.glyph_origins, scenearea) do _cs, _origins, area
        typeof(tbox.width[]) <: Number || return
        l, r, _b, _t = tbox.textpadding[]
        # The text starts `l` pixels in; the right edge of the visible text region
        # is `area.widths[1] - r`. Keep the caret inside that strip.
        caret_x = l + _caret_layout_x()
        tx = Float32(scene.transformation.translation[][1])
        rel_x = caret_x + tx
        right = Float32(area.widths[1]) - r
        offset = if rel_x < l
            l - rel_x
        elseif rel_x > right
            right - rel_x
        else
            0.0f0
        end
        offset == 0 || translate!(Accum, scene, offset, 0, 0)

        # When the text shrinks past the right edge, pull it back so the box
        # isn't padded with empty space.
        origins = text_plot.glyph_origins[]
        isempty(origins) && return
        extents = text_plot.glyph_extents[]
        scales = text_plot.text_scales[]
        text_right = Float32(l + origins[end][1] + extents[end].hadvance * scales[end][1])
        gap = right - (text_right + Float32(scene.transformation.translation[][1]))
        tx2 = Float32(scene.transformation.translation[][1])
        if tx2 < 0 && gap > 0
            translate!(Accum, scene, min(gap, -tx2), 0, 0)
        end
        return
    end

    # Trigger initial autosize and bbox so the layout settles.
    notify(tbox.displayed_string)
    tbox.layoutobservables.suggestedbbox[] = tbox.layoutobservables.suggestedbbox[]

    return tbox
end

function _reset_to_stored!(tbox::Textbox)
    tbox.displayed_string[] = isnothing(tbox.stored_string[]) ? "" : tbox.stored_string[]
    return
end

function validate_textbox(str, validator::Function)
    return validator(str)
end

function validate_textbox(str, T::Type)
    return !isnothing(tryparse(T, str))
end

function validate_textbox(str, validator::Regex)
    m = match(validator, str)
    return !isnothing(m) && m.match == str
end

is_allowed(_, ::Nothing) = true
is_allowed(char, restriction::Function) = restriction(char)::Bool

"""
    reset!(tb::Textbox)
Resets the stored_string of the given `Textbox` to `nothing` without triggering listeners, and resets the `Textbox` to the `placeholder` text.
"""
function reset!(tb::Textbox)
    tb.stored_string.val = nothing
    tb.displayed_string = ""
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
    tb.focused = true
    return nothing
end

"""
    defocus!(tb::Textbox)
Defocuses a `Textbox` so it doesn't receive keyboard input.
"""
function defocus!(tb::Textbox)
    tb.focused = false
    return nothing
end
