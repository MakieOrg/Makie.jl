# Precompilation

Makie and its backends precompile a set of common plots, so the first plot in a new session doesn't have to compile
everything. Packages with their own plotting functions can precompile those as well, including interactions like
`DataInspector` hovers.

## Precompiling plots in a package

Each backend has a `precompile_plot` function, which renders a figure the way displaying it does. Call it inside a
[PrecompileTools.jl](https://github.com/JuliaLang/PrecompileTools.jl) workload, usually in a package extension for
the backend:

```julia
module MyPackageGLMakieExt

using MyPackage, GLMakie, PrecompileTools

@compile_workload begin
    GLMakie.precompile_plot(MyPackage.my_plot(rand(10)))
end

end
```

`CairoMakie.precompile_plot` and `WGLMakie.precompile_plot` work the same way. `GLMakie.precompile_plot` renders in a
hidden window, and skips rendering if no OpenGL context can be created, e.g. on a headless machine.

## Precompiling interactions

With a function as the first argument, `precompile_plot` calls it after the first frame and renders the figure again
afterwards, so the updates caused by an interaction get compiled too. Interactions are simulated by setting the
[Events](@ref Events_page) of the figure, e.g. `events(fig).mouseposition` or `events(fig).mousebutton`.

[`pixel_position`](@ref) gives the position to move the mouse to:

- `pixel_position(plot, i)`: the `i`-th marker or vertex of a `scatter`, `meshscatter`, `lines`, `linesegments` or
  `mesh` plot,
- `pixel_position(ax, point)`: a data point of an `Axis`, `Axis3`, `LScene` or `Scene`,
- `pixel_position(block, (rx, ry); relative = true)`: a position relative to the bounding box of a block, with
  `(0, 0)` at its bottom left.

### DataInspector hovers

To precompile the tooltip of a plot, create a `DataInspector` and move the mouse onto a plot element. The hover is
handled before the figure is rendered again:

```julia
@compile_workload begin
    fig, ax, plt = scatter(rand(10); inspector_label = (plot, i, pos) -> "point $i")
    DataInspector(fig)
    GLMakie.precompile_plot(fig) do
        events(fig).mouseposition[] = Tuple(pixel_position(plt, 1))
    end
end
```

Only the last mouse position is hovered, so call `precompile_plot` once per plot to precompile hovers over several
plots. Plot elements can only be picked in GLMakie during precompilation, so hovers have no effect in CairoMakie and
WGLMakie.

## Makie's own precompile workload

Makie's workload is controlled by the Makie preference `precompile_workload_level`. With `"full"`, the backends also
precompile the long tail of common recipes, for a near compile-free first plot of most plot types, at the cost of a
longer package precompilation:

```julia
using Preferences, Makie
set_preferences!(Makie, "precompile_workload_level" => "full")
```

As with every package using PrecompileTools, the workloads can be turned off with the `precompile_workload = false`
preference of Makie and each backend, which makes precompilation much faster during development.

## API

```@docs
GLMakie.precompile_plot
CairoMakie.precompile_plot
WGLMakie.precompile_plot
```
