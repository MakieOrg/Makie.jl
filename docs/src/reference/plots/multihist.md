# multihist

```@shortdocs; canonical=false
multihist
```


## Examples

```@figure backend=GLMakie
data1 = rand(100) .* 2.0 .- 1.0
data2 = rand(100) .* 2.0

f = Figure()
multihist(f[1, 1], [data1, data2], colormap = :Set3_10)
f
```

#### Histogram with labels

You can use all the same arguments as [`barplot`](@ref):
```@figure
data = [randn(1000), randn(1000)]

multihist(data, normalization = :pdf, bar_labels = :values,
     label_formatter=x-> round(x, digits=2), label_size = 15,
     strokewidth = 0.5, strokecolor = (:black, 0.5), color = :values)
```

#### Moving histograms

With `scale_to`, and `offset`, one can put multiple histograms into the same plot.
Note, that offset automatically sets fillto, to move the whole barplot.
Also, one can use a negative `scale_to` amount to flip the histogram,
or `scale_to=:flip` to flip the direction of the bars without changing their height.

```@figure
fig = Figure()
ax = Axis(fig[1, 1])
for i in 1:5
     multihist!(ax, randn(1000), scale_to=-0.6, offset=i, direction=:x)
end
fig
```

## Attributes

```@attrdocs
MultiHist
```
