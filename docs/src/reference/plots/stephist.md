# stephist

```@shortdocs; canonical=false
stephist
```


## Examples

```@figure backend=GLMakie
data = randn(1000)

f = Figure()
stephist(f[1, 1], data, bins = 10)
stephist(f[1, 2], data, bins = 20, color = :red, linewidth = 3)
stephist(f[2, 1], data, bins = [-5, -2, -1, 0, 1, 2, 5], color = :gray)
stephist(f[2, 2], data, normalization = :pdf)
f
```

For more examples, see `hist`.

## Attributes

```@attrdocs
StepHist
```
