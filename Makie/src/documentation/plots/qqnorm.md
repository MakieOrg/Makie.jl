# qqnorm

## Examples

### Testing normality of data

```@figure
xs = 2 .* randn(100) .+ 3

qqnorm(xs, qqline = :fitrobust)
```
