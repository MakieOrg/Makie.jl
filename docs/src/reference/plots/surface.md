# surface

```@shortdocs; canonical=false
surface
```


## Examples

### Gridded surfaces

By default surface data is placed on a grid matching the size of the input data.
The grid can be specified explicitly by passing a Range or Vector of values as the X and Y arguments.
The positions/vertices of the surface are then effectively derived as `Point.(X, Y', Z)`.
Intervals (e.g `0..1`) can be used to specify the start and endpoint only, implying a linear range in between.

```@figure backend=GLMakie
xs = LinRange(0, 10, 100)
ys = LinRange(0, 15, 100)
zs = [cos(x) * sin(y) for x in xs, y in ys]

surface(xs, ys, zs, axis=(type=Axis3,))
```

```@figure backend=GLMakie
using DelimitedFiles

volcano = readdlm(Makie.assetpath("volcano.csv"), ',', Float64)

surface(volcano,
    colormap = :darkterrain,
    colorrange = (80, 190),
    axis=(type=Axis3, azimuth = pi/4))
```

```@figure backend=GLMakie
using SparseArrays
using LinearAlgebra

# This example was provided by Moritz Schauer (@mschauer).

#=
Define the precision matrix (inverse covariance matrix)
for the Gaussian noise matrix.  It approximately coincides
with the Laplacian of the 2d grid or the graph representing
the neighborhood relation of pixels in the picture,
https://en.wikipedia.org/wiki/Laplacian_matrix
=#
function gridlaplacian(m, n)
    S = sparse(0.0I, n*m, n*m)
    linear = LinearIndices((1:m, 1:n))
    for i in 1:m
        for j in 1:n
            for (i2, j2) in ((i + 1, j), (i, j + 1))
                if i2 <= m && j2 <= n
                    S[linear[i, j], linear[i2, j2]] -= 1
                    S[linear[i2, j2], linear[i, j]] -= 1
                    S[linear[i, j], linear[i, j]] += 1
                    S[linear[i2, j2], linear[i2, j2]] += 1
                end
            end
        end
    end
    return S
end

# d is used to denote the size of the data
d = 150

 # Sample centered Gaussian noise with the right correlation by the method
 # based on the Cholesky decomposition of the precision matrix
data = 0.1randn(d,d) + reshape(
        cholesky(gridlaplacian(d,d) + 0.003I) \ randn(d*d),
        d, d
)

surface(data; shading = NoShading, colormap = :deep)
surface(data; shading = NoShading, colormap = :deep)
```

### Quad Mesh surface

X and Y values can also be given as a Matrix.
In this case the surface positions follow as `Point.(X, Y, Z)` so the surface is no longer restricted to an XY grid.

```@figure backend=GLMakie
rs = 1:10
thetas = 0:10:360

xs = rs .* cosd.(thetas')
ys = rs .* sind.(thetas')
zs = sin.(rs) .* cosd.(thetas')

surface(xs, ys, zs)
```

### NaN Handling

If a vertex of the surface is NaN, meaning that either X, Y or Z contribute NaN to it, all connected faces can not be drawn.
Thus the surface will have a hole around a NaN vertex.
If just a color is NaN it will be drawn with `nan_color`.

```@figure backend=GLMakie
xs = ys = vcat(1:9, NaN, 11:30)
zs = [2 * sin(x+y) for x in range(-3, 3, length=30), y in range(-3, 3, length=30)]
zs_nan = copy(zs)
zs_nan[25, 25] = NaN

f = Figure(size = (600, 300))
surface(f[1, 1], xs, ys, zs_nan, axis = (show_axis = false,))
surface(f[1, 2], 1:30, 1:30, zs, color = zs_nan, nan_color = :red, axis = (show_axis = false,))
f
```

### 2D Surface

A surface plot can act as an off-grid version of heatmap or image in 2D.
For this it is recommended to pass data through `color` instead of the Z argument to avoid the plot interfering with others based on its Z values.

```@figure backend=GLMakie
rs = 1:10
thetas = 0:10:360

xs = rs .* cosd.(thetas')
ys = rs .* sind.(thetas')
zs = sin.(rs) .* cosd.(thetas')

surface(xs, ys, zeros(size(zs)), color = zs, shading = NoShading)
```

## Attributes

```@attrdocs
Surface
```
