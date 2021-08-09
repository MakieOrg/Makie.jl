# density

{{doc density}}

### Examples

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure()
Axis(f[1, 1])

density!(randn(200))

f
```
\end{examplefigure}

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure()
Axis(f[1, 1])

density!(randn(200), direction = :y, npoints = 10)

f
```
\end{examplefigure}

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure()
Axis(f[1, 1])

density!(randn(200), color = (:red, 0.3),
    strokecolor = :red, strokewidth = 3, strokearound = true)

f
```
\end{examplefigure}

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure()
Axis(f[1, 1])

vectors = [randn(1000) .+ i/2 for i in 0:5]

for (i, vector) in enumerate(vectors)
    density!(vector, offset = -i/4, color = (:slategray, 0.4),
        bandwidth = 0.1)
end

f
```
\end{examplefigure}

#### Gradients

You can color density plots with gradients by choosing `color = :x` or `:y`, depending on the `direction` attribute.

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

months = ["January", "February", "March", "April",
    "May", "June", "July", "August", "September",
    "October", "November", "December"]

f = Figure()
Axis(f[1, 1], title = "Fictive temperatures",
    yticks = ((1:12) ./ 4,  reverse(months)))

for i in 12:-1:1
    d = density!(randn(200) .- 2sin((i+3)/6*pi), offset = i / 4,
        color = :x, colormap = :thermal, colorrange = (-5, 5),
        strokewidth = 1, strokecolor = :black)
    # this helps with layering in GLMakie
    translate!(d, 0, 0, -0.1i)
end
f
```
\end{examplefigure}

Due to technical limitations, if you color the `:vertical` dimension (or :horizontal with direction = :y), only a colormap made with just two colors can currently work:

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure()
Axis(f[1, 1])
for x in 1:5
    d = density!(x * randn(200) .+ 3x,
        color = :y, colormap = [:darkblue, :gray95])
end
f
```
\end{examplefigure}
