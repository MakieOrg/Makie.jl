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

## Theming block objects

Every Block such as `Axis`, `Legend`, `Colorbar`, etc. can be themed by using its type name as a key in your theme.

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

## Special attributes

You can use the keys `rowgap` and `colgap` to change the default grid layout gaps.
