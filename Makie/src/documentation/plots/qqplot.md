# qqplot

## Examples

### Test if two samples follow the same distribution

```@figure
xs = randn(100)
ys = randn(100)

qqplot(xs, ys, qqline = :identity)
```
