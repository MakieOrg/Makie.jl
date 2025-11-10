# tricontourf

```
f, ax, pl = tricontourf(args...; kw...) # return a new figure, axis, and plot
   ax, pl = tricontourf(f[row, col], args...; kw...) # creates an axis in a subfigure grid position
       pl = tricontourf!(ax::Union{Scene, AbstractAxis}, args...; kw...) # Creates a plot in the given axis or scene.
SpecApi.Tricontourf(args...; kw...) # Creates a SpecApi plot, which can be used in `S.Axis(plots=[plot])`.
```

## Examples

```@figure
using Random
Random.seed!(1234)

x = randn(50)
y = randn(50)
z = -sqrt.(x .^ 2 .+ y .^ 2) .+ 0.1 .* randn.()

f, ax, tr = tricontourf(x, y, z)
scatter!(x, y, color = z, strokewidth = 1, strokecolor = :black)
Colorbar(f[1, 2], tr)
f
```

```@figure
using Random
Random.seed!(1234)

x = randn(200)
y = randn(200)
z = x .* y

f, ax, tr = tricontourf(x, y, z, colormap = :batlow)
scatter!(x, y, color = z, colormap = :batlow, strokewidth = 1, strokecolor = :black)
Colorbar(f[1, 2], tr)
f
```

#### Triangulation modes

Manual triangulations can be passed as a 3xN matrix of integers, where each column of three integers specifies the indices of the corners of one triangle in the vector of points.

```@figure
using Random
Random.seed!(123)

n = 20
angles = range(0, 2pi, length = n+1)[1:end-1]
x = [cos.(angles); 2 .* cos.(angles .+ pi/n)]
y = [sin.(angles); 2 .* sin.(angles .+ pi/n)]
z = (x .- 0.5).^2 + (y .- 0.5).^2 .+ 0.5.*randn.()

triangulation_inner = reduce(hcat, map(i -> [0, 1, n] .+ i, 1:n))
triangulation_outer = reduce(hcat, map(i -> [n-1, n, 0] .+ i, 1:n))
triangulation = hcat(triangulation_inner, triangulation_outer)

f, ax, _ = tricontourf(x, y, z, triangulation = triangulation,
    axis = (; aspect = 1, title = "Manual triangulation"))
scatter!(x, y, color = z, strokewidth = 1, strokecolor = :black)

tricontourf(f[1, 2], x, y, z, triangulation = Makie.DelaunayTriangulation(),
    axis = (; aspect = 1, title = "Delaunay triangulation"))
scatter!(x, y, color = z, strokewidth = 1, strokecolor = :black)

f
```

By default, `tricontourf` performs unconstrained triangulations. Greater control over the triangulation, such as allowing for enforced boundaries, can be achieved by using [DelaunayTriangulation.jl](https://github.com/DanielVandH/DelaunayTriangulation.jl) and passing the resulting triangulation as the first argument of `tricontourf`. For example, the above annulus can also be plotted as follows:

```@figure
using DelaunayTriangulation
using Random

Random.seed!(123)

n = 20
angles = range(0, 2pi, length = n+1)[1:end-1]
x = [cos.(angles); 2 .* cos.(angles .+ pi/n)]
y = [sin.(angles); 2 .* sin.(angles .+ pi/n)]
z = (x .- 0.5).^2 + (y .- 0.5).^2 .+ 0.5.*randn.()

inner = [n:-1:1; n] # clockwise inner 
outer = [(n+1):(2n); n+1] # counter-clockwise outer
boundary_nodes = [[outer], [inner]]
points = [x'; y']
tri = triangulate(points; boundary_nodes = boundary_nodes)
f, ax, _ = tricontourf(tri, z;
    axis = (; aspect = 1, title = "Constrained triangulation\nvia DelaunayTriangulation.jl"))
scatter!(x, y, color = z, strokewidth = 1, strokecolor = :black)
f
```

Boundary nodes make it possible to support more complicated regions, possibly with holes, than is possible by only providing points themselves.

```@figure using DelaunayTriangulation

See the [online documentation](https://docs.makie.org/stable/reference/plots/tricontourf) for rendered examples.

## Attributes

### `transparency`

**Default:** `false`

Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

### `alpha`

**Default:** `1.0`

The alpha value of the colormap or color attribute.

### `colormap`

**Default:** `@inherit colormap`

Sets the colormap from which the band colors are sampled.

### `visible`

**Default:** `true`

Controls whether the plot gets rendered or not.

### `space`

**Default:** `:data`

Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

### `colorscale`

**Default:** `identity`

Color transform function

### `extendlow`

**Default:** `nothing`

This sets the color of an optional additional band from `minimum(zs)` to the lowest value in `levels`. If it's `:auto`, the lower end of the colormap is picked and the remaining colors are shifted accordingly. If it's any color representation, this color is used. If it's `nothing`, no band is added.

### `inspector_hover`

**Default:** `automatic`

Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

### `clip_planes`

**Default:** `@inherit clip_planes automatic`

Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

### `ssao`

**Default:** `false`

Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

### `extendhigh`

**Default:** `nothing`

This sets the color of an optional additional band from the highest value of `levels` to `maximum(zs)`. If it's `:auto`, the high end of the colormap is picked and the remaining colors are shifted accordingly. If it's any color representation, this color is used. If it's `nothing`, no band is added.

### `inspector_label`

**Default:** `automatic`

Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

### `nan_color`

**Default:** `:transparent`

Sets the color used for nan values in the generated contour.

### `mode`

**Default:** `:normal`

Sets the way in which a vector of levels is interpreted, if it's set to `:relative`, each number is interpreted as a fraction between the minimum and maximum values of `zs`. For example, `levels = 0.1:0.1:1.0` would exclude the lower 10% of data.

### `overdraw`

**Default:** `false`

Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

### `transformation`

**Default:** `:automatic`

Controls the inheritance or directly sets the transformations of a plot. Transformations include the transform function and model matrix as generated by `translate!(...)`, `scale!(...)` and `rotate!(...)`. They can be set directly by passing a `Transformation()` object or inherited from the parent plot or scene. Inheritance options include:

  * `:automatic`: Inherit transformations if the parent and child `space` is compatible
  * `:inherit`: Inherit transformations
  * `:inherit_model`: Inherit only model transformations
  * `:inherit_transform_func`: Inherit only the transform function
  * `:nothing`: Inherit neither, fully disconnecting the child's transformations from the parent

Another option is to pass arguments to the `transform!()` function which then get applied to the plot. For example `transformation = (:xz, 1.0)` which rotates the `xy` plane to the `xz` plane and translates by `1.0`. For this inheritance defaults to `:automatic` but can also be set through e.g. `(:nothing, (:xz, 1.0))`.

### `model`

**Default:** `automatic`

Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

### `depth_shift`

**Default:** `0.0`

Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

### `triangulation`

**Default:** `DelaunayTriangulation()`

The mode with which the points in `xs` and `ys` are triangulated. Passing `DelaunayTriangulation()` performs a Delaunay triangulation. You can also pass a preexisting triangulation as an `AbstractMatrix{<:Int}` with size (3, n), where each column specifies the vertex indices of one triangle, or as a `Triangulation` from DelaunayTriangulation.jl.

### `inspectable`

**Default:** `@inherit inspectable`

Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

### `fxaa`

**Default:** `true`

Adjusts whether the plot is rendered with fxaa (fast approximate anti-aliasing, GLMakie only). Note that some plots implement a better native anti-aliasing solution (scatter, text, lines). For them `fxaa = true` generally lowers quality. Plots that show smoothly interpolated data (e.g. image, surface) may also degrade in quality as `fxaa = true` can cause blurring.

### `levels`

**Default:** `10`

Can be either an `Int` which results in n bands delimited by n+1 equally spaced levels, or it can be an `AbstractVector{<:Real}` that lists n consecutive edges from low to high, which result in n-1 bands.

### `inspector_clear`

**Default:** `automatic`

Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.
