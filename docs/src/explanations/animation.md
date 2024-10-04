# Animations

With Makie it is easy to create animated plots.
Animations work by making changes to data or plot attribute Observables and recording the changing figure frame by frame.
You can find out more about the Observables workflow on the [Observables](@ref) page.

## A simple example

To create an animation you need to use the [`record`](@ref) function.

First you create a `Figure`. Next, you pass a function that modifies this figure frame-by-frame to `record`.
Any changes you make to the figure or its plots will appear in the final animation.
You also need to pass an iterable which has as many elements as you want frames in your animation.
The function that you pass as the first argument is called with each element from this iterator
over the course of the animation.

As a start, here is how you can change the color of a line plot:

```@example
using GLMakie
GLMakie.activate!() # hide
using Makie.Colors

fig, ax, lineplot = lines(0..10, sin; linewidth=10)

# animation settings
nframes = 30
framerate = 30
hue_iterator = range(0, 360, length=nframes)

record(fig, "color_animation.mp4", hue_iterator;
        framerate = framerate) do hue
    lineplot.color = HSV(hue, 1, 0.75)
end
nothing # hide
```

```@raw html
<video autoplay loop muted playsinline controls src="./color_animation.mp4" />
```

Passing a function as the first argument is usually done with Julia's `do`-notation, which you might not be familiar with.
Instead of the above, we could also have written:

```julia
function change_function(hue)
    lineplot.color = HSV(hue, 1, 0.75)
end

record(change_function, fig, "color_animation.mp4", hue_iterator; framerate = framerate)
```

## File formats

Video files are created with [`FFMPEG_jll.jl`](https://github.com/JuliaBinaryWrappers/FFMPEG_jll.jl).
You can choose from the following file formats:

- `.mkv` (the default, doesn't need to convert)
- `.mp4` (good for web, widely supported)
- `.webm` (smallest file size)
- `.gif` (lowest quality with largest file size)

## Animations using `Observables`

Often, you want to animate a complex plot over time, and all the data that is displayed should be determined by the current time stamp.
Such a dependency is really easy to express with `Observables`.

We can save a lot of work if we create our data depending on a single time `Observable`, so we don't have to change every plot's data manually as the animation progresses.

Here is an example that plots two different functions.
The y-values of each depend on time and therefore we only have to change the time for both plots to change.
We use the convenient `@lift` macro which denotes that the `lift`ed expression depends on each Observable marked with a `$` sign.

```@example
using GLMakie

time = Observable(0.0)

xs = range(0, 7, length=40)

ys_1 = @lift(sin.(xs .- $time))
ys_2 = @lift(cos.(xs .- $time) .+ 3)

fig = lines(xs, ys_1, color = :blue, linewidth = 4,
    axis = (title = @lift("t = $(round($time, digits = 1))"),))
scatter!(xs, ys_2, color = :red, markersize = 15)

framerate = 30
timestamps = range(0, 2, step=1/framerate)

record(fig, "time_animation.mp4", timestamps;
        framerate = framerate) do t
    time[] = t
end
nothing # hide
```

```@raw html
<video autoplay loop muted playsinline controls src="./time_animation.mp4" />
```

You can set most plot attributes equal to `Observable`s, so that you need only update
a single variable (like time) during your animation loop.

For example, to make a line with color dependent on time, you could write:

```@example
using GLMakie

time = Observable(0.0)
color_observable = @lift(RGBf($time, 0, 0))

fig = lines(0..10, sin, color = color_observable)

framerate = 30
timestamps = range(0, 2, step=1/framerate)

record(fig, "color_animation_2.mp4", timestamps; framerate = framerate) do t
    time[] = t
end
nothing # hide
```

```@raw html
<video autoplay loop muted playsinline controls src="./color_animation_2.mp4" />
```

## Appending data with Observables

You can also append data to a plot during an animation.
Instead of passing `x` and `y` (or `z`) values separately,
it is better to make a `Observable` with a vector of `Point`s,
so that the number of `x` and `y` values can not go out of sync.

```@example
using GLMakie

points = Observable(Point2f[(0, 0)])

fig, ax = scatter(points)
limits!(ax, 0, 30, 0, 30)

frames = 1:30

record(fig, "append_animation.mp4", frames;
        framerate = 30) do frame
    new_point = Point2f(frame, frame)
    points[] = push!(points[], new_point)
end
nothing # hide
```

```@raw html
<video autoplay loop muted playsinline controls src="./append_animation.mp4" />
```

## Animating a plot "live"

You can animate a live plot easily using a loop.
Update all `Observables` that you need and then add a short sleep interval so that the display can refresh:

```julia
points = Observable(Point2f[randn(2)])

fig, ax = scatter(points)
limits!(ax, -4, 4, -4, 4)

fps = 60
nframes = 120

for i = 1:nframes
    new_point = Point2f(randn(2))
    points[] = push!(points[], new_point)
    sleep(1/fps) # refreshes the display!
end
```

Another example that updates the contents of a heatmap:

```@example
using GLMakie
GLMakie.activate!() # hide

function mandelbrot(x, y)
    z = c = x + y*im
    for i in 1:30.0; abs(z) > 2 && return i; z = z^2 + c; end; 0
end

x = LinRange(-2, 1, 200)
y = LinRange(-1.1, 1.1, 200)
matrix = mandelbrot.(x, y')
fig, ax, hm = heatmap(x, y, matrix)

N = 50
xmin = LinRange(-2.0, -0.72, N)
xmax = LinRange(1, -0.6, N)
ymin = LinRange(-1.1, -0.51, N)
ymax = LinRange(1, -0.42, N)

# we use `record` to show the resulting video in the docs.
# If one doesn't need to record a video, a normal loop works as well.
# Just don't forget to call `display(fig)` before the loop
# and without record, one needs to insert a yield to yield to the render task
record(fig, "heatmap_mandelbrot.mp4", 1:7:N) do i
    _x = LinRange(xmin[i], xmax[i], 200)
    _y = LinRange(ymin[i], ymax[i], 200)
    hm[1] = _x # update x coordinates
    hm[2] = _y # update y coordinates
    hm[3] = mandelbrot.(_x, _y') # update data
    autolimits!(ax) # update limits
    # yield() -> not required with record
end
```

```@raw html
<video loop muted playsinline controls src="./heatmap_mandelbrot.mp4" />
```
