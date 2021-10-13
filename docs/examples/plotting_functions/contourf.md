# contourf

{{doc contourf}}

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

xs = LinRange(0, 10, 100)
ys = LinRange(0, 10, 100)
zs = [cos(x) * sin(y) for x in xs, y in ys]

f = Figure()
Axis(f[1, 1])

co = contourf!(xs, ys, zs, levels = 10)

Colorbar(f[1, 2], co)

f
```
\end{examplefigure}

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

xs = LinRange(0, 10, 100)
ys = LinRange(0, 10, 100)
zs = [cos(x) * sin(y) for x in xs, y in ys]

f = Figure()
Axis(f[1, 1])

co = contourf!(xs, ys, zs, levels = -0.75:0.25:0.5,
    extendlow = :cyan, extendhigh = :magenta)

Colorbar(f[1, 2], co)

f
```
\end{examplefigure}

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

xs = LinRange(0, 10, 100)
ys = LinRange(0, 10, 100)
zs = [cos(x) * sin(y) for x in xs, y in ys]

f = Figure()
Axis(f[1, 1])

co = contourf!(xs, ys, zs,
    levels = -0.75:0.25:0.5,
    extendlow = :auto, extendhigh = :auto)

Colorbar(f[1, 2], co)

f
```
\end{examplefigure}

#### Relative mode

Sometimes it's beneficial to drop one part of the range of values, usually towards the outer boundary.
Rather than specifying the levels to include manually, you can set the `mode` attribute
to `:relative` and specify the levels from 0 to 1, relative to the current minimum and maximum value.

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide


using Makie.KernelDensity

k = kde([randn() + rand([0, 5]) for i in 1:10000, j in 1:2])

f = Figure(resolution = (800, 500))

Axis(f[1, 1], title = "Relative mode, drop lowest 10%")
contourf!(k, levels = 0.1:0.1:1, mode = :relative)

Axis(f[1, 2], title = "Normal mode")
contourf!(k, levels = 10)

f
```
\end{examplefigure}
