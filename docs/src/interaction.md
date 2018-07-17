```@meta
CurrentModule = Makie
```

```@setup animation_tutorial
using Makie
```

```@setup time_animation
using Makie
```

```@setup mouse_animation
using Makie
```

# Interaction
Makie offers a sophisticated referencing system to share attributes across the Scene
in your plot. This is great for animations and saving resources -- also if the backend
decides to put data on the GPU you might even share those in GPU memory.

Animations in Makie are handled by using `Reactive.jl` signals.
These signals are called `Node`s in Makie, and can be continuously updated by pushing a value to it.
See below for a brief tutorial about the signals pipeline.

## Tutorial: interaction pipeline
First, create a `Node`:

```@example animation_tutorial
x = Node(0.0) # set up a Node, and give it a default value of 0.0
```

Note that `Reactive` also assigns an ID and a unique name to the Node.
You can then derive a signal off of the value of the Node by using `lift`:

```@example animation_tutorial
f(a) = a^2
y = lift(a -> f(a), x)
```

Now, for every value of the Node `x`, the derived Node `y` will hold the value `f(x)`.

To update the value of the Node, `push!` to it:

```@example animation_tutorial
push!(x, 5.0)
```

Note how the value of `y` has been changed as well, in addition to `x`:

```@example animation_tutorial
for i in (x, y)
    println(i.value)
end
```

That is to say, the Node `y` maps the function `f` (which is `a -> a^2` in this case) on `x` whenever the Node `x` is updated, and returns the corresponding signal to `y`.
This is the basis of signal updating, and is used for updating plots in Makie.
Any plot created based on this pipeline system will get updated whenever the Nodes it is based on are updated.

Note: for now, `lift` is just an alias for `Reactive.map`,
and `Node` is just an alias for `Reactive.Signal`.

For more information, check out [`Reactive.jl`'s documentation](https://juliagizmos.github.io/Reactive.jl/).

## Animation using time
To animate a scene, you need to create a `Node`, e.g.:

```julia
time = Node(0.0)
```

and use `lift` on the Node to set up a pipeline to access its value. For example:

```julia
scene = Scene()
time = Node(0.0)
myfunc(v, t) = sin.(v, t)

scene = lines!(
    scene,
    lift(t -> f.(linspace(0, 2pi, 50), t), time)
)
```

now, whenever the Node `time` is updated (e.g. when you `push!` to it), the plot will also be updated.

```julia
push!(time, Base.time())
```


### Examples

@example_database("pulsing marker")

@example_database("Interaction")


## Interaction using the mouse
A few default Nodes are already implemented in a `scene`'s Events (see them in `scene.events`), so to use them in your interaction pipeline, you can simply `lift` them.

For example, for interaction with the mouse cursor, `lift` the `mouseposition` signal.

```julia
pos = lift(scene.events.mouseposition) do mpos
    # do stuff
end
```

### Examples

@example_database("Interaction with Mouse")

For more examples, consult the [Examples index](@ref).


## Correct way to animate a plot
You can animate a plot in a `for` loop:

```julia
r = 1:10
for i = 1:length(r)
    push!(s[:markersize], r[i])
    AbstractPlotting.force_update!()
    sleep(1/24)
end
```

But, if you `push!` to a plot, it doesn't necessarily get updated whenever an attribute changes, so you must call `force_update!()`.

A better way to do it is to access the attribute of a plot directly using its symbol, and when you change it, the plot automatically gets updated live, so you no longer need to call `force_update!()`:

```julia
for i = 1:length(r)
    s[:markersize] = r[i]
    # AbstractPlotting.force_update!() is no longer needed
    sleep(1/24)
end
```

Similarly, for plots based on functions:

```julia
scene = Scene()
v = linspace(0, 4pi, 50)
f(v, t) = sin(v + t) # some function
s = lines!(
    scene,
    lift(t -> f.(v, t), time),
)[end];

for i = 1:length(v)
    push!(time, i)
    sleep(1/24)
end
```
