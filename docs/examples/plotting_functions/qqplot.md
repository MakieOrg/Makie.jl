# qqplot and qqnorm

{{doc qqplot}}
{{doc qqnorm}}

### Examples

Test if `xs` and `ys` follow the same distribution.

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

xs = randn(100)
ys = randn(100)

qqplot(xs, ys)
```
\end{examplefigure}

Test if `ys` is normally distributed.

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

ys = randn(100)

qqnorm(ys)
```
\end{examplefigure}
