# Interaction

Makie offers a sophisticated referencing system to share attributes across the Scene
in your plot. This is great for animations and saving resources - also if the backend
decides to put data on the GPU you might even share those in GPU memory.


### Using Mouse and Time to animate plots

The simples form is just to use getindex into a scene, which returns a life node!
Which means, if you do anything with that node, your resulting data will also be life!
`lift_node` creates a new node from a list of input nodes, which updates every time any 
of the inputs updates.


```@example 
using Makie

scene = Scene(resolution = (500, 500))

f(t, v, s) = (sin(v + t) * s, cos(v + t) * s)

p1 = scatter(lift_node(t-> f.(t, linspace(0, 2pi, 50), 1), scene[:time]))
p2 = scatter(lift_node(t-> f.(t * 2.0, linspace(0, 2pi, 50), 1.5), scene[:time]))
center!(scene)
nothing
# you can now reference to life attributes from the above plots:

lines = lift_node(p1[:positions], p2[:positions]) do pos1, pos2
    map((a, b)-> (a, b), pos1, pos2)
end

linesegment(lines)

center!(scene)
# record a video 
io = VideoStream(scene, ".", "interaction")
for i = 1:300
    recordframe!(io)
    yield()
    sleep(1/30)
end
finish(io, "mp4") # could also be gif, webm or mkv
nothing
```
```@raw html
<video controls autoplay>
  <source src="interaction.mp4" type="video/mp4">
  Your browser does not support mp4. Please use a modern browser like Chrome or Firefox.
</video>
```


### `@ref`

Is just syntactic sugar for accessing a key in a scene.
It might actually get deprecated, since just accessing the scene directly is convenient enough!

@ref Variable = Value # Inserts Value under name Variable into Scene

@ref Scene.Name1.Name2 # Syntactic sugar for `Scene[:Name1, :Name2]`
@ref Expr1, Expr1 # Syntactic sugar for `(@ref Expr1, @ref Expr2)`


## Soon to be implemented


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
