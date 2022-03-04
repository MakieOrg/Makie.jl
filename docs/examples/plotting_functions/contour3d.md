# contour3d

{{doc contour3d}}

### Examples

\begin{examplefigure}{}
```julia
using GLMakie
GLMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure()
Axis3(f[1, 1], aspect=(0.5,0.5,1), perspectiveness=0.75)

H(x,y) = Hermitian([0 x-y*1im; x+y*1im 0])
xs = ys = LinRange(-0.5, 0.5, 100)
zs = [eigvals!(H(x,y)) for x in xs, y in ys]

contour3d!(xs, ys, getindex.(zs, 1), linewidth=2, color=:blue2)
contour3d!(xs, ys, getindex.(zs, 2), linewidth=2, color=:red2)

f
```
\end{examplefigure}

Omitting the `xs` and `ys` results in the indices of `zs` being used. We can also set arbitrary contour-levels using `levels`:

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure()
Axis3(f[1, 1], aspect=(0.5,0.5,1), perspectiveness=0.75)

H(x,y) = Hermitian([0 x-y*1im; x+y*1im 0])
xs = ys = LinRange(-0.5, 0.5, 100)
zs = [eigvals!(H(x,y)) for x in xs, y in ys]

contour3d!(getindex.(zs, 1), levels=-.475:0.05:-.025, linewidth=2, color=:blue2)
contour3d!(getindex.(zs, 2), levels=.025:0.05:.475,   linewidth=2, color=:red2)

f
```
\end{examplefigure}