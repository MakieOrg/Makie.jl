# Textbox

The `Textbox` provides an editable text field with optional validation.

```@setup textbox
using GLMakie
GLMakie.activate!()
using ..FakeInteraction

fig = Figure(size = (600, 200))
tb = Textbox(fig[1, 1], width = 400, height = 60, fontsize = 20, placeholder = "Click to edit...")

evts = [
    MouseTo(Point2f(550, 20), 0.0),
    Wait(0.4),
    Lazy(_ -> MouseTo(relative_pos(tb, (0.4, 0.5)))),
    Wait(0.4),
    LeftClick(),
    Wait(0.3),
    TypeText("the quick brown fox", char_duration = 0.07),
    Wait(0.7),

    # Click after "brown" → backspace to "the quick fox"
    Lazy(_ -> MouseTo(textbox_offset_pos(tb, 15))),
    Wait(0.3),
    LeftClick(),
    Wait(0.3),
    KeyPress(Keyboard.backspace), KeyPress(Keyboard.backspace), KeyPress(Keyboard.backspace),
    KeyPress(Keyboard.backspace), KeyPress(Keyboard.backspace), KeyPress(Keyboard.backspace),
    Wait(0.7),

    # Drag-select "quick" → replace with "slow"
    Lazy(_ -> MouseTo(textbox_offset_pos(tb, 4))),
    Wait(0.3),
    LeftDown(),
    Lazy(_ -> MouseTo(textbox_offset_pos(tb, 9), 0.5)),
    LeftUp(),
    Wait(0.5),
    TypeText("slow", char_duration = 0.07),
    Wait(0.8),

    # Triple-click → select line
    Lazy(_ -> MouseTo(textbox_offset_pos(tb, 4))),
    Wait(0.3),
    LeftClick(),
    LeftClick(),
    LeftClick(),
    Wait(0.7),

    # Click at end → Shift+Enter for newline → type second line
    Lazy(_ -> MouseTo(textbox_offset_pos(tb, 12))),
    Wait(0.3),
    LeftClick(),
    Wait(0.4),
    KeyDown(Keyboard.left_shift),
    KeyPress(Keyboard.enter),
    KeyUp(Keyboard.left_shift),
    Wait(0.3),
    TypeText("the smart dog", char_duration = 0.07),
    Wait(0.7),

    # Click before "fox" → cmd+click before "dog" to add a second cursor
    Lazy(_ -> MouseTo(textbox_offset_pos(tb, 9))),
    Wait(0.3),
    LeftClick(),
    Wait(0.4),
    Lazy(_ -> MouseTo(textbox_offset_pos(tb, 23))),
    Wait(0.3),
    KeyDown(Keyboard.left_super),
    LeftClick(),
    KeyUp(Keyboard.left_super),
    Wait(0.5),

    # Type at both cursors simultaneously
    TypeText("happy ", char_duration = 0.07),
    Wait(1.4),
]

interaction_record(fig, "textbox_example.mp4", evts)
```

```@raw html
<video autoplay loop muted playsinline src="./textbox_example.mp4" width="600"/>
```

## Editing

- Drag to select; double-click for the word at the cursor; triple-click for the line.
- Hold ⌘ (or Ctrl) while clicking to add an extra cursor. ⌘+double-click and ⌘+triple-click add a word or line selection.
- Arrow keys move the caret; Shift extends the selection; ⌥ (Alt) moves by whole words.
- ⌥+Backspace / ⌘+Backspace delete the previous word / line; ⌥+Delete / ⌘+Delete are the forward equivalents.
- ⌘+A selects all. ⌘+C / ⌘+X / ⌘+V copy / cut / paste; paste is filtered through `restriction`.
- ⌘+D selects the next occurrence of the current selection; ⌘+Shift+D the previous one.
- Enter submits (subject to `validator`); Shift+Enter forces a newline; Escape defocuses.

## Validation

The `validator` attribute is used with `validate_textbox(string, validator)` to determine if the current string is valid. It can be a `Regex` that needs to match the complete string, or a `Function` taking a `String` as input and returning a `Bool`. If the validator is a type T (for example `Float64`), validation will be `tryparse(T, string)`. The textbox will not allow submitting the currently entered value if the validator doesn't pass.

```@figure

f = Figure()

tb = Textbox(f[2, 1], placeholder = "Enter a frequency",
    validator = Float64, tellwidth = false)

frequency = Observable(1.0)

on(tb.stored_string) do s
    frequency[] = parse(Float64, s)
end

xs = 0:0.01:10
sinecurve = @lift(sin.($frequency .* xs))

lines(f[1, 1], xs, sinecurve)

f
```

## Attributes

```@attrdocs
Textbox
```