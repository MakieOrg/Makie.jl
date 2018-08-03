# Tutorial

Below is a quick tutorial to help get you started. Note that we assume you have [Julia](https://julialang.org/) installed and configured already.

To get Makie, run this in the REPL:
```julia
Pkg.add("Makie")
Pkg.update() # optional
```

To use Makie:
```julia
using Makie
```

The first use of Makie might take a little bit of time, due to precompilation.

## Set the `Scene`

The `Scene` object holds everything in a plot, and you can initialize it by doing so:

```julia
scene = Scene()
```

Note that before you put anything in the scene, it will be black!

## Basic plotting

Below are some examples of basic plots to help you get oriented.

You can put your in the plot window and scroll to zoom. Right click and drag lets you pan around the scene, and left click and drag lets you do selection zoom (in 2D plots), or orbit around the scene (in 3D plots).

Many of these examples also work in 3D,

### Scatter plot

@example_database("Tutorial simple scatter")

@example_database("Tutorial markersize")

### Line plot

@example_database("Tutorial simple line")

### Adding to a scene

@example_database("Tutorial adding to a scene")

### Adjusting scene limits

@example_database("Tutorial adjusting scene limits")

### Basic theming

@example_database("Tutorial basic theming")

## Saving plots or animations

See the [Output](@ref) section.


## More examples

See the [Examples index](@ref).
