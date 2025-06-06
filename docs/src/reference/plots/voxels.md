# voxels

```@shortdocs; canonical=false
voxels
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

The `gap` attribute allows you to specify a gap size between adjacent voxels.
It is given in units of the voxel size (at `gap = 0`) so that `gap = 0` creates no gaps and `gap = 1` reduces the voxel size to 0.
Note that this attribute only takes effect at values `gap > 0.01`.

```@figure backend=GLMakie
chunk = reshape(collect(1:27), 3, 3, 3)
voxels(chunk, gap = 0.33)
```


#### Color and the internal representation

Voxels are represented as an `Array{UInt8, 3}` of voxel ids internally.
In this representation the voxel id `0x00` is defined as an invisible air block.
All other ids (0x01 - 0xff or 1 - 255) are visible and derive their color from the various color attributes.
For `plot.color` specifically the voxel id acts as an index into an array of colors:

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

When passing voxel ids directly (i.e. an `Array{UInt8, 3}`) they are used to index a vector `[lowclip; sampled_colormap; highclip]`.
This means id 1 maps to lowclip, 2..254 to colors of the colormap and 255 to highclip.
`colorrange` and `colorscale` are ignored in this case.


#### Texture maps

For texture mapping we need an image containing multiple textures which are to be mapped to voxels.
As an example, we will use [Kenney's Voxel Pack](https://www.kenney.nl/assets/voxel-pack).

```@figure backend=GLMakie
using FileIO
texture = FileIO.load(Makie.assetpath("voxel_spritesheet.png"))
image(0..1, 0..1, texture, axis=(xlabel = "u", ylabel="v"))
```

Voxels render with texture mapping when `color` is an image and `uv_transform` is defined.
In this case uv (texture) coordinates are generated, transformed by `uv_transform` and then used to sample the image.
Each voxel starts with a 0..1 uv range, which can be shown by using Makie's "debug_texture" with an identity transform.
Here magenta corresponds to (0, 0), blue to (1, 0), red to (0, 1) and green to (1, 1).

```@figure backend=GLMakie
using FileIO, LinearAlgebra
texture = FileIO.load(Makie.assetpath("debug_texture.png"))
voxels(ones(UInt8, 3,3,3), uv_transform = [I], color = texture)
```

To do texture mapping we want to transform the 0..1 uv range to a smaller range corresponding to textures in the image.
We can do that by defining a `uv_transform` per voxel id that includes a translation and scaling.

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

Texture mapping can also be done per voxel side by passing a `Matrix` of uv transforms.
Here the first index correspond to the voxel id and the second to a side following the order: -x, -y, -z, +x, +y, +z.

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

Note that `uv_transform` allows various input types.
You can find more information on them with `?Makie.uv_transform`.
In the most general case a uv transform is a `Makie.Mat{2, 3, Float32}` which is multiplied to `Vec3f(uv..., 1)`.
The `(translation, scale)` syntax we used above can be written as `Makie.Mat{2, 3, Float32}(1/10, 0, 0, 1/9, x, y)`.


#### Updating Voxels

The voxel plot is a bit different from other plot types which affects how you can and should update its data.

First you *can* pass your data as an `Observable` and update that observable as usual:

```@figure backend=GLMakie
chunk = Observable(ones(8,8,8))
f, a, p = voxels(chunk, colorrange = (0, 1))
chunk[] = rand(8,8,8)
f
```

You can also update the data contained in the plot object.
For this you can't index into the plot though, since that will return the converted voxel id data.
Instead you need to index into `p.args`.

```@figure backend=GLMakie
f, a, p = voxels(ones(8,8,8), colorrange = (0, 1))
p.arg1 = rand(8,8,8)
f
```

Both of these solutions triggers a full replacement of the input array (i.e. `chunk`), the internal representation (`plot.chunk_u8[]`) and the texture on gpu.
This can be quite slow and wasteful if you only want to update a small section of a large chunk.
In that case you should instead use `Makie.local_update!()`.

```@figure backend=GLMakie
f, a, p = voxels(rand(64, 64, 64), colorrange = (0, 1))
Makie.local_update!(p, NaN, 26:38, :, :)
f
```



#### Picking Voxels

The `pick` function is able to pick individual voxels in a voxel plot.
The returned index is a flat index into the array passed to `voxels`, i.e. `plt.arg1[][idx]` (or the alias `p.chunk[][idx]` and the lowered `p.chunk_u8[][idx]`) will return the relevant data.
One important thing to note here is that the returned index is a `UInt32` internally and thus has limited range.
Very large voxel plots (~4.3 billion voxels or 2048 x 2048 x 1024) can reach this limit and trigger an integer overflow.

## Attributes

```@attrdocs
Voxels
```
