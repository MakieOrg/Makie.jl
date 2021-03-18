```@eval
using CairoMakie
CairoMakie.activate!()
```

# Toggle

A toggle with an attribute `active` that can either be true or false, to enable
or disable properties of an interactive plot.

```@example
using CairoMakie

fig = Figure(resolution = (1200, 900))

ax = Axis(fig[1, 1])

toggles = [Toggle(fig, active = ac) for ac in [true, false]]
labels = [Label(fig, lift(x -> x ? "active" : "inactive", t.active))
    for t in toggles]

fig[1, 2] = grid!(hcat(toggles, labels), tellheight = false)

fig
```
