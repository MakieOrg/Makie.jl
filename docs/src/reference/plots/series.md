# series

```@shortdocs; canonical=false
series
```


## Examples

### Matrix

```@figure
data = cumsum(randn(4, 101), dims = 2)

fig, ax, sp = series(data, labels=["label $i" for i in 1:4])
axislegend(ax)
fig
```

### Vector of vectors

```@figure
pointvectors = [Point2f.(1:100, cumsum(randn(100))) for i in 1:4]

series(pointvectors, markersize=5, color=:Set1)
```

### Vector and matrix

```@figure
data = cumsum(randn(4, 101), dims = 2)

series(0:0.1:10, data, solid_color=:black)
```

## Attributes

```@attrdocs
Series
```
