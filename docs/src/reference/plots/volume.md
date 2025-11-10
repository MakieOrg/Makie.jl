# volume

```
f, ax, pl = volume(args...; kw...) # return a new figure, axis, and plot
   ax, pl = volume(f[row, col], args...; kw...) # creates an axis in a subfigure grid position
       pl = volume!(ax::Union{Scene, AbstractAxis}, args...; kw...) # Creates a plot in the given axis or scene.
SpecApi.Volume(args...; kw...) # Creates a SpecApi plot, which can be used in `S.Axis(plots=[plot])`.
```

## Arguments

**Target signature:** `x::Makie.EndPoints, y::Makie.EndPoints, z::Makie.EndPoints, volume::AbstractArray{<:Union{ColorTypes.RGB{Float32}, ColorTypes.RGBA{Float32}, Float32, Vec3f, Vec4f, Vec3{Float32}, Vec4{Float32}}, 3}`

  * `volume_data`: An `AbstractArray{<:Real, 3}` defining volume data.
  * `x, y, z`: Defines the boundary of a 3D rectangle with a `Tuple{<:Real, <:Real}` or `ClosedInterval{<:Real}`. If omitted `x`, `y` and `z` default to `0 .. size(volume)`.

For detailed conversion information, see `Makie.conversion_docs(Volume)`.

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

RGBA algorithms sample colors directly from the given volume data. If the data contains less than 4 dimensions the remaining dimensions are filled with 0 for the green and blue channel and 1 for the alpha channel.

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

Indexing Algorithms interpret the value read from volume data as an index into the colormap. So effectively it reads `idx = round(Int, get(data, sample_pos))` and uses `colormap[idx]` as the color of the sample. Note that you can still use float data here, and without `interpolate = false` it will be interpolated.

```@figure backend=GLMakie
r = -5:5
data = map([(x,y,z) for x in r, y in r, z in r]) do (x,y,z)
    1 + min(abs(x), abs(y), abs(z))
end
colormap = [:red, :transparent, :transparent, RGBAf(0,1,0,0.5), :transparent, :blue]
volume(data, algorithm = :indexedabsorption, colormap = colormap,
    interpolate = false, absorption = 5)
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/volume) for rendered examples.

## Attributes

### `transparency`

**Default:** `false`

Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

### `absorption`

**Default:** `1.0`

Absorption multiplier for algorithm = :absorption, :absorptionrgba and :indexedabsorption. This changes how much light each voxel absorbs.

### `alpha`

**Default:** `1.0`

The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

### `specular`

**Default:** `0.2`

Sets how strongly the object reflects light in the red, green and blue channels.

### `colormap`

**Default:** `@inherit colormap :viridis`

Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

### `visible`

**Default:** `true`

Controls whether the plot gets rendered or not.

### `isovalue`

**Default:** `0.5`

Sets the target value for the :iso algorithm. `accepted = isovalue - isorange < value < isovalue + isorange`

### `space`

**Default:** `:data`

Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

### `colorscale`

**Default:** `identity`

The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10`, `Makie.Symlog10`, `Makie.AsinhScale`, `Makie.SinhScale`, `Makie.LogScale`, `Makie.LuptonAsinhScale`, and `Makie.PowerScale`.

### `inspector_hover`

**Default:** `automatic`

Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

### `clip_planes`

**Default:** `@inherit clip_planes automatic`

Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

### `ssao`

**Default:** `false`

Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

### `highclip`

**Default:** `automatic`

The color for any value above the colorrange.

### `algorithm`

**Default:** `:mip`

Sets the volume algorithm that is used. Available algorithms are:

  * `:iso`: Shows an isovalue surface within the given float data. For this only samples within `isovalue - isorange .. isovalue + isorange` are included in the final color of a pixel.
  * `:absorption`: Accumulates color based on the float values sampled from volume data. At each ray step (starting from the front) a value is sampled from the volume data and then used to sample the colormap. The resulting color is weighted by the ray step size and blended the previously accumulated color. The weight of each step can be adjusted with the multiplicative `absorption` attribute.
  * `:mip`: Shows the maximum intensity projection of the given float data. This derives the color of a pixel from the largest value sampled from the respective ray.
  * `:absorptionrgba`: This algorithm matches :absorption, but samples colors directly from RGBA volume data. For each ray step a color is sampled from the data, weighted by the ray step size and blended with the previously accumulated color. Also considers `absorption`.
  * `:additive`: Accumulates colors using `accumulated_color = 1 - (1 - accumulated_color) * (1 - sampled_color)` where `sampled_color` is a sample of volume data at the current ray step.
  * `:indexedabsorption`: This algorithm acts the same as :absorption, but interprets the volume data as indices. They are used as direct indices to the colormap. Also considers `absorption`.

### `backlight`

**Default:** `0.0`

Sets a weight for secondary light calculation with inverted normals.

### `enable_depth`

**Default:** `true`

Enables more accurate but slower depth handling. When turned off depth is based on the back vertices of the bounding box of the volume. When turned on it is based on the ray start point in front of the camera. For `algorithm = :iso` (and contours) it is based on the front most surface rendered.

### `inspector_label`

**Default:** `automatic`

Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

### `nan_color`

**Default:** `:transparent`

The color for NaN values.

### `shininess`

**Default:** `32.0`

Sets how sharp the reflection is.

### `interpolate`

**Default:** `true`

Sets whether the volume data should be sampled with interpolation.

### `overdraw`

**Default:** `false`

Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

### `transformation`

**Default:** `:automatic`

Controls the inheritance or directly sets the transformations of a plot. Transformations include the transform function and model matrix as generated by `translate!(...)`, `scale!(...)` and `rotate!(...)`. They can be set directly by passing a `Transformation()` object or inherited from the parent plot or scene. Inheritance options include:

  * `:automatic`: Inherit transformations if the parent and child `space` is compatible
  * `:inherit`: Inherit transformations
  * `:inherit_model`: Inherit only model transformations
  * `:inherit_transform_func`: Inherit only the transform function
  * `:nothing`: Inherit neither, fully disconnecting the child's transformations from the parent

Another option is to pass arguments to the `transform!()` function which then get applied to the plot. For example `transformation = (:xz, 1.0)` which rotates the `xy` plane to the `xz` plane and translates by `1.0`. For this inheritance defaults to `:automatic` but can also be set through e.g. `(:nothing, (:xz, 1.0))`.

### `model`

**Default:** `automatic`

Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

### `depth_shift`

**Default:** `0.0`

Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

### `colorrange`

**Default:** `automatic`

The values representing the start and end points of `colormap`.

### `isorange`

**Default:** `0.05`

Sets the maximum accepted distance from the isovalue for the :iso algorithm. `accepted = isovalue - isorange < value < isovalue + isorange`

### `material`

**Default:** `nothing`

RPRMakie only attribute to set complex RadeonProRender materials.         *Warning*, how to set an RPR material may change and other backends will ignore this attribute

### `shading`

**Default:** `true`

Controls if the plot object is shaded by the parent scenes lights or not. The lighting algorithm used is controlled by the scenes `shading` attribute.

### `inspectable`

**Default:** `@inherit inspectable`

Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

### `fxaa`

**Default:** `true`

Adjusts whether the plot is rendered with fxaa (fast approximate anti-aliasing, GLMakie only). Note that some plots implement a better native anti-aliasing solution (scatter, text, lines). For them `fxaa = true` generally lowers quality. Plots that show smoothly interpolated data (e.g. image, surface) may also degrade in quality as `fxaa = true` can cause blurring.

### `diffuse`

**Default:** `1.0`

Sets how strongly the red, green and blue channel react to diffuse (scattered) light.

### `inspector_clear`

**Default:** `automatic`

Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

### `lowclip`

**Default:** `automatic`

The color for any value below the colorrange.
