# qqplot and qqnorm

{{doc qqplot}}
{{doc qqnorm}}

### Examples

Test if `xs` and `ys` follow the same distribution.

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide


xs = randn(100)
ys = randn(100)

qqplot(xs, ys, qqline = :identity)
```
\end{examplefigure}

Test if `ys` is normally distributed.

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide


ys = 2 .* randn(100) .+ 3

qqnorm(ys, qqline = :fitrobust)
```
\end{examplefigure}
