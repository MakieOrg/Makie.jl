# Overview Of Plotting Methods

Makie offers a simple but powerful set of methods for each plotting function, which allow you to easily create and manipulate the most common aspects of a figure.

Each plot object like `Scatter` has two plotting functions associated to it, a non-mutating version (`scatter`) and a mutating version (`scatter!`).
These functions have different methods that behave slightly differently depending on the first argument.

Here's a short list before we show each version in more detail.
We use `Scatter` as our example, but the principles apply to every plot type.

## Non-Mutating

The non-mutating methods create and return something in addition to the plot object, either a figure with an axis in default position, or an axis at a given figure position.

```julia
scatter(args...) -> ::FigureAxisPlot
scatter(figureposition, args...) -> ::AxisPlot
```

`FigureAxisPlot` is just a collection of the new figure, axis and plot.
For convenience it has the same display overload as `Figure`, so that `scatter(args...)` displays a plot without further work.
It can be destructured at assignment like `fig, ax, plotobj = scatter(args...)`.

`AxisPlot` is a collection of a new axis and plot.
It has no special display overload but can also be destructured like `ax, plotobj = scatter(figureposition, args...)`.

## Mutating

The mutating methods always just return a plot object.
If no figure is passed, the `current_figure()` is used, if no axis or scene is given, the `current_axis()` is used.

```julia
scatter!(args...) -> ::Scatter
scatter!(figure, args...) -> ::Scatter
scatter!(figureposition, args...) -> ::Scatter
scatter!(axis, args...) -> ::Scatter
scatter!(scene, args...) -> ::Scatter
```

## FigurePositions

In the background, each `Figure` has a `GridLayout` from GridLayoutBase.jl, which takes care of layouting plot elements nicely.
For convenience, you can index into a figure multiple times to refer to nested grid positions, which makes it easy to quickly assemble complex layouts.

```@example
using GLMakie

fig = Figure()

# first row, first column
scatter(fig[1, 1], 1.0..10, sin)

# first row, second column
lines(fig[1, 2], 1.0..10, sin)

# first row, third column, then nested first row, first column
lines(fig[1, 3][1, 1], cumsum(randn(10000)), color = :blue)

# first row, third column, then nested second row, first column
lines(fig[1, 3][2, 1], cumsum(randn(10000)), color = :red)

# second row, first to third column
ax, hm = heatmap(fig[2, 1:3], randn(30, 10))

# across all rows, new column after the last one
fig[:, end+1] = Colorbar(fig, hm, width = 30)

fig
```