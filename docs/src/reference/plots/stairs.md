# stairs

```@shortdocs; canonical=false
stairs
```


## Examples

```@figure
f = Figure()

xs = LinRange(0, 4pi, 21)
ys = sin.(xs)

stairs(f[1, 1], xs, ys)
stairs(f[2, 1], xs, ys; step=:post, color=:blue, linestyle=:dash)
stairs(f[3, 1], xs, ys; step=:center, color=:red, linestyle=:dot)

f
```

## Attributes

```@attrdocs
Stairs
```
