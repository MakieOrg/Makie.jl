# Basic Tutorial

## Preface

Here is a quick tutorial to get you started with Makie!

Makie is the name of the whole plotting ecosystem and `Makie.jl` is the main package that describes how plots work.
To actually render and save plots, we need a backend that knows how to translate plots into images or vector graphics.

There are three main backends which you can use to render plots (for more information, have a look at \myreflink{Backends}):

- `CairoMakie.jl` if you want to render vector graphics or high quality 2D images and don't need interactivity or true 3D rendering.
- `GLMakie.jl` if you need interactive windows and true 3D rendering but no vector output.
- Or `WGLMakie.jl` which is similar to `GLMakie` but works in web browsers, not native windows.

This tutorial uses CairoMakie, but the code can be executed with any backend.
Note that CairoMakie can _create_ images but it cannot _display_ them.

To see the output of plotting commands when using CairoMakie, we recommend you either use an IDE which supports png or svg output, such as VSCode, Atom/Juno, Jupyter, Pluto, etc., or try using a viewer package such as [ElectronDisplay.jl](https://github.com/queryverse/ElectronDisplay.jl), or alternatively save your plots to files directly.
The Julia REPL by itself does not have the ability to show the plots.

Ok, now that this is out of the way, let's get started!

## Importing

First, we import CairoMakie. This makes all the exported symbols from `Makie.jl` available as well.

```julia:setup
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide
nothing # hide
```

## An empty figure

The basic container object in Makie is the \apilink{Figure}.
It is a canvas onto which we can add objects like axes and colorbars.

Let's create one and give it a background color so we can see something.
Returning a `Figure` from an expression will `display` it if your coding environment can show images.

\begin{examplefigure}{svg = true}
```julia
f = Figure(backgroundcolor = :tomato)
```
\end{examplefigure}

Another common thing to do is to give a figure a different size or resolution.
The default is 800x600, let's try halving the height:

\begin{examplefigure}{svg = true}
```julia
f = Figure(backgroundcolor = :tomato, resolution = (800, 300))
```
\end{examplefigure}

## Adding an Axis

The most common object you can add to a figure which you need for most plotting is the [Axis](\reflink{Axis}).
The usual syntax for adding such an object to a figure is to specify a position in the `Figure`'s layout as the first argument.
We'll learn more about layouts later, but for now the position `f[1, 1]` will just fill the whole figure.

\begin{examplefigure}{svg = true}
```julia
f = Figure()
ax = Axis(f[1, 1])
f
```
\end{examplefigure}

The default axis has no title or labels, you can pass those as keyword arguments.
For a whole list of available attributes, check the docstring for \apilink{Axis} (you can also do that by running `?Axis` in the REPL).
Be warned, it's very long!

\begin{examplefigure}{svg = true}
```julia
f = Figure()
ax = Axis(f[1, 1],
    title = "A Makie Axis",
    xlabel = "The x label",
    ylabel = "The y label"
)
f
```
\end{examplefigure}

Now we're ready to actually plot something!

## First line plot

Makie has many different plotting functions, the first we will learn about is \myreflink{lines}.
Let's try plotting a sine function:

\begin{examplefigure}{svg = true}
```julia
x = range(0, 10, length=100)
y = sin.(x)
lines(x, y)
```
\end{examplefigure}

There we have our first line plot, that was easy.

The return type of `lines(x, y)` is `FigureAxisPlot`.
You remember that we looked at making a `Figure` and an `Axis` first.
The `lines` function first creates a `Figure`, then puts an `Axis` into it and finally adds plot of type `Lines` to that axis.

Because these three objects are created at once, the function returns all three, just bundled up into one `FigureAxisPlot` object.
That's just so we can overload the `display` behavior for that type to match `Figure`.
Normally, multiple return values are returned as `Tuple`s in Julia but it's uncommon to overload `display` for `Tuple` types.

If you need the objects, for example to add more things to the figure later and edit axis and plot attributes, you can destructure the return value:

\begin{examplefigure}{svg = true}
```julia
figure, axis, lineplot = lines(x, y)
figure
```
\end{examplefigure}

As you can see, the output of returning the extracted figure is the same.

## Scatter plot

Another common function is \myreflink{scatter}.
It works very similar to `lines` but shows separate markers for each input point.

\begin{examplefigure}{svg = true}
```julia
x = range(0, 10, length=100)
y = sin.(x)
scatter(x, y)
```
\end{examplefigure}

## Passing Figure and Axis styles

You might wonder how to specify a different resolution for this scatter plot, or set an axis title and labels.
Because a normal plotting function like `lines` or `scatter` creates these objects before it creates the plot, you can pass special keyword arguments to it called `axis` and `figure`.
You can pass any kind of object with symbol-value pairs and these will be used as keyword arguments for `Figure` and `Axis`, respectively.

\begin{examplefigure}{svg = true}
```julia
x = range(0, 10, length=100)
y = sin.(x)
scatter(x, y;
    figure = (; resolution = (400, 400)),
    axis = (; title = "Scatter plot", xlabel = "x label")
)
```
\end{examplefigure}

The `;` in `(; resolution = (400, 400))` is nothing special, it just clarifies that we want a one-element `NamedTuple` and not a variable called `resolution`.
It's good habit to include it but it's not needed for `NamedTuple`s with more than one entry.

## Argument conversions

So far we have called `lines` and `scatter` with `x` and `y` arguments, where `x` was a range object and `y` vector of numbers.
Most plotting functions have different options how you can call them.
The input arguments are converted internally to one or more target representations that can be handled by the rendering backends.

Here are a few different examples of what you can use with `lines`:

An interval and a function:

\begin{examplefigure}{svg = true}
```julia
lines(0..10, sin)
```
\end{examplefigure}

A collection of numbers and a function:

\begin{examplefigure}{svg = true}
```julia
lines(0:1:10, cos)
```
\end{examplefigure}

A collection of `Point`s from `GeometryBasics.jl` (which supplies most geometric primitives in Makie):

\begin{examplefigure}{svg = true}
```julia
lines([Point(0, 0), Point(5, 10), Point(10, 5)])
```
\end{examplefigure}

The input arguments you can use with `lines` and `scatter` are mostly the same because they have the same conversion trait `PointBased`.
Other plotting functions have different conversion traits, \myreflink{heatmap} for example expects two-dimensional grid data.
The respective trait is called `DiscreteSurface`.

## Layering multiple plots

Every plotting function has a version with and one without `!` at the end.
For example, there's `scatter` and `scatter!`, `lines` and `lines!`, etc.

The functions without a `!` like `lines` and `scatter` always create a new axis with a plot inside.

The functions with `!` like `lines!` and `scatter!` mutate (plot into) an already existing axis.
Having functions ending with `!` that mutate one of their arguments is a common Julia convention.

To plot two things into the same axis, you can use the mutating plotting functions.
For example, here's how you could plot two lines on top of each other:

\begin{examplefigure}{svg = true}
```julia
x = range(0, 10, length=100)

f, ax, l1 = lines(x, sin)
l2 = lines!(ax, x, cos)
f
```
\end{examplefigure}

The second `lines!` call plots into the axis created by the first `lines` call.
It's colored differently because the `Axis` keeps track of what has been plotted into it and cycles colors for similar plotting functions.

You can also leave out the axis argument for convenience, then the axis being used is the `current_axis()`.
\begin{examplefigure}{svg = true}
```julia
x = range(0, 10, length=100)

f, ax, l1 = lines(x, sin)
lines!(x, cos)
f
```
\end{examplefigure}

Note that you cannot pass `figure` and `axis` keywords to mutating plotting functions like `lines!` or `scatter!`.
That's because they don't create an `Figure` and `Axis`, and we chose not to allow modification of the existing objects in plotting calls so it's clearer what is going on.

## Attributes

Every plotting function has attributes which you can set through keyword arguments.
The lines in the previous example have colors from Makie's default palette, but we can easily specify our own.

There are multiple ways you can specify colors, but common ones are:

- By name, like `:red` or `"red"`
- By hex string, like `"#ffccbk"`
- With color types like the Makie-exported `RGBf(0.5, 0, 0.6)` or `RGBAf(0.3, 0.8, 0.2, 0.8)`
- As a tuple where the first part is a color and the second an alpha value to make it transparent, like `(:red, 0.5)`

You can read more about colors at [juliagraphics.github.io/Colors.jl](https://juliagraphics.github.io/Colors.jl).

Here's a plot with one named color and one where we use `RGBf`:

\begin{examplefigure}{svg = true}
```julia
x = range(0, 10, length=100)

f, ax, l1 = lines(x, sin, color = :tomato)
l2 = lines!(ax, x, cos, color = RGBf(0.2, 0.7, 0.9))
f
```
\end{examplefigure}

Other plotting functions have different attributes.
The function `scatter`, for example, does not only have the `color` attribute, but also a `markersize` attribute.

You can read about all possible attributes by running `?scatter` in the REPL, and examples are shown on the page \myreflink{scatter}.

\begin{examplefigure}{svg = true}
```julia
x = range(0, 10, length=100)

f, ax, sc1 = scatter(x, sin, color = :red, markersize = 5)
sc2 = scatter!(ax, x, cos, color = :blue, markersize = 10)
f
```
\end{examplefigure}

You can also manipulate most plot attributes afterwards with the syntax `plot.attribute = new_value`.

\begin{examplefigure}{svg = true}
```julia
sc1.marker = :utriangle
sc1.markersize = 20

sc2.color = :transparent
sc2.markersize = 20
sc2.strokewidth = 1
sc2.strokecolor = :purple

f
```
\end{examplefigure}

## Array attributes

A lot of attributes can be set to either a single value or an array with as many elements as there are data points.
For example, it is usually much more performant to draw many points with one scatter object, than to create many scatter objects with one point each.

Here, we vary markersize and color:

\begin{examplefigure}{svg = true}
```julia
x = range(0, 10, length=100)

scatter(x, sin,
    markersize = range(5, 15, length=100),
    color = range(0, 1, length=100),
    colormap = :thermal
)
```
\end{examplefigure}

Note that the color array does not actually contain colors, rather the numerical values are mapped to the plot's `colormap`.
There are many different colormaps to choose from, take a look on the \myreflink{Colors} page.

The values are mapped to colors via the `colorrange` attribute, which by default goes from the minimum to the maximum color value.
But we can also limit or expand the range manually.
For example, we can constrain the previous scatter plot's color range to (0.33, 0.66), which will clip the colors at the bottom and the top.

\begin{examplefigure}{svg = true}
```julia
x = range(0, 10, length=100)

scatter(x, sin,
    markersize = range(5, 15, length=100),
    color = range(0, 1, length=100),
    colormap = :thermal,
    colorrange = (0.33, 0.66)
)
```
\end{examplefigure}

Of course you can also use an array of colors directly, in which case the `colorrange` is ignored:

\begin{examplefigure}{svg = true}
```julia

using CairoMakie

x = range(0, 10, length=100)

colors = repeat([:crimson, :dodgerblue, :slateblue1, :sienna1, :orchid1], 20)

scatter(x, sin, color = colors, markersize = 20)
```
\end{examplefigure}

## Simple legend

If you add label attributes to your plots, you can call the `axislegend` function to add a legend with all labeled plots to the current axis, or optionally to one you pass as the first argument.

\begin{examplefigure}{svg = true}
```julia

using CairoMakie

x = range(0, 10, length=100)

lines(x, sin, color = :red, label = "sin")
lines!(x, cos, color = :blue, label = "cos")
axislegend()
current_figure()
```
\end{examplefigure}

## Subplots

Makie uses a powerful layout system under the hood, which allows you to create very complex figures with many subplots.
So far, we have only used the default position [1, 1], where the Axis is created in a standard plotting call.

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

We can also create a couple of axes manually at first and then plot into them later.
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

## Next steps

We've only looked at a small subset of Makie's functionality here.

You can read about the different available plotting functions with examples in the \myreflink{Plotting Functions} section.

If you want to learn about making complex figures with nested sublayouts, have a look at the \myreflink{Layout Tutorial} section.

If you're interested in creating interactive visualizations that use Makie's special `Observables` workflow, this is explained in more detail in the \myreflink{Observables & Interaction} section.

If you want to create animated movies, you can find more information in the \myreflink{Animations} section.
