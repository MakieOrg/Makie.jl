# crossbar

```@shortdocs; canonical=false
crossbar
```


## Examples

```@figure
xs = [1, 1, 2, 2, 3, 3]
ys = rand(6)
ymins = ys .- 1
ymaxs = ys .+ 1
dodge = [1, 2, 1, 2, 1, 2]

crossbar(xs, ys, ymins, ymaxs, dodge = dodge, show_notch = true)
```

## Attributes

```@attrdocs
CrossBar
```
