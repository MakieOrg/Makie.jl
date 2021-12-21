# meshscatter

{{doc meshscatter}}

## Attributes

### Generic

- `visible::Bool = true` sets whether the plot will be rendered or not.
- `overdraw::Bool = false` sets whether the plot will draw over other plots. This specifically means ignoring depth checks in GL backends.
- `transparency::Bool = false` adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.
- `fxaa::Bool = true` adjusts whether the plot is rendered with fxaa (anti-aliasing).
- `inspectable::Bool = true` sets whether this plot should be seen by `DataInspector`.
- `depth_shift::Float32 = 0f0` adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `0 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw). 
- `model::Makie.Mat4f` sets a model matrix for the plot. This replaces adjustments made with `translate!`, `rotate!` and `scale!`.
- `color` sets the color of the plot. It can be given as a named color `Symbol` or a `Colors.Colorant`. Transparency can be included either directly as an alpha value in the `Colorant` or as an additional float in a tuple `(color, alpha)`. The color can also be set for each scattered mesh by passing a `Vector` of colors or be used to index the `colormap` by passing a `Real` number or `Vector{<: Real}`. 
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

- `cycle::Vector{Symbol} = [:color]` sets which attributes to cycle when creating multiple plots.
- `marker::Union{Symbol, GeometryBasics.GeometryPrimitive, GeometryBasics.Mesh}` sets the scattered mesh.
- `markersize::Union{<:Real, Vec3f} = 0.1` sets the scale of the mesh. This can be given as a Vector to apply to each scattered mesh individually.
- `rotations::Union{Real, Vec3f, Quaternion} = 0` sets the rotation of the mesh. A numeric rotation is around the z-axis, a `Vec3f` causes the mesh to rotate such that the the z-axis is now that vector, and a quaternion describes a general rotation. This can be given as a Vector to apply to each scattered mesh individually.


## Examples

\begin{examplefigure}{}
```julia
using GLMakie
GLMakie.activate!() # hide
Makie.inline!(true) # hide

xs = cos.(1:0.5:20)
ys = sin.(1:0.5:20)
zs = LinRange(0, 3, length(xs))

meshscatter(xs, ys, zs, markersize = 0.1, color = zs)
```
\end{examplefigure}
