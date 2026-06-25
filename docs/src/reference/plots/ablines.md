# ablines

```@shortdocs; canonical=false
ablines
```

```@figure
ablines(0, 1)
ablines!([1, 2, 3], [1, 1.5, 2], color = [:red, :orange, :pink], linestyle=:dash, linewidth=2)
current_figure()
```

## Non-identity axis scales

`ablines` defines `f(x) = slope * x + intercept` in data coordinates, so under a non-identity scale (such as `log10`) the line generally becomes a curve in the transformed space. It is drawn as a subdivided curve in that case.

```@figure
f = Figure(size = (600, 500))

ax = Axis(f[1, 1], title = "identity")
ablines!(ax, [0.0, 1.0, 2.0], [1.0, -0.5, 0.25], color = [:orange, :red, :purple], linewidth = 3)
limits!(ax, 0, 10, -2, 6)

ax = Axis(f[1, 2], xscale = log10, title = "log x")
ablines!(ax, 0.0, 0.002, color = :orange, linewidth = 3)
limits!(ax, 1, 1000, 0, 3)

ax = Axis(f[1, 3], yscale = log10, title = "log y, crosses zero")
ablines!(ax, -50.0, 50.0, color = :orange, linewidth = 3)
limits!(ax, 1, 4, 1, 200)

ax = Axis(f[2, 1], xscale = log10, yscale = log10, title = "log-log, zero intercept")
ablines!(ax, [0.0, 0.0, 0.0], [1.0, 3.0, 0.3], color = [:orange, :red, :purple], linewidth = [2, 4, 6])
limits!(ax, 1, 100, 0.1, 1000)

ax = Axis(f[2, 2], xscale = log10, yscale = log10, title = "log-log, nonzero intercept")
ablines!(ax, [1.0, 10.0, 100.0], 1.0, color = [:orange, :red, :purple], linewidth = 3)
limits!(ax, 1, 100, 1, 1000)

ax = Axis(f[2, 3], xscale = sqrt, title = "sqrt x")
ablines!(ax, 0.0, 1.0, color = :orange, linewidth = 3)
limits!(ax, 0, 100, 0, 100)

f
```

## Attributes

```@attrdocs
ABLines
```
