# lines

## Examples

### Dealing with outline artifacts in GLMakie

In GLMakie 3D line plots can generate outline artifacts depending on the order line segments are rendered in.
Currently there are a few ways to mitigate this problem, but they all come at a cost:
- `fxaa = true` will disable the native anti-aliasing of line segments and use fxaa instead. This results in less detailed lines.
- `transparency = true` will disable depth testing to a degree, resulting in all lines being rendered without artifacts. However with this lines will always have some level of transparency.
- `overdraw = true` will disable depth testing entirely (read and write) for the plot, removing artifacts. This will however change the z-order of line segments and allow plots rendered later to show up on top of the lines plot.

```@figure backend=GLMakie
ps = rand(Point3f, 500)
cs = rand(500)
f = Figure(size = (600, 650))
Label(f[1, 1], "base", tellwidth = false)
lines(f[2, 1], ps, color = cs, fxaa = false)
Label(f[1, 2], "fxaa = true", tellwidth = false)
lines(f[2, 2], ps, color = cs, fxaa = true)
Label(f[3, 1], "transparency = true", tellwidth = false)
lines(f[4, 1], ps, color = cs, transparency = true)
Label(f[3, 2], "overdraw = true", tellwidth = false)
lines(f[4, 2], ps, color = cs, overdraw = true)
f
```

## Attributes

### `linestyle`

```@figure
linestyles = [:solid, :dot, :dash, :dashdot, :dashdotdot]
gapstyles = [:normal, :dense, :loose, 10]
fig = Figure()
with_updates_suspended(fig.layout) do
    for (i, ls) in enumerate(linestyles)
        for (j, gs) in enumerate(gapstyles)
            title = gs === :normal ? repr(ls) : "\$((ls, gs))"
            ax = Axis(fig[i, j]; title, yautolimitmargin = (0.2, 0.2))
            hidedecorations!(ax)
            hidespines!(ax)
            linestyle = (ls, gs)
            for linewidth in 1:3
                lines!(ax, 1:10, fill(linewidth, 10); linestyle, linewidth)
            end
        end
    end
end
fig
```

```@figure
fig = Figure()
patterns = [
    [0, 1, 2],
    [0, 20, 22],
    [0, 2, 4, 12, 14],
    [0, 2, 4, 6, 8, 10, 20],
    [0, 1, 2, 4, 6, 9, 12],
    [0.0, 4.0, 6.0, 9.5],
]
ax = Axis(fig[1, 1], yautolimitmargin = (0.2, 0.2))
for (i, pattern) in enumerate(patterns)
    lines!(ax, [-i, -i], linestyle = Linestyle(pattern), linewidth = 4)
    text!(ax, (1.5, -i), text = "Linestyle(\$pattern)",
        align = (:center, :bottom), offset = (0, 10))
end
hidedecorations!(ax)
fig
```

### `joinstyle`

```@figure
fig = Figure()
ax = Axis(fig[1, 1], yautolimitmargin = (0.05, 0.15))
hidedecorations!(ax)

joinstyles = [:miter, :bevel, :round]
for (i, joinstyle) in enumerate(joinstyles)
    x = (1:3) .+ 5 * (i - 1)
    ys = [[0.5, 3.5, 0.5], [3, 5, 3], [5, 6, 5], [6.5, 7, 6.5]]
    for y in ys
        lines!(ax, x, y; linewidth = 15, joinstyle, color = :black)
    end
    text!(ax, x[2], ys[end][2], text = ":\$joinstyle",
        align = (:center, :bottom), offset = (0, 15), font = :bold)
end

text!(ax, 4.5, 4.5, text = "for angles\nbelow miter_limit,\n:miter == :bevel",
    align = (:center, :center))

fig
```

### `linecap`

```@figure
fig = Figure()
ax = Axis(fig[1, 1], yautolimitmargin = (0.2, 0.2), xautolimitmargin = (0.2, 0.2))
hidedecorations!(ax)

linecaps = [:butt, :square, :round]
for (i, linecap) in enumerate(linecaps)
    lines!(ax, [i, i]; color = :tomato, linewidth = 15, linecap)
    lines!(ax, [i, i]; color = :black, linewidth = 15, linecap = :butt)
    text!(1.5, i, text = ":\$linecap", font = :bold,
        align = (:center, :bottom), offset = (0, 15))
end
fig
```

### `color`

```@figure
fig = Figure()
ax = Axis(fig[1, 1], yautolimitmargin = (0.1, 0.1), xautolimitmargin = (0.1, 0.1))
hidedecorations!(ax)

lines!(ax, 1:9, iseven.(1:9) .- 0; color = :tomato)
lines!(ax, 1:9, iseven.(1:9) .- 1; color = (:tomato, 0.5))
lines!(ax, 1:9, iseven.(1:9) .- 2; color = 1:9)
lines!(ax, 1:9, iseven.(1:9) .- 3; color = 1:9, colormap = :plasma)
lines!(ax, 1:9, iseven.(1:9) .- 4; color = RGBf.(0, (0:8) ./ 8, 0))
fig
```

### `linewidth`

```@figure
fig = Figure()
ax = Axis(fig[1, 1], yautolimitmargin = (0.2, 0.2), xautolimitmargin = (0.1, 0.1))
hidedecorations!(ax)

for linewidth in 1:10
    lines!(ax, iseven.(1:9) .+ linewidth, 1:9; color = :black, linewidth)
    text!(ax, linewidth + 0.5, 9; text = "\$linewidth", font = :bold,
        align = (:center, :bottom), offset = (0, 15))
end
fig
```
