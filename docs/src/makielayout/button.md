```@eval
using CairoMakie
CairoMakie.activate!()
```

# Button

```@example
using GLMakie
GLMakie.activate!() # hide
fig = Figure()

ax = Axis(fig[1, 1])
fig[2, 1] = buttongrid = GridLayout(tellwidth = false)

counts = Node([1, 4, 3, 7, 2])

buttonlabels = [@lift("Count: $($counts[i])") for i in 1:5]

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
```
