```@setup plot_attributes
using GLMakie
using AbstractPlotting
```

Below is a list of some common plot attributes for Makie.

To view a plot's attributes and their values, you can call `plot.attributes` to view the raw output,
or `plot.attributes.attributes` to get a Dict of the attribute keys and their values.

```@example plot_attributes
fig, ax, plotobject = scatter(rand(10), rand(10))
plotobject.attributes
plotobject.attributes.attributes
```
