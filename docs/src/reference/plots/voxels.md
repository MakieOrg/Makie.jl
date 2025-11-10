# voxels

```
f, ax, pl = voxels(args...; kw...) # return a new figure, axis, and plot
   ax, pl = voxels(f[row, col], args...; kw...) # creates an axis in a subfigure grid position
       pl = voxels!(ax::Union{Scene, AbstractAxis}, args...; kw...) # Creates a plot in the given axis or scene.
SpecApi.Voxels(args...; kw...) # Creates a SpecApi plot, which can be used in `S.Axis(plots=[plot])`.
```

## Examples

#### Basic Example

```@figure backend=GLMakie
# Same as volume example
r = LinRange(-1, 1, 100)
cube = [(x.^2 + y.^2 + z.^2) for x = r, y = r, z = r]
cube_with_holes = cube .* (cube .> 1.4)

# To match the volume example with isovalue=1.7 and isorange=0.05 we map all
# values outside the range (1.65..1.75) to invisible air blocks with is_air
f, a, p = voxels(-1..1, -1..1, -1..1, cube_with_holes, is_air = x -> !(1.65 <= x <= 1.75))
```

#### Gap Attribute

The `gap` attribute allows you to specify a gap size between adjacent voxels. It is given in units of the voxel size (at `gap = 0`) so that `gap = 0` creates no gaps and `gap = 1` reduces the voxel size to 0. Note that this attribute only takes effect at values `gap > 0.01`.

```@figure backend=GLMakie
chunk = reshape(collect(1:27), 3, 3, 3)
voxels(chunk, gap = 0.33)
```

#### Color and the internal representation

Voxels are represented as an `Array{UInt8, 3}` of voxel ids internally. In this representation the voxel id `0x00` is defined as an invisible air block. All other ids (0x01 - 0xff or 1 - 255) are visible and derive their color from the various color attributes. For `plot.color` specifically the voxel id acts as an index into an array of colors:

```@figure backend=GLMakie
chunk = UInt8[
    1 0 2; 0 0 0; 3 0 4;;;
    0 0 0; 0 0 0; 0 0 0;;;
    5 0 6; 0 0 0; 7 0 8;;;
]
f, a, p = voxels(chunk, color = [:white, :red, :green, :blue, :black, :orange, :cyan, :magenta])
```

#### Colormaps

With non `UInt8` inputs, colormap attributes (colormap, colorrange, highclip, lowclip and colorscale) work as usual, with the exception of `nan_color` which is not applicable:

```@figure backend=GLMakie
chunk = reshape(collect(1:512), 8, 8, 8)

f, a, p = voxels(chunk,
    colorrange = (65, 448), colorscale = log10,
    lowclip = :red, highclip = :orange,
    colormap = [:blue, :green]
)
```

When passing voxel ids directly (i.e. an `Array{UInt8, 3}`) they are used to index a vector `[lowclip; sampled_colormap; highclip]`. This means id 1 maps to lowclip, 2..254 to colors of the colormap and 255 to highclip. `colorrange` and `colorscale` are ignored in this case.

#### Texture maps

For texture mapping we need an image containing multiple textures which are to be mapped to voxels. As an example, we will use [Kenney's Voxel Pack](https://www.kenney.nl/assets/voxel-pack).

```@figure backend=GLMakie
using FileIO
texture = FileIO.load(Makie.assetpath("voxel_spritesheet.png"))
image(0..1, 0..1, texture, axis=(xlabel = "u", ylabel="v"))
```

Voxels render with texture mapping when `color` is an image and `uv_transform` is defined. In this case uv (texture) coordinates are generated, transformed by `uv_transform` and then used to sample the image. Each voxel starts with a 0..1 uv range, which can be shown by using Makie's "debug_texture" with an identity transform. Here magenta corresponds to (0, 0), blue to (1, 0), red to (0, 1) and green to (1, 1).

```@figure backend=GLMakie
using FileIO, LinearAlgebra
texture = FileIO.load(Makie.assetpath("debug_texture.png"))
voxels(ones(UInt8, 3,3,3), uv_transform = [I], color = texture)
```

To do texture mapping we want to transform the 0..1 uv range to a smaller range corresponding to textures in the image. We can do that by defining a `uv_transform` per voxel id that includes a translation and scaling.

```@figure backend=GLMakie
using FileIO

# load a sprite sheet with 10 x 9 textures
texture = FileIO.load(Makie.assetpath("voxel_spritesheet.png"))

# create a mapping of voxel id -> (translation, scale)
uvt = [(Point2f(x, y), Vec2f(1/10, 1/9))
    for x in range(0.0, 1.0, length = 11)[1:end-1]
    for y in range(0.0, 1.0, length = 10)[1:end-1]
]

# Define which textures/uvs apply to which voxels (0 is invisible/air)
chunk = UInt8[
    1 0 2; 0 0 0; 3 0 4;;;
    0 0 0; 0 0 0; 0 0 0;;;
    5 0 6; 0 0 0; 7 0 9;;;
]

# draw
voxels(chunk, uv_transform = uvt, color = texture)
```

Texture mapping can also be done per voxel side by passing a `Matrix` of uv transforms. Here the first index correspond to the voxel id and the second to a side following the order: -x, -y, -z, +x, +y, +z.

```@figure backend=GLMakie
using FileIO

texture = FileIO.load(Makie.assetpath("voxel_spritesheet.png"))

# idx -> uv LRBT map for convenience. Note the change in order loop order
uvs = [
    (Point2f(x, y), Vec2f(1/10, 1/9))
    for y in range(0.0, 1.0, length = 10)[1:end-1]
    for x in range(0.0, 1.0, length = 11)[1:end-1]
]

# Create uvmap with sides (-x -y -z x y z) in second dimension
uvt = Matrix{Any}(undef, 5, 6)
uvt[1, :] = [uvs[9],  uvs[9],  uvs[8],  uvs[9],  uvs[9],  uvs[8]]  # 1 -> birch
uvt[2, :] = [uvs[11], uvs[11], uvs[10], uvs[11], uvs[11], uvs[10]] # 2 -> oak
uvt[3, :] = [uvs[2],  uvs[2],  uvs[2],  uvs[2],  uvs[2],  uvs[18]] # 3 -> crafting table
uvt[4, :] = [uvs[1],  uvs[1],  uvs[1],  uvs[1],  uvs[1],  uvs[1]]  # 4 -> planks
uvt[5, :] = [uvs[75], uvs[75], uvs[76], uvs[75], uvs[75], uvs[62]] # 5 -> dirt/grass

chunk = UInt8[
    1 0 1; 0 0 0; 1 0 5;;;
    0 0 0; 0 0 0; 0 0 0;;;
    2 0 2; 0 0 0; 3 0 4;;;
]

# rotate 0..1 texture coordinates first because the texture is rotated relative to what OpenGL expects
voxels(chunk, uv_transform = (uvt, :rotr90), color = texture)
```

Note that `uv_transform` allows various input types. You can find more information on them with `?Makie.uv_transform`. In the most general case a uv transform is a `Makie.Mat{2, 3, Float32}` which is multiplied to `Vec3f(uv..., 1)`. The `(translation, scale)` syntax we used above can be written as `Makie.Mat{2, 3, Float32}(1/10, 0, 0, 1/9, x, y)`.

#### Updating Voxels

The voxel plot is a bit different from other plot types which affects how you can and should update its data.

First you *can* pass your data as an `Observable` and update that observable as usual:

```@figure backend=GLMakie
chunk = Observable(ones(8,8,8))
f, a, p = voxels(chunk, colorrange = (0, 1))
chunk[] = rand(8,8,8)
f
```

You can also update the data contained in the plot object. For this you can't index into the plot though, since that will return the converted voxel id data. Instead you need to index into `p.args`.

```@figure backend=GLMakie
f, a, p = voxels(ones(8,8,8), colorrange = (0, 1))
p.arg1 = rand(8,8,8)
f
```

Both of these solutions triggers a full replacement of the input array (i.e. `chunk`), the internal representation (`plot.chunk_u8[]`) and the texture on gpu. This can be quite slow and wasteful if you only want to update a small section of a large chunk. In that case you should instead use `Makie.local_update!()`.

```@figure backend=GLMakie
f, a, p = voxels(rand(64, 64, 64), colorrange = (0, 1))
Makie.local_update!(p, NaN, 26:38, :, :)
f
```

#### Picking Voxels

The `pick` function is able to pick individual voxels in a voxel plot. The returned index is a flat index into the array passed to `voxels`, i.e. `plt.arg1[][idx]` (or the alias `p.chunk[][idx]` and the lowered `p.chunk_u8[][idx]`) will return the relevant data. One important thing to note here is that the returned index is a `UInt32` internally and thus has limited range. Very large voxel plots (~4.3 billion voxels or 2048 x 2048 x 1024) can reach this limit and trigger an integer overflow.

See the [online documentation](https://docs.makie.org/stable/reference/plots/voxels) for rendered examples.

## Attributes

### `transparency`

**Default:** `false`

Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

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

### `is_air`

**Default:** `x->begin         #= /sim/Programmieren/MakieDev/dev/Makie/Makie/src/basic_plots.jl:657 =#         isnothing(x) || (ismissing(x) || isnan(x))     end`

A function that controls which values in the input data are mapped to invisible (air) voxels.

### `backlight`

**Default:** `0.0`

Sets a weight for secondary light calculation with inverted normals.

### `depthsorting`

**Default:** `false`

Controls the render order of voxels. If set to `false` voxels close to the viewer are rendered first which should reduce overdraw and yield better performance. If set to `true` voxels are rendered back to front enabling correct order for transparent voxels.

### `uvmap`

**Default:** `nothing`

Deprecated - use uv_transform

### `inspector_label`

**Default:** `automatic`

Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

### `uv_transform`

**Default:** `nothing`

To use texture mapping `uv_transform` needs to be defined and `color` needs to be an image. The `uv_transform` can be given as a `Vector` where each index maps to a `UInt8` voxel id (skipping 0), or as a `Matrix` where the second index maps to a side following the order `(-x, -y, -z, +x, +y, +z)`. Each element acts as a `Mat{2, 3, Float32}` which is applied to `Vec3f(uv, 1)`, where uv's are generated to run from 0..1 for each voxel. The result is then used to sample the texture. UV transforms have a bunch of shorthands you can use, for example `(Point2f(x, y), Vec2f(xscale, yscale))`. They are listed in `?Makie.uv_transform`.

### `nan_color`

**Default:** `:transparent`

The color for NaN values.

### `shininess`

**Default:** `32.0`

Sets how sharp the reflection is.

### `interpolate`

**Default:** `false`

Controls whether the texture map is sampled with interpolation (i.e. smoothly) or not (i.e. pixelated).

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

### `gap`

**Default:** `0.0`

Sets the gap between adjacent voxels in units of the voxel size. This needs to be larger than 0.01 to take effect.

### `model`

**Default:** `automatic`

Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

### `depth_shift`

**Default:** `0.0`

Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

### `colorrange`

**Default:** `automatic`

The values representing the start and end points of `colormap`.

### `color`

**Default:** `nothing`

Sets colors per voxel id, skipping `0x00`. This means that a voxel with id 1 will grab `plot.colors[1]` and so on up to id 255. This can also be set to a Matrix of colors, i.e. an image for texture mapping.

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
