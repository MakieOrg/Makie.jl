using Makie: EditCursor, EditableText, editabletext!
using InteractiveUtils: clipboard

# Helpers to drive the recipe via synthesized events.
function _press_release(events, key)
    events.keyboardbutton[] = Makie.KeyEvent(key, Keyboard.press)
    events.keyboardbutton[] = Makie.KeyEvent(key, Keyboard.release)
    return
end

function _hold(f, events, mod)
    push!(events.keyboardstate, mod)
    return try
        f()
    finally
        delete!(events.keyboardstate, mod)
    end
end

function _make_editor(text = ""; cursors = [EditCursor(0)], focused = true, fontsize = 22, position = Point2f(20, 50))
    f = Figure(size = (400, 100))
    sc = Scene(f.scene; camera = campixel!)
    et = editabletext!(sc, text; position = position, fontsize = fontsize, focused = focused, cursors = cursors)
    Makie.update_state_before_display!(f)
    return f, et
end

@testset "EditableText" begin
    @testset "Word and line offsets" begin
        chars = collect("hello world foo")
        @test Makie.next_word_offset(chars, 0) == 5
        @test Makie.next_word_offset(chars, 5) == 11
        @test Makie.next_word_offset(chars, 14) == 15
        @test Makie.prev_word_offset(chars, 15) == 12
        @test Makie.prev_word_offset(chars, 12) == 6
        @test Makie.prev_word_offset(chars, 6) == 0
        @test Makie.word_at_offset(chars, 8) == (6, 11)
        @test Makie.word_at_offset(chars, 5) == (0, 5)  # right at edge, prefers right side
        @test Makie.word_at_offset(chars, 11) == (6, 11)  # right at edge, prefers left

        ml = collect("abc\ndef\nxyz")
        @test Makie.line_at_offset(ml, 0) == (0, 3)
        @test Makie.line_at_offset(ml, 3) == (0, 3)
        @test Makie.line_at_offset(ml, 4) == (4, 7)
        @test Makie.line_at_offset(ml, 8) == (8, 11)
    end

    @testset "Cursor merging" begin
        @test Makie.merge_cursors(EditCursor[]) == []
        # Touching ranges merge
        merged = Makie.merge_cursors([EditCursor(0, 3), EditCursor(3, 5)])
        @test length(merged) == 1
        @test Makie.sel_lo(merged[1]) == 0
        @test Makie.sel_hi(merged[1]) == 5
        # Non-overlapping stay separate, sorted by lo
        merged = Makie.merge_cursors([EditCursor(7), EditCursor(2)])
        @test length(merged) == 2
        @test merged[1].head == 2
        @test merged[2].head == 7
    end

    @testset "apply_edits — single cursor" begin
        # Insert
        new_text, new_cursors = Makie.apply_edits("hello", [EditCursor(2)], c -> Makie.EditOp(2:2, "X"))
        @test new_text == "heXllo"
        @test new_cursors == [EditCursor(3)]
        # Delete (selection)
        new_text, new_cursors = Makie.apply_edits("hello", [EditCursor(1, 4)], c -> Makie.EditOp(1:4, ""))
        @test new_text == "ho"
        @test new_cursors == [EditCursor(1)]
    end

    @testset "apply_edits — multi-cursor" begin
        # Insert at two cursors → text grows, cursors track properly
        new_text, new_cursors = Makie.apply_edits("hello world", [EditCursor(0), EditCursor(6)], c -> Makie.EditOp(Makie.sel_lo(c):Makie.sel_hi(c), "X"))
        @test new_text == "Xhello Xworld"
        @test [c.head for c in new_cursors] == [1, 8]

        # Overlapping selections collapse — the second op's insert is dropped
        # so we don't double-insert "X" in the overlap, and both cursors land
        # on the same final position.
        new_text, new_cursors = Makie.apply_edits(
            "abcdefgh",
            [EditCursor(0, 5), EditCursor(3, 7)],
            c -> Makie.EditOp(Makie.sel_lo(c):Makie.sel_hi(c), "X"),
        )
        @test new_text == "Xh"
        @test new_cursors == [EditCursor(1)]   # merge_cursors collapses duplicates
    end

    @testset "Type, backspace, delete" begin
        f, et = _make_editor("Hi"; cursors = [EditCursor(0)])
        ev = events(f)
        ev.unicode_input[] = 'a'
        @test et.text[] == "aHi"
        @test et.cursors[] == [EditCursor(1)]
        ev.unicode_input[] = 'b'
        ev.unicode_input[] = 'c'
        @test et.text[] == "abcHi"
        _press_release(ev, Keyboard.backspace)
        @test et.text[] == "abHi"
        _press_release(ev, Keyboard.delete)
        @test et.text[] == "abi"
    end

    @testset "Arrow movement" begin
        f, et = _make_editor("hello world"; cursors = [EditCursor(0)])
        ev = events(f)
        _press_release(ev, Keyboard.right)
        @test et.cursors[] == [EditCursor(1)]
        _hold(ev, Keyboard.left_alt) do
            _press_release(ev, Keyboard.right)
        end
        @test et.cursors[] == [EditCursor(5)]  # end of "hello"
        _hold(ev, Keyboard.left_shift) do
            _press_release(ev, Keyboard.right)
        end
        @test et.cursors[] == [EditCursor(5, 6)]  # extended into the space
        _hold(ev, Keyboard.left_alt) do
            _hold(ev, Keyboard.left_shift) do
                _press_release(ev, Keyboard.right)
            end
        end
        @test et.cursors[] == [EditCursor(5, 11)]  # extended to end of "world"
    end

    @testset "Vertical movement" begin
        f, et = _make_editor("abcd\nefgh"; cursors = [EditCursor(7)])  # in line 2
        ev = events(f)
        _press_release(ev, Keyboard.up)
        # Should land near offset 2 or 3 (line 1 closest x)
        @test 1 <= et.cursors[][1].head <= 3
        _press_release(ev, Keyboard.down)
        # Back near offset 7 (line 2)
        @test 6 <= et.cursors[][1].head <= 8
    end

    @testset "Word and line delete" begin
        f, et = _make_editor("hello world foo"; cursors = [EditCursor(15)])
        ev = events(f)
        _hold(ev, Keyboard.left_alt) do
            _press_release(ev, Keyboard.backspace)
        end
        @test et.text[] == "hello world "
        _hold(ev, Keyboard.left_super) do
            _press_release(ev, Keyboard.backspace)
        end
        @test et.text[] == ""
        @test et.cursors[] == [EditCursor(0)]
    end

    @testset "Newline insertion via enter" begin
        f, et = _make_editor("abc"; cursors = [EditCursor(3)])
        ev = events(f)
        _press_release(ev, Keyboard.enter)
        @test et.text[] == "abc\n"
        ev.unicode_input[] = 'd'
        @test et.text[] == "abc\nd"
        @test et.cursors[][1].head == 5
    end

    @testset "Click positions cursor" begin
        f, et = _make_editor("hello world"; cursors = [EditCursor(0)], focused = false)
        ev = events(f)
        # Click somewhere in the middle of the text — exact glyph positions depend on font metrics
        # so we just check focus + that the cursor moved into the string.
        ev.mouseposition[] = (60.0, 50.0)
        ev.mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.press)
        ev.mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.release)
        @test et.focused[] == true
        @test 0 < et.cursors[][1].head <= 11
    end

    @testset "Double-click selects word, triple-click selects line" begin
        f, et = _make_editor("hello world"; cursors = [EditCursor(0)], focused = false)
        ev = events(f)
        ev.mouseposition[] = (90.0, 50.0)  # somewhere inside "world"
        # double-click within the click-detection window
        for i in 1:2
            ev.tick[] = Makie.Tick(Makie.RegularRenderTick, i, 0.1 * i, 0.1)
            ev.mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.press)
            ev.mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.release)
        end
        c = et.cursors[][1]
        @test (Makie.sel_lo(c), Makie.sel_hi(c)) == (6, 11)  # "world"
        # triple-click — selects whole line (= all content here)
        ev.tick[] = Makie.Tick(Makie.RegularRenderTick, 3, 0.35, 0.1)
        ev.mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.press)
        ev.mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.release)
        c = et.cursors[][1]
        @test (Makie.sel_lo(c), Makie.sel_hi(c)) == (0, 11)
    end

    @testset "Cmd + double/triple click extends multi-cursor" begin
        f, et = _make_editor("hello world foo bar"; cursors = [EditCursor(0)], focused = false)
        ev = events(f)

        # Plain click at offset 0 — single cursor, no selection.
        ev.mouseposition[] = (22.0, 50.0)
        ev.tick[] = Makie.Tick(Makie.RegularRenderTick, 1, 0.1, 0.1)
        ev.mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.press)
        ev.mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.release)
        @test length(et.cursors[]) == 1

        # Cmd+double-click on a word elsewhere — should ADD the word selection
        # to the existing cursors, not replace them.
        ev.mouseposition[] = (90.0, 50.0)  # somewhere inside "world"
        _hold(ev, Keyboard.left_super) do
            for i in 2:3
                ev.tick[] = Makie.Tick(Makie.RegularRenderTick, i, 0.1 * i, 0.1)
                ev.mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.press)
                ev.mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.release)
            end
        end
        cursors = et.cursors[]
        @test length(cursors) == 2
        @test (Makie.sel_lo(cursors[2]), Makie.sel_hi(cursors[2])) == (6, 11)  # "world"

        # Cmd+triple-click adds a line selection on top.
        _hold(ev, Keyboard.left_super) do
            ev.tick[] = Makie.Tick(Makie.RegularRenderTick, 4, 0.4, 0.1)
            ev.mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.press)
            ev.mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.release)
        end
        # Adding a line selection (whole "hello world foo bar") swallows the
        # earlier word selection at offsets (6, 11), so cursors collapse to a
        # single (0, 19) range via `merge_cursors`.
        @test length(et.cursors[]) == 1
        @test (Makie.sel_lo(et.cursors[][1]), Makie.sel_hi(et.cursors[][1])) == (0, 19)
    end

    @testset "Selection rectangles hidden when defocused" begin
        f, et = _make_editor("hello world"; cursors = [EditCursor(0, 5)], focused = true)
        Makie.update_state_before_display!(f)
        poly_plot = only(p for p in et.plots if p isa Poly)
        @test poly_plot.visible[] == true
        et.focused[] = false
        @test poly_plot.visible[] == false
        # Re-focus → reappears
        et.focused[] = true
        @test poly_plot.visible[] == true
    end

    @testset "External text shrink with active selection" begin
        f, et = _make_editor("hello world"; cursors = [EditCursor(0, 11)], focused = true)
        et.arg1 = ""
        Makie.update_state_before_display!(f)
        rects = only(p for p in et.plots if p isa Poly).arg1[]
        @test rects == Rect2f[]
    end

    @testset "Drag extends selection" begin
        f, et = _make_editor("hello world"; cursors = [EditCursor(0)], focused = false)
        ev = events(f)
        ev.mouseposition[] = (90.0, 50.0)
        ev.mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.press)
        anchor_offset = et.cursors[][1].head
        ev.mouseposition[] = (40.0, 50.0)  # drag left
        c = et.cursors[][1]
        @test c.anchor == anchor_offset
        @test c.head < anchor_offset
        ev.mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.release)
    end

    @testset "Multi-cursor typing" begin
        f, et = _make_editor("hello world"; cursors = [EditCursor(0), EditCursor(6)])
        ev = events(f)
        ev.unicode_input[] = 'X'
        @test et.text[] == "Xhello Xworld"
        @test [c.head for c in et.cursors[]] == [1, 8]
    end

    @testset "Multi-line selection rectangles" begin
        # Check that a selection spanning three lines produces three rectangles.
        f = Figure(size = (300, 200))
        sc = Scene(f.scene; camera = campixel!)
        et = editabletext!(
            sc, "abc\ndef\nghi"; position = Point2f(20, 150), fontsize = 22,
            focused = true, cursors = [EditCursor(1, 10)],
        )
        Makie.update_state_before_display!(f)
        # Find the poly sub-plot by type; arg1 is its Vector{Rect2f} input.
        rects = only(p for p in et.plots if p isa Poly).arg1[]
        @test length(rects) == 3
    end

    @testset "Escape defocuses" begin
        f, et = _make_editor("abc"; cursors = [EditCursor(0)])
        ev = events(f)
        @test et.focused[] == true
        _press_release(ev, Keyboard.escape)
        @test et.focused[] == false
        # Subsequent keys are ignored
        ev.unicode_input[] = 'q'
        @test et.text[] == "abc"
    end

    @testset "Submit / multiline modes" begin
        # multiline = true: Enter inserts \n, Cmd+Enter submits.
        let
            submitted = Ref{Union{Nothing, String}}(nothing)
            f, et = _make_editor("abc"; cursors = [EditCursor(3)])
            et.multiline[] = true
            et.on_submit[] = text -> (submitted[] = text)
            ev = events(f)
            _press_release(ev, Keyboard.enter)
            @test et.text[] == "abc\n"
            @test submitted[] === nothing
            _hold(ev, Keyboard.left_super) do
                _press_release(ev, Keyboard.enter)
            end
            @test submitted[] == "abc\n"
        end
        # multiline = false: Enter submits, Shift+Enter inserts \n.
        let
            submitted = Ref{Union{Nothing, String}}(nothing)
            f, et = _make_editor("abc"; cursors = [EditCursor(3)])
            et.multiline[] = false
            et.on_submit[] = text -> (submitted[] = text)
            ev = events(f)
            _press_release(ev, Keyboard.enter)
            @test et.text[] == "abc"  # no newline inserted
            @test submitted[] == "abc"
            _hold(ev, Keyboard.left_shift) do
                _press_release(ev, Keyboard.enter)
            end
            @test et.text[] == "abc\n"
        end
    end

    @testset "input_filter rejects characters" begin
        f, et = _make_editor(""; cursors = [EditCursor(0)])
        et.input_filter[] = c -> isdigit(c)
        ev = events(f)
        ev.unicode_input[] = 'a'
        @test et.text[] == ""
        ev.unicode_input[] = '7'
        @test et.text[] == "7"
        # Newlines bypass the filter (Enter in multiline mode)
        _press_release(ev, Keyboard.enter)
        @test et.text[] == "7\n"
    end

    @testset "Copy / cut / paste" begin
        # Round-trip via the system clipboard; on a CI box this still works
        # because Julia's `clipboard(text)` and `clipboard()` use the same
        # in-process fallback.
        f, et = _make_editor("hello world"; cursors = [EditCursor(0, 5)])
        ev = events(f)

        # Cmd+C copies the selection to the clipboard, leaving text/cursors alone.
        _hold(ev, Keyboard.left_super) do
            _press_release(ev, Keyboard.c)
        end
        @test et.text[] == "hello world"
        @test et.cursors[] == [EditCursor(0, 5)]
        @test clipboard() == "hello"

        # Cmd+X cuts: clipboard gets the selection, text loses it.
        _hold(ev, Keyboard.left_super) do
            _press_release(ev, Keyboard.x)
        end
        @test et.text[] == " world"
        @test clipboard() == "hello"

        # Cmd+V pastes at every cursor.
        clipboard("XX")
        et.cursors[] = [EditCursor(0), EditCursor(3)]
        _hold(ev, Keyboard.left_super) do
            _press_release(ev, Keyboard.v)
        end
        @test et.text[] == "XX woXXrld"

        # Paste filters chars through `input_filter` (single-line semantics).
        clipboard("a\nb\nc")
        f2, et2 = _make_editor(""; cursors = [EditCursor(0)])
        et2.input_filter[] = c -> c != '\n'
        _hold(events(f2), Keyboard.left_super) do
            _press_release(events(f2), Keyboard.v)
        end
        @test et2.text[] == "abc"
    end

    @testset "Cmd+D selects next occurrence; Cmd+Shift+D selects previous" begin
        f, et = _make_editor("hello world hello world"; cursors = [EditCursor(2)], focused = true)
        ev = events(f)

        # First Cmd+D expands the bare cursor to the word it sits in.
        _hold(ev, Keyboard.left_super) do
            _press_release(ev, Keyboard.d)
        end
        @test length(et.cursors[]) == 1
        @test (Makie.sel_lo(et.cursors[][1]), Makie.sel_hi(et.cursors[][1])) == (0, 5)

        # Next Cmd+D adds the next occurrence of "hello" as a new cursor.
        _hold(ev, Keyboard.left_super) do
            _press_release(ev, Keyboard.d)
        end
        @test length(et.cursors[]) == 2
        @test (Makie.sel_lo(et.cursors[][end]), Makie.sel_hi(et.cursors[][end])) == (12, 17)

        # No more "hello" occurrences forward — Cmd+D is a no-op.
        _hold(ev, Keyboard.left_super) do
            _press_release(ev, Keyboard.d)
        end
        @test length(et.cursors[]) == 2

        # Cmd+Shift+D from a "world" position finds the previous "world".
        et.cursors[] = [EditCursor(18, 23)]   # the second "world"
        _hold(ev, Keyboard.left_super) do
            _hold(ev, Keyboard.left_shift) do
                _press_release(ev, Keyboard.d)
            end
        end
        @test length(et.cursors[]) == 2
        offsets = Set((Makie.sel_lo(c), Makie.sel_hi(c)) for c in et.cursors[])
        @test (6, 11) in offsets
        @test (18, 23) in offsets
    end

    @testset "Cursor blink driven by render ticks" begin
        f, et = _make_editor("abc"; cursors = [EditCursor(1)])
        ev = events(f)
        # Just before the post-edit pause expires — cursor should still be solid (alpha 1)
        ev.tick[] = Makie.Tick(Makie.RegularRenderTick, 1, 0.1, 0.05)
        # After the pause, in the "off" half of the blink cycle — alpha goes to 0
        # We can't easily inspect alpha (it's a closure-local Observable) but we
        # can at least verify ticking doesn't crash and the cursor segments are
        # always there (positions are independent of alpha).
        ev.tick[] = Makie.Tick(Makie.RegularRenderTick, 2, 1.0, 0.9)
        ev.tick[] = Makie.Tick(Makie.RegularRenderTick, 3, 1.5, 0.5)
        @test length(only(p for p in et.plots if p isa LineSegments).arg1[]) == 2  # one cursor → 2 endpoints
    end

    @testset "Caret visibility follows focus without ticks" begin
        f, et = _make_editor("abc"; cursors = [EditCursor(1)], focused = false)
        caret = only(p for p in et.plots if p isa LineSegments)
        @test caret.visible[] == false
        et.focused[] = true
        @test caret.visible[] == true
        et.focused[] = false
        @test caret.visible[] == false
    end
end
