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
implementation.
`surface` can be used as a replacement for `image` as it generates a triangle
mesh. However it also has a component in z-direction which will affect drawing
order. You can use `translate!(plot, 0, 0, z_shift)` to work around that.
As a replacement for `heatmap` you can use `voronoiplot`, which generates cells
of arbitrary shape around points given to it. Here you will generally need to
set `rlims!(ax, rmax)` yourself.

\begin{examplefigure}{svg = false}
```julia
f = Figure(resolution = (800, 500))

ax = PolarAxis(f[1, 1], title = "Surface")
rs = 0:10
phis = range(0, 2pi, 37)
cs = [r+cos(4phi) for r in rs, phi in phis]
p = surface!(ax, 0..10, 0..2pi, cs, shading = false, colormap = :coolwarm)
Colorbar(f[2, 1], p, vertical = false, flipaxis = false)

ax = PolarAxis(f[1, 2], title = "Voronoi")
rs = 1:10
phis = range(0, 2pi, 37)[1:36]
cs = [r+cos(4phi) for r in rs, phi in phis]
p = voronoiplot!(ax, rs, phis, cs, show_generators = false, strokewidth = 0)
Makie.rlims!(ax, 10.5)
Colorbar(f[2, 2], p, vertical = false, flipaxis = false)

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

The `PolarAxis` currently implements zooming by scrolling, radial translations by dragging while the right mouse button is pressed and allows you to reset the view by pressing left control + left mouse button.
Angular translations are also implemented but disabled by default.
You can make adjustments to these interactions with the attributes `ax.scrollspeed[] = 0.1`, `ax.radial_translation_button[] = Mouse.right`, `ax.theta_translation_button[] = false` and `ax.reset_button[] = Keyboard.left_control & Mouse.left`.
For example you can enable angular translations by setting `ax.theta_translation_button[] = Mouse.right`.

Note that `PolarAxis` currently does not implement the interaction interface
used by `Axis`.

## Limits and Orientation of PolarAxis

The PolarAxis includes radial limits `ax.rlimits[] = (rmin, rmax)` and `ax.thetalimits[] = (thetamin, thetamax)`.
They can be set either directly or with the helper functions `rlims!(ax, rmin, rmax)` and `thetalims!(ax, thetamin, thetamax)`.

\begin{examplefigure}{svg = true}
```julia
f = Figure(resolution = (600, 300))
ax = PolarAxis(f[1, 1], rlimits = (4, 8))
lines!(ax, range(0, 10, length=301), range(0, 20pi, length=301), linewidth = 5, color = :orange)
ax = PolarAxis(f[1, 2])
lines!(ax, range(0, 10, length=301), range(0, 20pi, length=301), linewidth = 5, color = :orange)
thetalims!(ax, -pi/2, pi/2)
f
```
\end{examplefigure}

As you can see adjusting the limits has an effect on the shape of the `PolarAxis`.
Setting `rmin > 0` will result in part of the center being removed, up to a maximum relative to `rmax` set by `ax.maximum_clip_radius[] = 1.0`. Note that if `rmin/rmax > maximum_clip_radius` the center of the PolarAxis will no longer be `r = 0`, leading to distortion.
Setting angular limits to a range smaller than `2pi` will result in the matching sector being shown.
You can adjust the orientation and placement of this sector with `ax.theta_0[] = 0.0` and `ax.direction[] = 1`.

\begin{examplefigure}{svg = true}
```julia
f = Figure(resolution = (500, 300))
ax = PolarAxis(f[1, 1],
    rlimits = (4, 8), thetalimits = (-pi/2, pi/2),
    theta_0 = -pi/2, direction = -1, maximum_clip_radius = 1/3)
lines!(ax, range(0, 10, length=301), range(0, 20pi, length=301), linewidth = 5, color = :orange)
f
```
\end{examplefigure}


## Other Notes

### Drawing over grid lines

By default grid lines are drawn in front of plots.
If you want to draw them behind plots set `ax.griddepth[]` to a value between -10_000 and 0 (exclusive), e.g. `ax.griddepth[] = -100`.

### Plotting outside a PolarAxis

Currently there are two poly plots outside the area of the `PolarAxis`
which clip the content to the relevant area. If you want to draw outside the
clip limiting the polar axis but still within it's scene area, you need
to translate those plots to a z range between `9000` and `10_000` or disable
clipping via the `clip` attribute.

For reference, the z values used by `PolarAxis` are `po.griddepth[] = 8999` for grid lines, 9000 for the clip polygons, 9001 for spines and 9002 for tick labels.

## Attributes

\attrdocs{PolarAxis}
