# volume

```@shortdocs; canonical=false
volume
```


## Examples

### Value based Algorithms (:absorption, :mip, :iso, counter)

Value based algorithms samples sample the colormap using values from volume data.

```@figure volume backend=GLMakie
r = LinRange(-1, 1, 100)
cube = [(x.^2 + y.^2 + z.^2) for x = r, y = r, z = r]
contour(cube, alpha=0.5)
```

```@figure volume
cube_with_holes = cube .* (cube .> 1.4)
volume(cube_with_holes, algorithm = :iso, isorange = 0.05, isovalue = 1.7)
```

```@figure backend=GLMakie
using NIfTI
brain = niread(Makie.assetpath("brain.nii.gz")).raw
mini, maxi = extrema(brain)
normed = Float32.((brain .- mini) ./ (maxi - mini))

fig = Figure(size=(1000, 450))
# Make a colormap, with the first value being transparent
colormap = to_colormap(:plasma)
colormap[1] = RGBAf(0,0,0,0)
volume(fig[1, 1], normed, algorithm = :absorption, absorption=4f0, colormap=colormap, axis=(type=Axis3, title = "Absorption"))
volume(fig[1, 2], normed, algorithm = :mip, colormap=colormap, axis=(type=Axis3, title="Maximum Intensity Projection"))
fig
```

### RGB(A) Algorithms (:absorptionrgba, :additive)

RGBA algorithms sample colors directly from the given volume data.
If the data contains less than 4 dimensions the remaining dimensions are filled with 0 for the green and blue channel and 1 for the alpha channel.

```@figure backend=GLMakie
using LinearAlgebra
# Signed distance field for a chain Link (generates distance values from the
# surface of the shape with negative values being inside)
# based on https://iquilezles.org/articles/distfunctions/ "Link"
# (x,y,z) sample position, length between ends, shape radius, tube radius
function sdf(x, y, z, le, r1, r2)
    x, y, z = Vec3f(x, max(abs(y) - le, 0.0), z);
    return norm(Vec2f(sqrt(x*x + y*y) - r1, z)) - r2;
end

r = range(-5, 5, length=31)
data = map([(x,y,z) for x in r, y in r, z in r]) do (x,y,z)
    r = max(-sdf(x,y,z, 1.5, 2, 1), 0)
    g = max(-sdf(y,z,x, 1.5, 2, 1), 0)
    b = max(-sdf(z,x,y, 1.5, 2, 1), 0)
    # RGBAf(1+r, 1+g, 1+b, max(r, g, b) - 0.1)
    RGBAf(r, g, b, max(r, g, b))
end

f = Figure(backgroundcolor = :black, size = (700, 400))
volume(f[1, 1], data, algorithm = :absorptionrgba, absorption = 20)
volume(f[1, 2], data, algorithm = :additive)
f
```

### Indexing Algorithms (:indexedabsorption)

Indexing Algorithms interpret the value read from volume data as an index into the colormap.
So effectively it reads `idx = round(Int, get(data, sample_pos))` and uses `colormap[idx]` as the color of the sample.
Note that you can still use float data here, and without `interpolate = false` it will be interpolated.

```@figure backend=GLMakie
r = -5:5
data = map([(x,y,z) for x in r, y in r, z in r]) do (x,y,z)
    1 + min(abs(x), abs(y), abs(z))
end
colormap = [:red, :transparent, :transparent, RGBAf(0,1,0,0.5), :transparent, :blue]
volume(data, algorithm = :indexedabsorption, colormap = colormap,
    interpolate = false, absorption = 5)
```


## Attributes

```@attrdocs
Volume
```
