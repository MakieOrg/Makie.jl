# Interaction

Makie offers a sophisticated referencing system to share attributes across the Scene
in your plot. This is great for animations and saving resources -- also if the backend
decides to put data on the GPU you might even share those in GPU memory.


## Using Mouse and Time to animate plots

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

For more info, consult the [Examples gallery](@ref).

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
