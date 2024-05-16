# qqnorm

```@shortdocs; canonical=false
qqnorm
```

## Examples

Test if `xs` is normally distributed.

```@figure
xs = 2 .* randn(100) .+ 3

qqnorm(xs, qqline = :fitrobust)
```

## Attributes

```@attrdocs
QQNorm
```
