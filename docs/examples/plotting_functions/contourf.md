# contourf

{{doc contourf}}

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
using DelimitedFiles
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

volcano = readdlm(Makie.assetpath("volcano.csv"), ',', Float64)

f = Figure()
Axis(f[1, 1])

co = contourf!(volcano, levels = 10)

Colorbar(f[1, 2], co)

f
```
\end{examplefigure}

\begin{examplefigure}{svg = true}
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

\begin{examplefigure}{svg = true}
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

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
using DelimitedFiles
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

volcano = readdlm(Makie.assetpath("volcano.csv"), ',', Float64)

f = Figure(resolution = (800, 400))

Axis(f[1, 1], title = "Relative mode, drop lowest 30%")
contourf!(volcano, levels = 0.3:0.1:1, mode = :relative)

Axis(f[1, 2], title = "Normal mode")
contourf!(volcano, levels = 10)

f
```
\end{examplefigure}
