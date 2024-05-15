# qqnorm

Test if `xs` is normally distributed.

```@figure
xs = 2 .* randn(100) .+ 3

qqnorm(ys, qqline = :fitrobust)
```

## Attributes

```@attrdocs
QQNorm
```