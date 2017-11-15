# Legend

The Legend is an interactive object, that can be edited and interacted with like
any other object in Makie.

You can create it on your own, or let it get created by automatically by a `plot`
command.

```julia

scene = Scene()

legend = Legend(
    names = ["hello", "names"],
    markers = [:circle, :plus],
    colors = [:white, :black],
    backgroundcolor = :gray
)

legend[:names][1] = "update name" # easily update the names in the label

legend[:colors] = [:green, :blue] # update color and all other attributes in the same way

# add to a plot

p = plot(rand(10, 2))

p[:legend] = legend # voila, your plot now has a legend.

# Alternatively do:

p = plot(rand(10, 2), legend = Legend(names = ["hello", "legend"]))
```
