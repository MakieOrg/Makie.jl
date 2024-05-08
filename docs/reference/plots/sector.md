# sector

{{doc sector}}

## Examples

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide

sector(Point2f(0), 1, 0.0, π)
```
\end{examplefigure}

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide
f = Figure() 
Axis(f[1, 1], aspect = DataAspect())

for i in 1:10
    sector!(Point2f(i, 0), 0.4, 0, 2π*i/10, inner_radius = 0.2)
end

f
```
\end{examplefigure}

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide

f = Figure()
Axis(f[1, 1])

for i in 1:4
    radius = 1/(i*2)
    left = 1/(i*2)
    right = (i*2-1)/(i*2)
    sector!(Point2f(left, 0), radius, 0, π)
    sector!(Point2f(right, 0), radius, 0, π)
end
for i in 3:4
    radius = 1/(i*(i-1)*2)
    left = (1/i) + 1/(i*(i-1)*2)
    right = ((i-1)/i) - 1/(i*(i-1)*2)
    sector!(Point2f(left, 0), radius, 0, π)
    sector!(Point2f(right, 0), radius, 0, π)
end

f
```
\end{examplefigure}
