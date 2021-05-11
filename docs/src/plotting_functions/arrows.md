# arrows

```@docs
arrows
```

### Attributes

- `arrowhead = automatic`: Defines the marker (2D) or mesh (3D) that is used as
  the arrow head. The default for is `'▲'` in 2D and a cone mesh in 3D. For the
  latter the mesh should start at `Point3f0(0)` and point in positive z-direction.
- `arrowtail = automatic`: Defines the mesh used to draw the arrow tail in 3D.
  It should start at `Point3f0(0)` and extend in negative z-direction. The default
  is a cylinder. This has no effect on the 2D plot.
- `quality = 32`: Defines the number of angle subdivisions used when generating
  the arrow head and tail meshes. Consider lowering this if you have performance
  issues. Only applies to 3D plots.
- `linecolor = :black`: Sets the color used for the arrow tail which is
  represented by a line in 2D.
- `arrowcolor = linecolor`: Sets the color of the arrow head.
- `arrowsize = automatic`: Scales the size of the arrow head. This defaults to
  `0.3` in the 2D case and `Vec3f0(0.2, 0.2, 0.3)` in the 3D case. For the latter
  the first two components scale the radius (in x/y direction) and the last scales
  the length of the cone. If the arrowsize is set to 1, the cone will have a
  diameter and length of 1.
- `linewidth = automatic`: Scales the width/diameter of the arrow tail.
  Defaults to `1` for 2D and `0.05` for the 3D case.
- `lengthscale = 1f0`: Scales the length of the arrow tail.
- `linestyle = nothing`: Sets the linestyle used in 2D. Does not apply to 3D
  plots.
- `normalize = false`: By default the lengths of the directions given to `arrows`
  are used to scale the length of the arrow tails. If this attribute is set to
  true the directions are normalized, skipping this scaling.
- `align = :origin`: Sets how arrows are positioned. By default arrows start at
  the given positions and extend along the given directions. If this attribute is
  set to `:head`, `:lineend`, `:tailend`, `:headstart` or `:center` the given
  positions will be between the head and tail of each arrow instead.

### Examples

```@example
using GLMakie
GLMakie.activate!() # hide
AbstractPlotting.inline!(true) # hide

f = Figure()
Axis(f[1, 1])

xs = LinRange(1, 10, 20)
ys = LinRange(1, 15, 20)
us = [cos(x) for x in xs, y in ys]
vs = [sin(y) for x in xs, y in ys]

arrows!(xs, ys, us, vs, arrowsize = 0.2, lengthscale = 0.3)

f
```

```@example 1
using GLMakie
GLMakie.activate!() # hide
AbstractPlotting.inline!(true) # hide

ps = [Point3f0(x, y, z) for x in -5:2:5 for y in -5:2:5 for z in -5:2:5]
ns = map(p -> 0.1 * Vec3f0(p[2], p[3], p[1]), ps)
arrows(
    ps, ns, fxaa=true, # turn on anti-aliasing
    linecolor = :gray, arrowcolor = :black,
    linewidth = 0.1, arrowsize = Vec3f0(0.3, 0.3, 0.4),
    align = :center, axis=(type=Axis3,)
)
```

```@example 1
using LinearAlgebra
lengths = norm.(ns)
arrows(
    ps, ns, fxaa=true, # turn on anti-aliasing
    color=lengths,
    linewidth = 0.1, arrowsize = Vec3f0(0.3, 0.3, 0.4),
    align = :center, axis=(type=Axis3,)
)
```
