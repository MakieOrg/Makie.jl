# Textbox

The `Textbox` supports entry of a simple, single-line string, with optional validation logic.

```@figure

f = Figure()
Textbox(f[1, 1], placeholder = "Enter a string...")
Textbox(f[2, 1], width = 300)

f
```

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