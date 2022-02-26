# polar

{{doc polar}}



## Attributes

### Generic

- `rticks = 4` sets the number of radial ticks.
- `tticks = 8` sets the number of angle ticks. Note that the last angle is omitted, since it is at the same angle as the first, so there will be n-1 total ticks.
- `tlabeloffset = 0.1` is a multiplier that sets the distance from outermost circle of the θ tick labels.
- `transparency = false` adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.
- `inspectable = true` sets whether this plot should be seen by `DataInspector`.

### Other

Set the axis properties `autolimitaspect = 1` to make the plot a circle instead of an ellipse.
Use `hidespines!()` to hide the x- and y-axis spines and use `hidedecorations!()` to hide the horizontal and vertical grid, ticks, and labels.

## Examples


### Polar Plot

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

θ = 0:0.01:8π
r1 = 1 .* sin.(2*θ)
r2 = 3 .* sin.(5*θ/4)
r3 = 8 .* sin.(θ)

f = Figure(resolution = (1800, 600))

ax1 = Axis(f[1, 1], autolimitaspect = 1)
polar!(ax1, r1, θ)

ax2 = Axis(f[1, 2], autolimitaspect = 1)
polar!(ax2, r2, θ, rticks = 0, tticks = 0)

ax3 = Axis(f[1, 3], autolimitaspect = 1)
polar!(ax3, r3, θ, rticks = 5, tticks = 6, tlabeloffset = 0.3)

hidespines!(ax1)
hidespines!(ax2)
hidespines!(ax3)
hidedecorations!(ax1)
hidedecorations!(ax2)
hidedecorations!(ax3)

f
```
\end{examplefigure}

### Polar Scatter Plot
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

θ = 0:0.1:2π
r = 1 .* sin.(2*θ)

f = Figure()

ax = Axis(f[1, 1], autolimitaspect = 1)
polarscatter!(ax, r, θ)

hidespines!(ax)
hidedecorations!(ax)

f
```
\end{examplefigure}