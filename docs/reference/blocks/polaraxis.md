# PolarAxis

The `PolarAxis` is an axis for data given in polar coordinates, i.e a radius and an angle.
It is currently an experimental feature, meaning that some functionality might be missing or broken, and that the `PolarAxis` is (more) open to breaking changes.

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

Like with an `Axis` you can use mutating 2D plot functions directly on a `PolarAxis`.
The input arguments of the plot functions will then be interpreted in polar coordinates, i.e. as an angle (in radians) and a radius.
The order of a arguments can be changed with `ax.theta_as_x`.

\begin{examplefigure}{svg = true}
```julia
f = Figure(resolution = (800, 400))

ax = PolarAxis(f[1, 1], title = "Theta as x")
lineobject = lines!(ax, 0..2pi, sin, color = :red)

ax = PolarAxis(f[1, 2], title = "R as x", theta_as_x = false)
scatobject = scatter!(range(0, 10, length=100), cos, color = :orange)

f
```
\end{examplefigure}

## PolarAxis Limits

By default the PolarAxis will assume `po.rlimits[] = (0.0, nothing)` and `po.thetalimits[] = (0.0, 2pi)`, showing a full circle.
You can adjust these limits to show different cut-outs of the PolarAxis.
For example, we can limit `thetalimits` to a smaller range to generate a circle sector and further limit rmin through `rlimits` to cut out the center to an arc.

\begin{examplefigure}{svg = true}
```julia
f = Figure(resolution = (600, 600))

ax = PolarAxis(f[1, 1], title = "Default")
lines!(ax, range(0, 8pi, length=300), range(0, 10, length=300))
ax = PolarAxis(f[1, 2], title = "thetalimits", thetalimits = (-pi/6, pi/6))
lines!(ax, range(0, 8pi, length=300), range(0, 10, length=300))

ax = PolarAxis(f[2, 1], title = "rlimits", rlimits = (5, 10))
lines!(ax, range(0, 8pi, length=300), range(0, 10, length=300))
ax = PolarAxis(f[2, 2], title = "both")
lines!(ax, range(0, 8pi, length=300), range(0, 10, length=300))
thetalims!(ax, -pi/6, pi/6)
rlims!(ax, 5, 10)

f
```
\end{examplefigure}

You can make further adjustments to the orientation of the PolarAxis by adjusting `ax.theta_0` and `ax.direction`.
These adjust how angles are interpreted by the polar transform following the formula `output_angle = direction * (input_angle + theta_0)`.

\begin{examplefigure}{svg = true}
```julia
f = Figure()

ax = PolarAxis(f[1, 1], title = "Reoriented Axis", theta_0 = -pi/2, direction = -1)
lines!(ax, range(0, 8pi, length=300), range(0, 10, length=300))
thetalims!(ax, -pi/6, pi/6)
rlims!(ax, 5, 10)

f
```
\end{examplefigure}

Note that by default translations in adjustments of rmin and thetalimits are blocked.
These can be unblocked by calling `autolimits!(ax[, true])` which also tells the PolarAxis to derive r- and thetalimits freely from data, or by setting `ax.fixrmin[] = false` and `ax.thetazoomlock[] = false`.


## Plot type compatability

Not every plot type is compatible with the polar transform.
For example `image` is not as it expects to be drawn on a rectangle.
`heatmap` works to a degree in CairoMakie, but not GLMakie due to differences in the backend implementation.
`surface` can be used as a replacement for `image` as it generates a triangle mesh.
However it also has a component in z-direction which will affect drawing order.
You can use `translate!(plot, 0, 0, z_shift)` to work around that.
As a replacement for `heatmap` you can use `voronoiplot`, which generates cells of arbitrary shape around points given to it. Here you will generally need to set `rlims!(ax, rmax)` yourself.

\begin{examplefigure}{svg = false}
```julia
f = Figure(resolution = (800, 500))

ax = PolarAxis(f[1, 1], title = "Surface")
rs = 0:10
phis = range(0, 2pi, 37)
cs = [r+cos(4phi) for phi in phis, r in rs]
p = surface!(ax, 0..2pi, 0..10, cs, shading = false, colormap = :coolwarm)
ax.gridz[] = 100
tightlimits!(ax) # surface plots include padding by default
Colorbar(f[2, 1], p, vertical = false, flipaxis = false)

ax = PolarAxis(f[1, 2], title = "Voronoi")
rs = 1:10
phis = range(0, 2pi, 37)[1:36]
cs = [r+cos(4phi) for phi in phis, r in rs]
p = voronoiplot!(ax, phis, rs, cs, show_generators = false, strokewidth = 0)
rlims!(ax, 0.0, 10.5)
Colorbar(f[2, 2], p, vertical = false, flipaxis = false)

f
```
\end{examplefigure}

Note that in order to see the grid we need to adjust its depth with `ax.gridz[] = 100` (higher z means lower depth).
The hard limits for `ax.gridz` are `(-10_000, 10_000)` with `9000` being a soft limit where axis components may order incorrectly.

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

The `PolarAxis` currently implements zooming, translation and resetting.
Zooming is implemented via scrolling, with `ax.rzoomkey = Keyboard.r` restricting zooming to the radial direction and `ax.thetazoomkey = Keyboard.t` restring to angular zooming.
You can block zooming in the r-direction by setting `ax.rzoomlock = true` and `ax.thetazoomlock = true` for theta direction.
Furthermore you can disable zooming from changing just rmin with `ax.fixrmin = true` and adjust its speed with `ax.zoomspeed = 0.1`.

Translations are implemented with mouse drag.
By default radial translations use `ax.r_translation_button = Mouse.right` and angular translations also use `ax.theta_translation_button = Mouse.right`.
If `ax.fixrmin = true` translation in the r direction are not allowed.
If you want to disable one of these interaction you can set corresponding button to `false`.

There is also an interaction for rotating the whole axis using `ax.axis_rotation_button = Keyboard.left_control & Mouse.right` and resetting the axis view uses `ax.reset_button = Keyboard.left_control & Mouse.left`, matching `Axis`.
You can adjust whether this resets the rotation of the axis with `ax.reset_axis_orientation = false`.

Note that `PolarAxis` currently does not implement the interaction interface
used by `Axis`.

## Other Notes

### Plotting outside a PolarAxis

Currently there are two poly plots outside the area of the `PolarAxis`
which clip the content to the relevant area. If you want to draw outside the
clip limiting the polar axis but still within it's scene area, you need
to translate those plots to a z range between `9000` and `10_000` or disable
clipping via the `clip` attribute.

For reference, the z values used by `PolarAxis` are `po.griddepth[] = 8999` for grid lines, 9000 for the clip polygons, 9001 for spines and 9002 for tick labels.

### Radial Distortion

If you have a plot with a large rmin and rmax over a wide range of angles you will end up with a narrow PolarAxis.
Consider for example:

\begin{examplefigure}{svg = true}
```julia
fig = Figure()
ax = PolarAxis(fig[1, 1], thetalimits = (0, pi))
lines!(ax, range(0, pi, length=100), 10 .+ sin.(0.3 .* (1:100)))
fig
```
\end{examplefigure}

In this case you may want to distort the r-direction to make more of your data visible.
This can be done by setting `ax.radial_distortion_threshold` to a value between 0 and 1.

\begin{examplefigure}{svg = true}
```julia
fig = Figure()
ax = PolarAxis(fig[1, 1], thetalimits = (0, pi), radial_distortion_threshold = 0.2, rlimits = (nothing, nothing))
lines!(ax, range(0, pi, length=100), 10 .+ sin.(0.3 .* (1:100)))
fig
```
\end{examplefigure}

Internally PolarAxis will check `rmin/rmax` against the set threshold.
If that ratio exceed the threshold, the polar transform is adjusted to shift all radii by some `r0` such that `(rmin - r0) / rmax - r0) == ax.radial_distortion_threshold`.
In effect this will hold the inner cutout/clip radius at a fraction of the outer radius.
Note that at `ax.radial_distortion_threshold >= 1.0` (default) this will never distort your data.

## Attributes

\attrdocs{PolarAxis}
