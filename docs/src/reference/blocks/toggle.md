# Toggle

A toggle with an attribute `active` that can either be true or false, to enable
or disable properties of an interactive plot.

```@example toggle
using GLMakie
GLMakie.activate!() # hide

fig = Figure()

ax = Axis(fig[1, 1], limits = (0, 600, -2, 2))
hidexdecorations!(ax)

t = Observable(0.0)
points = lift(t) do t
    x = range(t-1, t+1, length = 500)
    @. sin(x) * sin(2x) * sin(4x) * sin(23x)
end

lines!(ax, points, color = (1:500) .^ 2, linewidth = 2, colormap = [(:blue, 0.0), :blue])

gl = GridLayout(fig[2, 1], tellwidth = false)
Label(gl[1, 1], "Live Update")
toggle = Toggle(gl[1, 2], active = false)

on(fig.scene.events.tick) do tick
    toggle.active[] || return
    t[] += tick.delta_time
end

fig
nothing # hide
```

```@setup toggle
using ..FakeInteraction

events = [
    Wait(0.5),
    Lazy() do fig
        MouseTo(relative_pos(toggle, (0.7, 0.3)))
    end,
    Wait(0.2),
    LeftClick(),
    Wait(2.0),
    LeftClick(),
    Wait(1.5),
    LeftClick(),
    Wait(2.0),
]

interaction_record(fig, "toggle_example.mp4", events)
```

```@raw html
<video autoplay loop muted playsinline src="./toggle_example.mp4" width="600"/>
```


## Attributes

```@attrdocs
Toggle
```