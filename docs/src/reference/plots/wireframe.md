# wireframe

```@shortdocs; canonical=false
wireframe
```


## Examples

```@figure backend=GLMakie
x, y = collect(-8:0.5:8), collect(-8:0.5:8)
z = [sinc(√(X^2 + Y^2) / π) for X ∈ x, Y ∈ y]

wireframe(x, y, z, axis=(type=Axis3,), color=:black)
```

## Attributes

```@attrdocs
Wireframe
```
