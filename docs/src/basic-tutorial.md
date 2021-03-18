# Basic Tutorial

Here is a quick tutorial to get you started. We assume you have [Julia](https://julialang.org/) and `GLMakie.jl` (or one of the other backends) installed already.

First, we import GLMakie, which might take a little bit of time because there is a lot to precompile. Just sit tight!
For this tutorial, we also call `AbstractPlotting.inline!(true)` so plots appear inline after each example.
Otherwise, an interactive window will open when you return a `Figure`.

```@example 1
using GLMakie
GLMakie.activate!() # hide
AbstractPlotting.inline!(true)
nothing # hide
```

!!! note
    A `Figure` is usually displayed whenever it is returned in global scope (e.g. in the REPL).
    To display a Figure from within a local scope,
    like from within a function, you can directly call `display(figure)`.  

## A First Plot

Let's begin by plotting some points using the `scatter` function.


```@example 1
points = [Point2f0(cos(t), sin(t)) for t in LinRange(0, 2pi, 20)]
colors = 1:20
figure, axis, scatterobject = scatter(points, color = colors, markersize = 15)
figure
```

You can see that we've split the return value of `scatter` into three components: `figure`, `axis` and `scatterobject`.
Every plotting function in its default form returns an object of type `FigureAxisPlot` which bundles these three parts, which makes it easy to continue working separately with them.

## Changing Attributes

One great feature of Makie is that it uses `Observables` (or `Nodes` as a Makie-specific alias),
which make it easy to write visualizations that can be updated dynamically with new data.

An `Observable` is a container object which notifies all its listeners whenever its content changes.
Put simply, using `Observables`, if your input data changes your plots change as well.

Plot objects usually have a collection of attributes, which are observables. If you change them,
the plots update immediately.
Let's try to change the marker size of our scatter plot:

```@example 1
scatterobject.markersize = 30
figure
```


## Adding A Plot

Let's add another scatter plot to our axis.
To add a plot to an existing figure or axis, you use the mutating version with a `!`.
Each plot type such as `Scatter` has a non-mutating function (`scatter`) and a mutating function (`scatter!`) associated with it.

Let's plot another circle.
This time we try some different arguments, a circle function and a range of values.

We use `scatter!` without passing a specific target as the first argument, which plots into the last used axis.

```@example 1
circlefunc = ts -> 1.5 .* Point2f0.(cos.(ts), sin.(ts))
scatter!(circlefunc, LinRange(0, 2pi, 30), color = :red)
figure
```

## Plotting `Observables`

So far, we have plotted normal "static" values - a simple array of points, or a function evaluated on static values.
Makie makes it really easy to plot "dynamic" values as well.
This is done using Observables.

Imagine that you want to interactively visualize how a sine function over a constant interval depends on its parameters.
That means the x values are fixed but the y values depend on the frequency and phase of the sine function.
Such a dependency is easy to express with `Observables` or `Nodes` for short.

Usually, all plot functions accept their input arguments and attributes as `Observables`.
If you don't pass `Observables`, they get converted internally anyway.

```@example 1
xs = -pi:0.01:pi
frequency = Node(3.0) # Node === Observable
phase = Node(0.0)

ys = lift(frequency, phase) do fr, ph
    @. 0.3 * sin(fr * xs - ph)
end

lines!(xs, ys, color = :blue, linewidth = 3)
figure
```

You can see that our sine function was nicely visualized. The `lift` function takes as its first
input a function which computes its output from the other arguments, `frequency` and `phase`
in this case, which are `Observables`.
The output is then stored inside another `Observable`, `ys`.
Therefore, `ys` always contains the result of the sine function
with the current `frequency` and `phase` applied
to the values in `xs`. (If you haven't used the `do` syntax before, it is Julia's way of passing
an anonymous function as the first argument to another function.
It's very useful for dealing with `Observables`.)

!!! note
    For short functions, there is a really convenient macro alternative to `lift`.
    Instead of what we wrote above, we could have written `ys = @lift(0.3 * sin($frequency .* xs .- $phase))`.
    Just prefix expressions that reference observables with a `$` symbol.

Now, we can change the `frequency` to a different value and the plot will change with it.
`Observables` are mutated with empty square brackets (like `Ref`s).

```@example 1
frequency[] = 9
figure
```

You see that the line plot has changed to reflect the new frequency.
That's how easy it is to create a dynamic visualization with `Observables`. 
Imagine the opportunities to hook Observables up with sliders and buttons to control a complex plot.


## Saving Static Plots

Makie overloads the `FileIO` interface. This is how you save this figure as a `png`:

```julia
save("sineplot.png", figure)
```

!!! note
    Different backends have different possible output formats. `GLMakie` as a GPU-powered backend can
    only output bitmaps like `png`. `CairoMakie` can output high-quality vector graphics such as `svg` and
    `pdf`, on the other hand those formats don't work as well (or at all) with 3D content.

See [Backends & Output](@ref) for more information on this.

## Creating Animations

Often, we want to create small videos that show how a visualization changes over time.
This is really easy to do if we already have a plot with observables.
Once we have our figure, we can just change the observables that we want in a closure function and
pass that to `record`, which creates a video for us.

We can just re-use our existing figure. Let's change the phase over time.
We just need to supply an iterator with as many elements as we want frames in our video.

```@example 1
framerate = 30 # fps
timestamps = 0:1/framerate:3

record(figure, "phase_animation.mp4", timestamps; framerate = framerate) do t
    phase[] = 2 * t * 2pi
end
nothing # hide
```

And here is our result, as we expect the sine function moves sideways.

![phase_animation](phase_animation.mp4)

For more information, see the [Animations](@ref) and the [Observables & Interaction](@ref) sections.

## Summary

That concludes our short tutorial. We hope you have learned how to create basic plots
with Makie and how easy it is to change and animate them using Observables.

