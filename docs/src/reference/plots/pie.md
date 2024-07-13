# pie

```@shortdocs; canonical=false
pie
```


## Examples

```@figure
data   = [36, 12, 68, 5, 42, 27]
colors = [:yellow, :orange, :red, :blue, :purple, :green]

f, ax, plt = pie(data,
                 color = colors,
                 radius = 4,
                 inner_radius = 2,
                 strokecolor = :white,
                 strokewidth = 5,
                 axis = (autolimitaspect = 1, )
                )

f
```


```@figure
f, ax, plt = pie([π/2, 2π/3, π/4],
                normalize=false,
                offset = π/2,
                color = [:orange, :purple, :green],
                axis = (autolimitaspect = 1,)
                )

f
```

```@figure
fig = Makie.Figure()
ax = Makie.Axis(fig[1, 1]; autolimitaspect=1)

vs = 0:6 |> Vector
vs_ = vs ./ sum(vs) .* (3/2*π)
cs = Makie.wong_colors()
Δx = [1, 1, 1, -1, -1, -1, 1] ./ 10
Δy = [1, 1, 1, 1, 1, -1, -1] ./ 10
Δr1 = [0, 0, 0.2, 0, 0.2, 0, 0]
Δr2 = [0, 0, 0.2, 0, 0, 0, 0]

Makie.pie!(ax, vs; color=cs)
Makie.pie!(ax, 3 .+ Δx, 0, vs; color=cs)
Makie.pie!(ax, 0, 3 .+ Δy, vs; color=cs)
Makie.pie!(ax, 3 .+ Δx, 3 .+ Δy, vs; color=cs)

Makie.pie!(ax, 7, 0, vs; color=cs, offset_radius=Δr1)
Makie.pie!(ax, 7, 3, vs; color=cs, offset_radius=0.2)
Makie.pie!(ax, 10 .+ Δx, 3 .+ Δy, vs; color=cs, offset_radius=0.2)
Makie.pie!(ax, 10, 0, vs_; color=cs, offset_radius=Δr1, normalize=false, offset=π/2)

Makie.pie!(ax, Makie.Point2(0.5, -3), vs_; color=cs, offset_radius=Δr2, normalize=false, offset=π/2)
Makie.pie!(ax, Makie.Point2.(3.5, -3 .+ Δy), vs_; color=cs, offset_radius=Δr2, normalize=false, offset=π/2)
Makie.pie!(ax, Makie.Point2.(6.5 .+ Δx, -3), vs_; color=cs, offset_radius=Δr2, normalize=false, offset=π/2)
Makie.pie!(ax, Makie.Point2.(9.5 .+ Δx, -3 .+ Δy), vs_; color=cs, offset_radius=Δr2, normalize=false, offset=π/2)

Makie.pie!(ax, 0.5, -6, vs_; inner_radius=0.2, color=cs, offset_radius=0.2, normalize=false, offset=π/2)
Makie.pie!(ax, 3.5, -6 .+ Δy, vs_; inner_radius=0.2, color=cs, offset_radius=0.2, normalize=false, offset=π/2)
Makie.pie!(ax, 6.5 .+ Δx, -6, vs_; inner_radius=0.2, color=cs, offset_radius=0.2, normalize=false, offset=π/2)
Makie.pie!(ax, 9.5 .+ Δx, -6 .+ Δy, vs_; inner_radius=0.2, color=cs, offset_radius=0.2, normalize=false, offset=π/2)

fig
```

## Attributes

```@attrdocs
Pie
```
