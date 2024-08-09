

# CameraWidget

The `CameraWidget` consists of a textured sphere which synchronizes with the view of a 3D `LScene` or `Axis3`.
It can be used to rotate the connected LScene or Axis3 and it gives you information on their orientation.

The widget can be created as part of the GridLayout like any other Block.

\begin{examplefigure}{}
```julia
using GLMakie
GLMakie.activate!() # hide

fig = Figure()
ax = Axis3(fig[1, 1])
meshscatter!(ax, rand(Point3f, 10))

cw = CameraWidget(fig[1, 2], ax)

fig
```
\end{examplefigure}

By ommitting the grid position the widget can be created free from the layout.
In this case it can be moved out around using right-drag.


\begin{examplefigure}{}
```julia
using GLMakie
GLMakie.activate!() # hide

fig = Figure()
ax = LScene(fig[1, 1])
meshscatter!(ax, rand(Point3f, 10))

cw = CameraWidget(ax)

fig
```
\end{examplefigure}

## Attributes

\attrdocs{CameraWidget}