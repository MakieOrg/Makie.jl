# Animation

`Makie.jl` has extensive support for animations; you can create arbitrary plots, and save them to:

- `.mkv` (the default, doesn't need to convert)
- `.mp4` (good for Web, most supported format)
- `.webm` (smallest file size)
- `.gif` (largest file size for the same quality)

This is all made possible through the use of the `ffmpeg` tool, wrapped by [`FFMPEG.jl`](https://github.com/JuliaIO/FFMPEG.jl).

Have a peek at [Interaction](@ref) for some more information once you're done with this.

## A simple example

Simple animations are easy to make; all you need to do is wrap your changes in the `record` function.

When recording, you can make changes to any aspect of the Scene or its plots.

Below is a small example of using `record`.


```@setup 1
using Makie, AbstractPlotting
```

```@example 1
scene = lines(rand(10); linewidth=10)

record(scene, "out.mp4", 1:255; framerate = 60) do i
    scene.plots[2][:color] = RGBf0(i/255, (255 - i)/255, 0) # animate scene
    # `scene.plots` gives the plots of the Scene.
    # `scene.plots[1]` is always the Axis if it exists,
    # and `scene.plots[2]` onward are the user-defined plots.
end;
```
![](out.mp4)

```@docs
record
```

In both cases, the returned value is a path pointing to the location of the recorded file.

## Animation using time

To animate a scene, you can also create a `Node`, e.g.:

```@example 1
time = Node(0.0)
```

and use `lift` on the Node to set up a pipeline to access its value. For example:

```@example 1
scene = Scene()
time = Node(0.1)
myfunc(v, t) = sin.(v .* t)
positions = lift(t -> myfunc.(range(0, stop=2pi, length=50), t), time)
scene = lines!(scene, positions)
```

now, whenever the Node `time` is updated (e.g. when you `push!` to it), the plot will also be updated.

```@example 1
push!(time, Base.time());
```

You can also set most attributes equal to `Observable`s, so that you need only update
a single variable (like time) during your animation loop. A translation of the first
example to this `Observables` paradigm is below:

```@example 1
"'Time' - an Observable that controls the animation"
t = Node(0)

"The colour of the line"
c = lift(t) do t
    RGBf0(t/255, (255 - t)/255, 0)
end

scene = lines(rand(10); linewidth=10, color = c)

record(scene, "out2.mp4", 1:255; framerate = 60) do i
    t[] = i # update `t`'s value
end
```
![](out2.mp4)

A more complicated example:

```@example 1
let
    scene = Scene()

    f(t, v, s) = (sin(v + t) * s, cos(v + t) * s, (cos(v + t) + sin(v)) * s)
    t = Node(Base.time()) # create a life signal
    limits = FRect3D(Vec3f0(-1.5, -1.5, -3), Vec3f0(3, 3, 6))
    p1 = meshscatter!(scene, lift(t-> f.(t, range(0, stop = 2pi, length = 50), 1), t), markersize = 0.05)[end]
    p2 = meshscatter!(scene, lift(t-> f.(t * 2.0, range(0, stop = 2pi, length = 50), 1.5), t), markersize = 0.05)[end]

    lines = lift(p1[1], p2[1]) do pos1, pos2
        map((a, b)-> (a, b), pos1, pos2)
    end
    linesegments!(scene, lines, linestyle = :dot, limits = limits)
    # record a video
    N = 150
    record(scene, "out3.mp4", 1:N) do i
        t[] = Base.time()
    end
end
```
![](out3.mp4)

## Appending data to a plot

If you're planning to append to a plot, like a `lines` or `scatter` plot (basically, anything that's point-based),
you will want to pass an `Observable` Array of [`Point`](@ref)s to the plotting function, instead of passing `x`, `y`
(and `z`) as separate Arrays.
This will mean that you won't run into dimension mismatch issues (since Observables are synchronously updated).

TODO add more tips here

## Animating a plot "live"

You can animate a plot in a `for` loop:

```julia
for i = 1:length(r)
    s[:markersize] = r[i]
    sleep(1/24)
end
```

Similarly, for plots based on functions:

```julia
scene = Scene()
v = range(0, stop=4pi, length=50)
f(v, t) = sin(v + t) # some function
s = lines!(
    scene,
    lift(t -> f.(v, t), time),
)[end];

for i = 1:length(v)
    time[] = i
    sleep(1/24)
end
```

If you want to animate a plot while interacting with it, check out the `async_latest` function,
and the [Interaction](@ref) section.

## Transforming a live loop to an animation

You can transform a live loop to a recording using the [`record`](@ref) function very simply. For example,

```julia
positions = Node(Point2f0.(rand(10), rand(10)))
scene = Scene()
scatter!(scene, positions)
for i in 1:10
    positions[] = Point2f0.(rand(10), rand(10))
    sleep(1/4)
end
```

can be recorded just by changing the for loop to a `record-do` "loop":

```@example 1
positions = Node(Point2f0.(rand(10), rand(10)))
scene = Scene()
scatter!(scene, positions)
record(scene, "name.mp4", 1:10) do i
    positions[] = Point2f0.(rand(10), rand(10))
    sleep(1/4)
end
```
![](name.mp4)

## More complex examples

```@example 1
scene = Scene();
function xy_data(x, y)
    val = sqrt(x^2 + y^2)
    val == 0.0 ? 1f0 : (sin(val)/val)
end
r = range(-2, stop = 2, length = 50)
surf_func(i) = [Float32(xy_data(x*i, y*i)) for x = r, y = r]
z = surf_func(20)
surf = surface!(scene, r, r, z)[end]

wf = wireframe!(scene, r, r, lift(x-> x .+ 1.0, surf[3]),
    linewidth = 2f0, color = lift(x-> to_colormap(x)[5], surf[:colormap])
)
N = 150
scene
record(scene, "out5.mp4", range(5, stop = 40, length = N)) do i
    surf[3] = surf_func(i)
end
```
![](out5.mp4)

You can see yet more complicated examples in the [Example Gallery](index.html)!
