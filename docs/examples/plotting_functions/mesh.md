# mesh

{{doc mesh}}

## Attributes

### Generic

- `visible::Bool = true` sets whether the plot will be rendered or not.
- `overdraw::Bool = false` sets whether the plot will draw over other plots. This specifically means ignoring depth checks in GL backends.
- `transparency::Bool = false` adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.
- `fxaa::Bool = true` adjusts whether the plot is rendered with fxaa (anti-aliasing).
- `inspectable::Bool = true` sets whether this plot should be seen by `DataInspector`.
- `depth_shift::Float32 = 0f0` adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `0 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw). 
- `model::Makie.Mat4f` sets a model matrix for the plot. This replaces adjustments made with `translate!`, `rotate!` and `scale!`.
- `color::Union{Symbol, <:Colorant, Tuple{Symbol, <:AbstractFloat}, Tuple{<:Colorant, <:AbstractFloat}, Real}` sets the color of the plot. Usually the color can also be given per plot element (e.g. scattered marker, point in line, vertex in mesh, etc) by passing a `Vector` of colors. If the color is numeric it will be used to sample the `colormap`. In some cases a `Matrix{<: Colorant}` can be passed to be used as a texture.
- `colormap::Union{Symbol, Vector{<:Colorant}} = :viridis` sets the colormap that is sampled for numeric `color`s.
- `colorrange::Tuple{<:Real, <:Real}` sets the values representing the start and end points of `colormap`.
- `nan_color::Union{Symbol, <:Colorant} = RGBAf(0,0,0,0)` sets a replacement color for `color = NaN`.

### Generic 3D

- `shading = true` enables lighting.
- `diffuse::Vec3f = Vec3f(0.4)` sets how strongly the red, green and blue channel react to diffuse (scattered) light. 
- `specular::Vec3f = Vec3f(0.2)` sets how strongly the object reflects light in the red, green and blue channels.
- `shininess::Real = 32.0` sets how sharp the reflection is.
- `ssao::Bool = false` adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.


## Examples

\begin{examplefigure}{}
```julia
using GLMakie
GLMakie.activate!() # hide
Makie.inline!(true) # hide

vertices = [
    0.0 0.0;
    1.0 0.0;
    1.0 1.0;
    0.0 1.0;
]

faces = [
    1 2 3;
    3 4 1;
]

colors = [:red, :green, :blue, :orange]

scene = mesh(vertices, faces, color = colors, shading = false)
```
\end{examplefigure}

\begin{examplefigure}{}
```julia
using FileIO
using GLMakie
GLMakie.activate!() # hide
Makie.inline!(true) # hide

brain = load(assetpath("brain.stl"))

mesh(
    brain,
    color = [tri[1][2] for tri in brain for i in 1:3],
    colormap = Reverse(:Spectral),
    figure = (resolution = (1000, 1000),)
)
```
\end{examplefigure}
