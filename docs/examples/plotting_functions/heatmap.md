# heatmap

{{doc heatmap}}

## Attributes

### Generic

- `visible::Bool = true` sets whether the plot will be rendered or not.
- `overdraw::Bool = false` sets whether the plot will draw over other plots. This specifically means ignoring depth checks in GL backends.
- `transparency::Bool = false` adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.
- `fxaa::Bool = true` adjusts whether the plot is rendered with fxaa (anti-aliasing).
- `inspectable::Bool = true` sets whether this plot should be seen by `DataInspector`.
- `depth_shift::Float32 = 0f0` adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `0 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).
- `model::Makie.Mat4f` sets a model matrix for the plot. This replaces adjustments made with `translate!`, `rotate!` and `scale!`.
- `color` is set by the plot.
- `colormap::Union{Symbol, Vector{<:Colorant}} = :viridis` sets the colormap that is sampled for numeric `color`s.
- `colorrange::Tuple{<:Real, <:Real}` sets the values representing the start and end points of `colormap`.
- `nan_color::Union{Symbol, <:Colorant} = RGBAf(0,0,0,0)` sets a replacement color for `color = NaN`.

### Other

- `lowclip::Union{Nothing, Symbol, <:Colorant} = nothing` sets a color for any value below the colorrange.
- `highclip::Union{Nothing, Symbol, <:Colorant} = nothing` sets a color for any value above the colorrange.
- `interpolate::Bool = false` sets whether colors should be interpolated.


## Examples

### Two vectors and a matrix

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide


xs = range(0, 10, length = 25)
ys = range(0, 15, length = 25)
zs = [cos(x) * sin(y) for x in xs, y in ys]

heatmap(xs, ys, zs)
```
\end{examplefigure}

### Two ranges and a function

\begin{examplefigure}{name = "mandelbrot_heatmap"}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

function mandelbrot(x, y)
    z = c = x + y*im
    for i in 1:30.0; abs(z) > 2 && return i; z = z^2 + c; end; 0
end

heatmap(-2:0.1:1, -1.1:0.1:1.1, mandelbrot,
    colormap = Reverse(:deep))
```
\end{examplefigure}

### Three vectors

There must be no duplicate combinations of x and y, but it is allowed to leave out values.

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide


xs = [1, 2, 3, 1, 2, 3, 1, 2, 3]
ys = [1, 1, 1, 2, 2, 2, 3, 3, 3]
zs = [1, 2, 3, 4, 5, 6, 7, 8, NaN]

heatmap(xs, ys, zs)
```
\end{examplefigure}

### Colors

Using the previous example, we can see how to change the color of our plot. You can find additional colors [here](https://makie.juliaplots.org/stable/documentation/colors/index.html#colors).
