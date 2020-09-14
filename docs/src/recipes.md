# Plot Recipes

Recipes allow you to extend `Makie` with your own custom types and plotting commands.

There are two types of recipes. _Type recipes_ define a simple mapping from a
user defined type to an existing plot type. _Full recipes_ can customize the
theme and define a custom plotting function.

## Type recipes

Type recipes are really simple and just overload the argument conversion
pipeline, converting from one type to another, plottable type.

!!! warning `convert_arguments` must always return a Tuple.

An example is:

```julia
convert_arguments(x::Circle) = (decompose(Point2f, x),)
```

This can be done for all plot types or for a subset of plot types:

```julia
# All plot types
convert_arguments(P::Type{<:AbstractPlot}, x::MyType) = convert_arguments(P, rand(10, 10))
# Only for scatter plots
convert_arguments(P::Type{<:Scatter}, x::MyType) = convert_arguments(P, rand(10, 10))
# For a group of plots, using a conversion trait for instance PointBased plots, which includes Lines and Scatter
convert_arguments(P::PointBased, x::MyType)
# It is also possible to convert multiple arguments
convert_arguments(P::Type{<:Scatter}, x::MyType, y::MyOtherType)
```

Optionally you may define the default plot type so that `plot(x::MyType)` will
use this:

```julia
plottype(::MyType) = Surface
```

## Full recipes with the `@recipe` macro

A full recipe for `MyPlot` comes in two parts. First is the plot type name,
arguments and theme definition which are defined using the `@recipe` macro.
Second is a custom `plot!` for `MyPlot`, implemented in terms of the atomic
plotting functions.
We use an example to show how this works:

```julia
# arguments (x, y, z) && theme are optional
@recipe(MyPlot, x, y, z) do scene
    Theme(
        plot_color => :red
    )
end
```

This macro expands to several things. Firstly a type definition:

```julia
const MyPlot{ArgTypes} = Combined{myplot, ArgTypes}
```

The type parameter of `Combined` contains the function instead of e.g. a
symbol. This way the mapping from `MyPlot` to `myplot` is safer and simpler.
(The downside is we always need a function `myplot` - TODO: is this a problem?)
The following signatures are defined to make `MyPlot` nice to use:

```julia
myplot(args...; kw_args...) = ...
myplot!(scene, args...; kw_args...) = ...
myplot(kw_args::Dict, args...) = ...
myplot!(scene, kw_args::Dict, args...) = ...
#etc (not 100% settled what signatures there will be)
```

A specialization of `argument_names` is emitted if you have an argument list
`(x,y,z)` provided to the recipe macro:

    `argument_names(::Type{<: MyPlot}) = (:x, :y, :z)`

This is optional but it will allow the use of `plot_object[:x]` to
fetch the first argument from the call
`plot_object = myplot(rand(10), rand(10), rand(10))`, for example.

Alternatively you can always fetch the `i`th argument using `plot_object[i]`,
and if you leave out the `(x,y,z)`, the default version of `argument_names`
will provide `plot_object[:arg1]` etc.

The theme given in the body of the `@recipe` invocation is inserted into a
specialization of `default_theme` which inserts the theme into any scene that
plots `Myplot`:

```julia
function default_theme(scene, ::Myplot)
    Theme(
        plot_color => :red
    )
end
```

As the second part of defining `MyPlot`, you should implement the actual
plotting of the `MyPlot` object by specializing `plot!`:

```julia
function plot!(plot::MyPlot)
    # normal plotting code, building on any previously defined recipes
    # or atomic plotting operations, and adding to the combined `plot`:
    lines!(plot, rand(10), color = plot[:plot_color])
    plot!(plot, plot[:x], plot[:y])
    plot
end
```

It's possible to add specializations here, depending on the argument _types_
supplied to `myplot`. For example, to specialize the behavior of `myplot(a)`
when `a` is a 3D array of floating point numbers:

```julia
const MyVolume = MyPlot{Tuple{<:AbstractArray{<: AbstractFloat, 3}}}
argument_names(::Type{<: MyVolume}) = (:volume,) # again, optional
function plot!(plot::MyVolume)
    # plot a volume with a colormap going from fully transparent to plot_color
    volume!(plot, plot[:volume], colormap = :transparent => plot[:plot_color])
    plot
end
```

Here is a complete example of creating a custom type and a recipe for it.

```@example
using Makie
using AbstractPlotting
import AbstractPlotting: Plot, default_theme, plot!, to_value

struct Simulation
    grid::Vector{Point3f0}
end
# Probably worth having a macro for this!
function default_theme(scene::SceneLike, ::Type{<: Plot(Simulation)})
    Theme(
        advance = 0,
        molecule_sizes = [0.08, 0.04, 0.04],
        molecule_colors = [:maroon, :deepskyblue2, :deepskyblue2]
    )
end

# The recipe! - will get called for plot(!)(x::SimulationResult)
function AbstractPlotting.plot!(p::Plot(Simulation))
    sim = to_value(p[1]) # first argument is the SimulationResult
    # when advance changes, get new positions from the simulation
    mpos = lift(p[:advance]) do i
        sim.grid .+ rand(Point3f0, length(sim.grid)) .* 0.01f0
    end
    # size shouldn't change, so we might as well get the value instead of signal
    pos = to_value(mpos)
    N = length(pos)
    sizes = lift(p[:molecule_sizes]) do s
        repeat(s, outer = N ÷ 3)
    end
    sizes = lift(p[:molecule_sizes]) do s
        repeat(s, outer = N ÷ 3)
    end
    colors = lift(p[:molecule_colors]) do c
        repeat(c, outer = N ÷ 3)
    end
    scene = meshscatter!(p, mpos, markersize = sizes, color = colors)
    indices = Int[]
    for i in 1:3:N
        push!(indices, i, i + 1, i, i + 2)
    end
    meshplot = p.plots[end] # meshplot is the last plot we added to p
    # meshplot[1] -> the positions (first argument) converted to points, so
    # we don't do the conversion 2 times for linesegments!
    linesegments!(p, lift(x-> view(x, indices), meshplot[1]))
end

# To write out a video of the whole simulation
n = 5
r = range(-1, stop = 1, length = n)
grid = Point3f0.(r, reshape(r, (1, n, 1)), reshape(r, (1, 1, n)))
molecules = map(1:(n^3) * 3) do i
    i3 = ((i - 1) ÷ 3) + 1
    xy = 0.1; z = 0.08
    i % 3 == 1 && return grid[i3]
    i % 3 == 2 && return grid[i3] + Point3f0(xy, xy, z)
    i % 3 == 0 && return grid[i3] + Point3f0(-xy, xy, z)
end
result = Simulation(molecules)
scene = plot(result)
N = 100
record(scene, "molecules_simulation.mp4", 1:N) do i
    scene[end][:advance] = i
end

nothing # hide
```

![molecules simulation](molecules_simulation.mp4)