# volume

{{doc volume}}

## Examples

\begin{examplefigure}{}
```julia
using GLMakie
GLMakie.activate!() # hide
r = LinRange(-1, 1, 100)
cube = [(x.^2 + y.^2 + z.^2) for x = r, y = r, z = r]
contour(cube, alpha=0.5)
```
\end{examplefigure}

\begin{examplefigure}{}
```julia
cube_with_holes = cube .* (cube .> 1.4)
volume(cube_with_holes, algorithm = :iso, isorange = 0.05, isovalue = 1.7)
```
\end{examplefigure}

\begin{examplefigure}{}
```julia
using NIfTI
brain = niread(Makie.assetpath("brain.nii.gz")).raw
mini, maxi = extrema(brain)
normed = Float32.((brain .- mini) ./ (maxi - mini))

fig = Figure(resolution=(1000, 450))
# Make a colormap, with the first value being transparent
colormap = to_colormap(:plasma)
colormap[1] = RGBAf(0,0,0,0)
volume(fig[1, 1], normed, algorithm = :absorption, absorption=4f0, colormap=colormap, axis=(type=Axis3, title = "Absorption"))
volume(fig[1, 2], normed, algorithm = :mip, colormap=colormap, axis=(type=Axis3, title="Maximum Intensity Projection"))
fig
```
\end{examplefigure}
