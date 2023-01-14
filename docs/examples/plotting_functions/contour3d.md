# contour3d

{{doc contour3d}}

### Examples

\begin{examplefigure}{}
```julia
using GLMakie
GLMakie.activate!() # hide


f = Figure()
Axis3(f[1, 1], aspect=(0.5,0.5,1), perspectiveness=0.75)

xs = ys = LinRange(-0.5, 0.5, 100)
zs = [sqrt(x^2+y^2) for x in xs, y in ys]

contour3d!(xs, ys, -zs, linewidth=2, color=:blue2)
contour3d!(xs, ys, +zs, linewidth=2, color=:red2)

f
```
\end{examplefigure}

Omitting the `xs` and `ys` results in the indices of `zs` being used. We can also set arbitrary contour-levels using `levels`:

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide


f = Figure()
Axis3(f[1, 1], aspect=(0.5,0.5,1), perspectiveness=0.75)

xs = ys = LinRange(-0.5, 0.5, 100)
zs = [sqrt(x^2+y^2) for x in xs, y in ys]

contour3d!(-zs, levels=-(.025:0.05:.475), linewidth=2, color=:blue2)
contour3d!(+zs, levels=  .025:0.05:.475,  linewidth=2, color=:red2)

f
```
\end{examplefigure}
