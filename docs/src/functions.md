# Functions

The follow document lists the primitive plotting functions from `atomics.jl`, and their usage.
These are the most atomic operations which one can stack together to form more complex plots.

For styling options of each function, see the keyword arguments list for each function.
For a general overview of styling and to see the default parameters, refer to the chapter [Themes](@ref).

# Scatter plots

## Scatter

The `scatter` function can be called either as
`scatter(x, y, z)`, `scatter(x, y)`, or `scatter(positions)`.
The function plots a marker for each element in `(x, y, z)`, `(x, y)`, or `positions`.

```@example
using Makie
scene = Scene(resolution = (500, 500))
scatter(rand(10), rand(10))
center!(scene)
save("scatter.png", scene); nothing # hide
```

![](scatter.png)

```@docs
scatter
```

Available keyword arguments for `scatter` are:
* either one of: `color` or `colormap` (if you use colormap, you'll also need to provide the `intensities`)
* `marker`
* `markersize`
* `strokecolor`
* `strokewidth`
* `glowcolor`
* `glowwidth`
* `rotations`


## Meshscatter

Similar to `scatter`, `meshscatter` plots a mesh for each element in `(x, y, z)`, `(x, y)`, or `positions`.
Usage: `meshscatter(x, y, z)`, `meshscatter(x, y)`, or `meshscatter(positions)`.

```@example
using Makie, GLVisualize, GeometryTypes
scene = Scene(resolution = (500, 500))
meshscatter(Sphere(Point3f0(0), 1f0), marker = loadasset("cat.obj"), markersize = 0.2)
center!(scene)
save("meshscatter.png", scene); nothing # hide
```
![](meshscatter.png)


```@docs
meshscatter
```
Available keyword arguments for `meshscatter`are:
* either one of: `color` or `colormap` (if you use colormap, you'll also need to provide the `intensities`)
* `marker`
* `markersize`
* `rotations`


# Lines

`lines` creates a connected line plot for each element in `(x, y, z)`, `(x, y)` or `positions`.
Usage: `lines(x, y, z)`, `lines(x, y)`, or `lines(positions)`.

```@example
using Makie
scene = Scene(resolution = (500, 500))
x = linspace(0, 3pi)
lines(x, sin.(x))
center!(scene)
save("lines.png", scene); nothing # hide
```

![](lines.png)

```@docs
lines
```

Available keyword arguments for `lines` are:
* either one of: `color` or `colormap` (if you use colormap, you'll also need to provide the `intensities`)
* `linecolor`
* `linewidth`
* `linestyle`
* `drawoever`


# Surface

`surface` plots a surface, where `(x, y, z)` are supposed to lie on a grid.
Usage: `surface(x, y, z)`.

```@example surf
using Makie
scene = Scene(resolution = (500, 500))
N = 32
function xy_data(x,y,i, N)
    x = ((x/N)-0.5)*i
    y = ((y/N)-0.5)*i
    r = sqrt(x*x + y*y)
    res = (sin(r)/r)
    isnan(res) ? 1 : res
end
z = [Float32(xy_data(x, y, 20, 32)) + 0.5 for x=1:32, y=1:32]
range = linspace(0, 3, N)
surf = surface(range, range, z, colormap = :Spectral)
center!(scene)
save("surface.png", scene); nothing # hide
```
![](surface.png)

The plotted surface can be textured, or painted, with one of the following:
* `colormap`
* `colormap` with `image`
* `color`
* `image`


# Wireframe

The `wireframe` function can be called either as
`wireframe(x, y, z)`, `wireframe(positions)`, or `wireframe(mesh)`.
The function draws a wireframe, either interpreted as a surface or as a mesh.

```@docs
wireframe
```

```@example surf
using Makie
scene = Scene(resolution = (500, 500))
surf = wireframe(range, range, z)
center!(scene)
save("wireframe.png", scene); nothing # hide
```
![](wireframe.png)


# Mesh

The `mesh` function can be called either as
`mesh(x, y, z)`, `mesh(mesh_object)`, `mesh(x, y, z, faces)`, or `mesh(xyz, faces)`.
This function plots a 3D mesh.

```@docs
mesh
```

```@example mesh
using Makie
using GLVisualize: loadasset, assetpath

scene = Scene(resolution = (500, 500))
x = [0, 1, 2, 0]
y = [0, 0, 1, 2]
z = [0, 2, 0, 1]
color = [:red, :green, :blue, :yellow]
i = [0, 0, 0, 1]
j = [1, 2, 3, 2]
k = [2, 3, 1, 3]

indices = [1, 2, 3, 1, 3, 4, 1, 4, 2, 2, 3, 4]
m = mesh(x, y, z, indices, color = color)
r = linspace(-0.5, 2.5, 4)
axis(r, r, r)
center!(scene)
save("coloredmesh.png", scene); nothing # hide
```
![](coloredmesh.png)

Additionally, it is possible to combine `mesh` with `wireframe` to generate an "outlined" mesh plot:
```
using GLVisualize: loadasset, assetpath
wireframe(m[:mesh], color = :black, linewidth = 10)
center!(scene)
save("coloredmesh.png", scene); nothing # hide
```
![](coloredmesh-wireframe.png)

`mesh` can also plot using externally-loaded assets as `mesh_object` (using `FileIO`):

```@example mesh
scene = Scene(resolution = (500, 500))
mesh(loadasset("cat.obj"))
axis(r, r, r)
center!(scene)
save("loadedmesh.png", scene); nothing # hide
```
![](loadedmesh.png)

```@example mesh
using Makie, GeometryTypes, FileIO, GLVisualize

scene = Scene(resolution = (500, 500))
cat = load(assetpath("cat.obj"), GLNormalUVMesh)
Makie.mesh(cat, color = loadasset("diffusemap.tga"))
center!(scene)
save("texturemesh.png", scene); nothing # hide
```
![](texturemesh.png)

Available keyword arguments for `mesh` are:
* `indices`
* `shading`
* `attribute_id`


# Heatmap

The `heatmap` function can be called either as
`heatmap(x, y, values)` or `heatmap(values)`.
The function plots a heatmap as an image on `x, y` (defaults to interpretation as dimensions).

```@docs
heatmap
```

```@example heatmap
using Makie
scene = Scene(resolution = (500, 500))
heatmap(rand(32, 32))
center!(scene)
save("heatmap.png", scene); nothing # hide
```
![](heatmap.png)

Available keyword arguments for `heatmap` are:
* `colormap`
* `linewidth`
* `levels`
* `interpolate`

The `interpolate` keyword argument can be used to generate almost organic-looking plots:
```@example heatmap
using Makie
scene = Scene(resolution = (500, 500))
heatmap(rand(32, 32), colormap = :Spectral, interpolate = true)
center!(scene)
save("heatmap.png", scene); nothing # hide
```
![](heatmap-interpolated.png)


# Volume

`volume` plots a volume.
Usage: `volume(volume_data)`.

```@docs
volume

```

```@example volume
using Makie
scene = Scene()
volume(rand(32, 32, 32), algorithm = :iso)
center!(scene)
save("volume.png", scene); nothing # hide
```
![](volume.png)

Available keyword arguments for `volume` are:
* either one of: `color` or `colormap`
* `algorithm`
* `absorption`
* `isovalue`
* `isorange`


# TODOs
```
image
volume
text
poly
```
