# Figures

The `Figure` object contains a top-level `Scene` and a `GridLayout`, as well as a list of blocks that have been placed into it, like `Axis`, `Colorbar`, `Slider`, `Legend`, etc.


## Creating a Figure

You can create a figure explicitly with the `Figure()` function, and set attributes of the underlying scene.
The most important one of which is the `size`.

```julia
f = Figure()
f = Figure(size = (600, 400))
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
scatter(rand(100, 2), figure = (size = (600, 400),))
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

```@figure
f = Figure()
pos = f[1, 1]
scatter(pos, rand(100, 2))

pos2 = f[1, 2]
lines(pos2, cumsum(randn(100)))

# you don't have to store the position in a variable first, of course
heatmap(f[1, 3], randn(10, 10))

f
```


You can also index further into a `GridPosition`, which creates a `GridSubposition`.
With `GridSubposition`s you can describe positions in arbitrarily nested grid layouts.
Often, a desired plot layout can only be achieved with nesting, and repeatedly indexing makes this easy.

```@figure
f = Figure()

f[1, 1] = Axis(f, title = "I'm not nested")
f[1, 2][1, 1] = Axis(f, title = "I'm nested")

# plotting into nested positions also works
heatmap(f[1, 2][2, 1], randn(20, 20))

f
```


All nested GridLayouts that don't exist yet, but are needed for a nested plotting call, are created in the background automatically.

!!! note
    The `GridLayout`s that are implicitly created when using `GridSubpositions` are not directly available in the return
    value for further manipulation. You can instead retrieve them after the fact with the `content` function, for example,
    as explained in the following section.


## Figure padding

You can change the amount of whitespace (margin) around the figure content with the keyword `figure_padding`.
This takes either a number for all four sides, or a tuple of four numbers for left, right, bottom, top.
You can also theme this setting with `set_theme!(figure_padding = 30)`, for example.

```@figure
f = Figure(figure_padding = 1, backgroundcolor = :gray80)

Axis(f[1, 1])
scatter!(1:10)

f
```

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

## Figure size and units

In Makie, figure size and attributes like line widths, font sizes, scatter marker extents, or layout column and row gaps are usually given as plain numbers, without an explicit unit attached.
What does it mean to have a `Figure` with `size = (600, 450)`, a line with `linewidth = 10` or a column gap of `30`?

The first underlying idea is that, no matter what your final output format is, these numbers are _relative_.
You can expect a `linewidth = 10` to cover 1/60th of the width `600` of the `Figure` and a column gap of `30` to span 1/20th of the Figure.
This holds, no matter if you later export that `Figure` as an image made out of pixels, or as a vector graphic that doesn't have pixels at all.

The second idea is that, given some `Figure`, we want to be able to export an image at arbitrary resolution, or a vector graphic at any size from it, as long as the relative sizes of all elements stay intact.
So we need to _translate_ our abstract sizes to real sizes when we render.
In Makie, this is done with two scaling factors: `px_per_unit` for images and `pt_per_unit` for vector graphics.

A line with `linewidth = 10` will be 10 pixels wide if rendered to an image file with `px_per_unit = 1`. It will be 5 pixels wide if `px_per_unit = 0.5` and 20 pixels if `px_per_unit = 2`. A `Figure` with `size = (600, 450)` will have 600 x 450 pixels when exported with `px_per_unit = 1`, 300 x 225 with `px_per_unit = 0.5` and 1200 x 900 with `px_per_unit = 2`.

It works exactly the same for vector graphics, just with a different target unit. A `pt` or point is a typographic unit that is defined as 1/72 of an inch, which comes out to about 0.353 mm. A line with `linewidth = 10` will be 10 points wide if rendered to an svg file with `pt_per_unit = 1`, it will be 5 points wide for `pt_per_unit = 0.5` and 20 points wide if `pt_per_unit = 2`. A `Figure` with `size = (600, 450)` will be 600 x 450 points in size when exported with `pt_per_unit = 1`, 300 x 225 with `pt_per_unit = 0.5` and 1200 x 900 with `pt_per_unit = 2`.

### Defaults of `px_per_unit` and `pt_per_unit`

What are the default values of `px_per_unit` and `pt_per_unit` in each Makie backend, and why are they set that way?

Let us start with `pt_per_unit` because this value is only relevant for one backend, which is CairoMakie.
The default value in CairoMakie is `pt_per_unit = 0.75`. So if you `save("output.svg", figure)` a `Figure` with `size = (600, 450)`, this comes out as a vector graphic that is 450 x 337.5 pt large.

Why 0.75 and not simply 1? This has to do with web standards and device-independent pixels. Websites mix vector graphics and images, so they need some way to relate the sizes of both types to each other. In principle, a pixel in an image doesn't have a real-world width. But you don't want the images on your site to shrink relative to the other content when device pixels are small, or grow when device pixels are large. So web browsers don't directly map image pixels to device pixels. Instead, they use a concept called device-independent pixels. If you place an image with 600 x 450 pixels in a website, this image is interpreted by default to be 600 x 450 device-independent pixels wide. One device-independent pixel is defined to be 0.75 pt wide, that's where the factor 0.75 comes in. So an image with 600 x 450 device-independent pixels is the same apparent size as a vector graphic with size 450 x 337.5 pt. On high-resolution screens, browsers then simply render one device-independent pixel with multiple device pixels (for example 2x2 on an Apple Retina display) so that content stays at readable sizes and doesn't look tiny.

For Makie, we decided that we want our abstract units to match device-independent pixels when used in web contexts, because that's very convenient and easy to predict for the end user. If you have a Jupyter or Pluto notebook, it's nice if a `Figure` comes out at the same apparent size, no matter if you're currently in CairoMakie's svg mode, or in the bitmap mode of any backend. Therefore, we annotate images with the original `Figure` size in device-independent pixels, so they are of the same apparent size, no matter what the `px_per_unit` value and therefore the effective pixel size is. And we give svg files the default scaling factor of 0.75 so that svgs always match images in apparent size.

Now let us look at the default values for `px_per_unit`. In CairoMakie, the default is `px_per_unit = 2`. This means, a `Figure` with `size = (600, 450)` will be rendered as a 1200 x 900 pixel image. The reason it isn't `px_per_unit = 1` is that CairoMakie plots are often embedded in notebooks or websites, or looked at in image viewers or IDEs like VSCode. On websites, you don't know in advance what the pixel density of a reader's display is going to be. And in image viewers and IDEs, people like to zoom in to look at details. To cover these use cases by default, we decided `px_per_unit = 2` is a good compromise between sharp resolution and appropriate file size. Again, the _apparent_ size of output images in notebooks and websites (wherever the `MIME"text/html"` type is used) depends only on the `size`, because the output images are embedded with `<img width=$(size[1]) height=$(size[2])` no matter what value `px_per_unit` has.

In GLMakie, the default behavior is different. Because GLMakie doesn't just produce images, but renders `Figure`s in interactive native windows, website or image viewer considerations don't apply. If a window covers 600 x 450 pixels of the screen it's displayed on, you want to render your `Figure` at exactly 600 x 450 pixels resolution. More, and you waste computation time, less, and your image becomes blurry. That doesn't mean however, that `px_per_unit` is always 1. Rather, `px_per_unit` automatically adjusts to the scale value of the screen that the window rendering the `Figure` is currently on. The scale value for a screen is set by the OS. On a high-dpi screen like a MacBook which has a scale factor of 2, a `Figure` of `size = (600, 450)` will be rendered with `px_per_unit = 2` to exactly cover the window's render buffer of size 1200 x 900 pixels. If you place this screen next to a regular monitor of the same physical size but with half the resolution, this monitor should have the scale factor 1 assigned to it by the OS, so that text has the same size on both of them (just sharper on the high-dpi screen). So the same `Figure` displayed on that monitor will automatically switch to `px_per_unit = 1` and therefore fill a window buffer of 600 x 450 pixels. You should never have to directly change `px_per_unit` for a window that is being displayed on a screen. However, you can still increase `px_per_unit` when saving images, so that your rendered outputs have a higher pixel count for embedding in websites or documents.

### Matching figure and font sizes to documents

Academic journals usually demand that figures you submit adhere to specific physical dimensions.
How can you render Makie figures at exactly the right sizes?

First, let's look at vector graphics, which are usually desired for documents because they have the best text and line rendering quality at any zoom level. The output unit of vector graphics is always `pt` in CairoMakie. You can convert to points from inches via `1 in == 72 pt` and from centimeters via `1 cm = 28.3465 pt`.

Let's say your desired output size is 5 x 4 inches and you should use a font size of 12 pt. You multiply 5 x 4 by 72 to get 360 x 288 pt. The size you need to set on your `Figure` depends on the `pt_per_unit` value you want to use. When making plots for publications, you should usually just save with `pt_per_unit = 1`. So in our example, we would use `Figure(size = (360, 288))` and for text set `fontsize = 12` to match the 12 pt requirement.

Pixel images, on the other hand, have no inherent physical size. You can stretch any pixel image over any area in a document that you want, it will just be more or less sharp. If you want to render pixel images, you therefore have to consider what pixel density the journal demands. Usually, this value is given as dots per inch or `dpi` which is often used interchangeably with pixels per inch or `ppi`. Let's say we already have the `Figure` from our previous example with `size = (360, 288)` and `fontsize = 12`, but we want to save it as a pixel image for a target dpi or ppi of 600. We can calculate `(5, 4) inch .* (600 px / inch) ./ (360, 288)`. We only have to do it for one side because our pixels are square, so `5 * 600 / 360 == 8.3333`. That means the final image saved with `px_per_unit = 8.3333` has a size of 3000 x 2400 px, which is exactly 600 dpi when placed at a size of 5 x 4 inches.

We could of course have set up the `Figure` with `size = (3000, 2400)` and then saved with `px_per_unit = 1` to reach the same final size. Then, however, we would have had to calculate the fontsize that would have ended up to match 12 pt at this pixel density. Usually, when preparing figures for journals, it's easiest to use `pt` as the base unit and set everything up for saving with `pt_per_unit = 1` which makes font sizes and line widths trivial to understand for a reader of the code.

!!! note
    If you keep the intended physical size of an image constant and increase the dpi by increasing `px_per_unit`, the size of text and other content relative to the figure will stay constant.
    However, if you instead try to increase the dpi by increasing the Figure size itself, the relative size of text and other content will shrink.
    The first option is usually much more convenient, as it keeps the look and layout of the overall figure exactly the same, just with higher resolution.
