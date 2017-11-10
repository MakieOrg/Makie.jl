# Functions

Primitive plotting functions.
These are the most atomic operations from which one can stack together more complex plots


## Scatter

```@example
using MakiE
scene = Scene(resolution = (500, 500))
scatter(rand(10), rand(10))
center!(scene)
save("scatter.png", scene); nothing # hide
```

![](scatter.png)

```@docs
scatter
```

# Meshscatter

```@example
using MakiE, GLVisualize, GeometryTypes
scene = Scene(resolution = (500, 500))
meshscatter(Sphere(Point3f0(0), 1f0), marker = loadasset("cat.obj"), markersize = 0.2)
center!(scene)
save("meshscatter.png", scene); nothing # hide
```
![](meshscatter.png)


```@docs
meshscatter
```

## Lines

```@example
using MakiE
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

## Surface

```@example surf
using MakiE
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


## Wireframe

```@docs
wireframe
```

```@example surf
using MakiE
scene = Scene(resolution = (500, 500))
surf = wireframe(range, range, z)
center!(scene)
save("wireframe.png", scene); nothing # hide
```
![](wireframe.png)


## Mesh

```@docs
mesh
```

```@example mesh
using MakiE
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
mesh(x, y, z, indices, color = color)
r = linspace(-0.5, 2.5, 4)
axis(r, r, r)
center!(scene)
save("coloredmesh.png", scene); nothing # hide
```
![](coloredmesh.png)


```@example mesh
scene = Scene(resolution = (500, 500))
mesh(loadasset("cat.obj"))
axis(r, r, r)
center!(scene)
save("loadedmesh.png", scene); nothing # hide
```
![](loadedmesh.png)

```@example mesh
using MakiE, GeometryTypes, FileIO, GLVisualize

scene = Scene(resolution = (500, 500))
cat = load(assetpath("cat.obj"), GLNormalUVMesh)
MakiE.mesh(cat, color = loadasset("diffusemap.tga"))
center!(scene)
save("texturemesh.png", scene); nothing # hide
```
![](texturemesh.png)

## Heatmap

```@docs
heatmap
```

```@example heatmap
using MakiE
scene = Scene(resolution = (500, 500))
heatmap(rand(32, 32))
center!(scene)
save("heatmap.png", scene); nothing # hide
```
![](heatmap.png)


## Volume

```@docs
volume

```

```@example volume
#julia
using MakiE
scene = Scene()
volume(rand(32, 32, 32), algorithm = :iso)
center!(scene)
save("volume.png", scene); nothing # hide
```
![](volume.png)


```
image
volume
text
poly
```
