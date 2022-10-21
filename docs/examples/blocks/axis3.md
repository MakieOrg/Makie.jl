# Axis3

## Viewing angles

The two attributes `azimuth` and `elevation` control the angles from which the plots are viewed.

\begin{examplefigure}{}
```julia
using GLMakie
using FileIO
GLMakie.activate!() # hide


f = Figure()

brain = load(assetpath("brain.stl"))
colors = [tri[1][2] for tri in brain for i in 1:3]

azimuths = [0, 0.2pi, 0.4pi]
elevations = [-0.2pi, 0, 0.2pi]

for (i, elevation) in enumerate(elevations)
    for (j, azimuth) in enumerate(azimuths)
        ax = Axis3(f[i, j], aspect = :data,
        title = "elevation = $(round(elevation/pi, digits = 2))π\nazimuth = $(round(azimuth/pi, digits = 2))π",
        elevation = elevation, azimuth = azimuth,
        protrusions = (0, 0, 0, 40))

        hidedecorations!(ax)
        mesh!(brain, color = colors, colormap = :thermal)
    end
end

f
```
\end{examplefigure}
## Data aspects and view mode

The attributes `aspect` and `viewmode` both influence the apparent relative scaling of the three axes.

### `aspect`

The `aspect` changes how long each axis is relative to the other two.

If you set it to `:data`, the axes will be scaled according to their lengths in data space.
The visual result is that objects with known real-world dimensions look correct and not squished.

You can also set it to a three-tuple, where each number gives the relative length of that axis vs the others.

\begin{examplefigure}{}
```julia
using GLMakie
using FileIO
GLMakie.activate!() # hide


f = Figure()

brain = load(assetpath("brain.stl"))

aspects = [:data, (1, 1, 1), (1, 2, 3), (3, 2, 1)]

for (i, aspect) in enumerate(aspects)
    ax = Axis3(f[fldmod1(i, 2)...], aspect = aspect, title = "$aspect")
    mesh!(brain, color = :bisque)
end

f
```
\end{examplefigure}
### `viewmode`

The `viewmode` changes how the final projection is adjusted to fit the axis into its scene.

The default is `:fitzoom`, which scales the final projection evenly, so that the farthest corner of the axis goes right up to the scene boundary.
If you rotate an axis with this mode, the apparent size will shrink and grow depending on the viewing angles, but the plot objects will never look skewed relative to their `aspect`.

The next option `:fit` is like `:fitzoom`, but without the zoom component.
The axis is scaled so that no matter what the viewing angles are, the axis does not clip the scene boundary and its apparent size doesn't change, even though this makes less efficient use of the available space.
You can imagine a sphere around the axis, which is zoomed right up until it touches the scene boundary.

The last option is `:stretch`.
In this mode, scaling in both x and y direction is applied to fit the axis right into its scene box.
Be aware that this mode can skew the axis a lot and doesn't keep the `aspect` intact.
On the other hand, it uses the available space most efficiently.

\begin{examplefigure}{}
```julia
using GLMakie
GLMakie.activate!() # hide


f = Figure()

r = LinRange(-1, 1, 100)
cube = [(x.^2 + y.^2 + z.^2) for x = r, y = r, z = r]
cube_with_holes = cube .* (cube .> 1.4)

viewmodes = [:fitzoom, :fit, :stretch]

for (j, viewmode) in enumerate(viewmodes)
    for (i, azimuth) in enumerate([1.1, 1.275, 1.45] .* pi)
        ax = Axis3(f[i, j], aspect = :data,
            azimuth = azimuth,
            viewmode = viewmode, title = "$viewmode")
        hidedecorations!(ax)
        ax.protrusions = (0, 0, 0, 20)
        volume!(cube_with_holes, algorithm = :iso, isorange = 0.05, isovalue = 1.7)
    end
end

f
```
\end{examplefigure}
## Perspective or orthographic look

You can switch smoothly between an orthographic look and a perspective look using the `perspectiveness` attribute.

A value of 0 looks like an orthographic projection (it is only approximate to a real one) while 1 gives a quite strong perspective look.

\begin{examplefigure}{}
```julia
using GLMakie
GLMakie.activate!() # hide


f = Figure(resolution = (1200, 800), fontsize = 14)

xs = LinRange(0, 10, 100)
ys = LinRange(0, 10, 100)
zs = [cos(x) * sin(y) for x in xs, y in ys]

for (i, perspectiveness) in enumerate(LinRange(0, 1, 6))
    Axis3(f[fldmod1(i, 3)...], perspectiveness = perspectiveness,
        title = "$perspectiveness")

    surface!(xs, ys, zs)
end

f
```
\end{examplefigure}
