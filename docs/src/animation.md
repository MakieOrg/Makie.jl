# Animations

With `Makie.jl` it is easy to create animated plots.
Animations work by making changes to data or plot attribute Observables and recording the changing scene frame by frame.
You can find out more about the Observables workflow on the [Observables & Interaction](@ref) page.


## A Simple Example

To create an animation you need to use the [`record`](@ref) function.

First you create a `Scene`. Next, you pass a function that modifies this scene frame-by-frame to `record`.
Any changes you make to the scene or its plots will appear in the final animation.
You also need to pass an iterable which has as many elements as you want frames in your animation.
The function that you pass as the first argument is called with each element from this iterator
over the course of the animation.

As a start, here is how you can change the color of a line plot:

```@example 1
using GLMakie, AbstractPlotting
using AbstractPlotting.Colors

figure, ax, lineplot = lines(0..10, sin; linewidth=10)

# animation settings
n_frames = 30
framerate = 30
hue_iterator = LinRange(0, 360, n_frames)

record(figure, "color_animation.mp4", hue_iterator; framerate = framerate) do hue
    lineplot.color = HSV(hue, 1, 0.75)
end
nothing # hide
```
![color animation](color_animation.mp4)

Passing a function as the first argument is usually done with Julia's `do`-notation, which you might not be familiar with.
Instead of the above, we could also have written:

```julia
function change_function(hue)
    lineplot.color = HSV(hue, 1, 0.75)
end

record(change_function, figure, "color_animation.mp4", hue_iterator; framerate = framerate)
```


## File Formats

Video files are created with [`FFMPEG.jl`](https://github.com/JuliaIO/FFMPEG.jl).
You can choose from the following file formats:

- `.mkv` (the default, doesn't need to convert)
- `.mp4` (good for web, widely supported)
- `.webm` (smallest file size)
- `.gif` (lowest quality with largest file size)


## Animations Using Observables

Often, you want to animate a complex plot over time, and all the data that is displayed should be determined by the current time stamp.
Such a dependency is really easy to express with `Observables` or `Nodes`.

We can save a lot of work if we create our data depending on a single time `Node`, so we don't have to change every plot's data manually as the animation progresses.

Here is an example that plots two different functions.
The y-values of each depend on time and therefore we only have to change the time for both plots to change.
We use the convenient `@lift` macro which denotes that the `lift`ed expression depends on each Observable marked with a `$` sign.

```@example 1
time = Node(0.0)

xs = LinRange(0, 7, 40)

ys_1 = @lift(sin.(xs .- $time))
ys_2 = @lift(cos.(xs .- $time) .+ 3)

figure, _ = lines(xs, ys_1, color = :blue, linewidth = 4)
scatter!(xs, ys_2, color = :red, markersize = 15)

timestamps = 0:1/30:2

record(figure, "time_animation.mp4", timestamps; framerate = 30) do t
    time[] = t
end
nothing # hide
```

![time animation](time_animation.mp4)

You can set most plot attributes equal to `Observable`s, so that you need only update
a single variable (like time) during your animation loop.

For example, to make a line with color dependent on time, you could write:

```julia
time = Node(0.0)
color_observable = @lift(RGBf0($time, 0, 0))

lines(0..10, sin, color = color_observable)
```

## Appending Data With Observables

You can also append data to a plot during an animation.
Instead of passing x and y (or z) values separately,
it's better to make a `Node` with a vector of `Point`s,
so that the number of x and y values can not go out of sync.

```@example 1
points = Node(Point2f0[(0, 0)])

figure = Figure()
ax = figure[1, 1] = Axis(figure)
scatter!(ax, points)
limits!(ax, 0, 30, 0, 30)

frames = 1:30

record(figure, "append_animation.mp4", frames; framerate = 30) do frame
    new_point = Point2f0(frame, frame)
    points[] = push!(points[], new_point)
end
nothing # hide
```

![append animation](append_animation.mp4)

## Animating a Plot "Live"

You can animate a live plot easily using a loop. 
Update all `Observables` that you need and then add a short sleep interval so that the display can refresh:

```julia
for i = 1:n_frames
    time_observable[] = time()
    sleep(1/30)
end
```

If you want to animate a plot while interacting with it, check out the `async_latest` function,
and the [Observables & Interaction](@ref) section.


## More Animation Examples

You can see more complex examples in the [Example Gallery](http://juliaplots.org/MakieReferenceImages/gallery/index.html)!
