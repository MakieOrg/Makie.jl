# tricontourf

{{doc tricontourf}}

## Examples

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide
using Random
Random.seed!(1234)

x = randn(50)
y = randn(50)
z = -sqrt.(x .^ 2 .+ y .^ 2) .+ 0.1 .* randn.()

Makie.tricontourf(x, y, z)
scatter!(x, y, color = z, strokewidth = 1, strokecolor = :black)
current_figure()
```
\end{examplefigure}

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide
using Random
Random.seed!(1234)

x = randn(200)
y = randn(200)
z = x .* y

Makie.tricontourf(x, y, z, colormap = :batlow)
scatter!(x, y, color = z, colormap = :batlow, strokewidth = 1, strokecolor = :black)
current_figure()
```
\end{examplefigure}

#### Relative mode

Sometimes it's beneficial to drop one part of the range of values, usually towards the outer boundary.
Rather than specifying the levels to include manually, you can set the `mode` attribute
to `:relative` and specify the levels from 0 to 1, relative to the current minimum and maximum value.

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide
using Random
Random.seed!(1234)

x = randn(50)
y = randn(50)
z = -sqrt.(x .^ 2 .+ y .^ 2) .+ 0.1 .* randn.()

Makie.tricontourf(x, y, z, mode = :relative, levels = 0.2:0.1:1)
scatter!(x, y, color = z, strokewidth = 1, strokecolor = :black)
current_figure()
```
\end{examplefigure}