# lines

{{doc lines}}

## Examples

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

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
Makie.inline!(true) # hide

f = Figure()
Axis(f[1, 1])

xs = 0:0.01:10
ys = 0.5 .* sin.(xs)

for (i, linewidth) in enumerate([1, 2, 3])
    lines!(xs, ys .- i/6, linestyle = nothing)
    lines!(xs, ys .- i/6 .- 1, linestyle = :dash)
    lines!(xs, ys .- i/6 .- 2, linestyle = :dot)
    lines!(xs, ys .- i/6 .- 3, linestyle = :dashdot)
    lines!(xs, ys .- i/6 .- 4, linestyle = :dashdotdot)
    lines!(xs, ys .- i/6 .- 5, linestyle = [0.5, 1.0, 1.5, 2.5])
end

f
```
\end{examplefigure}