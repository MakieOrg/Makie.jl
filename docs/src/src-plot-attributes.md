```@setup plot_attributes
using Makie
```

Below is a list of some common plot attributes for Makie.

To view a plot's attributes and their values, you can call `plot.attributes` to view the raw output,
or `plot.attributes.attributes` to get a Dict of the attribute keys and their values.

```@example plot_attributes
p = scatter(rand(10), rand(10))[end]; # use `[end]` to access the plot
p.attributes
p.attributes.attributes
```
