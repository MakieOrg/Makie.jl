# qqnorm

## Examples

### Test if data follows a normal distribution

```@figure
xs = 2 .* randn(100) .+ 3

qqnorm(xs, qqline = :fitrobust)
```
