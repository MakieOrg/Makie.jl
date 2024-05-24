# hist

```@shortdocs; canonical=false
hist
```


## Examples

```@figure backend=GLMakie
data = randn(1000)

f = Figure()
hist(f[1, 1], data, bins = 10)
hist(f[1, 2], data, bins = 20, color = :red, strokewidth = 1, strokecolor = :black)
hist(f[2, 1], data, bins = [-5, -2, -1, 0, 1, 2, 5], color = :gray)
hist(f[2, 2], data, normalization = :pdf)
f
```

#### Histogram with labels

You can use all the same arguments as [`barplot`](@ref):
```@figure
data = randn(1000)

hist(data, normalization = :pdf, bar_labels = :values,
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
     hist!(ax, randn(1000), scale_to=-0.6, offset=i, direction=:x)
end
fig
```

#### Using statistical weights

```@figure
using Distributions


N = 100_000
x = rand(Uniform(-5, 5), N)

w = pdf.(Normal(), x)

fig = Figure()
hist(fig[1,1], x)
hist(fig[1,2], x, weights = w)

fig
```

## Attributes

```@attrdocs
Hist
```
