# arrows2d

## Examples

### Basic 2D arrow plot

```@figure
f = Figure(size = (800, 800))
Axis(f[1, 1], backgroundcolor = "black")

xs = LinRange(0, 2pi, 20)
ys = LinRange(0, 3pi, 20)
us = [sin(x) * cos(y) for x in xs, y in ys]
vs = [-cos(x) * sin(y) for x in xs, y in ys]
strength = vec(sqrt.(us .^ 2 .+ vs .^ 2))

arrows2d!(xs, ys, us, vs, lengthscale = 0.2, color = strength)

f
```

### Using a function to define arrow directions

`arrows` can also take a function `f(x::Point{N})::Point{N}` which returns the arrow vector when given the arrow's origin.

```@figure
fig = Figure(size = (800, 800))
ax = Axis(fig[1, 1], backgroundcolor = "black")
xs = LinRange(0, 2pi, 20)
ys = LinRange(0, 3pi, 20)
# explicit method
us = [sin(x) * cos(y) for x in xs, y in ys]
vs = [-cos(x) * sin(y) for x in xs, y in ys]
strength = vec(sqrt.(us .^ 2 .+ vs .^ 2))
# function method
arrow_fun(x) = Point2f(sin(x[1])*cos(x[2]), -cos(x[1])*sin(x[2]))
arrows2d!(ax, xs, ys, arrow_fun, lengthscale = 0.3, color = strength)
fig
```

### Arrow Components & Details

![Arrow Components](../../assets/arrow_components.png)

#### Arrow Length

The target size of each arrow is determined by its direction vector (second plot argument), `normalize` and `lengthscale`.
From tail to tip, the length is given as `lengthscale * norm(direction)`.
If `normalize = true` the direction is normalized first, i.e. the length becomes just `lengthscale`.

There is also the option to treat the second plot argument as the arrows endpoint with `argmode = :endpoint`.
In this case the directions are determined as `direction = endpoint - startpoint` and then follow the same principles.

#### Scaling

Arrow markers are separated into 3 components, a tail, a shaft and a tip.
Each component comes with a length and width which determines its size.
In 2D the sizes are given in pixel units by default (dependent on `markerspace`).
To fit arrows to the length determined by `directions`, `lengthscale` and `normalize`, the `shaftlength` varies between `minshaftlength` and `maxshaftlength` if it is not explicitly set.
Outside of this range or if it is explicitly set, all arrow lengths and widths/radii are scaled by a common factor instead.

```@figure
ps = Point2f.(1:5, 0)
vs = Vec2f.(0, 2 .^ (1:2:10))

fig = Figure()

ax = Axis(fig[1, 1], title = "Always scale, never elongate")
arrows2d!(ax, ps, vs, shaftlength = 16)

ax = Axis(fig[1, 2], title = "Never scale, always elongate")
arrows2d!(ax, ps, vs, minshaftlength = 0)

fig
```

#### Shapes

The base shape of each component is given by the `tail`, `shaft` and `tip` attributes.
They can be anything compatible with `poly`, e.g. a 2D mesh, Polygon or Vector of points.
Each component should be defined in a 0..1 x -0.5..0.5 range, where +x is the direction of the arrow.
The shape can also be constructed by a callback function `f(length, width, metrics)` returning something poly-compatible.
It is given the final length and width of the component as well as the all the other final lengths and widths through metrics.

#### Arrow alignment

With `argmode = :direction` (default) arrows are aligned relative to the given positions (first argument).
If `align = :tail` (or 0) the arrow will start at the respective position, `align = :center` (0.5) will be centered and with `align = :tip` (1.0) it will point to the position.
`align` can also take values outside the 0..1 range to create a gap between the position and the arrow marker.

If `argmode = :endpoint`, alignment works differently and only takes effect if `normalize = true` or `lengthscale != 1`.
Here `align` determines a point `p = startpoint + align * (endpoint - startpoint)` which aligns with same fraction of the arrow marker.
So for example `align = 0.5` (:center) aligns the midpoint between the plot arguments with the midpoint of each arrow marker.
If the length of arrows is scaled down, this will create a matching gap on either side of the arrow.

```@figure
f = Figure(size = (500, 500))

a = Axis(f[1,1], aspect = DataAspect())
ps = [Point2f(cos(a), sin(a)) for a in range(0, 2pi, length=21)[1:end-1]]
scatter!(ps, marker = Circle, color = :transparent, strokewidth = 1)

# Double headed arrow between two points, filling half the distance with
# :center alignment
p = arrows2d!(
    ps, [ps[2:end]..., ps[1]], color = (:blue, 0.5),
    align = :center, lengthscale = 0.5, argmode = :endpoint,
    tail = Point2f[(0, 0), (1, -0.5), (1, 0.5)], taillength = 8
)

# arrow pointing away from ps with a 0.2 gap between the tail and ps
arrows2d!(
    ps, ps, color = eachindex(ps), align = -0.2,
    colormap = :rainbow, lengthscale = 0.5
)

# arrow pointing to ps with a 0.2 gap between the tip and ps
arrows2d!(
    ps, ps, color = eachindex(ps), align = 1.2,
    colormap = :rainbow, lengthscale = 0.5
)
f
```
