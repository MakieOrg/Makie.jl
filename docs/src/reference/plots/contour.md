# contour

```@shortdocs; canonical=false
contour
```


## Examples

```@figure
f = Figure()
Axis(f[1, 1])

xs = LinRange(0, 10, 100)
ys = LinRange(0, 15, 100)
zs = [cos(x) * sin(y) for x in xs, y in ys]

contour!(xs, ys, zs)

f
```

Omitting the `xs` and `ys` results in the indices of `zs` being used. We can also set arbitrary contour-levels using `levels`

```@figure
f = Figure()
Axis(f[1, 1])

xs = LinRange(0, 10, 100)
ys = LinRange(0, 15, 100)
zs = [cos(x) * sin(y) for x in xs, y in ys]

contour!(zs,levels=-1:0.1:1)

f
```

One can also add labels and control label attributes such as `labelsize`, `labelcolor` or `labelfont`.

```@figure
himmelblau(x, y) = (x^2 + y - 11)^2 + (x + y^2 - 7)^2
x = y = range(-6, 6; length=100)
z = himmelblau.(x, y')

levels = 10.0.^range(0.3, 3.5; length=10)
colorscale = ReversibleScale(x -> x^(1 / 10), x -> x^10)
f, ax, ct = contour(x, y, z; labels=true, levels, colormap=:hsv, colorscale)
f
```

### Curvilinear grids

`contour` also supports _curvilinear_ grids, where `x` and `y` are both matrices of the same size as `z`.
This is similar to the input that [`surface`](@ref) accepts.

Let's warp a regular grid of `x` and `y` by some nonlinear function, and plot its contours:

```@figure
x = -10:10
y = -10:10
# The curvilinear grid:
xs = [x + 0.01y^3 for x in x, y in y]
ys = [y + 10cos(x/40) for x in x, y in y]

# Now, for simplicity, we calculate the `zs` values to be
# the radius from the center of the grid (0, 10).
zs = sqrt.(xs .^ 2 .+ (ys .- 10) .^ 2)

# We can use Makie's tick finders to get some nice looking contour levels:
levels = Makie.get_tickvalues(Makie.LinearTicks(7), extrema(zs)...)

# and now, we plot!
fig, ax, srf = surface(xs, ys, fill(0f0, size(zs)); color=zs, shading = NoShading, axis = (; type = Axis, aspect = DataAspect()))
ctr = contour!(ax, xs, ys, zs; color = :orange, levels = levels, labels = true, labelfont = :bold, labelsize = 12)

fig
```

### 3D contours

3D contour plots exist in two variants.
`contour` implements a variant showing multiple isosurfaces, i.e. surfaces that sample the same value from a 3D array.
[contour3d](@ref) computes the same isolines as a 2D `contour` plot but renders them in 3D at z values equal to their level.

```@figure backend=GLMakie
r = range(-pi, pi, length = 21)
data2d = [cos(x) + cos(y) for x in r, y in r]
data3d = [cos(x) + cos(y) + cos(z) for x in r, y in r, z in r]

f = Figure(size = (700, 400))
a1 = Axis3(f[1, 1], title = "3D contour()")
contour!(a1, -pi .. pi, -pi .. pi, -pi .. pi, data3d)

a2 = Axis3(f[1, 2], title = "contour3d()")
contour3d!(a2, r, r, data2d, linewidth = 3, levels = 10)
f
```

```@figure backend=GLMakie
r = range(-pi, pi, length = 21)
data3d = [cos(x) + cos(y) + cos(z) for x in r, y in r, z in r]

f = Figure(size = (700, 300))

# isorange controls the thickness of isosurfaces
# Note that artifacts may appear if isorange becomes too small (< 0.03 here)
a1 = Axis3(f[1, 1])
contour!(a1, -pi .. pi, -pi .. pi, -pi .. pi, data3d, isorange = 0.04)

# small alpha can be used to see into the contour plot
a2 = Axis3(f[1, 2])
contour!(a2, -pi .. pi, -pi .. pi, -pi .. pi, data3d, alpha = 0.05)
f
```


## Attributes

```@attrdocs
Contour
```
