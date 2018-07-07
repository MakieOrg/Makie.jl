```@meta
CurrentModule = Makie
```

```@setup animation_tutorial
using Makie
```

# Interaction

Makie offers a sophisticated referencing system to share attributes across the Scene
in your plot. This is great for animations and saving resources -- also if the backend
decides to put data on the GPU you might even share those in GPU memory.

Animations in Makie are handled by using `Reactive.jl` signals.
These signals are called `Node`s in Makie, and can be continuously updated by pushing a value to it.
Here is a brief tutorial:

First, create a `Node`:

```@example animation_tutorial
x = Node(0.0) # set up a Node, and give it a default value of 0.0
```

You can then derive a signal off of the value of the Node by using `lift`:

```@example animation_tutorial
y = lift(a -> a^2, x)
```

Now, for every value of the Node `x`, the derived Node `y` will hold the square of the value.

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

That is to say, the Node `y` maps the function `f` (`a -> a^2` in this case) to `x` whenever the Node `x` is updated, and returns the corresponding signal to `y`.
This is the basis of signal updating, and is used for updating plots in Makie.

Note: `lift` is just an alias for `Reactive.map`,
and `Node` is just an alias for `Reactive.Signal`.

For more information, check out [`Reactive.jl`'s documentation](https://juliagizmos.github.io/Reactive.jl/).

## Using Mouse and Time to animate plots

Animations are enabled using `Reactive.jl` signals.

### Interaction using time

To animate a scene, you need to create a `Node`, e.g.:

```julia
time = Node(0.0)
```

and then use `lift` on the node to access the values live. Then, any plot that is based on the `lift` will be updated every time the input node updates!

@example_database("Interaction")


### Interaction using the mouse

To interact with a scene using the mouse cursor, simply `lift` the cursor, e.g.:

```julia
pos = lift(scene.events.mouseposition, time)
```

@example_database("Interaction with Mouse")

For more info, consult the [Examples index](@ref).

### Animating and sharing on the GPU

```Julia
using Makie

scene = Scene(resolution = (500, 500))
@ref A = rand(32, 32) # if uploaded to the GPU, it will be shared on the GPU

surface(@ref A) # refer to exactly the same a in wireframe and surface plot
wireframe((@ref A) .+ 0.5) # offsets A on the GPU based on the same data

for i = 1:10
    # updates A - resulting in an animation of the surface and offsetted wireframe plot
    @ref A[:, :] = rand(32, 32)
end
```

### Simple GUI

```Julia
using Makie

scene = Scene()
@ref slicer1 = slider(linspace(0, 1, 100)) # create a slider

# generate some pretty data
function xy_data(x,y,i)
    x = (x - 0.5f0) * i
    y = (y - 0.5f0) * i
    r = sqrt(x * x + y * y)
    Float32(sin(r) / r)
end

surf(i, N) = Float32[xy_data(x, y, i, N) for x = linspace(0, 1, N), y = linspace(0, 1, N)]

surface(surf.(@ref slicer1, 512)) # refer to exactly the same a in wireframe and surface plot

```
