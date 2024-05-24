# qqplot

```@shortdocs; canonical=false
qqplot
```


## Examples

Test if `xs` and `ys` follow the same distribution.

```@figure
xs = randn(100)
ys = randn(100)

qqplot(xs, ys, qqline = :identity)
```

## Attributes

```@attrdocs
QQPlot
```
