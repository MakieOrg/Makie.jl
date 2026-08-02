# ParamForm

`ParamForm` builds a labelled, themed form of input widgets from a `NamedTuple`
specification. Each field maps to a `(default, constraint)` pair; the constraint
selects the widget type and validation rule. All validated values are always
available as a live `NamedTuple` from the block's compute graph — no read-back
step needed.

```@example paramform
using GLMakie
GLMakie.activate!() # hide

fig = Figure(size = (500, 300))

pf = ParamForm(fig[1, 1], (
    iterations = (50,    Between(1, 200)),
    method     = ("LBFGS", OneOf(["LBFGS", "Newton", "GradDesc"])),
    tolerance  = (1e-6,  nothing),
    verbose    = (false, nothing),
); title = "Solver settings")

Label(fig[2, 1], lift(vals -> "tolerance = $(vals.tolerance)",
                      pf.graph[:values]); tellwidth = false)

fig
nothing # hide
```

## Constraint types

| Constraint | Widget | Description |
|:-----------|:-------|:------------|
| `Between(lo, hi)` | `Slider` | Numeric range — value must satisfy `lo ≤ v ≤ hi` |
| `OneOf(options)` | `Menu` | Fixed option set — value must be one of `options` |
| `FilePath(; extension)` | `Textbox` + browse button | File path, optionally filtered by extension |
| `nothing` | `Toggle` (Bool) or `Textbox` | No constraint; widget chosen by field type |

## Reading values

`pf.graph[:values][]` returns the current validated `NamedTuple`. Wire it to
other observables with `on` or `lift`:

```julia
on(pf.graph[:values]) do vals
    run_solver(vals.method; tol = vals.tolerance, iters = vals.iterations)
end
```

## Inside a Modal

`ParamForm` composes naturally with [`Modal`](@ref) for settings dialogs:

```julia
modal = Modal(fig; title = "Settings")
pf    = ParamForm(modal[1, 1], (alpha = (0.5, Between(0.0, 1.0)),))
on(pf.graph[:values]) do vals; update_plot!(vals) end
on(_ -> open!(modal), settings_button.clicks)
```

## Clearing a form

[`clear!`](@ref) removes all blocks from a `GridLayout` recursively, which is
useful when rebuilding a form in place:

```julia
clear!(pf.layout)  # or delete!(pf) to remove the whole block
```

## Attributes

```@attrdocs
ParamForm
```
