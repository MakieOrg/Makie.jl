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

Check if `xs` follows a `Normal` distribution which is fit to the data first.
Alternatively, you can pass a specific `Normal` distribution to use, like `Normal(0, 1)`.

```@figure
using Distributions

xs = randn(100)

qqplot(Normal, xs, qqline = :identity)
```

An alternative syntax is giving the data as the sole positional argument and passing the distribution via the `distribution` keyword. This syntax is compatible with AlgebraOfGraphics where currently only array-valued positional arguments can be used.

```@figure
using Distributions

xs = randn(100)

qqplot(xs, distribution = Normal(0, 1), qqline = :identity)
```

## Attributes

```@attrdocs
QQPlot
```
