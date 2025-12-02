# PolarAxis

The `PolarAxis` is an axis for data given in polar coordinates, i.e a radius and an angle.
It is currently an experimental feature, meaning that some functionality might be missing or broken, and that the `PolarAxis` is (more) open to breaking changes.

## Creating a PolarAxis

Creating a `PolarAxis` works the same way as creating an `Axis`.

```@figure

f = Figure()

ax = PolarAxis(f[1, 1], title = "Title")

f
```


## Plotting into an PolarAxis

Like with an `Axis` you can use mutating 2D plot functions directly on a `PolarAxis`.
The input arguments of the plot functions will then be interpreted in polar coordinates, i.e. as an angle (in radians) and a radius.
The order of a arguments can be changed with `ax.theta_as_x`.

```@figure
f = Figure(size = (800, 400))

ax = PolarAxis(f[1, 1], title = "Theta as x")
lineobject = lines!(ax, 0..2pi, sin, color = :red)

ax = PolarAxis(f[1, 2], title = "R as x", theta_as_x = false)
scatobject = scatter!(range(0, 10, length=100), cos, color = :orange)

f
```


## PolarAxis Limits

By default the PolarAxis will assume `po.rlimits = (0.0, nothing)` and `po.thetalimits = (0.0, 2pi)`, showing a full circle.
You can adjust these limits to show different cut-outs of the PolarAxis.
For example, we can limit `thetalimits` to a smaller range to generate a circle sector and further limit rmin through `rlimits` to cut out the center to an arc.

```@figure
f = Figure(size = (600, 600))

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


You can make further adjustments to the orientation of the PolarAxis by adjusting `ax.theta_0` and `ax.direction`.
These adjust how angles are interpreted by the polar transform following the formula `output_angle = direction * (input_angle + theta_0)`.

```@figure
f = Figure()

ax = PolarAxis(f[1, 1], title = "Reoriented Axis", theta_0 = -pi/2, direction = -1)
lines!(ax, range(0, 8pi, length=300), range(0, 10, length=300))
thetalims!(ax, -pi/6, pi/6)
rlims!(ax, 5, 10)

f
```


Note that by default translations in adjustments of rmin and thetalimits are blocked.
These can be unblocked by calling `autolimits!(ax[, true])` which also tells the PolarAxis to derive r- and thetalimits freely from data, or by setting `ax.fixrmin = false` and `ax.thetazoomlock = false`.


## Plot type compatibility

Not every plot type is compatible with the polar transform.
For example `image` is not as it expects to be drawn on a rectangle.
`heatmap` works to a degree in CairoMakie, but not GLMakie due to differences in the backend implementation.
`surface` can be used as a replacement for `image` as it generates a triangle mesh.
To avoid having the `surface` plot extend in z-direction and thus messing with render order it is recommended to pass the color-data through the `color` attribute and use a matrix of zeros for the z-data.
As a replacement for `heatmap` you can use `voronoiplot`, which generates cells of arbitrary shape around points given to it. Here you will generally need to set `rlims!(ax, rmax)` yourself.

```@figure
f = Figure(size = (800, 500))

ax = PolarAxis(f[1, 1], title = "Surface")
rs = 0:10
phis = range(0, 2pi, 37)
cs = [r+cos(4phi) for phi in phis, r in rs]
p = surface!(ax, 0..2pi, 0..10, zeros(size(cs)), color = cs, shading = NoShading, colormap = :coolwarm)
ax.gridz = 100
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


Note that in order to see the grid we need to adjust its depth with `ax.gridz = 100` (higher z means lower depth).
The hard limits for `ax.gridz` are `(-10_000, 10_000)` with `9000` being a soft limit where axis components may order incorrectly.

## Hiding spines and decorations

For a `PolarAxis` we interpret the outer ring limiting the plotting area as the
axis spine. You can manipulate it with the `spine...` attributes.

```@figure
f = Figure(size = (800, 400))
ax1 = PolarAxis(f[1, 1], title = "No spine", spinevisible = false)
scatterlines!(ax1, range(0, 1, length=100), range(0, 10pi, length=100), color = 1:100)

ax2 = PolarAxis(f[1, 2], title = "Modified spine")
ax2.spinecolor = :red
ax2.spinestyle = :dash
ax2.spinewidth = 5
scatterlines!(ax2, range(0, 1, length=100), range(0, 10pi, length=100), color = 1:100)

f
```


Decorations such as grid lines and tick labels can be adjusted through
attributes in much the same way.

```@figure
f = Figure(size = (600, 600), backgroundcolor = :black)
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


We can also hide the spine after creation
with `hidespines!(ax)`. And, hide the ticklabels, grid, and/or minorgrid with `hidedecorations!`, `hiderdecorations`, and `hidethetadecorations!`.

```@figure
fig = Figure()
fullaxis(figpos, title) = PolarAxis(figpos;
                                    title,
                                    thetaminorgridvisible=true,
                                    rminorgridvisible=true,
                                    rticklabelrotation=deg2rad(-90),
                                    rticklabelsize=12,
                                    )
ax1 = fullaxis(fig[1, 1][1, 1], "all decorations")
ax2 = fullaxis(fig[1, 1][1, 2], "hide spine")
hidespines!(ax2)
ax3 = fullaxis(fig[2, 1][1, 1], "hide r decorations")
hiderdecorations!(ax3)
ax4 = fullaxis(fig[2, 1][1, 2], "hide theta decorations")
hidethetadecorations!(ax4)
ax5 = fullaxis(fig[2, 1][1, 3], "hide all decorations")
hidedecorations!(ax5)
fig
```

## Ticks and Minorticks

Ticks and minor ticks are hidden by default.
They are made visible with the `tickvisible` attributes.

```@figure
f = Figure()
a = PolarAxis(f[1,1],
    rticksvisible = true, thetaticksvisible = true,
    rminorticksvisible = true,
    thetaminorticksvisible = true,
)
f
```

They can be styled with various other `tick` attributes.
They can also be mirrored to the other side of a sector-style PolarAxis with `ticksmirrored`.

```@figure
f = Figure(size = (800, 400))
kwargs = (
    rticksvisible = true, rticksize = 12, rtickwidth = 4, rtickcolor = :red, rtickalign = 0.5,
    thetaticksvisible = true, thetaticksize = 12, thetatickwidth = 4, thetatickcolor = :blue, thetatickalign = 0.5,
    rminorticksvisible = true, rminorticksize = 8, rminortickwidth = 3, rminortickcolor = :orange, rminortickalign = 1.0,
    thetaminorticksvisible = true, thetaminorticksize = 8, thetaminortickwidth = 3, thetaminortickcolor = :cyan, thetaminortickalign = 1.0,
)
a = PolarAxis(f[1,1], title = "normal", rticksmirrored = false, thetaticksmirrored = false; kwargs...)
rlims!(a, 0.5, 0.9)
thetalims!(a, 1pi/5, 2pi/5)
a = PolarAxis(f[1,2], title = "mirrored", rticksmirrored = true, thetaticksmirrored = true; kwargs...)
rlims!(a, 0.5, 0.9)
thetalims!(a, 1pi/5, 2pi/5)
f
```

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

For reference, the z values used by `PolarAxis` are `po.griddepth = 8999` for grid lines, 9000 for the clip polygons, 9001 for spines and 9002 for tick labels.

### Radial Offset

If you have a plot with rlimits far away from 0 you will end up with a lot of empty space in the PolarAxis.
Consider for example:

```@figure
fig = Figure()
ax = PolarAxis(fig[1, 1], thetalimits = (0, pi))
lines!(ax, range(0, pi, length=100), 10 .+ sin.(0.3 .* (1:100)))
fig
```


In this case you may want to offset the r-direction to make more of your data visible.
This can be done by setting `ax.radius_at_origin` which translates radii as `r_out = r_in - radius_at_origin`.

```@figure
fig = Figure()
ax = PolarAxis(fig[1, 1], thetalimits = (0, pi), radius_at_origin = 8)
lines!(ax, range(0, pi, length=100), 10 .+ sin.(0.3 .* (1:100)))
fig
```


This can also be used to show a plot with negative radii:

```@figure
fig = Figure()
ax = PolarAxis(fig[1, 1], thetalimits = (0, pi), radius_at_origin = -12)
lines!(ax, range(0, pi, length=100), sin.(0.3 .* (1:100)) .- 10)
fig
```


Note however that translating radii results in some level of distortion:

```@figure
phis = range(pi/4, 9pi/4, length=201)
rs = 1.0 ./ sin.(range(pi/4, 3pi/4, length=51)[1:end-1])
rs = vcat(rs, rs, rs, rs, rs[1])

fig = Figure(size = (900, 300))
ax1 = PolarAxis(fig[1, 1], radius_at_origin = -2,  title = "radius_at_origin = -2")
ax2 = PolarAxis(fig[1, 2], radius_at_origin = 0,   title = "radius_at_origin = 0")
ax3 = PolarAxis(fig[1, 3], radius_at_origin = 0.5, title = "radius_at_origin = 0.5")
for ax in (ax1, ax2, ax3)
    lines!(ax, phis, rs .- 2, color = :red, linewidth = 4)
    lines!(ax, phis, rs, color = :black, linewidth = 4)
    lines!(ax, phis, rs .+ 0.5, color = :blue, linewidth = 4)
end
fig
```


### Radial clipping

By default radii `r_out = r_in - radius_at_origin < 0` are clipped by the Polar transform.
This can be disabled by setting `ax.clip_r = false`.
With that setting `r_out < 0` will pass through the polar transform as is, resulting in a coordinate at $(|r_{out}|, \theta - pi)$.

```@figure
fig = Figure(size = (600, 300))
ax1 = PolarAxis(fig[1, 1], radius_at_origin = 0.0, clip_r = true, title = "clip_r = true")
ax2 = PolarAxis(fig[1, 2], radius_at_origin = 0.0, clip_r = false, title = "clip_r = false")
for ax in (ax1, ax2)
    lines!(ax, 0..2pi, phi -> cos(2phi) - 0.5, color = :red, linewidth = 4)
    lines!(ax, 0..2pi, phi -> sin(2phi), color = :black, linewidth = 4)
end
fig
```


## Attributes

```@attrdocs
PolarAxis
```
