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

## Attributes

\attrdocs{Axis3}