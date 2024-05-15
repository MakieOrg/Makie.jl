# qqplot and qqnorm


## Examples

Test if `xs` and `ys` follow the same distribution.

```@figure
xs = randn(100)
ys = randn(100)

qqplot(xs, ys, qqline = :identity)
```

Test if `ys` is normally distributed.

```@figure
ys = 2 .* randn(100) .+ 3

qqnorm(ys, qqline = :fitrobust)
```
