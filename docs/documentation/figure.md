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
Right now, the implicit scaling factor of GLMakie and WGLMakie is 1, which means that a window of a figure with resolution 800x600 will actually have 800x600 pixels.
In the future, this should be adjustable, for example for "retina" or high-dpi displays, where the frame buffer for a 800x600 window typically has 1600x1200 pixels.

### Physical dimensions

Device-independent pixels do not have a fixed mapping to physical measurements like centimeters or inches.
If you need a bitmap file at a size of 6 x 4 inches, you will have to decide how many dpi, or dots per inch, you want.
Typical values for printing are 300 to 600 dpi.

In CairoMakie, you can adjust the `px_per_unit` attribute to decide how many output pixels per device-independent pixel you want to render.
The default value is 2, which means that image output should look sharp on typical high-dpi displays.

Here is a table that shows how to set your Figure's resolution depending on what `px_per_unit` value you choose.

| Physical size | DPI | resolution in dots | `px_per_unit` | Figure size |
|:--|:--|:--|:--|:--|
| 4 x 3 inches | 300 | 1200 x 900 | 1 | 1200 x 900 |
|   |   |  | 2 | 600 x 450 |
|   |   |  | 3 | 600 x 450 |
| 4 x 3 inches | 600 | 2400 x 1800 | 1 | 2400 x 1800 |
|   |   |  | 2 | 1200 x 900 |
|   |   |  | 3 | 800 x 600 |


If you keep the physical size constant and increase the dpi by increasing `px_per_unit`, the relative size of text and other content will stay constant.
However, if you keep the physical size constant and increase the dpi by increasing the Figure size, the relative size of text and other content will shrink.

#### Matching font sizes

If you need a font size of `12pt` in your final output, you need to control this with the combination of `fontsize` and `px_per_unit` for bitmaps, or `pt_per_unit` for vector graphics.
The unit `pt` is a physical dimension and is typically defined as `1 inch / 72`.

By default, `px_per_unit` is 2 and `pt_per_unit` is 0.75.
This is because in CSS, `1px` is equal to `0.75pt` and images with a density of 2 pixels for each `px` look sharper on modern high-density displays.
The default fontsize of `16` will by default look like `12pt` in web and print contexts this way.

The following table shows you how to set your font size and scaling factor to achieve a consistent output font size.

| Desired fontsize in pt | fontsize value | desired dpi | `px_per_unit` | `pt_per_unit` |
|:--|:--|:--|:--|:--|
| 12 | 12 | 72 | 1 | |
| 12 | 12 | 144 | 2 | |
| 12 | 12 | 600 | 8.33 | |
| 12 | 24 | 72 | 0.5 | |
| 12 | 24 | 144 | 1 | |
| 12 | 24 | 600 | 4.16 | |
| 12 | 12 | | | 1 |
| 12 | 16 | | | 0.75 |
| 12 | 24 | | | 0.5 |

If you want to set up a Figure such that you can either save it as a vector graphic or bitmap, it's easiest if you use device-independent pixels with the CSS-like conversion ratio of 0.75 to `pt`, and then set `pt_per_unit` and `px_per_unit` accordingly.
For example, let's say you need a font size of `12pt`, which is `16dip`.

```julia
using CairoMakie

size_inches = (4, 3)
size_dip = size_inches .* 72 / 0.75 # 
f = Figure(resolution = size_dip, fontsize = 16)
save("figure.pdf", f, pt_per_unit = 0.75)
dpi = 400
save("figure.png", f, px_per_unit = dpi / 72 * 0.75)
```

If you export only vector graphics, you can of course set `pt_per_unit = 1` and use `fontsize = 12` directly, however this will currently not look as nice when switching back and forth to GLMakie with its implicit `px_per_unit = 1`.