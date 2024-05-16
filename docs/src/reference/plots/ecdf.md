# ecdfplot

```@shortdocs; canonical=false
ecdfplot
```


## Examples

```@figure
f = Figure()
Axis(f[1, 1])

ecdfplot!(randn(200))

f
```

```@figure
f = Figure()
Axis(f[1, 1])

x = randn(200)
ecdfplot!(x, color = (:blue, 0.3))
ecdfplot!(x, color = :red, npoints=10)

f
```

```@figure
f = Figure()
Axis(f[1, 1])

x = rand(200)
w = @. x^2 * (1 - x)^2
ecdfplot!(x)
ecdfplot!(x; weights = w, color=:orange)

f
```

## Attributes

```@attrdocs
ECDFPlot
```
