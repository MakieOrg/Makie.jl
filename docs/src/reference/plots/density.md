# density

```@shortdocs; canonical=false
density
```


## Examples

```@figure
f = Figure()
Axis(f[1, 1])

density!(randn(200))
density!(randn(200) .+ 2, alpha = 0.8)

f
```

```@figure
f = Figure()
Axis(f[1, 1])

density!(randn(200), direction = :y, npoints = 10)

f
```

```@figure
f = Figure()
Axis(f[1, 1])

density!(randn(200), color = (:red, 0.3),
    strokecolor = :red, strokewidth = 3, strokearound = true)

f
```

```@figure
f = Figure()
Axis(f[1, 1])

vectors = [randn(1000) .+ i/2 for i in 0:5]

for (i, vector) in enumerate(vectors)
    density!(vector, offset = -i/4, color = (:slategray, 0.4),
        bandwidth = 0.1)
end

f
```

#### Gradients

You can color density plots with gradients by choosing `color = :x` or `:y`, depending on the `direction` attribute.

```@figure
months = ["January", "February", "March", "April",
    "May", "June", "July", "August", "September",
    "October", "November", "December"]

f = Figure()
Axis(f[1, 1], title = "Fictive temperatures",
    yticks = ((1:12) ./ 4,  reverse(months)))

for i in 12:-1:1
    d = density!(randn(200) .- 2sin((i+3)/6*pi), offset = i / 4,
        color = :x, colormap = :thermal, colorrange = (-5, 5),
        strokewidth = 1, strokecolor = :black)
    # this helps with layering in GLMakie
    translate!(d, 0, 0, -0.1i)
end
f
```

Due to technical limitations, if you color the `:vertical` dimension (or :horizontal with direction = :y), only a colormap made with just two colors can currently work:

```@figure
f = Figure()
Axis(f[1, 1])
for x in 1:5
    d = density!(x * randn(200) .+ 3x,
        color = :y, colormap = [:darkblue, :gray95])
end
f
```

#### Using statistical weights

```@figure
using Distributions


N = 100_000
x = rand(Uniform(-2, 2), N)

w = pdf.(Normal(), x)

fig = Figure()
density(fig[1,1], x)
density(fig[1,2], x, weights = w)

fig
```

## Attributes

```@attrdocs
Density
```
