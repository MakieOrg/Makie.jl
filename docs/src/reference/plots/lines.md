# lines

{{doc lines}}

## Examples

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide


f = Figure()
Axis(f[1, 1])

xs = 0:0.01:10
ys = 0.5 .* sin.(xs)

lines!(xs, ys)
lines!(xs, ys .- 1, linewidth = 5)
lines!(xs, ys .- 2, linewidth = 5, color = ys)
lines!(xs, ys .- 3, linestyle = :dash)

f
```
\end{examplefigure}

### Linestyles

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide


f = Figure()
Axis(f[1, 1])

xs = 0:0.01:10
ys = 0.5 .* sin.(xs)

for (i, lw) in enumerate([1, 2, 3])
    lines!(xs, ys .- i/6, linestyle = nothing, linewidth = lw)
    lines!(xs, ys .- i/6 .- 1, linestyle = :dash, linewidth = lw)
    lines!(xs, ys .- i/6 .- 2, linestyle = :dot, linewidth = lw)
    lines!(xs, ys .- i/6 .- 3, linestyle = :dashdot, linewidth = lw)
    lines!(xs, ys .- i/6 .- 4, linestyle = :dashdotdot, linewidth = lw)
    lines!(xs, ys .- i/6 .- 5, linestyle = Linestyle([0.5, 1.0, 1.5, 2.5]), linewidth = lw)
end

f
```
\end{examplefigure}

### Linecaps and Joinstyles

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide

f = Figure()
Axis(f[1, 1])

ps = 0.8 .* Point2f[(-0.2, -0.5), (0.5, -0.5), (0.5, 0.5), (-0.5, 0.5), (-0.5, -0.2)]

for i in 1:3, j in 1:3
    lines!(
        ps .+ Point2f(i, -j), linewidth = 20,
        linecap = (:butt, :square, :round)[i],
        joinstyle = (:miter, :bevel, :round)[j]
    )
    scatterlines!(ps .+ Point2f(i, -j), color = :gray)
end

f
```
\end{examplefigure}

### Dealing with outline artifacts in GLMakie

In GLMakie 3D line plots can generate outline artifacts depending on the order line segments are rendered in.
Currently there are a few ways to mitigate this problem, but they all come at a cost:
- `fxaa = true` will disable the native anti-aliasing of line segments and use fxaa instead. This results in less detailed lines.
- `transparency = true` will disable depth testing to a degree, resulting in all lines being rendered without artifacts. However with this lines will always have some level of transparency.
- `overdraw = true` will disable depth testing entirely (read and write) for the plot, removing artifacts. This will however change the z-order of line segments and allow plots rendered later to show up on top of the lines plot.

\begin{examplefigure}{}
```julia
using GLMakie
GLMakie.activate!() # hide

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
\end{examplefigure}