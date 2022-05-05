# Basic Tutorial

## Preface

Here is a quick tutorial to get you started with Makie!

We assume you have [Julia](https://julialang.org/) and `CairoMakie.jl` (or one of the other backends, i.e. `GLMakie.jl` or `WGLMakie.jl`) installed already.

This tutorial uses CairoMakie, but the code can be executed with any backend.
CairoMakie can output beautiful static vector graphics, but it doesn't have the native ability to open interactive windows.

To see the output of plotting commands when using CairoMakie, we recommend you either use an IDE which supports png or svg output, such as VSCode, Atom/Juno, Jupyter, Pluto, etc., or try using a viewer package such as [ElectronDisplay.jl](https://github.com/queryverse/ElectronDisplay.jl), or alternatively save your plots to files directly.
The Julia REPL by itself does not have the ability to show the plots.

GLMakie can open interactive plot windows, also from the Julia REPL, or alternatively display bitmaps inline if `Makie.inline!(true)` is called
and if it is supported by the environment.

WGLMakie shows interactive plots in environments that support interactive html displays, such as VSCode, Atom/Juno, Jupyter, Pluto, etc.

For more information, have a look at \myreflink{Backends & Output}.

Ok, now that this is out of the way, let's get started!

## First plot

First, we import CairoMakie.

```julia:setup
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide
nothing # hide
```

Makie has many different plotting functions, one of the most common ones is \myreflink{lines}.
You can just call such a function and your plot will appear if your coding environment can show png or svg files.

!!! note
    Objects such as [Figure](\reflink{Figures}), `FigureAxisPlot` or `Scene` are usually displayed whenever they are returned in global scope (e.g. in the REPL).
    To display such objects from within a local scope, like from within a function, you can directly call `display(figure)`, for example.

\begin{examplefigure}{svg = true}
```julia

x = range(0, 10, length=100)
y = sin.(x)
lines(x, y)
```
\end{examplefigure}

Another common function is \myreflink{scatter}.

\begin{examplefigure}{svg = true}
```julia

using CairoMakie

x = range(0, 10, length=100)
y = sin.(x)
scatter(x, y)
```
\end{examplefigure}

## Multiple plots

Every plotting function has a version with and one without `!`.
For example, there's `scatter` and `scatter!`, `lines` and `lines!`, etc.
The functions without a `!` always create a new axis with a plot inside, while the functions with `!` plot into an already existing axis.

Here's how you could plot two lines on top of each other. Also, notice you can pass a function (`sin` and `cos` in this case) as the
`y` argument to a plotting function.

\begin{examplefigure}{svg = true}
```julia

using CairoMakie

x = range(0, 10, length=100)

lines(x, sin)
lines!(x, cos)
current_figure()
```
\end{examplefigure}

The second `lines!` call plots into the axis created by the first `lines` call.
If you don't specify an axis to plot into, it's as if you had called `lines!(current_axis(), ...)`.

The call to `current_figure` is necessary here, because functions with `!` return only the newly created plot object, but this alone does not cause the figure to display when returned.

## Attributes

Every plotting function has attributes which you can set through keyword arguments.
The lines in the previous example both have the same default color, which we can change easily.

\begin{examplefigure}{svg = true}
```julia

using CairoMakie

x = range(0, 10, length=100)
y1 = sin.(x)
y2 = cos.(x)

lines(x, y1, color = :red)
lines!(x, y2, color = :blue)
current_figure()
```
\end{examplefigure}

Other plotting functions have different attributes.
The function `scatter`, for example, does not only have the `color` attribute, but also a `markersize` attribute.

\begin{examplefigure}{svg = true}
```julia

using CairoMakie

x = range(0, 10, length=100)
y1 = sin.(x)
y2 = cos.(x)

scatter(x, y1, color = :red, markersize = 5)
scatter!(x, y2, color = :blue, markersize = 10)
current_figure()
```
\end{examplefigure}

If you save the plot object returned from a call like `scatter!`, you can also manipulate its attributes later with the syntax `plot.attribute = new_value`.

\begin{examplefigure}{svg = true}
```julia

using CairoMakie

x = range(0, 10, length=100)
y1 = sin.(x)
y2 = cos.(x)

scatter(x, y1, color = :red, markersize = 5)
sc = scatter!(x, y2, color = :blue, markersize = 10)
sc.color = :green
sc.markersize = 20
current_figure()
```
\end{examplefigure}

## Array attributes

A lot of attributes can be set to either a single value or an array with as many elements as there are data points.
For example, it is usually much more performant to draw many points with one scatter object, than to create many scatter objects with one point each.

Here are the two scatter plots again, but one has varying markersize, and the other varying color.

\begin{examplefigure}{svg = true}
```julia

using CairoMakie

x = range(0, 10, length=100)
y1 = sin.(x)
y2 = cos.(x)

scatter(x, y1, color = :red, markersize = range(5, 15, length=100))
sc = scatter!(x, y2, color = range(0, 1, length=100), colormap = :thermal)

current_figure()
```
\end{examplefigure}

Note that the color array does not actually contain colors, rather the numerical values are mapped to the plot's `colormap`.
There are many different colormaps to choose from, take a look on the \myreflink{Colors} page.

The values are mapped to colors via the `colorrange` attribute, which by default goes from the minimum to the maximum color value, but we can also limit or expand the range manually.
For example, we can constrain the previous scatter plot's color range to (0.25, 0.75), which will clip the colors at the bottom and the top quarters.

\begin{examplefigure}{svg = true}
```julia

sc.colorrange = (0.25, 0.75)

current_figure()
```
\end{examplefigure}

Of course you can also use an array of colors directly, in which case the `colorrange` is ignored:

\begin{examplefigure}{svg = true}
```julia

using CairoMakie

x = range(0, 10, length=100)
y = sin.(x)

colors = repeat([:crimson, :dodgerblue, :slateblue1, :sienna1, :orchid1], 20)

scatter(x, y, color = colors, markersize = 20)
```
\end{examplefigure}

## Simple legend

If you add label attributes to your plots, you can call the `axislegend` function to add a legend with all labeled plots to the current axis.

\begin{examplefigure}{svg = true}
```julia

using CairoMakie

x = range(0, 10, length=100)
y1 = sin.(x)
y2 = cos.(x)

lines(x, y1, color = :red, label = "sin")
lines!(x, y2, color = :blue, label = "cos")
axislegend()
current_figure()
```
\end{examplefigure}

## Subplots

Makie uses a powerful layout system under the hood, which allows you to create very complex figures with many subplots.
For the easiest way to do this, we need a [Figure](\reflink{Figures}) object.
So far, we haven't seen this explicitly, it was created in the background in the first plotting function call.

We can also create a [Figure](\reflink{Figures}) directly and then continue working with it.
We can make subplots by giving the location of the subplot in our layout grid as the first argument to our plotting function.
The basic syntax for specifying the location in a figure is `fig[row, col]`.

\begin{examplefigure}{svg = true}
```julia

using CairoMakie

x = LinRange(0, 10, 100)
y = sin.(x)

fig = Figure()
lines(fig[1, 1], x, y, color = :red)
lines(fig[1, 2], x, y, color = :blue)
lines(fig[2, 1:2], x, y, color = :green)

fig
```
\end{examplefigure}

Each `lines` call creates a new axis in the position given as the first argument, that's why we use `lines` and not `lines!` here.

## Constructing axes manually

Like [Figure](\reflink{Figures})s, we can also create axes manually.
This is useful if we want to prepare an empty axis to then plot into it later.

The default 2D axis that we have created implicitly so far is called \myreflink{Axis} and can also be created in a specific position in the figure by passing that position as the first argument.

For example, we can create a figure with three axes.

\begin{examplefigure}{svg = true}
```julia

using CairoMakie

fig = Figure()
ax1 = Axis(fig[1, 1])
ax2 = Axis(fig[1, 2])
ax3 = Axis(fig[2, 1:2])
fig
```
\end{examplefigure}

And then we can continue to plot into these empty axes.

\begin{examplefigure}{svg = true}
```julia

lines!(ax1, 0..10, sin)
lines!(ax2, 0..10, cos)
lines!(ax3, 0..10, sqrt)
fig
```
\end{examplefigure}

Note, the notation `0..10` above creates a closed interval from `0` to `10` (see [`IntervalSets.jl`](https://github.com/JuliaMath/IntervalSets.jl) for further details).

Axes also have many attributes that you can set, for example to give them a title, or labels.

\begin{examplefigure}{svg = true}
```julia

ax1.title = "sin"
ax2.title = "cos"
ax3.title = "sqrt"

ax1.ylabel = "amplitude"
ax3.ylabel = "amplitude"
ax3.xlabel = "time"
fig
```
\end{examplefigure}

## Legend and Colorbar

We have seen two `Blocks` so far, the \myreflink{Axis} and the \myreflink{Legend} which was created by the function `axislegend`.
All `Block`s can be placed into the layout of a figure at arbitrary positions, which makes it easy to assemble complex figures.

In the same way as with the \myreflink{Axis} before, you can also create a \myreflink{Legend} manually and then place it freely, wherever you want, in the figure.
There are multiple ways to create \myreflink{Legend}s, for one of them you pass one vector of plot objects and one vector of label strings.

You can see here that we can deconstruct the return value from the two `lines` calls into one newly created axis and one plot object each.
We can then feed the plot objects to the legend constructor.
We place the legend in the second column and across both rows, which centers it nicely next to the two axes.

\begin{examplefigure}{svg = true}
```julia

using CairoMakie

fig = Figure()
ax1, l1 = lines(fig[1, 1], 0..10, sin, color = :red)
ax2, l2 = lines(fig[2, 1], 0..10, cos, color = :blue)
Legend(fig[1:2, 2], [l1, l2], ["sin", "cos"])
fig
```
\end{examplefigure}

The \myreflink{Colorbar} works in a very similar way.
We just need to pass a position in the figure to it, and one plot object.
In this example, we use a `heatmap`.

You can see here that we split the return value of `heatmap` into three parts: the newly created figure, the axis and the heatmap plot object.
This is useful as we can then continue with the figure `fig` and the heatmap `hm` which we need for the colorbar.

\begin{examplefigure}{svg = true}
```julia

using CairoMakie

fig, ax, hm = heatmap(randn(20, 20))
Colorbar(fig[1, 2], hm)
fig
```
\end{examplefigure}

The previous short syntax is basically equivalent to this longer, manual version.
You can switch between those workflows however you please.

\begin{examplefigure}{svg = true}
```julia

using CairoMakie

fig = Figure()
ax = Axis(fig[1, 1])
hm = heatmap!(ax, randn(20, 20))
Colorbar(fig[1, 2], hm)
fig
```
\end{examplefigure}

## Passing attributes to Figure and Axis

For one-off plots, it can be convenient to set axis or figure settings directly with the plotting command.
You can do this using the plotting functions without the `!` suffix, like `lines` or `scatter`, because these always create a new axis and also create a new figure if they are not plotting onto an existing one. This is explained further under \myreflink{Plot Method Signatures}.

You can pass axis attributes under the keyword `axis` and figure attributes under the keyword `figure`.

\begin{examplefigure}{svg = true}
```julia

using CairoMakie

heatmap(randn(20, 20),
    figure = (backgroundcolor = :pink,),
    axis = (aspect = 1, xlabel = "x axis", ylabel = "y axis")
)
```
\end{examplefigure}

If you set only one attribute, be careful to do `axis = (key = value,)` (note the trailing comma), otherwise you're not creating a `NamedTuple` but a local variable `key`.

## Next steps

We've only looked at a small subset of Makie's functionality here.

You can read about the different available plotting functions with examples in the Plotting Functions section.

If you want to learn about making complex figures with nested sublayouts, have a look at the \myreflink{Layout Tutorial} section.

If you're interested in creating interactive visualizations that use Makie's special `Observables` workflow, this is explained in more detail in the \myreflink{Observables & Interaction} section.

If you want to create animated movies, you can find more information in the \myreflink{Animations} section.
