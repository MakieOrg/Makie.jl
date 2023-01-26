# Predefined themes

Makie has a few predefined themes.
Here you can see the same example figure with these different themes applied.

~~~
<input id="hidecode" class="hidecode" type="checkbox">
~~~

```julia:demofigure
using CairoMakie
using Random

CairoMakie.activate!(type = "svg") # hide

function demofigure()
    Random.seed!(2)

    f = Figure()
    ax = Axis(f[1, 1],
        title = "measurements",
        xlabel = "time (s)",
        ylabel = "amplitude")

    labels = ["alpha", "beta", "gamma", "delta", "epsilon", "zeta"]
    for i in 1:6
        y = cumsum(randn(10)) .* (isodd(i) ? 1 : -1)
        lines!(y, label = labels[i])
        scatter!(y, label = labels[i])
    end

    Legend(f[1, 2], ax, "legend", merge = true)

    Axis3(f[1, 3],
        viewmode = :stretch,
        zlabeloffset = 40,
        title = "sinusoid")

    s = surface!(0:0.5:10, 0:0.5:10, (x, y) -> sqrt(x * y) + sin(1.5x))

    Colorbar(f[1, 4], s, label = "intensity")

    ax = Axis(f[2, 1:2],
        title = "different species",
        xlabel = "height (m)",
        ylabel = "density",)
    for i in 1:6
        y = randn(200) .+ 2i
        density!(y)
    end
    tightlimits!(ax, Bottom())
    xlims!(ax, -1, 15)

    Axis(f[2, 3:4],
        title = "stock performance",
        xticks = (1:6, labels),
        xlabel = "company",
        ylabel = "gain (\$)",
        xticklabelrotation = pi/6)
    for i in 1:6
        data = randn(1)
        barplot!([i], data)
        rangebars!([i], data .- 0.2, data .+ 0.2)
    end

    f
end
```

~~~
<label for="hidecode" class="hidecode"></label>
~~~

## Default theme

\begin{examplefigure}{}
```julia
demofigure()
```
\end{examplefigure}

## theme_ggplot2

\begin{examplefigure}{}
```julia
with_theme(demofigure, theme_ggplot2())
```
\end{examplefigure}

## theme_minimal

\begin{examplefigure}{}
```julia
with_theme(demofigure, theme_minimal())
```
\end{examplefigure}

## theme_black

\begin{examplefigure}{}
```julia
with_theme(demofigure, theme_black())
```
\end{examplefigure}

## theme_light

\begin{examplefigure}{}
```julia
with_theme(demofigure, theme_light())
```
\end{examplefigure}

## theme_dark

\begin{examplefigure}{}
```julia
with_theme(demofigure, theme_dark())
```
\end{examplefigure}

## theme_pretty

\begin{examplefigure}{}
```julia
with_theme(demofigure, theme_pretty())
```
\end{examplefigure}

For Cycling available options with this theme go to [theming](https://makie.juliaplots.org/stable/documentation/theming/index.html#theming).
