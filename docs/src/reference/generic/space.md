# space

The data of each plot goes through a number of transformations before being displayed.
In Makie we divide them into three groups - conversions which normalize types, plot owned [Transformations](@ref transformations_reference_docs) which transform data and scene owned projections which move between coordinate system.
(You may think of blocks like `Axis` as analogous to scenes here. They each wrap a scene and more or less directly manage it and its projections.)
You can find more information on these groups in [Conversion, Transformation and Projection Pipeline](@ref).

The `space` attribute declares which coordinate system the plot is in with respect to projections.
It thus allows you to change which projections are applied to a plot without creating a new scene.
Your options for this are limited to:
- `space = :data`: The plot is in the space defined by the scenes camera and uses it's view and projection matrices.
- `space = :pixel`: The plot is in pixel units and is projected based on the scenes viewport.
- `space = :relative`: The plot is a 0..1 normalized space.
- `space = :clip`: The plot is in a -1..1 normalized space.

```@figure
using GLMakie

f = Figure()
a = Axis(f[1, 1], limits = (-10, 10, -10, 10),
    xminorgridvisible = true, xminorticksvisible = true, xminorticks = IntervalsBetween(5),
    yminorgridvisible = true, yminorticksvisible = true, yminorticks = IntervalsBetween(5))

text_kwargs = (align = (:left, :center), offset = (10, 0))

# default
scatter!(a, Point2f(4, 5), space = :data)
text!(a, Point2f(4, 5), text = "(4, 5) in world space", space = :data; text_kwargs...)

scatter!(a, Point2f(50, 50), space = :pixel)
text!(a, Point2f(50, 50), text = "(50, 50) in pixel space", space = :pixel; text_kwargs...)

scatter!(a, Point2f(0.3, 0.8), space = :relative)
text!(a, Point2f(0.3, 0.8), text = "(0.3, 0.8) in relative space", space = :relative; text_kwargs...)

scatter!(a, Point2f(0, 0.1), space = :clip)
text!(a, Point2f(0, 0.1), text = "(0, 0.1) in clip space", space = :clip; text_kwargs...)

f
```

## markerspace

A few plots also allow you to set a `markerspace`.
In these cases the projections are split up into two steps.
The first projects plot arguments from `space` to `markerspace`.
There the projected arguments get merged with other data.
In scatter for example, each projected position gets expanded to quad whose size, position and orientation are based on the `markersize`, `marker_offset` and `rotation` attributes.
The result then continues to get projected as need to be displayed.
What `markerspace` does, is allow you to choose which coordinate system attributes like `markersize` etc apply.
The options here are the same as with `space`.

```@figure
using GLMakie

f = Figure()
a = Axis(f[1, 1], limits = (-10, 10, -10, 10),
    xminorgridvisible = true, xminorticksvisible = true, xminorticks = IntervalsBetween(5),
    yminorgridvisible = true, yminorticksvisible = true, yminorticks = IntervalsBetween(5))

text_kwargs = (align = (:left, :center), offset = (10, 0))

# markerspace is :pixel by default for scatter
# marker = Circle fills out the full markersize^2 quad
scatter!(a, Point2f(-7, 7), markerspace = :pixel, markersize = 20, marker = Circle)
text!(a, Point2f(-7, 7), text = "pixel space w/ markersize = 20"; text_kwargs...)

scatter!(a, Point2f(-7, 2), markerspace = :clip, markersize = 0.2, marker = Circle)
text!(a, Point2f(-7, 2), text = "clip space w/ markersize = 0.2"; text_kwargs...)

scatter!(a, Point2f(-7, -2), markerspace = :relative, markersize = 0.2, marker = Circle)
text!(a, Point2f(-7, -2), text = "relative space w/ markersize = 0.2"; text_kwargs...)

scatter!(a, Point2f(-7, -7), markerspace = :data, markersize = 2, marker = Circle)
text!(a, Point2f(-7, -7), text = "world space w/ markersize = 2"; text_kwargs...)

f
```