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
