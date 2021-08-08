# violin

{{doc violin}}

### Examples

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

xs = rand(1:3, 1000)
ys = randn(1000)

violin(xs, ys)
```
\end{examplefigure}

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

xs = rand(1:3, 1000)
ys = map(xs) do x
    return x == 1 ? randn() : x == 2 ? 0.5 * randn() : 5 * rand()
end

violin(xs, ys, datalimits = extrema)
```
\end{examplefigure}

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

N = 1000
xs = rand(1:3, N)
dodge = rand(1:2, N)
side = rand([:left, :right], N)
color = @. ifelse(side == :left, :orange, :teal)
ys = map(side) do s
    return s == :left ? randn() : rand()
end

violin(xs, ys, dodge = dodge, side = side, color = color)
```
\end{examplefigure}

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

N = 1000
xs = rand(1:3, N)
side = rand([:left, :right], N)
color = map(xs, side) do x, s
    colors = s == :left ? [:red, :orange, :yellow] : [:blue, :teal, :cyan]
    return colors[x]
end
ys = map(side) do s
    return s == :left ? randn() : rand()
end

violin(xs, ys, side = side, color = color)
```
\end{examplefigure}
