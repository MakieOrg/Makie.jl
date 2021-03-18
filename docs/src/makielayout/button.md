```@eval
using CairoMakie
CairoMakie.activate!()
```

# Button

```@example
using CairoMakie

fig = Figure(resolution = (1200, 900))

Axis(fig[1, 1])
fig[2, 1] = buttongrid = GridLayout(tellwidth = false)

buttons = buttongrid[1, 1:5] = [Button(fig, label = "Button $i") for i in 1:5]

for button in buttons
    on(button.clicks) do n
        println("$(button.label[]) was clicked $n times.")
    end
end

fig
```
