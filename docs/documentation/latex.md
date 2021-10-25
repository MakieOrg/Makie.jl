# LaTeX

Makie can render LaTeX strings from the [LaTeXStrings.jl](https://github.com/stevengj/LaTeXStrings.jl) package using [MathTeXEngine.jl](https://github.com/Kolaru/MathTeXEngine.jl/).

This engine supports a subset of LaTeX's most used commands, which are rendered quickly enough for responsive use in GLMakie.

## Using L-strings

You can pass `LaTeXString` objects to almost any object with text labels. They are constructed using the `L` string macro prefix.
The whole string is interpreted as an equation if it doesn't contain an unescaped `$`.


```!
# hideall
using CairoMakie
```

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide

f = Figure(fontsize = 18)

Axis(f[1, 1],
    title = L"\frac{x + y}{\sin(k^2)}",
    xlabel = L"\sum_a^b{xy}",
    ylabel = L"\sqrt{\frac{a}{b}}"
)

f
```
\end{examplefigure}

You can also mix math-mode and text-mode.
For [string interpolation](https://docs.julialang.org/en/v1/manual/strings/#string-interpolation) use `%$`instead of `$`:

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide

f = Figure(fontsize = 18)
t = "text"
Axis(f[1,1], title=L"Some %$(t) and some math: $\frac{2\alpha+1}{y}$")

f
```
\end{examplefigure}


## Caveats

You can currently not change a text object which has been instantiated with a normal `String` input to use a `LaTeXString`. If you do this, the `LaTeXString` is converted to a `String` implicitly, losing its special properties. Instead it appears with `$` signs wrapped around.

Notice how the second axis loses its LaTeX title. You have to pass the L-string at axis construction.

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide

f = Figure(fontsize = 18)

Axis(f[1, 1], title = L"\frac{x + y}{\sin(k^2)}")
ax2 = Axis(f[1, 2])
ax2.title = L"\frac{x + y}{\sin(k^2)}"

f
```
\end{examplefigure}


For implicitly created axes, you can do this via the `axis` keyword argument.


\begin{examplefigure}{svg = true}
```julia
scatter(randn(50, 2), axis = (; title = L"\frac{x + y}{\sin(k^2)}"))
```
\end{examplefigure}
