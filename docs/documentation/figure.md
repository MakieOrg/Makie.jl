# Figures

The `Figure` object contains a top-level `Scene` and a `GridLayout`, as well as a list of blocks that have been placed into it, like `Axis`, `Colorbar`, `Slider`, `Legend`, etc.


## Creating a Figure

You can create a figure explicitly with the `Figure()` function, and set attributes of the underlying scene.
The most important one of which is the `resolution`.

```julia
f = Figure()
f = Figure(resolution = (600, 400))
```

A figure is also created implicitly when you use simple, non-mutating plotting commands like `plot()`, `scatter()`, `lines()`, etc.
Because these commands also create an axis for the plot to live in and the plot itself, they return a compound object `FigureAxisPlot`, which just stores these three parts.
To access the figure you can either destructure that object into its three parts or access the figure field directly.

```julia
figureaxisplot = scatter(rand(100, 2))
figure = figureaxisplot.figure

# destructuring syntax
figure, axis, plot = scatter(rand(100, 2))

# you can also ignore components
figure, = scatter(rand(100, 2))
```

You can pass arguments to the created figure in a dict-like object to the special `figure` keyword:

```julia
scatter(rand(100, 2), figure = (resolution = (600, 400),))
```

## Placing Blocks into a Figure

All Blocks take their parent figure as the first argument, then you can place them in the figure layout via indexing syntax.

```julia
f = Figure()
ax = f[1, 1] = Axis(f)
sl = f[2, 1] = Slider(f)
```

## GridPositions and GridSubpositions

The indexing syntax of `Figure` is implemented to work seamlessly with layouting.
If you index into the figure, a `GridPosition` object that stores this indexing operation is created.
This object can be used to plot a new axis into a certain layout position in the figure, for example like this:

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide

f = Figure()
pos = f[1, 1]
scatter(pos, rand(100, 2))

pos2 = f[1, 2]
lines(pos2, cumsum(randn(100)))

# you don't have to store the position in a variable first, of course
heatmap(f[1, 3], randn(10, 10))

f
```
\end{examplefigure}


You can also index further into a `GridPosition`, which creates a `GridSubposition`.
With `GridSubposition`s you can describe positions in arbitrarily nested grid layouts.
Often, a desired plot layout can only be achieved with nesting, and repeatedly indexing makes this easy.

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide

f = Figure()

f[1, 1] = Axis(f, title = "I'm not nested")
f[1, 2][1, 1] = Axis(f, title = "I'm nested")

# plotting into nested positions also works
heatmap(f[1, 2][2, 1], randn(20, 20))

f
```
\end{examplefigure}


All nested GridLayouts that don't exist yet, but are needed for a nested plotting call, are created in the background automatically.

!!! note
    The `GridLayout`s that are implicitly created when using `GridSubpositions` are not directly available in the return
    value for further manipulation. You can instead retrieve them after the fact with the `content` function, for example,
    as explained in the following section.


## Figure padding

You can change the amount of whitespace around the figure content with the keyword `figure_padding`.
This takes either a number for all four sides, or a tuple of four numbers for left, right, bottom, top.
You can also theme this setting with `set_theme!(figure_padding = 30)`, for example.

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide

f = Figure(figure_padding = 1, backgroundcolor = :gray80)

Axis(f[1, 1])
scatter!(1:10)

f
```
\end{examplefigure}

## Retrieving Objects From A Figure

Sometimes users are surprised that indexing into a figure does not retrieve the object placed at that position.
This is because the `GridPosition` is needed for plotting, and returning content objects directly would take away that possibility.
Furthermore, a `GridLayout` can hold multiple objects at the same position, or have partially overlapping content,
so it's not well-defined what should be returned given a certain index.

To retrieve objects from a Figure you can instead use indexing plus the `contents` or `content` functions.
The `contents` function returns a Vector of all objects found at the given `GridPosition`.
You can use the `exact = true` keyword argument so that the position has to match exactly, otherwise objects
contained in that position are also returned.

```julia
f = Figure()
box = f[1:3, 1:2] = Box(f)
ax = f[1, 1] = Axis(f)

contents(f[1, 1]) == [ax]
contents(f[1:3, 1:2]) == [box, ax]
contents(f[1:3, 1:2], exact = true) == [box]
```

If you use `contents` on a `GridSubposition`, the `exact` keyword only refers to the lowest-level
grid layout, all upper levels have to match exactly.

```julia
f = Figure()
ax = f[1, 1][2, 3] = Axis(f)

contents(f[1, 1][2, 3]) == [ax]
contents(f[1:2, 1:2][2, 3]) == [] # the upper level has to match exactly
```

Often, you will expect only one object at a certain position and you want to work directly with it, without
retrieving it from the Vector returned by `contents`.
In that case, use the `content` function instead.
It works equivalently to `only(contents(pos, exact = true))`, so it errors if it can't return exactly one object
from an exact given position.

```julia
f = Figure()
ax = f[1, 1] = Axis(f)

contents(f[1, 1]) == [ax]
content(f[1, 1]) == ax
```

## Figure size

The size or resolution of a Figure is given without units, such as `resolution = (800, 600)`.
You can think of these values as "device-independent pixels".
Like the `px` unit in CSS, these values do not directly correspond to physical pixels of your screen or pixels in a png file.
Instead, they can be mapped to these device pixels using a scaling factor.

Currently, these scaling factors are only directly supported by CairoMakie, but in the future they should be available for GLMakie and WGLMakie as well.
Right now, the implicit scaling factor of GLMakie and WGLMakie is 1, which means that a window of a figure with resolution 800 x 600 will actually have 800 x 600 pixels in its frame buffer.
In the future, this should be adjustable, for example for "retina" or high-dpi displays, where the frame buffer for a 800 x 600 window typically has 1600 x 1200 pixels.

## Matching figure and font sizes to documents

Journal papers and other documents written in Word or LaTeX commonly use the `pt` unit to define font sizes.
The unit `pt` is a physical dimension and is typically defined as `1 inch / 72`.
To match font sizes of Makie plots with other text in these documents, you have to adjust both the figure size and font size together.

First, you need to convert the physical target size of your figure in the document to device-independent pixels.
For this, you have to decide a `px_per_unit` value if you're exporting a bitmap, or a `pt_per_unit` value if you export vector graphics.
With those, you can convert the target font size into device-independent pixels as well.

CairoMakie is the only backend that can export both bitmaps and vector graphics.
By default, its `px_per_unit` is `2` and `pt_per_unit` is `0.75`, but those values are chosen with interactive plotting with web-technology tools in mind.
The reason is that in normal web browsers, `1px` is equal to `0.75pt` and images with a density of 2 pixels for each device-independent `px` look sharper on modern high-dpi displays.
The default fontsize of `16` will by default look like `12pt` in web and print contexts this way.

### Example

Let's say we want to create a vector graphic for a scientific paper set with 12pt font size, and the figure size should be 5 x 4 inches which is equivalent to 360 x 288 pt (multiply by 72).

With the default `pt_per_unit = 0.75` we arrive at a necessary figure size of 480 x 384 device-independent pixels (divide by 0.75).

Equivalently, the font size we need to match 12pt is `12 / 0.75 = 16`.

Therefore, we can create our figure with `Figure(resolution = (480, 384), fontsize = 16)` and save with `save("figure.pdf", fig)`.

Let's say we now decide that our figure is too large in vector format, because it has a million scatter points, so we want to switch to bitmap format.

We keep our figure with its resolution and font size as it is.
The question is now only, how high should our dpi be.
With CairoMakie's default of `px_per_unit = 2`, we would get a pixel size of 960 x 768` for our image, if we divide that by 5 x 4 inches we get a dpi of 192.

Let's say this is not sharp enough for our purposes and we want to bump to 600 dpi.
The necessary pixel size of the image is 3000 x 2400.
With our figure size of 480 x 386 device-independent pixels, that gives a `px_per_unit` value of 6.25 to reach 600 dpi.
Note that we do not have to change anything about the font or other content sizes in the figure, we just scale up the render size.
We only need to run `save("figure.png", fig, px_per_unit = 6.25)` and take care to insert the image with the correct size of 5 x 4 inches, as image files usually don't store what physical size they are intended to be.

!!! note
    If you keep the intended physical size of an image constant and increase the dpi by increasing `px_per_unit`, the size of text and other content relative to the figure will stay constant.
    However, if you instead try to increase the dpi by increasing the Figure size itself, the relative size of text and other content will shrink when viewed at the same physical size.
    The first option is usually much more convenient, as it keeps the look and layout of the overall figure exactly the same, just with higher resolution.