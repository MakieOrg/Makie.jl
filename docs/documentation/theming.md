# Theming

Makie allows you to change almost every visual aspect of your plots via attributes.
You can set attributes whenever you create an object, or you define a general style that is then used as the default by all following objects.

There are three functions you can use for that purpose:

```julia
set_theme!
update_theme!
with_theme
```

## set_theme!

You can call `set_theme!(theme; kwargs...)` to change the current default theme to `theme` and override or add attributes given by `kwargs`.
You can also reset your changes by calling `set_theme!()` without arguments.

Let's create a plot with the default theme:

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

function example_plot()
    f = Figure()
    for i in 1:2, j in 1:2
        lines(f[i, j], cumsum(randn(50)))
    end
    f
end

example_plot()
```
\end{examplefigure}

Now we define a theme which changes the default fontsize, activate it, and plot.

\begin{examplefigure}{}
```julia
fontsize_theme = Theme(fontsize = 10)
set_theme!(fontsize_theme)

example_plot()
```
\end{examplefigure}

This theme will be active until we call `set_theme!()`.

```julia:set_theme
set_theme!()
```

## update_theme!

If you have activated a theme already and want to update it partially, without removing the attributes not in the new theme, you can use `update_theme!`.

For example, you can first call `set_theme!(my_theme)` and later update font and fontsize with `update_theme!(font = "Arial", fontsize = 18)`, leaving all other settings intact.


## with_theme

Because it can be tedious to remember to switch themes off which you need only temporarily, there's the function `with_theme(f, theme)` which handles the resetting for you automatically, even if you encounter an error while running `f`.

\begin{examplefigure}{}
```julia
with_theme(fontsize_theme) do
    example_plot()
end
```
\end{examplefigure}

You can also pass additional keywords to add or override attributes in your theme:

\begin{examplefigure}{}
```julia
with_theme(fontsize_theme, fontsize = 25) do
    example_plot()
end
```
\end{examplefigure}

## Theming plot objects

You can theme plot objects by using their uppercase type names as a key in your theme.

\begin{examplefigure}{}
```julia
lines_theme = Theme(
    Lines = (
        linewidth = 4,
        linestyle = :dash,
    )
)

with_theme(example_plot, lines_theme)
```
\end{examplefigure}

## Theming layoutable objects

Every Layoutable such as `Axis`, `Legend`, `Colorbar`, etc. can be themed by using its type name as a key in your theme.

Here is how you could define a simple ggplot-like style for your axes:

\begin{examplefigure}{}
```julia
ggplot_theme = Theme(
    Axis = (
        backgroundcolor = :gray90,
        leftspinevisible = false,
        rightspinevisible = false,
        bottomspinevisible = false,
        topspinevisible = false,
        xgridcolor = :white,
        ygridcolor = :white,
    )
)

with_theme(example_plot, ggplot_theme)
```
\end{examplefigure}

## Cycles

Makie supports a variety of options for cycling plot attributes automatically.
For a plot object to use cycling, either its default theme or the currently active theme must have the `cycle` attribute set.

There are multiple ways to specify this attribute:

```julia
# You can either make a list of symbols
cycle = [:color, :marker]
# or map specific plot attributes to palette attributes
cycle = [:linecolor => :color, :marker]
# you can also map multiple attributes that should receive
# the same cycle attribute
cycle = [[:linecolor, :markercolor] => :color, :marker]
# nothing disables cycling
cycle = nothing # equivalent to cycle = []
```

### Covarying cycles

You can also construct a `Cycle` object directly, which additionally allows to set the `covary` keyword, that defaults to `false`. A cycler with `covary = true` cycles all attributes together, instead of cycling through all values of the first, then the second, etc.

```julia
# palettes: color = [:red, :blue, :green] marker = [:circle, :rect, :utriangle, :dtriangle]

cycle = [:color, :marker]
# 1: :red, :circle
# 2: :blue, :circle
# 3: :green, :circle
# 4: :red, :rect
# ...

cycle = Cycle([:color, :marker], covary = true)
# 1: :red, :circle
# 2: :blue, :rect
# 3: :green, :utriangle
# 4: :red, :dtriangle
# ...
```

### Manual cycling using `Cycled`

If you want to give a plot's attribute a specific value from the respective cycler, you can use the `Cycled` object.
The index `i` passed to `Cycled` is used directly to look up a value in the cycler that belongs to the attribute, and errors if no such cycler is defined.
For example, to access the third color in a cycler, instead of plotting three plots to advance the cycler, you can use `color = Cycled(3)`.

The cycler's internal counter is not advanced when using `Cycled` for any attribute, and only attributes with `Cycled` access the cycled values, all other usually cycled attributes fall back to their non-cycled defaults.

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure()

Axis(f[1, 1])

# the normal cycle
lines!(0..10, x -> sin(x) - 1)
lines!(0..10, x -> sin(x) - 2)
lines!(0..10, x -> sin(x) - 3)

# manually specified colors
lines!(0..10, x -> sin(x) - 5, color = Cycled(3))
lines!(0..10, x -> sin(x) - 6, color = Cycled(2))
lines!(0..10, x -> sin(x) - 7, color = Cycled(1))

f
```
\end{examplefigure}

### Palettes

The attributes specified in the cycle are looked up in the axis' palette.
A single `:color` is both plot attribute as well as palette attribute, while `:color => :patchcolor` means that `plot.color` should be set to `palette.patchcolor`.
Here's an example that shows how density plots react to different palette options:

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

set_theme!() # hide

f = Figure(resolution = (800, 800))

Axis(f[1, 1], title = "Default cycle palette")

for i in 1:6
    density!(randn(50) .+ 2i)
end

Axis(f[2, 1],
    title = "Custom cycle palette",
    palette = (patchcolor = [:red, :green, :blue, :yellow, :orange, :pink],))

for i in 1:6
    density!(randn(50) .+ 2i)
end

set_theme!(Density = (cycle = [],))

Axis(f[3, 1], title = "No cycle")

for i in 1:6
    density!(randn(50) .+ 2i)
end

set_theme!() # hide

f
```
\end{examplefigure}

You can also theme global palettes via `set_theme!(palette = (color = my_colors, marker = my_markers))` for example.

### Cycle lines, theme_jlmke

\begin{examplefigure}{}

```julia
using CairoMakie
CairoMakie.activate!() # HIDE
function demoLinesCycle()
    x = range(0, 20; length=7)
    fig = Figure()
    ax11 = Axis(fig[1, 1]; title="lines(x,y)")
    for (idx, i) in enumerate(x)
        lines!(ax11, x, i .* x; label="$idx")
    end
    axislegend("Label"; merge=true, nbanks=2)

    ax12 = Axis(fig[1, 2]; title="lines(x,y; cycle=:color)")
    for (idx, i) in enumerate(x)
        lines!(ax12, x, i .* x; label="$idx", cycle=:color)
    end
    axislegend("Label"; merge=true, position=:lt, nbanks=2)

    ax21 = Axis(fig[2, 1]; title="lines(x,y; linestyle=:dash,\n cycle=:color)")
    for (idx, i) in enumerate(x)
        lines!(ax21, x, i .* x; label="$idx", linestyle=:dash, cycle=:color)
    end
    axislegend("Label"; merge=true, position=:lt, nbanks=2)

    ax22 = Axis(fig[2, 2]; title="lines(x,y; color=:red,\n cycle=:linestyle)")
    for (idx, i) in enumerate(x)
        lines!(ax22, x, i .* x; label="$idx", color=:red, cycle=:linestyle)
    end
    axislegend("Label"; merge=true, position=:lt, nbanks=2)
    return fig
end
with_theme(theme_makie()) do
    demoLinesCycle()
end
```
\end{examplefigure}

#### Cycle scatters

\begin{examplefigure}{}

```julia
using CairoMakie
CairoMakie.activate!() # HIDE
function demoScattersCycle()
    x = range(0, 20; length=7)
    fig = Figure()
    ax11 = Axis(fig[1, 1]; title="scatter(x,y)")
    for (idx, i) in enumerate(x)
        scatter!(ax11, x, i .* x; label="$idx")
    end
    axislegend("Label"; merge=true, nbanks=2)

    ax12 = Axis(fig[1, 2]; title="scatter(x,y; cycle=:color)")
    for (idx, i) in enumerate(x)
        scatter!(ax12, x, i .* x; label="$idx", cycle=:color)
    end
    axislegend("Label"; merge=true, position=:lt, nbanks=2)

    ax22 = Axis(fig[2, 1];
                title="scatter(x,y; color=:transparent, \n strokewidth=2.0, \n cycle= Cycle([:strokecolor, :marker]; covary=true))")
    for (idx, i) in enumerate(x)
        scatter!(ax22, x, i .* x; label="$idx", color=:transparent, strokewidth=2.0,
                 cycle=Cycle([:strokecolor, :marker]; covary=true))
    end
    axislegend("Label"; merge=true, position=:lt, nbanks=2)

    ax23 = Axis(fig[2, 2]; title="scatter(x,y; color=:red,\n cycle=:marker")
    for (idx, i) in enumerate(x)
        scatter!(ax23, x, i .* x; label="$idx", color=:red, cycle=:marker)
    end
    axislegend("Label"; merge=true, position=:lt, nbanks=2)
    return fig
end
with_theme(theme_jlmke()) do
    return demoScattersCycle()
end
```

\end{examplefigure}

#### Cycle scatterlines

\begin{examplefigure}{}

```julia
using CairoMakie
CairoMakie.activate!() # HIDE
function demoScatterLinesCycle()
    x = range(0, 20; length=7)
    fig = Figure()
    ax11 = Axis(fig[1, 1]; title="scatterlines(x,y)")
    for (idx, i) in enumerate(x)
        scatterlines!(ax11, x, i .* x; label="$idx")
    end
    axislegend("Label"; merge=true, nbanks=2)

    ax12 = Axis(fig[1, 2]; title="scatterlines(x,y; cycle=:color)")
    for (idx, i) in enumerate(x)
        scatterlines!(ax12, x, i .* x; label="$idx", cycle=:color)
    end
    axislegend("Label"; merge=true, position=:lt, nbanks=2)

    ax21 = Axis(fig[2, 1];
                title="scatterlines(x,y; markercolor=:transparent,\n strokewidth=2.0, cycle= Cycle([:color, :strokecolor,\n :marker, :linestyle]; covary=true))")
    for (idx, i) in enumerate(x)
        scatterlines!(ax21, x, i .* x; label="$idx", markercolor=:transparent, strokewidth=2.0,
                      cycle=Cycle([:color, :strokecolor, :marker, :linestyle]; covary=true))
    end
    axislegend("Label"; merge=true, position=:lt, nbanks=2)

    ax22 = Axis(fig[2, 2]; title="scatterlines(x,y; \ncolor=:red, cycle=:marker)")
    for (idx, i) in enumerate(x)
        scatterlines!(ax22, x, i .* x; label="$idx", color=:red, cycle=:marker)
    end
    axislegend("Label"; merge=true, position=:lt, nbanks=2)
    return fig
end

with_theme(theme_jlmke()) do
    return demoScatterLinesCycle()
end
```

\end{examplefigure}

#### Cycle lines scatter in 3d

\begin{examplefigure}{}

```julia
using GLMakie
GLMakie.activate!() # HIDE
function demo3dLineScatter()
    a, m, z₀ = 1, 2.1, 0
    φ = LinRange(0,20π,500)
    r = a*φ
    x, y, z = r .* cos.(φ), r .* sin.(φ), m .* r .+ z₀
    fig = Figure()
    axs = [Axis3(fig[i, j]; aspect=(1, 1, 1)) for i in 1:2 for j in 1:2]
    [scatter!(axs[1], 4x, -2y .+ i, z .+ 5i) for i in 1:7]
    [lines!(axs[2], 4x, -2y .+ i, z .+ 5i) for i in 1:7]
    [scatterlines!(axs[3], 4x, -2y .+ i, z .+ 5i; linestyle=:solid,
        cycle=Cycle([:color, :strokecolor, :marker]; covary=true)) for i in 1:7]
    [scatterlines!(axs[4], 4x, -2y .+ i, z .+ 5i; markercolor=:transparent, linestyle=:solid, strokewidth=2,
        cycle=Cycle([:color, :strokecolor, :marker]; covary=true)) for i in 1:7]
    return fig
end

with_theme(theme_jlmke()) do
    return demo3dLineScatter()
end
```

\end{examplefigure}

#### Cycle band, barplot

\begin{examplefigure}{}

```julia
using CairoMakie
CairoMakie.activate!() # HIDE
function demo1Stats()
    fig = Figure()
    axs = [Axis(fig[i, j]) for i in 1:2 for j in 1:2]
    xs = 1:0.2:5.0
    ys_low = -0.2 .* sin.(xs) .- 0.25
    ys_high = 0.2 .* sin.(xs) .+ 0.25
    for i in 0:6
        band!(axs[1], xs, ys_low .- i, ys_high .- i)
    end
    xs = 1:0.2:10
    ys = 0.5 .* sin.(xs)
    for i in 0:6
        barplot!(axs[2], xs, ys; offset=i)
    end
    for i in 0:6
        barplot!(axs[3], xs, ys; color=:transparent, strokewidth=1, offset=i, cycle=:strokecolor)
    end
    barplot!(axs[4], xs, ys; color=xs)
    return fig
end

with_theme(theme_jlmke()) do
    return demo1Stats()
end
```

\end{examplefigure}

#### Cycle boxplot, violin

\begin{examplefigure}{}

```julia
using CairoMakie
CairoMakie.activate!() # HIDE
function demo2Stats()
    fig = Figure()
    axs = [Axis(fig[i, j]) for i in 1:2 for j in 1:2]
    for i in 0:6
        boxplot!(axs[1], fill(i, 1000), rand(1000); mediancolor=:white)
    end
    for i in 0:6
        boxplot!(axs[2], fill(i, 1000), rand(1000); color=:transparent, strokewidth=2.5,
                 cycle=Cycle([:strokecolor, :whiskercolor]; covary=true))
    end
    for i in 0:6
        violin!(axs[3], fill(i, 1000), rand(1000) / (i + 1))
    end
    for i in 0:6
        violin!(axs[4], fill(i, 1000), rand(1000) / (i + 1); color=:transparent, strokewidth=2.5,
                show_median=true, cycle=Cycle([:strokecolor, :mediancolor]; covary=true))
    end
    return fig
end

fig = with_theme(theme_jlmke()) do
    return demo2Stats()
end
```

\end{examplefigure}

#### Cycle histograms and density plots

\begin{examplefigure}{}

```julia
using CairoMakie
CairoMakie.activate!() # HIDE
function demo3Stats()
    fig = Figure()
    axs = [Axis(fig[i, j]) for i in 1:2 for j in 1:2]
    for i in 1:7
        hist!(axs[1], randn(1000); scale_to=0.6, offset=i, direction=:x, strokewidth=0.85)
        text!(axs[1], "$i"; position=(i + 0.5, 2.5))
    end
    for i in 1:5
        hist!(axs[2], randn(1000); scale_to=0.6, color=:transparent, offset=i, direction=:x, strokewidth=0.85,
              cycle=:strokecolor)
    end
    for i in 1:7
        density!(axs[3], randn(50) .+ 2i; color=(:orange, 0.1), strokewidth=1.5,
                 cycle=Cycle([:strokecolor, :linestyle]; covary=true))
    end
    for i in 1:7
        density!(axs[4], randn(50) .+ 2i; color=:transparent, strokewidth=1.5, cycle=:strokecolor)
    end
    return fig
end
with_theme(theme_jlmke()) do
    return demo3Stats()
end
```

\end{examplefigure}

## Special attributes

You can use the keys `rowgap` and `colgap` to change the default grid layout gaps.
