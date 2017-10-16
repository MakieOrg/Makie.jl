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


```
mesh
image
heatmap
volume
text
poly
