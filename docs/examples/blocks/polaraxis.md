# PolarAxis

The `PolarAxis` is an axis for data in polar coordinates `(radius, angle)`. It 
is currently an experimental feature, meaning that some functionality might be
missing or broken, and that the `PolarAxis` is (more) open to breaking changes.

## Creating a PolarAxis

Creating a `PolarAxis` works the same way as creating an `Axis`.

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide

f = Figure()

ax = PolarAxis(f[1, 1], title = "Title")

f
```
\end{examplefigure}

## Plotting into an PolarAxis

Like with an `Axis` you can use mutating 2D plot functions directly on a 
`PolarAxis`. The input arguments of the plot functions will then be interpreted
in polar coordinates, i.e. as a radius and angle (in radians).

\begin{examplefigure}{svg = true}
```julia
lineobject = lines!(ax, 0..10, sin, color = :red)
scatobject = scatter!(0:0.5:10, cos, color = :orange)

f
```
\end{examplefigure}

Note that not every plot type is compatible with polar transforms. For example 
`image` is not as it expects to be drawn on a rectangle. `heatmap` works to a 
degree in CairoMakie, but not GLMakie due to differences in the backend 
implementation. `surface` works in both, as it is designed to generate a 
triangle mesh.

\begin{examplefigure}{svg = false}
```julia
f = Figure()
ax = PolarAxis(f[1, 1])
# The first two arguments should be set to a sensible radial and angular range
zs = [r*cos(phi) for r in range(1, 2, length=100), phi in range(0, 4pi, length=100)]
p = surface!(ax, 0..10, 0..2pi, zs, shading = false, colormap = :coolwarm, colorrange=(-2, 2))
Colorbar(f[1, 2], p)
f
```
\end{examplefigure}

## Hiding spines and decorations

For a `PolarAxis` we interpret the outer ring limitting the plotting are as the
axis spine. You can manipulate it with the `spine...` attributes.

\begin{examplefigure}{svg = true}
```julia
f = Figure(resolution = (800, 400))
ax1 = PolarAxis(f[1, 1], title = "No spine", spinevisible = false)
scatterlines!(ax1, range(0, 1, length=100), range(0, 10pi, length=100), color = 1:100)

ax2 = PolarAxis(f[1, 2], title = "Modified spine")
ax2.spinecolor[] = :red
ax2.spinestyle[] = :dash
ax2.spinewidth[] = 5
scatterlines!(ax2, range(0, 1, length=100), range(0, 10pi, length=100), color = 1:100)

f
```
\end{examplefigure}

Decorations such as grid lines and tick labels can be adjusted through 
attributes in much the same way.

\begin{examplefigure}{svg = true}
```julia
f = Figure(resolution = (600, 600), backgroundcolor = :black)
ax = PolarAxis(
    f[1, 1], 
    backgroundcolor = :black,
    # r minor grid
    rminorgridvisible = true, rminorgridcolor = :red, 
    rminorgridwidth = 1.0, rminorgridstyle = :dash,
    # theta minor grid
    thetaminorgridvisible = true, thetaminorgridcolor = :lightblue,
    thetaminorgridwidth = 1.0, thetaminorgridstyle = :dash,
    # major grid
    rgridwidth = 2, rgridcolor = :red,
    thetagridwidth = 2, thetagridcolor = :lightblue,
    # r labels
    rticklabelsize = 18, rticklabelcolor = :red,
    rticklabelstrokewidth = 1.0, rticklabelstrokecolor = :white,
    # theta labels
    thetaticklabelsize = 18, thetaticklabelcolor = :lightblue
)

f
```
\end{examplefigure}

## Interactivity

The `PolarAxis` currently implements zooming by scrolling and allows you to 
reset the view with left control + left mouse button. You can change the key
combination for resetting the view with the `reset_button` attribute, which 
accepts anything `ispressed` accepts.

Note that `PolarAxis` currently does not implement the interaction itnerface 
used by `Axis`.

## Other Notes

### Plotting outside a PolarAxis

Currently there is a scatter and poly plot outside the area of the `PolarAxis`
which clips the content to the relevant area. If you want to draw outside the
circle limiting the polar axis but still within it's scene area, you will need
to translate those plots to a z range between `9000` and `10_000` or disable 
clipping via the `clip` attribute.

## Attributes

\attrdocs{PolarAxis}
