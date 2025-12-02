# Button

```@example button
using GLMakie
GLMakie.activate!() # hide

fig = Figure()

ax = Axis(fig[1, 1])
fig[2, 1] = buttongrid = GridLayout(tellwidth = false)

counts = Observable([1, 4, 3, 7, 2])

buttonlabels = [lift(x -> "Count: $(x[i])", counts) for i in 1:5]

buttons = buttongrid[1, 1:5] = [Button(fig, label = l) for l in buttonlabels]

for i in 1:5
    on(buttons[i].clicks) do n
        counts[][i] += 1
        notify(counts)
    end
end

barplot!(counts, color = cgrad(:Spectral)[LinRange(0, 1, 5)])
ylims!(ax, 0, 20)

fig
nothing # hide
```

```@setup button
using ..FakeInteraction

events = [
    Wait(0.5),
    Lazy() do fig
        MouseTo(relative_pos(buttons[1], (0.3, 0.3)))
    end,
    LeftClick(),
    Wait(0.2),
    LeftClick(),
    Wait(0.2),
    LeftClick(),
    Wait(0.4),
    Lazy() do fig
        MouseTo(relative_pos(buttons[4], (0.7, 0.2)))
    end,
    Wait(0.2),
    LeftClick(),
    Wait(0.2),
    LeftClick(),
    Wait(0.2),
    LeftClick(),
    Wait(0.5)
]

interaction_record(fig, "button_example.mp4", events)
```

```@raw html
<video autoplay loop muted playsinline src="./button_example.mp4" width="600"/>
```
## Attributes

```@attrdocs
Button
```