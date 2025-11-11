# qqplot

## Examples

### Comparing two distributions

```@figure
xs = randn(100)
ys = randn(100)

qqplot(xs, ys, qqline = :identity)
```
