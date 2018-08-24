# Tutorial

Below is a quick tutorial to help get you started. Note that we assume you have [Julia](https://julialang.org/) installed and configured already.

## Getting Makie on Julia 0.6

```julia
#=
This will install the deprecated, first version of Makie
Look at IJulia examples for the old style
=#
Pkg.add("Makie")

#=
Get the bleeding edge version, which is used to generate
the `Examples from the documentation` + `Complex examples` section
=#
Pkg.checkout("Makie")
Pkg.checkout("AbstractPlotting")
```

## Getting Makie on Julia 0.7<sup>+</sup>

```Julia
add Makie#sd/07 AbstractPlotting#sd/07 GeometryTypes#sd/07 ImageMagick#sd/07 Reactive#sd/07
add ImageFiltering#master
test Makie
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
