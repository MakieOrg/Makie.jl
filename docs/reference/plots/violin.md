# violin

{{doc violin}}

### Examples

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide


xs = rand(1:3, 1000)
ys = randn(1000)

violin(xs, ys)
```
\end{examplefigure}

\begin{examplefigure}{}
```julia
using Makie, CairoMakie
CairoMakie.activate!() # hide


fig = Figure()
xs = vcat([fill(i, i * 1000) for i in 1:4]...)
ys = vcat(randn(6000), randn(4000) * 2)
for (i, scale) in enumerate([:area, :count, :width])
    ax = Axis(fig[i, 1])
    violin!(ax, xs, ys; scale, show_median=true)
    Makie.xlims!(0.2, 4.8)
    ax.title = "scale=:$(scale)"
end
fig
```
\end{examplefigure}

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide


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


N = 1000
xs = rand(1:3, N)
dodge = rand(1:2, N)
side = rand([:left, :right], N)
color = @. ifelse(side === :left, :orange, :teal)
ys = map(side) do s
    return s === :left ? randn() : rand()
end

violin(xs, ys, dodge = dodge, side = side, color = color)
```
\end{examplefigure}

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide


N = 1000
xs = rand(1:3, N)
side = rand([:left, :right], N)
color = map(xs, side) do x, s
    colors = s === :left ? [:red, :orange, :yellow] : [:blue, :teal, :cyan]
    return colors[x]
end
ys = map(side) do s
    return s === :left ? randn() : rand()
end

violin(xs, ys, side = side, color = color)
```
\end{examplefigure}

#### Using statistical weights

\begin{examplefigure}{}
```julia
using CairoMakie, Distributions
CairoMakie.activate!() # hide


N = 100_000
x = rand(1:3, N)
y = rand(Uniform(-1, 5), N)

w = pdf.(Normal(), x .- y)

fig = Figure()

violin(fig[1,1], x, y)
violin(fig[1,2], x, y, weights = w)

fig
```
\end{examplefigure}
