# arc

{{doc arc}}

## Examples

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide

arc(Point2f(0), 1, -π, π)
```
\end{examplefigure}

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide
f = Figure() 
Axis(f[1, 1])

for i in 1:10
    arc!(Point2f(0, i), i, -π, π)
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
    arc!(Point2f(left, 0), radius, 0, π)
    arc!(Point2f(right, 0), radius, 0, π)
end
for i in 3:4
    radius = 1/(i*(i-1)*2)
    left = (1/i) + 1/(i*(i-1)*2)
    right = ((i-1)/i) - 1/(i*(i-1)*2)
    arc!(Point2f(left, 0), radius, 0, π)
    arc!(Point2f(right, 0), radius, 0, π)
end

f
```
\end{examplefigure}
