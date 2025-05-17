
# density {#density}
<details class='jldocstring custom-block' open>
<summary><a id='Makie.density-reference-plots-density' href='#Makie.density-reference-plots-density'><span class="jlbinding">Makie.density</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
density(values)
```


Plot a kernel density estimate of `values`.

**Plot type**

The plot type alias for the `density` function is `Density`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/cefec3bc07a829ab04fb7edfbd5ae240496109fa/MakieCore/src/recipes.jl#L520-L569" target="_blank" rel="noreferrer">source</a></Badge>

</details>


## Examples {#Examples}
<a id="example-a0d83ef" />


```julia
using CairoMakie
f = Figure()
Axis(f[1, 1])

density!(randn(200))
density!(randn(200) .+ 2, alpha = 0.8)

f
```

<img src="./a0d83ef.png" width="600px" height="450px"/>

<a id="example-d6d6800" />


```julia
using CairoMakie
f = Figure()
Axis(f[1, 1])

density!(randn(200), direction = :y, npoints = 10)

f
```

<img src="./d6d6800.png" width="600px" height="450px"/>

<a id="example-201c8aa" />


```julia
using CairoMakie
f = Figure()
Axis(f[1, 1])

density!(randn(200), color = (:red, 0.3),
    strokecolor = :red, strokewidth = 3, strokearound = true)

f
```

<img src="./201c8aa.png" width="600px" height="450px"/>

<a id="example-132a52d" />


```julia
using CairoMakie
f = Figure()
Axis(f[1, 1])

vectors = [randn(1000) .+ i/2 for i in 0:5]

for (i, vector) in enumerate(vectors)
    density!(vector, offset = -i/4, color = (:slategray, 0.4),
        bandwidth = 0.1)
end

f
```

<img src="./132a52d.png" width="600px" height="450px"/>


#### Gradients {#Gradients}

You can color density plots with gradients by choosing `color = :x` or `:y`, depending on the `direction` attribute.
<a id="example-81af4f0" />


```julia
using CairoMakie
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

<img src="./81af4f0.png" width="600px" height="450px"/>


Due to technical limitations, if you color the `:vertical` dimension (or :horizontal with direction = :y), only a colormap made with just two colors can currently work:
<a id="example-84f2a9c" />


```julia
using CairoMakie
f = Figure()
Axis(f[1, 1])
for x in 1:5
    d = density!(x * randn(200) .+ 3x,
        color = :y, colormap = [:darkblue, :gray95])
end
f
```

<img src="./84f2a9c.png" width="600px" height="450px"/>


#### Using statistical weights {#Using-statistical-weights}
<a id="example-6bb0d7f" />


```julia
using CairoMakie
using Distributions


N = 100_000
x = rand(Uniform(-2, 2), N)

w = pdf.(Normal(), x)

fig = Figure()
density(fig[1,1], x)
density(fig[1,2], x, weights = w)

fig
```

<img src="./6bb0d7f.png" width="600px" height="450px"/>


## Attributes {#Attributes}

### alpha {#alpha}

Defaults to `1.0`

The alpha value of the colormap or color attribute. Multiple alphas like in plot(alpha=0.2, color=(:red, 0.5), will get multiplied.

### bandwidth {#bandwidth}

Defaults to `automatic`

Kernel density bandwidth, determined automatically if `automatic`.

### boundary {#boundary}

Defaults to `automatic`

Boundary of the density estimation, determined automatically if `automatic`.

### color {#color}

Defaults to `@inherit patchcolor`

Usually set to a single color, but can also be set to `:x` or `:y` to color with a gradient. If you use `:y` when `direction = :x` (or vice versa), note that only 2-element colormaps can work correctly.

### colormap {#colormap}

Defaults to `@inherit colormap`

No docs available.

### colorrange {#colorrange}

Defaults to `Makie.automatic`

No docs available.

### colorscale {#colorscale}

Defaults to `identity`

No docs available.

### cycle {#cycle}

Defaults to `[:color => :patchcolor]`

No docs available.

### direction {#direction}

Defaults to `:x`

The dimension along which the `values` are distributed. Can be `:x` or `:y`.

### inspectable {#inspectable}

Defaults to `@inherit inspectable`

No docs available.

### linestyle {#linestyle}

Defaults to `nothing`

No docs available.

### npoints {#npoints}

Defaults to `200`

The resolution of the estimated curve along the dimension set in `direction`.

### offset {#offset}

Defaults to `0.0`

Shift the density baseline, for layering multiple densities on top of each other.

### strokearound {#strokearound}

Defaults to `false`

No docs available.

### strokecolor {#strokecolor}

Defaults to `@inherit patchstrokecolor`

No docs available.

### strokewidth {#strokewidth}

Defaults to `@inherit patchstrokewidth`

No docs available.

### weights {#weights}

Defaults to `automatic`

Assign a vector of statistical weights to `values`.
