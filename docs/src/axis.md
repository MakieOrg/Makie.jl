# Axis

The axis is just a scene object, making it easy to manipulate and share between plots.
Axis objects also contains the mapping you want to apply to the data and can interactively be changed.
An Axis object can be created from any boundingbox and inserted into any plot.

```@docs
axis
```


```@example axis
using MakiE
scene = Scene(resolution = (500, 500))
aviz = axis(linspace(0, 2, 4), linspace(0, 2, 4))
center!(scene)
save("axis2d.png", scene); nothing # hide
```
![](axis2d.png)


```@example axis
using MakiE
scene = Scene(resolution = (500, 500))
aviz = axis(linspace(0, 2, 4), linspace(0, 2, 4), linspace(0, 2, 4))
center!(scene)
save("axis3d.png", scene); nothing # hide
```
![](axis3d.png)

### Interaction

One can quite easily interact with the attributes of the axis like with any other plot:

```@example axis
# always tuples of xyz for most attributes that are applied to each axis
aviz[:gridcolors] = (:gray, :gray, :gray)
aviz[:axiscolors] = (:red, :black, :black)
aviz[:showticks] = (true, true, false)
save("axis3d_customized.png", scene); nothing # hide
```
![](axis3d_customized.png)