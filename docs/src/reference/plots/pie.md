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

vs = 0:6
cs = Makie.wong_colors()
Δx = [1, 1, 1, -1, -1, -1, 1] ./ 10
Δy = [1, 1, 1, 1, 1, -1, -1] ./ 10
Δr1 = [0, 0, 0.2, 0, 0.2, 0, 0]
Δr2 = [0, 0, 0.2, 0, 0, 0, 0]

Makie.pie!(ax, vs; color=cs, x=0, y=0)
Makie.pie!(ax, vs; color=cs, x=3 .+ Δx, y=0)
Makie.pie!(ax, vs; color=cs, x=0, y=3 .+ Δy)
Makie.pie!(ax, vs; color=cs, x=3 .+ Δx, y=3 .+ Δy)

Makie.pie!(ax, vs; color=cs, x=7, y=0, r=Δr1)
Makie.pie!(ax, vs; color=cs, x=7, y=3, r=0.2)
Makie.pie!(ax, vs; color=cs, x=10 .+ Δx, y=3 .+ Δy, r=0.2)
Makie.pie!(ax, vs ./ sum(vs) .* (3/2*π); color=cs, x=10, y=0, r=Δr1, normalize=false, offset=π/2)

Makie.pie!(ax, vs ./ sum(vs) .* (3/2*π); color=cs, x=0.5, y=-3, r=Δr2, normalize=false, offset=π/2)
Makie.pie!(ax, vs ./ sum(vs) .* (3/2*π); color=cs, x=3.5, y=-3 .+ Δy, r=Δr2, normalize=false, offset=π/2)
Makie.pie!(ax, vs ./ sum(vs) .* (3/2*π); color=cs, x=6.5 .+ Δx, y=-3, r=Δr2, normalize=false, offset=π/2)
Makie.pie!(ax, vs ./ sum(vs) .* (3/2*π); color=cs, x=9.5 .+ Δx, y=-3 .+ Δy, r=Δr2, normalize=false, offset=π/2)

Makie.pie!(ax, vs ./ sum(vs) .* (3/2*π); inner_radius=0.2, color=cs, x=0.5, y=-6, r=0.2, normalize=false, offset=π/2)
Makie.pie!(ax, vs ./ sum(vs) .* (3/2*π); inner_radius=0.2, color=cs, x=3.5, y=-6 .+ Δy, r=0.2, normalize=false, offset=π/2)
Makie.pie!(ax, vs ./ sum(vs) .* (3/2*π); inner_radius=0.2, color=cs, x=6.5 .+ Δx, y=-6, r=0.2, normalize=false, offset=π/2)
Makie.pie!(ax, vs ./ sum(vs) .* (3/2*π); inner_radius=0.2, color=cs, x=9.5 .+ Δx, y=-6 .+ Δy, r=0.2, normalize=false, offset=π/2)

fig
```

## Attributes

```@attrdocs
Pie
```
