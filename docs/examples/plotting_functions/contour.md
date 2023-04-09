# contour

{{doc contour}}

### Examples

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide


f = Figure()
Axis(f[1, 1])

xs = LinRange(0, 10, 100)
ys = LinRange(0, 15, 100)
zs = [cos(x) * sin(y) for x in xs, y in ys]

contour!(xs, ys, zs)

f
```
\end{examplefigure}

Omitting the `xs` and `ys` results in the indices of `zs` being used. We can also set arbitrary contour-levels using `levels`

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide


f = Figure()
Axis(f[1, 1])

xs = LinRange(0, 10, 100)
ys = LinRange(0, 15, 100)
zs = [cos(x) * sin(y) for x in xs, y in ys]

contour!(zs,levels=-1:0.1:1)

f
```
\end{examplefigure}

One can also add labels and control label attributes such as `labelsize`, `labelcolor` or `labelfont`.

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide


himmelblau(x, y) = (x^2 + y - 11)^2 + (x + y^2 - 7)^2
x = y = range(-6, 6; length=100)
z = himmelblau.(x, y')

levels = 10.0.^range(0.3, 3.5; length=10)
colormap = Makie.sampler(:hsv, 100; scaling=Makie.Scaling(x -> x^(1 / 10), nothing))
f, ax, ct = contour(x, y, z; labels=true, levels, colormap)
f
```
\end{examplefigure}
