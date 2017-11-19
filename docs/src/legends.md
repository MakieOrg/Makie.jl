# Legends

The Legend is an interactive object, that can be edited and interacted with like
any other object in Makie.

You can create it on your own, or let it get created by automatically by a `plot`
command.

```@example

using Makie, GeometryTypes, Colors

# Create some plots for which we want to generate a legend
scene = Scene()
plots = map([:dot, :dash, :dashdot], [2, 3, 4]) do ls, lw
    linesegment(linspace(1, 5, 100), rand(100), rand(100), linestyle = ls, linewidth = lw)
end
push!(plots, scatter(linspace(1, 5, 100), rand(100), rand(100)))
center!(scene)

# plot a legend for the plots with an array of names
l = Makie.legend(plots, ["attribute $i" for i in 1:4])
io = VideoStream(scene, ".", "legend")
record(io) = (for i = 1:35; recordframe!(io); sleep(1/30); end);

record(io)
# Change some attributes interactively
l[:position] = (0.4, 0.7)
record(io)
l[:backgroundcolor] = RGBA(0.95, 0.95, 0.95)
record(io)
l[:strokecolor] = RGB(0.8, 0.8, 0.8)
record(io)
l[:gap] = 30
record(io)
l[:textsize] = 19
record(io)
l[:linepattern] = Point2f0[(0,-0.2), (0.5, 0.2), (0.5, 0.2), (1.0, -0.2)]
record(io)
l[:scatterpattern] = decompose(Point2f0, Circle(Point2f0(0.5, 0), 0.3f0), 9)
record(io)
l[:markersize] = 2f0
record(io)
finish(io, "mp4")
nothing
```

```@raw html
<video controls autoplay>
  <source src="legend.mp4" type="video/mp4">
  Your browser does not support mp4. Please use a modern browser like Chrome or Firefox.
</video>
```
