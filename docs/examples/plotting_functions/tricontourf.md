# tricontourf

{{doc tricontourf}}

## Examples

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide

using Random
Random.seed!(1234)

x = randn(50)
y = randn(50)
z = -sqrt.(x .^ 2 .+ y .^ 2) .+ 0.1 .* randn.()

f, ax, tr = tricontourf(x, y, z)
scatter!(x, y, color = z, strokewidth = 1, strokecolor = :black)
Colorbar(f[1, 2], tr)
f
```
\end{examplefigure}

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide

using Random
Random.seed!(1234)

x = randn(200)
y = randn(200)
z = x .* y

f, ax, tr = tricontourf(x, y, z, colormap = :batlow)
scatter!(x, y, color = z, colormap = :batlow, strokewidth = 1, strokecolor = :black)
Colorbar(f[1, 2], tr)
f
```
\end{examplefigure}

#### Triangulation modes

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide

using Random
Random.seed!(123)

n = 20
angles = range(0, 2pi, length = n+1)[1:end-1]
x = [cos.(angles); 2 .* cos.(angles .+ pi/n)]
y = [sin.(angles); 2 .* sin.(angles .+ pi/n)]
z = (x .- 0.5).^2 + (y .- 0.5).^2 .+ 0.5.*randn.()

triangulation_inner = reduce(hcat, map(i -> [0, 1, n] .+ i, 1:n))
triangulation_outer = reduce(hcat, map(i -> [n-1, n, 0] .+ i, 1:n))
triangulation = hcat(triangulation_inner, triangulation_outer)

f, ax, _ = tricontourf(x, y, z, triangulation = triangulation,
    axis = (; aspect = 1, title = "Manual triangulation"))
scatter!(x, y, color = z, strokewidth = 1, strokecolor = :black)

tricontourf(f[1, 2], x, y, z, triangulation = Makie.DelaunayTriangulation(),
    axis = (; aspect = 1, title = "Delaunay triangulation"))
scatter!(x, y, color = z, strokewidth = 1, strokecolor = :black)

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
CairoMakie.activate!() # hide

using Random
Random.seed!(1234)

x = randn(50)
y = randn(50)
z = -sqrt.(x .^ 2 .+ y .^ 2) .+ 0.1 .* randn.()

f, ax, tr = tricontourf(x, y, z, mode = :relative, levels = 0.2:0.1:1)
scatter!(x, y, color = z, strokewidth = 1, strokecolor = :black)
Colorbar(f[1, 2], tr)
f
```
\end{examplefigure}
