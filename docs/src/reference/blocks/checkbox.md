# Checkbox

```@example checkbox
using GLMakie
using Random # hide
GLMakie.activate!() # hide


f = Figure()

gl = GridLayout(f[2, 1], tellwidth = false)
subgl = GridLayout(gl[1, 1])

cb1 = Checkbox(subgl[1, 1], checked = false)
cb2 = Checkbox(subgl[2, 1], checked = true)
cb3 = Checkbox(subgl[3, 1], checked = true)

Label(subgl[1, 2], "Dataset A", halign = :left)
Label(subgl[2, 2], "Dataset B", halign = :left)
Label(subgl[3, 2], "Dataset C", halign = :left)
rowgap!(subgl, 8)
colgap!(subgl, 8)

ax = Axis(f[1, 1])
  
Random.seed!(123) # hide
for cb in [cb1, cb2, cb3]
    lines!(ax, cumsum(randn(1000)), alpha = @lift($(cb.checked) ? 1.0 : 0.1))
end

f
nothing # hide
```

```@setup checkbox
using ..FakeInteraction

evts = [
    Wait(0.5),
    Lazy() do fig
        MouseTo(relative_pos(cb1, (0.7, 0.3)))
    end,
    Wait(0.2),
    LeftClick(),
    Wait(0.5),
    Lazy() do fig
        MouseTo(relative_pos(cb2, (0.5, 0.6)))
    end,
    Wait(0.2),
    LeftClick(),
    Wait(0.5),
    Lazy() do fig
        MouseTo(relative_pos(cb3, (0.4, 0.4)))
    end,
    Wait(0.2),
    LeftClick(),
    Wait(0.5),
    Lazy() do fig
        MouseTo(relative_pos(cb2, (0.6, 0.5)))
    end,
    Wait(0.2),
    LeftClick(),
    Wait(0.5),
    Lazy() do fig
        MouseTo(relative_pos(cb1, (0.3, 0.3)))
    end,
    Wait(0.2),
    LeftClick(),
    Wait(1.0),
]

interaction_record(f, "checkbox_example.mp4", evts)
```

```@raw html
<video autoplay loop muted playsinline src="./checkbox_example.mp4" width="600"/>
```

## Attributes

```@attrdocs
Checkbox
```