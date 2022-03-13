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

## theme_makie

### scatter and lines
\begin{examplefigure}{}

```julia
with_theme(theme_makie()) do
    x = range(0, 20; length=7)
    fig = Figure()
    ax = Axis(fig[1, 1])
    for (idx, i) in enumerate(x)
        scatterlines!(ax, x, i .* x; label="$idx")
    end
    axislegend("Label"; merge=true, position=:lt)
    fig
end
```

### Heatmaps

\end{examplefigure}

```julia
with_theme(theme_makie()) do
   x = range(0, 2π, 50)
    fig, ax, hm = heatmap(rand(10, 10); figure=(; resolution=(1200, 900)))
    ax1 = Axis(fig[1, 3]; xlabel="", ylabel="")
    ax2 = Axis(fig[2, 1:3])
    hm2 = heatmap!(ax1, rand(10, 10); colorrange=(0.2, 0.8), highclip=:black, lowclip=:grey)
    hm3 = lines!(ax2, x, sin.(x); color=x, linewidth=5)
    Colorbar(fig[1, 2], hm)
    Colorbar(fig[1, 4], hm2; label="")
    Colorbar(fig[2, 4], hm3; label="x")
    fig
end
```

\end{examplefigure}

### On how to use Cycles with this theme for scatter and lines

~~~
<input id="hidecode" class="hidecode" type="checkbox">
~~~

```julia:demofig

using CairoMakie
CairoMakie.activate!(type = "svg") # hide

function demoScatterLines()
    x = range(0, 20; length=7)
    fig = Figure(; resolution=(2600, 1600))
    ax11 = Axis(fig[1, 1]; title="lines(x,y)")
    for (idx, i) in enumerate(x)
        lines!(ax11, x, i .* x; label="$idx")
    end
    axislegend("Label"; merge=true)

    ax12 = Axis(fig[1, 2]; title="lines(x,y; cycle=:color)")
    for (idx, i) in enumerate(x)
        lines!(ax12, x, i .* x; label="$idx", cycle=:color)
    end
    axislegend("Label"; merge=true, position=:lt)

    ax13 = Axis(fig[1, 3]; title="lines(x,y; cycle=:linestyle)")
    for (idx, i) in enumerate(x)
        lines!(ax13, x, i .* x; label="$idx", cycle=:linestyle)
    end
    axislegend("Label"; merge=true, position=:lt)

    ax14 = Axis(fig[1, 4]; title="lines(x,y; linestyle=:dash,\n cycle=:color)")
    for (idx, i) in enumerate(x)
        lines!(ax14, x, i .* x; label="$idx", linestyle=:dash, cycle=:color)
    end
    axislegend("Label"; merge=true, position=:lt)

    ax15 = Axis(fig[1, 5]; title="lines(x,y; color=:red,\n cycle=:linestyle)")
    for (idx, i) in enumerate(x)
        lines!(ax15, x, i .* x; label="$idx", color=:red, cycle=:linestyle)
    end
    axislegend("Label"; merge=true, position=:lt)

    ax21 = Axis(fig[2, 1]; title="scatter(x,y)")
    for (idx, i) in enumerate(x)
        scatter!(ax21, x, i .* x; label="$idx")
    end
    axislegend("Label"; merge=true)

    ax22 = Axis(fig[2, 2]; title="scatter(x,y; cycle=:color)")
    for (idx, i) in enumerate(x)
        scatter!(ax22, x, i .* x; label="$idx", cycle=:color)
    end
    axislegend("Label"; merge=true, position=:lt)

    ax23 = Axis(fig[2, 3]; title="scatter(x,y; cycle=:marker)")
    for (idx, i) in enumerate(x)
        scatter!(ax23, x, i .* x; label="$idx", cycle=:marker)
    end
    axislegend("Label"; merge=true, position=:lt)

    ax24 = Axis(fig[2, 4];
                title="scatter(x,y; color=:transparent, \n strokewidth=2.0, \n cycle= Cycle([:strokecolor, :marker]; covary=true))")
    for (idx, i) in enumerate(x)
        scatter!(ax24, x, i .* x; label="$idx", color=:transparent, strokewidth=2.0,
                 cycle=Cycle([:strokecolor, :marker]; covary=true))
    end
    axislegend("Label"; merge=true, position=:lt)

    ax25 = Axis(fig[2, 5]; title="scatter(x,y; color=:red,\n cycle=:marker")
    for (idx, i) in enumerate(x)
        scatter!(ax25, x, i .* x; label="$idx", color=:red, cycle=:marker)
    end
    axislegend("Label"; merge=true, position=:lt)

    ax31 = Axis(fig[3, 1]; title="scatterlines(x,y)")
    for (idx, i) in enumerate(x)
        scatterlines!(ax31, x, i .* x; label="$idx")
    end
    axislegend("Label"; merge=true)

    ax32 = Axis(fig[3, 2]; title="scatterlines(x,y; cycle=:color)")
    for (idx, i) in enumerate(x)
        scatterlines!(ax32, x, i .* x; label="$idx", cycle=:color)
    end
    axislegend("Label"; merge=true, position=:lt)

    ax33 = Axis(fig[3, 3]; title="scatterlines(x,y; cycle=:marker)")
    for (idx, i) in enumerate(x)
        scatterlines!(ax33, x, i .* x; label="$idx", cycle=:marker)
    end
    axislegend("Label"; merge=true, position=:lt)

    ax34 = Axis(fig[3, 4];
                title="scatterlines(x,y; markercolor=:transparent,\n strokewidth=2.0, cycle= Cycle([:color, :strokecolor,\n :marker, :linestyle]; covary=true))")
    for (idx, i) in enumerate(x)
        scatterlines!(ax34, x, i .* x; label="$idx", markercolor=:transparent, strokewidth=2.0,
                      cycle=Cycle([:color, :strokecolor, :marker, :linestyle]; covary=true))
    end
    axislegend("Label"; merge=true, position=:lt)

    ax35 = Axis(fig[3, 5]; title="scatterlines(x,y; \ncolor=:red, cycle=:marker)")
    for (idx, i) in enumerate(x)
        scatterlines!(ax35, x, i .* x; label="$idx", color=:red, cycle=:marker)
    end
    axislegend("Label"; merge=true, position=:lt)
    return fig
end

```

~~~
<label for="hidecode" class="hidecode"></label>
~~~

\begin{examplefigure}{}

```julia
with_theme(demoScatterLines, theme_makie())
```

\end{examplefigure}

Similarly, for some statistical plots we can do

~~~
<input id="hidecode" class="hidecode" type="checkbox">
~~~

```julia:demofigstats
using CairoMakie
CairoMakie.activate!(type = "svg") # hide

function demoStats()
    fig = Figure(; resolution=(2600, 1600))
    ax11 = Axis(fig[1, 1])
    ax12 = Axis(fig[1, 2])
    ax13 = Axis(fig[1, 3])
    ax14 = Axis(fig[1, 4])

    ax21 = Axis(fig[2, 1])
    ax22 = Axis(fig[2, 2])
    ax23 = Axis(fig[2, 3])
    ax24 = Axis(fig[2, 4])

    ax31 = Axis(fig[3, 1])
    ax32 = Axis(fig[3, 2])
    ax33 = Axis(fig[3, 3])
    ax34 = Axis(fig[3, 4])

    xs = 1:0.2:5.0
    ys_low = -0.2 .* sin.(xs) .- 0.25
    ys_high = 0.2 .* sin.(xs) .+ 0.25
    for i in 0:6
        band!(ax11, xs, ys_low .- i, ys_high .- i)
    end
    xs = 1:0.2:10
    ys = 0.5 .* sin.(xs)
    for i in 0:6
        barplot!(ax12, xs, ys; offset=i)
    end
    for i in 0:6
        barplot!(ax13, xs, ys; color=:transparent, strokewidth=1, offset=i, cycle=[:strokecolor])
    end
    barplot!(ax14, xs, ys; color=xs)

    for i in 0:6
        boxplot!(ax21, fill(i, 1000), rand(1000); mediancolor=:white)
    end
    for i in 0:6
        boxplot!(ax22, fill(i, 1000), rand(1000); color=:transparent, strokewidth=2.5,
                 cycle=Cycle([:strokecolor, :whiskercolor]; covary=true))
    end
    for i in 0:6
        boxplot!(ax23, fill(i, 1000), rand(1000); color=:white, strokewidth=2.5)
    end

    for i in 0:6
        violin!(ax31, fill(i, 1000), rand(1000) / (i + 1))
    end
    for i in 0:6
        violin!(ax32, fill(i, 1000), rand(1000) / (i + 1); color=:transparent, strokewidth=2.5,
                show_median=true, cycle=Cycle([:strokecolor, :mediancolor]; covary=true))
    end
    for i in 0:6
        violin!(ax33, fill(i, 1000), rand(1000) / (i + 1); color=:white, strokewidth=2.5)
    end
    for i in 1:7
        hist!(ax34, randn(1000); scale_to=0.6, offset=i, direction=:x, strokewidth=0.85)
        text!(ax34, "$i"; position=(i + 0.5, 2.5))
    end
    for i in 1:5
        hist!(ax24, randn(1000); scale_to=0.6, color=:transparent, offset=i, direction=:x, strokewidth=0.85,
              cycle=:strokecolor)
    end
    return fig
end

```

~~~
<label for="hidecode" class="hidecode"></label>
~~~

\begin{examplefigure}{}

```julia
with_theme(demoStats, theme_makie())
```

\end{examplefigure}

This theme also works with `Axis3`.

~~~
<input id="hidecode" class="hidecode" type="checkbox">
~~~

```julia:demofigstats
using GLMakie
GLMakie.activate!(type = "png") # hide, not sure is this works here... ?
function demo3dmix()
    function peaks(; n=49)
        x = LinRange(-3, 3, n)
        y = LinRange(-3, 3, n)
        a = 3 * (1 .- x') .^ 2 .* exp.(-(x' .^ 2) .- (y .+ 1) .^ 2)
        b = 10 * (x' / 5 .- x' .^ 3 .- y .^ 5) .* exp.(-x' .^ 2 .- y .^ 2)
        c = 1 / 3 * exp.(-(x' .+ 1) .^ 2 .- y .^ 2)
        return (x, y, a .- b .- c)
    end
    x, y, z = peaks()
    fig = Figure(; resolution=(2600, 1600))
    ax11 = Axis3(fig[1, 1]; aspect=(1, 1, 1))
    ax12 = Axis3(fig[1, 2]; aspect=(1, 1, 1))
    ax13 = Axis3(fig[1, 3]; aspect=(1, 1, 1))
    ax14 = Axis3(fig[1, 4]; aspect=(1, 1, 1))
    ax21 = Axis3(fig[2, 1]; aspect=(1, 1, 1))
    ax22 = Axis3(fig[2, 2]; aspect=(1, 1, 1))
    ax23 = Axis3(fig[2, 3]; aspect=(1, 1, 1))
    ax24 = Axis3(fig[2, 4]; aspect=(1, 1, 1))
    ax31 = Axis(fig[3, 1])
    ax32 = Axis(fig[3, 2])
    ax33 = Axis(fig[3, 3])
    ax34 = Axis(fig[3, 4])

    [scatter!(ax11, [Point3f(rand(3)) for _ in 1:10]; markersize=80) for i in 1:7]
    [lines!(ax12, [Point3f(rand(3)) for _ in 1:10]; markersize=80) for _ in 1:7]
    [scatterlines!(ax13, [Point3f(rand(3)) for _ in 1:10]; markersize=80) for _ in 1:7]
    [scatterlines!(ax14, [Point3f(rand(3)) for _ in 1:10]; markersize=80, linestyle=:solid,
                   cycle=Cycle([:color, :strokecolor, :marker]; covary=true)) for _ in 1:7]
    [scatterlines!(ax21, [Point3f(rand(3)) for _ in 1:10]; markersize=80, linestyle=:solid,
                   cycle=Cycle([:color, :strokecolor]; covary=true)) for _ in 1:7]
    [scatterlines!(ax22, [Point3f(rand(3)) for _ in 1:10]; markersize=80, markercolor=:transparent,
                   linestyle=:solid, strokewidth=2,
                   cycle=Cycle([:color, :strokecolor, :marker]; covary=true)) for _ in 1:7]
    contour!(ax23, rand(30, 30, 30))
    contour3d!(ax24, x, y, z; levels=14, transparency=true, linewidth=5)
    for i in 1:7
        density!(ax31, randn(50) .+ 2i)
    end
    for i in 1:7
        density!(ax32, randn(50) .+ 2i; color=(:orange, 0.1), strokewidth=1.5,
                 cycle=Cycle([:strokecolor, :linestyle]; covary=true))
    end
    for i in 1:7
        density!(ax33, randn(50) .+ 2i; color=:transparent, strokewidth=1.5, cycle=:strokecolor)
    end
    for i in 1:7
        density!(ax34, randn(50) .+ 2i; strokewidth=2.5, cycle=:strokecolor)
    end
    return fig
end
```

~~~
<label for="hidecode" class="hidecode"></label>
~~~

\begin{examplefigure}{}

```julia
with_theme(demo3dmix, theme_makie())
```

\end{examplefigure}
