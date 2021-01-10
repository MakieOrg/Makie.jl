# Theming

Makie allows you to change almost every visual aspect of your plots via attributes.
You can set attributes whenever you create an object, or you define a general style that is then used as the default by all following objects.

You can call `set_theme!(theme; kwargs...)` to change the current default theme to `theme` and override or add attributes given by `kwargs`.
You can also reset your changes by calling `set_theme!()` without arguments.

Let's create a plot with the default theme:

```@example 1
using GLMakie

function example_plot()
    f = Figure(resolution = (1000, 800))
    for i in 1:2, j in 1:2
        lines(f[i, j], cumsum(randn(1000)))
    end
    f
end

example_plot()
```

Now we define a theme which changes the default fontsize, activate it, and plot.

```@example 1
fontsize_theme = Theme(fontsize = 10)
set_theme!(fontsize_theme)

example_plot()
```

This theme will be active until we call `set_theme!()`.

```@example 1
set_theme!()
```

Because it can be tedious to remember to switch themes off which you need only temporarily, there's the function `with_theme(f, theme)` which handles the resetting for you automatically, even if you encounter an error while running `f`.

```@example 1
with_theme(fontsize_theme) do
    example_plot()
end
```

You can also pass additional keywords to add or override attributes in your theme:

```@example 1
with_theme(fontsize_theme, fontsize = 25) do
    example_plot()
end
```

## Theming layoutable objects

Every Layoutable such as `Axis`, `Legend`, `Colorbar`, etc. can be themed by using its type name as a key in your theme.

Here is how you could define a simple ggplot-like style for your axes:

```@example 1
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

### Special attributes

You can use the keys `rowgap` and `colgap` to change the default grid layout gaps.
