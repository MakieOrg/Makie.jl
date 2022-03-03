# volume

{{doc volume}}

## Attributes

### Generic

- `visible::Bool = true` sets whether the plot will be rendered or not.
- `overdraw::Bool = false` sets whether the plot will draw over other plots. This specifically means ignoring depth checks in GL backends.
- `transparency::Bool = false` adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.
- `fxaa::Bool = true` adjusts whether the plot is rendered with fxaa (anti-aliasing).
- `inspectable::Bool = true` sets whether this plot should be seen by `DataInspector`.
- `depth_shift::Float32 = 0f0` adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `0 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).
- `model::Makie.Mat4f` sets a model matrix for the plot. This replaces adjustments made with `translate!`, `rotate!` and `scale!`.
- `colormap::Union{Symbol, Vector{<:Colorant}} = :viridis` sets the colormap that is sampled for numeric `color`s.
- `colorrange::Tuple{<:Real, <:Real}` sets the values representing the start and end points of `colormap`.
- `nan_color::Union{Symbol, <:Colorant} = RGBAf(0,0,0,0)` sets a replacement color for `color = NaN`.

### Generic 3D

- `shading = true` enables lighting.
- `diffuse::Vec3f = Vec3f(0.4)` sets how strongly the red, green and blue channel react to diffuse (scattered) light.
- `specular::Vec3f = Vec3f(0.2)` sets how strongly the object reflects light in the red, green and blue channels.
- `shininess::Real = 32.0` sets how sharp the reflection is.
- `ssao::Bool = false` adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

### Other

- `algorithm::Union{Symbol, RaymarchAlgorithm} = :mip` sets the volume algorithm that is used.
- `isorange::Real = 0.05` sets the range of values picked up by the IsoValue algorithm.
- `isovalue = 0.5` sets the target value for the IsoValue algorithm.


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
