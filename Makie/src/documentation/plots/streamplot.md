# streamplot

## Examples

### Basic example

```@figure
v(x::Point2{T}) where T = Point2f(x[2], 4*x[1])
streamplot(v, -2..2, -2..2)
```


### FitzHugh-Nagumo Vector Field with Stream Plot

```@figure
struct FitzhughNagumo{T}
    ϵ::T
    s::T
    γ::T
    β::T
end

P = FitzhughNagumo(0.1, 0.0, 1.5, 0.8)

f(x, P::FitzhughNagumo) = Point2f(
    (x[1]-x[2]-x[1]^3+P.s)/P.ϵ,
    P.γ*x[1]-x[2] + P.β
)

f(x) = f(x, P)

fig, ax, pl = streamplot(f, -1.5..1.5, -1.5..1.5, colormap = :magma)
# you can also pass a function to `color`, to either return a number or color value
streamplot(fig[1,2], f, -1.5 .. 1.5, -1.5 .. 1.5, color=(p)-> RGBAf(p..., 0.0, 1))
fig
```

### 3D streamplot

```@figure
# Define a 3D vector field (rotating flow around z-axis with upward component)
function field_3d(x, y, z)
    # Circular flow in xy-plane with strength decreasing from center
    r = sqrt(x^2 + y^2)
    strength = exp(-r^2 / 4)
    return Point3f(-y * strength, x * strength, 0.3 * sin(r))
end

streamplot(field_3d, -2..2, -2..2, -2..2,
    colormap = :viridis,
    gridsize = (8, 8, 8),
    arrow_size = 0.1,
    stepsize = 0.02)
```
