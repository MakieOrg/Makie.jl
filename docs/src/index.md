![Makie.jl](assets/logo.png)

Welcome to [`Makie`](https://github.com/JuliaPlots/Makie.jl/), a high-performance, extendable, and multi-platform plotting ecosystem for the [Julia](https://julialang.org/) programming language.

## Installation and Import

The `Makie.jl` package is a convenience bundle of `AbstractPlotting.jl` and the commonly used `GLMakie.jl` backend.
To install it, do:

```julia
# in the REPL
]add Makie

# elsewhere
using Pkg
Pkg.add("Makie")

# import the package
using Makie
```

If you want to use a different backend, for example `CairoMakie`, install `AbstractPlotting` as well.
```julia
# install
]add AbstractPlotting, CairoMakie

# import
using AbstractPlotting
using CairoMakie

# to switch between multiple loaded backends, use activate!()
CairoMakie.activate!()
```

## Getting Started

See the [Tutorial](@ref) to learn the basics of plotting with Makie.
For an introduction to more complex plots and layouts, check the [MakieLayout Tutorial](@ref).


## The Makie Ecosystem

The Makie ecosystem spans several core and extension packages.

### Core Packages

`AbstractPlotting.jl` is the backbone of the ecosystem. It defines the infrastructure objects which can be visualized using backend packages.

There are three backends:

| Package | Description |
| --- | --- |
| [`GLMakie.jl`](https://github.com/JuliaPlots/GLMakie.jl) | Default Makie backend. GPU-powered, interactive 2D and 3D plotting in standalone `GLFW.jl` windows. |
| [`CairoMakie.jl`](https://github.com/JuliaPlots/CairoMakie.jl) | `Cairo.jl` based, non-interactive 2D backend for publication-quality vector graphics. |
| [`WGLMakie.jl`](https://github.com/JuliaPlots/WGLMakie.jl) | WebGL-based interactive 2D and 3D plotting that runs within browsers.


### Extension Packages

Here is a selection of peripheral packages which offer additional features:

| Package | Description |
| --- | --- |
| [`AlgebraOfGraphics.jl`](https://github.com/JuliaPlots/AlgebraOfGraphics.jl/) | Grammar-of-graphics style plotting, inspired by ggplot2. |
| [`GeoMakie.jl`](https://github.com/JuliaPlots/GeoMakie.jl) | Geographic plotting utilities. |


## Getting Help

If have questions or run into any issues, you can:

1) Use the REPL `?` help mode
1) Open an issue in the [Makie.jl](https://github.com/JuliaPlots/Makie.jl) repository.
1) Join the `#makie` channel in the [Julia Slack group](https://slackinvite.julialang.org).
