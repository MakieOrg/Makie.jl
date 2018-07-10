```@setup plot_attributes
using Makie
```

Below is the list of all of the available plot attributes for Makie.
You can also get this by doing

```julia
help_attributes(Typ[; extended = true])
```

where `Typ` is the plot type.

To view a plot's attributes and their values, you can call `plot.attributes` to view the raw output,
or `plot.attributes.attributes` to get a Dict of the attribute keys and their values.

```@example plot_attributes
p = scatter(rand(10), rand(10))[end]; # use `[end]` to access the plot
p.attributes
p.attributes.attributes
```
