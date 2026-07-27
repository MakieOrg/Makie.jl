"""
    EditCursor(anchor, head)

A single cursor / selection inside an `EditableText`. `anchor` and `head` are
0-based character offsets into the underlying string, where offset `i` denotes
the position between character `i` and character `i+1` (so valid offsets are
`0:length(string)`). When `anchor == head` this is just a caret with no
selection; otherwise the selected range is `min(anchor, head):max(anchor, head)`.

`head` is the side that moves under arrow keys / drag; `anchor` is the fixed
side.
"""
struct EditCursor
    anchor::Int
    head::Int
end
EditCursor(i::Int) = EditCursor(i, i)

sel_lo(c::EditCursor) = min(c.anchor, c.head)
sel_hi(c::EditCursor) = max(c.anchor, c.head)
is_selection(c::EditCursor) = c.anchor != c.head

"""
    editabletext(text; attributes...)

A `Text`-like recipe that renders an editable string. Selections and a blinking
cursor are derived from the `cursors` attribute, which can hold multiple
[`EditCursor`](@ref) entries (multi-cursor). Editing happens through mouse and
keyboard event handlers that update `text` and `cursors` in place.

Only single-font / single-color text is supported (no per-glyph styling). The
recipe relies on the basic `Text` path producing a 1:1 character-to-glyph
mapping (which it already does for plain `String`s — newline glyphs are kept
with `glyph_index = 0` and skipped at the backend).
"""
@recipe_internal EditableText (text,) begin
    "The position at which the text is anchored, in `space`."
    position = Point2f(0)
    "Active cursors / selections. A `Vector{EditCursor}`; the default is a single empty caret at offset 0."
    cursors = [EditCursor(0)]
    "Whether the text is focused. When `true` the cursor blinks and edit keys take effect."
    focused = false
    "Color of the rendered text."
    color = @inherit textcolor
    "Font used for the text (single font, no per-glyph styling)."
    font = @inherit font
    fonts = @inherit fonts
    "Pixel size of the text."
    fontsize = @inherit fontsize
    "Alignment of the text relative to `position`."
    align = (:left, :baseline)
    "Multiplier for vertical line spacing."
    lineheight = 1.0
    "Color of selection rectangles drawn behind the text."
    selection_color = RGBAf(0.4, 0.6, 1.0, 0.35)
    "Color of the cursor caret."
    cursor_color = @inherit textcolor
    "Width of the cursor caret in pixels."
    cursor_width = 1.5
    "Full on/off period of the cursor blink in seconds. Set to `Inf` to disable blinking."
    blink_period = 1.0
    "Space the `position` is given in (passed through to the inner text plot)."
    space = :data
    """
    If `true` (default), the recipe focuses on click inside the text bbox and
    defocuses on click outside. Set to `false` when a parent block (e.g.
    `Textbox`) owns focus state — the recipe will then only place the cursor
    when clicked while already focused, leaving focus changes to the parent.
    """
    manage_focus = true
    """
    If `true`, Enter inserts a newline and Cmd/Ctrl+Enter triggers `on_submit`.
    If `false`, plain Enter triggers `on_submit` and Shift+Enter inserts a
    newline (chat-box / single-line input style).
    """
    multiline = true
    "Optional callback `(text::String) -> Any` invoked on submit (Cmd/Ctrl+Enter when `multiline = true`, plain Enter when `multiline = false`)."
    on_submit = nothing
    """
    Filter applied to typed characters: `(c::Char) -> Bool`. Characters that
    fail the predicate are dropped. Newlines inserted via the Enter / Shift+Enter
    keypath are not subject to this filter — use `multiline = false` to forbid
    them. Default accepts everything.
    """
    input_filter = c -> true
    visible = true
    inspectable = false
end

################################################################################
# Word / line helpers (operating on Vector{Char}, 0-based offsets)
################################################################################

isword_char(c::Char) = isletter(c) || isdigit(c) || c == '_'

function next_word_offset(chars::Vector{Char}, i::Int)
    n = length(chars)
    j = clamp(i, 0, n)
    j == n && return n
    while j < n && !isword_char(chars[j + 1])
        j += 1
    end
    while j < n && isword_char(chars[j + 1])
        j += 1
    end
    return j
end

function prev_word_offset(chars::Vector{Char}, i::Int)
    j = clamp(i, 0, length(chars))
    j == 0 && return 0
    while j > 0 && !isword_char(chars[j])
        j -= 1
    end
    while j > 0 && isword_char(chars[j])
        j -= 1
    end
    return j
end

# Word containing the cursor at offset `i`. Returns (lo, hi).
function word_at_offset(chars::Vector{Char}, i::Int)
    n = length(chars)
    j = clamp(i, 0, n)
    target = if j < n && isword_char(chars[j + 1])
        j + 1
    elseif j > 0 && isword_char(chars[j])
        j
    else
        return (j, j)
    end
    a = target
    while a > 1 && isword_char(chars[a - 1])
        a -= 1
    end
    b = target
    while b < n && isword_char(chars[b + 1])
        b += 1
    end
    return (a - 1, b)
end

# Line containing the cursor at offset `i`. Returns (lo, hi) such that the
# selection covers from start-of-line to end-of-line (excluding the trailing '\n').
function line_at_offset(chars::Vector{Char}, i::Int)
    n = length(chars)
    j = clamp(i, 0, n)
    a = j
    while a > 0 && chars[a] != '\n'
        a -= 1
    end
    b = j
    while b < n && chars[b + 1] != '\n'
        b += 1
    end
    return (a, b)
end

################################################################################
# Cursor anchor positions in markerspace (relative to the text block position)
################################################################################

"""
    CursorAnchors

Layout output from `cursor_anchor_positions`.

* `anchors[i+1]` is the baseline position of the cursor at offset `i` (0-based).
* `ascender` / `descender` are pixel offsets from the baseline (descender is
  negative); the visible caret spans `[baseline + descender, baseline + ascender]`.
* `line_h` is the spacing between line baselines, used for vertical
  extrapolation past the last glyph.
"""
struct CursorAnchors
    anchors::Vector{Point2f}
    ascender::Float32
    descender::Float32
    line_h::Float32
end

function cursor_anchor_positions(
        glyph_origins::AbstractVector{<:VecTypes{3}},
        glyph_extents::AbstractVector{GlyphExtent},
        glyph_scales::AbstractVector{Vec2f},
        font::NativeFont,
        fontsize::Float32, lineheight::Float32,
        align::Tuple, trailing_newline::Bool,
    )::CursorAnchors
    line_h = Float32(font.height / font.units_per_EM * fontsize * lineheight)
    # A single font is in use, so the font-level ascender / descender apply to
    # every glyph (including the empty-editor case). FreeType gives them in
    # font units; multiply by `fontsize` to get pixels.
    ascender = Float32(FreeTypeAbstraction.ascender(font) * fontsize)
    descender = Float32(FreeTypeAbstraction.descender(font) * fontsize)

    n = length(glyph_origins)
    if n == 0
        # No glyphs to anchor to. Place the caret at where the first glyph's
        # baseline *would* sit given the current `align` — for `:top` the
        # baseline is `ascender` pixels below the position; for `:bottom`
        # it's `descender` (negative) below; etc. This matches what the text
        # plot does to its first glyph in the alignment step, so the caret
        # remains in the same spot when the user types the first character.
        _halign, valign = align
        y0 = if valign === :top
            -ascender
        elseif valign === :bottom
            -descender
        elseif valign === :center
            -(ascender + descender) / 2
        else  # :baseline or numeric
            0.0f0
        end
        return CursorAnchors([Point2f(0, y0)], ascender, descender, line_h)
    end

    anchors = Vector{Point2f}(undef, n + 1)
    anchors[1] = Point2f(glyph_origins[1][1], glyph_origins[1][2])
    for i in 1:(n - 1)
        anchors[i + 1] = Point2f(glyph_origins[i + 1][1], glyph_origins[i + 1][2])
    end
    if trailing_newline
        # Trailing newline: extrapolate to the start of the empty next line.
        anchors[n + 1] = Point2f(0, glyph_origins[n][2] - line_h)
    else
        adv = Float32(glyph_extents[n].hadvance) * glyph_scales[n][1]
        anchors[n + 1] = Point2f(glyph_origins[n][1] + adv, glyph_origins[n][2])
    end
    return CursorAnchors(anchors, ascender, descender, line_h)
end

# `line_idx[i+1]` = 1-based line of cursor offset `i`.
function cursor_anchor_lines(chars::Vector{Char})
    n = length(chars)
    line_idx = Vector{Int}(undef, n + 1)
    line = 1
    line_idx[1] = 1
    for i in 1:n
        if chars[i] == '\n'
            line += 1
        end
        line_idx[i + 1] = line
    end
    return line_idx
end

################################################################################
# Selection rectangles
################################################################################

# Build per-line rectangles covering the selection range lo..hi.
function selection_rects_for_range(
        lo::Int, hi::Int,
        anchors::Vector{Point2f}, line_idx::Vector{Int},
        ascender::Float32, descender::Float32, line_h::Float32,
    )
    lo == hi && return Rect2f[]
    rects = Rect2f[]
    seg_lo = lo
    while seg_lo < hi
        line = line_idx[seg_lo + 1]
        seg_hi = seg_lo
        while seg_hi < hi && line_idx[seg_hi + 2] == line
            seg_hi += 1
        end
        a = anchors[seg_lo + 1]
        b = anchors[seg_hi + 1]
        crosses_newline = seg_hi < hi
        # When the segment ends at a newline, give the rectangle a small visible
        # tail to the right so it is clear the newline is included.
        right_x = crosses_newline ? max(b[1], a[1] + 0.4f0 * line_h) : b[1]
        x0 = min(a[1], right_x)
        w = abs(right_x - a[1])
        # The rect spans descender..ascender vertically.
        push!(rects, Rect2f(Point2f(x0, a[2] + descender), Vec2f(w, ascender - descender)))
        # If the segment crosses a newline (chars[seg_hi+1] == '\n'), step past it
        # so the next iteration starts on the next line. Otherwise we'd loop forever
        # when the inner while didn't advance.
        seg_lo = crosses_newline ? seg_hi + 1 : seg_hi
    end
    return rects
end

################################################################################
# Multi-cursor edit application
################################################################################

# Merge cursors that overlap or touch. Direction (anchor vs head) is taken from
# the cursor that "wins" each merge.
function merge_cursors(cursors::Vector{EditCursor})
    isempty(cursors) && return cursors
    sorted = sort(cursors; by = sel_lo)
    out = EditCursor[sorted[1]]
    for c in @view sorted[2:end]
        last = out[end]
        if sel_lo(c) <= sel_hi(last)
            new_lo = min(sel_lo(last), sel_lo(c))
            new_hi = max(sel_hi(last), sel_hi(c))
            out[end] = c.anchor <= c.head ? EditCursor(new_lo, new_hi) : EditCursor(new_hi, new_lo)
        else
            push!(out, c)
        end
    end
    return out
end

# A single primitive edit: remove the characters in `range` (0-based char
# offsets, where `a:b` denotes the chars between cursor positions `a` and `b`)
# and insert `insert` in their place. Either side can be empty:
#   * insert only (range a:a, insert "x"): pure insertion at cursor `a`
#   * delete only (range a:b, insert ""): pure deletion of chars (a, b]
#   * replace   (range a:b, insert "x"): selection replacement
# All movement / deletion key handlers reduce to one of these primitives;
# `apply_edits` then composes per-cursor ops left-to-right.
struct EditOp
    range::UnitRange{Int}
    insert::String
end

# Apply per-cursor edit ops. `op_for(cursor) -> EditOp`. Returns
# `(new_text, new_cursors)`. Overlapping ops are coalesced left-to-right.
function apply_edits(text::String, cursors::Vector{EditCursor}, op_for)
    # Single-cursor fast path: skip the sort / paired round-trip; this is the
    # path every keystroke takes in a normal Textbox.
    if length(cursors) == 1
        chars = collect(text)
        n = length(chars)
        edit = op_for(cursors[1])::EditOp
        a = clamp(edit.range.start, 0, n)
        b = clamp(edit.range.stop, 0, n)
        new_chars = Char[]
        sizehint!(new_chars, n - (b - a) + length(edit.insert))
        append!(new_chars, view(chars, 1:a))
        append!(new_chars, edit.insert)
        append!(new_chars, view(chars, (b + 1):n))
        return String(new_chars), [EditCursor(a + length(edit.insert))]
    end
    chars = collect(text)
    n = length(chars)
    paired = [(i, op_for(c)::EditOp) for (i, c) in enumerate(cursors)]
    sort!(paired; by = p -> p[2].range.start)

    new_chars = Char[]
    new_cursors = Vector{EditCursor}(undef, length(cursors))
    pos = 0
    for (cursor_idx, edit) in paired
        a = clamp(edit.range.start, 0, n)
        b = clamp(edit.range.stop, 0, n)
        if a < pos
            # Range overlaps the previous edit's deletion. Skip this insert and
            # collapse the cursor onto the previous edit's tail position so the
            # combined output never duplicates an insertion in the overlap.
            new_cursors[cursor_idx] = EditCursor(length(new_chars))
            pos = max(pos, b)
            continue
        end
        for j in (pos + 1):a
            push!(new_chars, chars[j])
        end
        for c in edit.insert
            push!(new_chars, c)
        end
        new_cursors[cursor_idx] = EditCursor(length(new_chars))
        pos = b
    end
    for j in (pos + 1):n
        push!(new_chars, chars[j])
    end
    return String(new_chars), merge_cursors(new_cursors)
end

# EditOp builders for common actions.
_replace_op(c::EditCursor, replacement::String) = EditOp(sel_lo(c):sel_hi(c), replacement)

function _backspace_op(_::Vector{Char}, c::EditCursor)
    is_selection(c) && return EditOp(sel_lo(c):sel_hi(c), "")
    h = c.head
    return h == 0 ? EditOp(0:0, "") : EditOp((h - 1):h, "")
end

function _delete_op(chars::Vector{Char}, c::EditCursor)
    is_selection(c) && return EditOp(sel_lo(c):sel_hi(c), "")
    h = c.head
    return h == length(chars) ? EditOp(h:h, "") : EditOp(h:(h + 1), "")
end

function _word_back_op(chars::Vector{Char}, c::EditCursor)
    is_selection(c) && return EditOp(sel_lo(c):sel_hi(c), "")
    return EditOp(prev_word_offset(chars, c.head):c.head, "")
end

function _word_forward_op(chars::Vector{Char}, c::EditCursor)
    is_selection(c) && return EditOp(sel_lo(c):sel_hi(c), "")
    return EditOp(c.head:next_word_offset(chars, c.head), "")
end

function _line_back_op(chars::Vector{Char}, c::EditCursor)
    is_selection(c) && return EditOp(sel_lo(c):sel_hi(c), "")
    line_start, _ = line_at_offset(chars, c.head)
    return EditOp(line_start:c.head, "")
end

function _line_forward_op(chars::Vector{Char}, c::EditCursor)
    is_selection(c) && return EditOp(sel_lo(c):sel_hi(c), "")
    _, line_end = line_at_offset(chars, c.head)
    return EditOp(c.head:line_end, "")
end

# Search for `pattern` in `chars`, starting *at or after* `from_offset`
# (0-based character offset). Returns `(lo, hi)` such that `chars[lo+1:hi]` equals
# `pattern`, or `nothing` if no further occurrence exists.
function _find_next_match(chars::Vector{Char}, pattern::Vector{Char}, from_offset::Int)
    n = length(chars)
    m = length(pattern)
    (m == 0 || m > n) && return nothing
    lo = max(from_offset, 0)
    @inbounds while lo <= n - m
        match = true
        for k in 1:m
            if chars[lo + k] != pattern[k]
                match = false
                break
            end
        end
        match && return (lo, lo + m)
        lo += 1
    end
    return nothing
end

# Symmetric backward search: returns the last occurrence whose `hi <= up_to_offset`.
function _find_prev_match(chars::Vector{Char}, pattern::Vector{Char}, up_to_offset::Int)
    m = length(pattern)
    m == 0 && return nothing
    lo = up_to_offset - m
    @inbounds while lo >= 0
        match = true
        for k in 1:m
            if chars[lo + k] != pattern[k]
                match = false
                break
            end
        end
        match && return (lo, lo + m)
        lo -= 1
    end
    return nothing
end

# Concatenated text of every selection, in cursor order, joined by newlines.
# Returns "" when no cursor has a selection (so callers can no-op cleanly).
function _selection_text(chars::Vector{Char}, cursors::Vector{EditCursor})
    buf = IOBuffer()
    first = true
    for c in cursors
        is_selection(c) || continue
        first || print(buf, '\n')
        first = false
        for ch in view(chars, (sel_lo(c) + 1):sel_hi(c))
            print(buf, ch)
        end
    end
    return String(take!(buf))
end

################################################################################
# Cursor movement
################################################################################

function move_cursor(c::EditCursor, chars::Vector{Char}, dir::Int; word::Bool, extend::Bool)
    if !extend && is_selection(c) && !word
        return EditCursor(dir < 0 ? sel_lo(c) : sel_hi(c))
    end
    new_head = if word
        dir < 0 ? prev_word_offset(chars, c.head) : next_word_offset(chars, c.head)
    else
        clamp(c.head + dir, 0, length(chars))
    end
    return extend ? EditCursor(c.anchor, new_head) : EditCursor(new_head)
end

function move_cursor_vertical(
        c::EditCursor, dir::Int;
        anchors::Vector{Point2f}, line_idx::Vector{Int}, n_lines::Int, extend::Bool,
    )
    head_line = line_idx[c.head + 1]
    target_line = clamp(head_line + dir, 1, n_lines)
    target_line == head_line && return c
    target_x = anchors[c.head + 1][1]
    best_off = c.head
    best_dist = Inf32
    for off in 0:(length(anchors) - 1)
        if line_idx[off + 1] == target_line
            d = abs(anchors[off + 1][1] - target_x)
            if d < best_dist
                best_dist = Float32(d)
                best_off = off
            end
        end
    end
    return extend ? EditCursor(c.anchor, best_off) : EditCursor(best_off)
end

# Convert a pixel-space point (relative to the text block's anchor — already
# in the same coordinate system as the entries of `anchors`) into the nearest
# character offset.
function offset_from_pixel_point(
        pt::Point2f, anchors::Vector{Point2f}, line_idx::Vector{Int},
    )
    # Line first (closest y), then closest x within the line.
    best_line = 1
    best_dy = Inf32
    seen_lines = Set{Int}()
    for off in 0:(length(anchors) - 1)
        line = line_idx[off + 1]
        line in seen_lines && continue
        push!(seen_lines, line)
        dy = abs(anchors[off + 1][2] - pt[2])
        if dy < best_dy
            best_dy = Float32(dy)
            best_line = line
        end
    end
    best_off = 0
    best_dx = Inf32
    for off in 0:(length(anchors) - 1)
        if line_idx[off + 1] == best_line
            d = abs(anchors[off + 1][1] - pt[1])
            if d < best_dx
                best_dx = Float32(d)
                best_off = off
            end
        end
    end
    return best_off
end

################################################################################
# Recipe `plot!`
################################################################################

function plot!(plot::EditableText)
    text_plot = text!(
        plot, plot.position; text = plot.text,
        color = plot.color, font = plot.font, fonts = plot.fonts,
        fontsize = plot.fontsize, align = plot.align,
        lineheight = plot.lineheight,
        space = plot.space, markerspace = :pixel,
        visible = plot.visible, inspectable = false,
    )
    register_markerspace_positions!(text_plot, Point2f)

    # The block's projected pixel position. `text!` always renders one block
    # per position vector, so `only` matches that invariant — it errors if the
    # text plot is ever set up with more than one position.
    block_pos_obs = lift(mps -> Point2f(only(mps)), text_plot.markerspace_positions)

    chars_obs = lift(collect, plot.text)

    anchors_obs = lift(
        text_plot.glyph_origins, text_plot.glyph_extents,
        text_plot.glyph_scales, text_plot.selected_font, plot.fontsize, plot.lineheight, plot.align,
    ) do origins, extents, scales, font, fontsize, lh, align
        # `plot.text` is the upstream input that drives `glyph_origins`, so by
        # the time this lift fires the text observable is already up to date.
        # We read it directly (rather than listing it as a dep) to avoid a
        # second redundant fire per text change.
        text = plot.text[]
        trailing_newline = !isempty(text) && last(text) == '\n'
        return cursor_anchor_positions(
            origins, extents, scales, font,
            Float32(fontsize), Float32(lh), align, trailing_newline,
        )
    end

    line_idx_obs = lift(cursor_anchor_lines, chars_obs)
    n_lines_obs = lift(li -> isempty(li) ? 1 : maximum(li), line_idx_obs)

    # ── Selection rectangles ─────────────────────────────────────────────────
    # `cursors` and `anchors_obs` live in different compute graphs (ours vs.
    # the inner text plot's), so an edit fires this lift twice — once before
    # the text-plot graph has caught up, once after. Clamping head/anchor to
    # the current anchor range absorbs the transient mismatch; the second fire
    # produces the final, correct rectangles.
    selection_rects_obs = lift(plot.cursors, anchors_obs, line_idx_obs, block_pos_obs) do cursors, m, li, bp
        rects = Rect2f[]
        n = length(m.anchors) - 1
        for c in cursors
            cc = EditCursor(clamp(c.anchor, 0, n), clamp(c.head, 0, n))
            is_selection(cc) || continue
            for r in selection_rects_for_range(sel_lo(cc), sel_hi(cc), m.anchors, li, m.ascender, m.descender, m.line_h)
                push!(rects, Rect2f(minimum(r) + bp, widths(r)))
            end
        end
        return rects
    end

    selection_plot = poly!(
        plot, selection_rects_obs;
        color = plot.selection_color, strokewidth = 0,
        # Hide selections when the editor isn't focused — matches typical
        # text-input UX where the highlight disappears on click-away.
        visible = plot.focused,
        space = :pixel, transformation = :nothing, inspectable = false,
    )
    # The selection rects need to render *behind* the text. Plot order in
    # `plot.plots` is rendering order, and the text plot was created first
    # above, so move the poly to the front of the list.
    deleteat!(plot.plots, findfirst(==(selection_plot), plot.plots))
    pushfirst!(plot.plots, selection_plot)

    # ── Cursor caret(s) ──────────────────────────────────────────────────────
    # Each caret is a vertical segment spanning descender..ascender. See
    # `selection_rects_obs` above for the clamp rationale.
    cursor_segments_obs = lift(plot.cursors, anchors_obs, block_pos_obs) do cursors, m, bp
        segs = Point2f[]
        n = length(m.anchors) - 1
        for c in cursors
            head = clamp(c.head, 0, n)
            p = m.anchors[head + 1] + bp
            push!(segs, p + Point2f(0, m.descender))
            push!(segs, p + Point2f(0, m.ascender))
        end
        return segs
    end

    # Cursor blink: simple binary on/off driven by render ticks. `last_edit_time`
    # gets reset on focus and on every edit, so the caret is always solid when
    # the cursor first appears or after the user types — never half-faded mid-cycle.
    last_edit_time = Observable(0.0)
    cursor_visible_obs = Observable(true; ignore_equal_values = true)

    parent = parent_scene(plot)
    push!(
        plot.deregister_callbacks, on(events(parent).tick) do tick
            cursor_visible_obs[] = if !plot.focused[]
                false
            else
                period = plot.blink_period[]
                elapsed = tick.time - last_edit_time[]
                isinf(period) || mod(elapsed, period) < period / 2
            end
            return nothing
        end
    )
    push!(
        plot.deregister_callbacks, on(plot.focused) do f
            if f
                last_edit_time[] = events(parent).tick[].time
            end
            return nothing
        end
    )

    linesegments!(
        plot, cursor_segments_obs;
        color = plot.cursor_color, linewidth = plot.cursor_width,
        visible = cursor_visible_obs,
        space = :pixel, transformation = :nothing, inspectable = false,
    )

    # ── Event handling ───────────────────────────────────────────────────────
    attach_editabletext_events!(plot, parent, text_plot, chars_obs, anchors_obs, line_idx_obs, n_lines_obs, block_pos_obs, last_edit_time)

    return plot
end

################################################################################
# Event handlers
################################################################################

# Helper: bump `last_edit_time` to the current tick time so the caret is solid
# again after editing.
function _bump_edit_time!(parent::Scene, last_edit_time::Observable{Float64})
    last_edit_time[] = events(parent).tick[].time
    return
end

# Push a new (text, cursors) pair. We can't bundle the two updates into a
# single observable notification: the text plot's glyph data lives in its own
# compute graph, and propagation across graphs goes through observable
# notifications whose ordering relative to our `cursors` listener isn't
# guaranteed. The lifts on `cursors`/`anchors` therefore clamp head/anchor
# offsets defensively to absorb a transient stale combination.
function _commit_edit!(plot::EditableText, new_text::String, new_cursors::Vector{EditCursor}, parent::Scene, last_edit_time)
    plot.cursors[] = new_cursors
    plot.arg1 = new_text
    _bump_edit_time!(parent, last_edit_time)
    return
end

function attach_editabletext_events!(
        plot::EditableText, parent::Scene, text_plot,
        chars_obs, anchors_obs, line_idx_obs, n_lines_obs, block_pos_obs, last_edit_time,
    )

    # Track click count + timing for double/triple click. We can't reuse the
    # `addmouseevents!` state machine for two reasons: it stops at double-click
    # (no triple), and it runs at priority 1 while we need priority 60 to set
    # focus before sibling EditableText listeners place a cursor.
    click_state = Ref((count = 0, time = 0.0, pos = Point2f(0)))
    drag_anchor = Ref{Union{Nothing, Int}}(nothing)

    function _mouse_to_offset(state_data::Point2f)
        # `state_data` is the scene-relative pixel mouse position. Subtract the
        # block's projected pixel anchor to get a position relative to the
        # cursor anchor list, then snap to the nearest offset.
        anchors = anchors_obs[].anchors
        line_idx = line_idx_obs[]
        local_pt = state_data - block_pos_obs[]
        return offset_from_pixel_point(local_pt, anchors, line_idx)
    end

    push!(
        plot.deregister_callbacks, on(events(parent).mousebutton, priority = 60) do event
            event.button == Mouse.left || return Consume(false)

            if event.action == Mouse.press
                mpos = mouseposition_px(parent)
                if plot.manage_focus[]
                    # Auto-focus on clicks within the text bbox; auto-defocus
                    # on clicks outside.
                    if !is_click_inside_text(text_plot, plot, mpos)
                        if plot.focused[]
                            plot.focused[] = false
                        end
                        return Consume(false)
                    end
                else
                    # Parent owns focus. Only place a cursor if we're actually
                    # focused right now; otherwise leave the click for the parent.
                    plot.focused[] || return Consume(false)
                end

                offset = _mouse_to_offset(Point2f(mpos))

                # Multi-click handling
                now = events(parent).tick[].time
                ctrl_or_cmd = ispressed(parent, Keyboard.left_super | Keyboard.right_super) ||
                    ispressed(parent, Keyboard.left_control | Keyboard.right_control)

                prev = click_state[]
                same_spot = norm(Point2f(mpos) - prev.pos) < 4
                within_time = (now - prev.time) < 0.4
                new_count = (same_spot && within_time) ? prev.count + 1 : 1
                click_state[] = (count = new_count, time = now, pos = Point2f(mpos))

                chars = chars_obs[]
                plot.focused[] = true

                # `new_selection` is what this click would produce on its own;
                # `ctrl_or_cmd` then decides whether it replaces the existing
                # cursors or extends them (multi-cursor / multi-selection).
                new_selection = if new_count == 3
                    lo, hi = line_at_offset(chars, offset)
                    EditCursor(lo, hi)
                elseif new_count == 2
                    lo, hi = word_at_offset(chars, offset)
                    EditCursor(lo, hi)
                else
                    EditCursor(offset)
                end
                cursors = ctrl_or_cmd ? vcat(plot.cursors[], [new_selection]) : EditCursor[new_selection]
                plot.cursors[] = merge_cursors(cursors)

                # On single click we set up a drag anchor so subsequent motion
                # extends the selection.
                drag_anchor[] = new_count == 1 ? offset : nothing
                _bump_edit_time!(parent, last_edit_time)
                # Consume only when *we* own focus management — that's the case
                # where there's no parent waiting to react to the click. When the
                # parent owns focus (Textbox), we must not consume so other
                # widgets at the same priority (e.g. another EditableText that
                # wants to defocus itself) still see the press.
                return plot.manage_focus[] ? Consume(true) : Consume(false)

            elseif event.action == Mouse.release
                drag_anchor[] = nothing
                return Consume(false)
            end
            return Consume(false)
        end
    )

    push!(
        plot.deregister_callbacks, on(events(parent).mouseposition, priority = 60) do _
            anchor = drag_anchor[]
            anchor === nothing && return Consume(false)
            Mouse.left in events(parent).mousebuttonstate || return Consume(false)
            mpos = mouseposition_px(parent)
            head = _mouse_to_offset(Point2f(mpos))
            cursors = plot.cursors[]
            # Only rewrite the last cursor (the one created by the press) so prior
            # multi-cursors stay intact. Skip if its head hasn't moved — mouseposition
            # fires per pixel of motion so this saves a lot of redundant lift work.
            last_cursor = cursors[end]
            last_cursor.anchor == anchor && last_cursor.head == head && return Consume(true)
            new_cursors = merge_cursors(vcat(cursors[1:(end - 1)], [EditCursor(anchor, head)]))
            plot.cursors[] = new_cursors
            _bump_edit_time!(parent, last_edit_time)
            return Consume(true)
        end
    )

    # Unicode character input — type a character.
    push!(
        plot.deregister_callbacks, on(events(parent).unicode_input, priority = 60) do char
            plot.focused[] || return Consume(false)
            char == '\0' && return Consume(false)
            plot.input_filter[](char) || return Consume(true)  # filtered out, but consume so other listeners don't double-handle
            new_text, new_cursors = apply_edits(plot.text[], plot.cursors[], c -> _replace_op(c, string(char)))
            _commit_edit!(plot, new_text, new_cursors, parent, last_edit_time)
            return Consume(true)
        end
    )

    # Keyboard.
    push!(
        plot.deregister_callbacks, on(events(parent).keyboardbutton, priority = 60) do event
            plot.focused[] || return Consume(false)
            event.action == Keyboard.release && return Consume(false)

            key = event.key
            kbstate = events(parent).keyboardstate
            shift = (Keyboard.left_shift in kbstate) || (Keyboard.right_shift in kbstate)
            alt = (Keyboard.left_alt in kbstate) || (Keyboard.right_alt in kbstate)
            cmd = (Keyboard.left_super in kbstate) || (Keyboard.right_super in kbstate) ||
                (Keyboard.left_control in kbstate) || (Keyboard.right_control in kbstate)

            chars = chars_obs[]
            text = plot.text[]
            cursors = plot.cursors[]

            # Run an EditOp builder against `text` / `cursors`, push the result.
            commit_op!(op_for) = begin
                new_text, new_cursors = apply_edits(text, cursors, c -> op_for(chars, c))
                _commit_edit!(plot, new_text, new_cursors, parent, last_edit_time)
            end
            # Move every cursor through `move` and store the result.
            commit_move!(move) = begin
                plot.cursors[] = merge_cursors([move(c) for c in cursors])
                _bump_edit_time!(parent, last_edit_time)
            end

            if key == Keyboard.escape
                plot.focused[] = false
                return Consume(true)

            elseif key == Keyboard.left
                commit_move!(c -> move_cursor(c, chars, -1; word = alt, extend = shift))
                return Consume(true)

            elseif key == Keyboard.right
                commit_move!(c -> move_cursor(c, chars, +1; word = alt, extend = shift))
                return Consume(true)

            elseif key == Keyboard.up || key == Keyboard.down
                anchors = anchors_obs[].anchors
                li = line_idx_obs[]
                n_lines = n_lines_obs[]
                dir = key == Keyboard.up ? -1 : +1
                commit_move!(c -> move_cursor_vertical(c, dir; anchors = anchors, line_idx = li, n_lines = n_lines, extend = shift))
                return Consume(true)

            elseif key == Keyboard.backspace
                commit_op!(cmd ? _line_back_op : alt ? _word_back_op : _backspace_op)
                return Consume(true)

            elseif key == Keyboard.delete
                commit_op!(cmd ? _line_forward_op : alt ? _word_forward_op : _delete_op)
                return Consume(true)

            elseif key == Keyboard.enter || key == Keyboard.kp_enter
                multiline = plot.multiline[]
                do_newline = multiline ? !cmd : shift
                do_submit = multiline ? cmd : !shift
                do_newline && commit_op!((_, c) -> _replace_op(c, "\n"))
                if do_submit
                    cb = plot.on_submit[]
                    cb === nothing || cb(plot.text[])
                end
                return Consume(true)

            elseif key == Keyboard.a && cmd
                # Select-all
                n = length(chars)
                plot.cursors[] = [EditCursor(0, n)]
                _bump_edit_time!(parent, last_edit_time)
                return Consume(true)

            elseif key == Keyboard.c && cmd
                content = _selection_text(chars, cursors)
                isempty(content) || clipboard(content)
                return Consume(true)

            elseif key == Keyboard.x && cmd
                content = _selection_text(chars, cursors)
                isempty(content) && return Consume(true)
                clipboard(content)
                commit_op!((_, c) -> _replace_op(c, ""))
                return Consume(true)

            elseif key == Keyboard.v && cmd
                content = try
                    String(clipboard())
                catch err
                    @warn "Accessing the clipboard failed: $err"
                    return Consume(true)
                end
                # Run the same per-char filter as typed input so e.g. a single-line
                # textbox strips newlines from a multi-line paste.
                filtered = String(filter(plot.input_filter[], collect(content)))
                isempty(filtered) && return Consume(true)
                commit_op!((_, c) -> _replace_op(c, filtered))
                return Consume(true)

            elseif key == Keyboard.d && cmd
                # Cmd+D: select next occurrence of the most recent cursor's text;
                # Cmd+Shift+D: select previous. If the most recent cursor has no
                # selection, the first press expands it to the word at the caret
                # (matching the common "select word, then keep adding next match"
                # pattern from VS Code / Sublime).
                last_c = isempty(cursors) ? EditCursor(0) : cursors[end]
                if !is_selection(last_c)
                    lo, hi = word_at_offset(chars, last_c.head)
                    lo == hi && return Consume(true)
                    plot.cursors[] = merge_cursors(vcat(cursors[1:(end - 1)], [EditCursor(lo, hi)]))
                    _bump_edit_time!(parent, last_edit_time)
                    return Consume(true)
                end
                pattern = chars[(sel_lo(last_c) + 1):sel_hi(last_c)]
                found = if shift
                    _find_prev_match(chars, pattern, sel_lo(cursors[1]))
                else
                    _find_next_match(chars, pattern, sel_hi(cursors[end]))
                end
                found === nothing && return Consume(true)
                lo, hi = found
                plot.cursors[] = merge_cursors(vcat(cursors, [EditCursor(lo, hi)]))
                _bump_edit_time!(parent, last_edit_time)
                return Consume(true)
            end

            return Consume(false)
        end
    )
    return
end

# Whether a pixel-space point clicks within the text's string boundingbox.
# Used to decide focus-on-click vs defocus-on-click-outside.
function is_click_inside_text(text_plot, plot, mpos)
    # Best-effort: use `markerspace_positions` and pad by half the font size
    # so an empty editor still receives clicks at its anchor point.
    bbs = try
        fast_string_boundingboxes(text_plot)
    catch
        nothing
    end
    bp = Point2f(only(text_plot.markerspace_positions[]))
    pad = Float32(plot.fontsize[]) * 0.5f0
    if bbs === nothing || isempty(bbs)
        # Empty text — accept clicks within a small box at the anchor.
        rect = Rect2f(bp - Point2f(pad), Vec2f(2pad, plot.fontsize[]))
        return Point2f(mpos[1], mpos[2]) in rect
    end
    bb = bbs[1]
    rect_min = Point2f(minimum(bb)[1], minimum(bb)[2]) + bp - Point2f(pad)
    rect_w = Vec2f(widths(bb)[1] + 2pad, widths(bb)[2] + 2pad)
    return Point2f(mpos[1], mpos[2]) in Rect2f(rect_min, rect_w)
end
