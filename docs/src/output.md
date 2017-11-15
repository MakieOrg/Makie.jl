# Input Output

Makie overloads the FileIO interface.
So you can just write e.g.:
```Julia
save(scene, "test.png")
save(scene, "test.jpg")
```

There is also the option to save a plot as a Julia File (not implemented yet)

```Julia
save(scene, "test.jl")
```

This will try to reproduce the plotting commands as closely as possible to recreate the current scene.
You can specify if you want to save the defaults explicitly or if you not want to store them, so that
whenever you change defaults and the saved code gets loaded it will take the new defaults.


# VideoStream


```@docs

VideoStream
finish
```

```@example
using Makie

scene = Scene(resolution = (500, 500))

f(t, v, s) = (sin(v + t) * s, cos(v + t) * s, (cos(v + t) + sin(v)) * s)
t = to_node(time()) # create a life signal
p1 = meshscatter(lift_node(t-> f.(t, linspace(0, 2pi, 50), 1), t))
p2 = meshscatter(lift_node(t-> f.(t * 2.0, linspace(0, 2pi, 50), 1.5), t))
center!(scene)
nothing
# you can now reference to life attributes from the above plots:

lines = lift_node(p1[:positions], p2[:positions]) do pos1, pos2
    map((a, b)-> (a, b), pos1, pos2)
end

linesegment(lines, linestyle = :dot)

center!(scene)
# record a video
io = VideoStream(scene, ".", "output_vid")
for i = 1:300
    push!(t, time())
    recordframe!(io)
    yield()
    sleep(1/30)
end
finish(io, "mp4") # could also be gif, webm or mkv
nothing
```

```@raw html
<video controls autoplay>
  <source src="output_vid.mp4" type="video/mp4">
  Your browser does not support mp4. Please use a modern browser like Chrome or Firefox.
</video>
```
