# lines

{{doc lines}}

## Attributes

### Generic

- `visible::Bool = true` sets whether the plot will be rendered or not.
- `overdraw::Bool = false` sets whether the plot will draw over other plots. This specifically means ignoring depth checks in GL backends.
- `transparency::Bool = false` adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.
- `fxaa::Bool = false` adjusts whether the plot is rendered with fxaa (anti-aliasing). Note that line plots already use a different form of anti-aliasing.
- `inspectable::Bool = true` sets whether this plot should be seen by `DataInspector`.
- `depth_shift::Float32 = 0f0` adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `0 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw). 
- `model::Makie.Mat4f` sets a model matrix for the plot. This replaces adjustments made with `translate!`, `rotate!` and `scale!`.
- `color` sets the color of the plot. It can be given as a named color `Symbol` or a `Colors.Colorant`. Transparency can be included either directly as an alpha value in the `Colorant` or as an additional float in a tuple `(color, alpha)`. The color can also be set for each point in the line by passing a `Vector` of colors or be used to index the `colormap` by passing a `Real` number or `Vector{<: Real}`.
- `colormap::Union{Symbol, Vector{<:Colorant}} = :viridis` sets the colormap that is sampled for numeric `color`s.
- `colorrange::Tuple{<:Real, <:Real}` sets the values representing the start and end points of `colormap`.
- `nan_color::Union{Symbol, <:Colorant} = RGBAf(0,0,0,0)` sets a replacement color for `color = NaN`.
- `space::Symbol = :data` sets the transformation space for line position. See `Makie.spaces()` for possible inputs.

### Other

- `cycle::Vector{Symbol} = [:color]` sets which attributes to cycle when creating multiple plots.
- `linestyle::Union{Nothing, Symbol, Vector} = nothing` sets the pattern of the line (e.g. `:solid`, `:dot`, `:dashdot`)
- `linewidth::Real = 1.5` sets the width of the line in pixel units.


## Examples

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure()
Axis(f[1, 1])

xs = 0:0.01:10
ys = 0.5 .* sin.(xs)

lines!(xs, ys)
lines!(xs, ys .- 1, linewidth = 5)
lines!(xs, ys .- 2, linewidth = 5, color = ys)
lines!(xs, ys .- 3, linestyle = :dash)

f
```
\end{examplefigure}

### Linestyles

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure()
Axis(f[1, 1])

xs = 0:0.01:10
ys = 0.5 .* sin.(xs)

for (i, lw) in enumerate([1, 2, 3])
    lines!(xs, ys .- i/6, linestyle = nothing, linewidth = lw)
    lines!(xs, ys .- i/6 .- 1, linestyle = :dash, linewidth = lw)
    lines!(xs, ys .- i/6 .- 2, linestyle = :dot, linewidth = lw)
    lines!(xs, ys .- i/6 .- 3, linestyle = :dashdot, linewidth = lw)
    lines!(xs, ys .- i/6 .- 4, linestyle = :dashdotdot, linewidth = lw)
    lines!(xs, ys .- i/6 .- 5, linestyle = [0.5, 1.0, 1.5, 2.5], linewidth = lw)
end

f
```
\end{examplefigure}