# Tutorial

Here is a quick tutorial to get you started. We assume you have [Julia](https://julialang.org/) and `Makie.jl` installed already.

First, we import Makie, which might take a little bit of time because there is a lot to precompile.
For this tutorial, we also call `inline!(true)` so plots appear inline after each example.
Otherwise, an interactive window will open when you return a `Scene`.

!!! note
    `Scene`s will only display by default in global scope.
    To make a Scene display when it's defined in a local scope,
    like a function or a module, you can call `display(scene)`,
    which will automatically display it in the best available display.  


```@example 1
using Makie
Makie.AbstractPlotting.inline!(true)
nothing # hide
```

## Creating a `Scene`

A `Scene` object contains plot objects such as `lines`, `scatter`s and `poly`s, and is the basis of a Makie figure. You can initialize it like so:

```@example 1
scene = Scene()
```

The scene is empty as we haven't put anything into it, yet.

## Adding plots to a `Scene`

Let's create a scatter plot. We make a vector of points in a circle and use `scatter!` to plot them into
our scene.
Each plot type (e.g. `Scatter`) in Makie has a normal version (`scatter`) and a mutating version (`scatter!`).
The normal version returns a `Scene` with the plot in it, the mutating version adds that plot to an
existing `Scene`. Here we use the mutating version because we have a scene already.

Mutating plotting functions return the changed scene by default.


```@example 1
points = [Point2f0(cos(t), sin(t)) for t in LinRange(0, 2pi, 20)]
colors = 1:20
scatter!(scene, points, color = colors, markersize = 15)
```

As you can see, we also got a basic 2D axis with the `scatter!` command. If you use a 3D plotting function,
the axis will be a 3D version as well. Sometimes you don't want this automatic axis.
In that case, you can use the keyword argument `show_axis = false`.

!!! note
    You can put your mouse in the plot window and scroll to zoom. **Right click and drag** lets you pan around the scene, and **left click and drag** lets you do selection zoom (in 2D plots), or orbit around the scene (in 3D plots).

## Changing Attributes

One great feature of Makie is that it uses `Observables` (or `Nodes` as a Makie-specific alias),
which make it easy to write visualizations that can be updated dynamically with new data.

An `Observable` is a container object which notifies all its listeners whenever its content changes.
Put simply, using `Observables`, if your input data changes your plots change as well.

Plot objects usually have a collection of attributes, which are observables. If you change them,
the plots update and the scene will reflect that.
Let's try to change the marker size of the scatter we created last.

To access the `Scatter` object we added to the scene, we can index into the scene.
The scatter is the last object, so we can use `scene[end]`. Then we change the markersize attribute:

```@example 1
scatterobject = scene[end]
scatterobject.markersize = 30
scene
```

## Plotting `Observables`

Let's add a line plot to our scene. The corresponding function is `lines!`.

Imagine that you want to interactively visualize different sine functions along an interval.
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

lines!(scene, xs, ys, color = :blue, linewidth = 3)
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

scene
```

You see that the line plot has changed to reflect the new frequency.
That's how easy it is to create a dynamic visualization with `Observables`. 
Imagine the opportunities to hook Observables up with sliders and buttons to control a complex plot.


## Saving Static Plots

Makie overloads the `FileIO` interface. This is how you save this scene as a `png`:

```julia
save("sineplot.png", scene)
```

!!! note
    Different backends have different possible output formats. `GLMakie` as a GPU-powered backend can
    only output bitmaps like `png`. `CairoMakie` can output high-quality vector graphics such as `svg` and
    `pdf`, on the other hand those formats don't work well (or at all) with 3D content.

See [Output](@ref) for more information on this.

## Creating Animations

Often, we want to create small videos that show how a visualization changes over time.
This is really easy to do if we already have a plot with observables.
Once we have our scene, we can just change the observables that we want in a closure function and
pass that to `record`, which creates a video for us.

We can just re-use our existing scene. Let's change the phase over time.
We just need to supply an iterator with as many elements as we want frames in our video.

```@example 1
framerate = 30 # fps
timestamps = 0:1/framerate:3

record(scene, "phase_animation.mp4", timestamps; framerate = framerate) do t
    phase[] = 2 * t * 2pi
end
nothing # hide
```

And here is our result, as we expect the sine function moves sideways.

![phase_animation](phase_animation.mp4)

For more information, see the [Animation](@ref) and the [Interaction](@ref) sections.

## Summary

That concludes our short tutorial. We hope you have learned how to create basic plots
with Makie and how easy it is to change and animate them using Observables.

You can check out more examples that you can adapt
in the [Example Gallery](http://juliaplots.org/MakieReferenceImages/gallery/index.html).
