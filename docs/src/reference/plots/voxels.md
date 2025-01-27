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

You can also map a texture to voxels based on their id (and optionally the direction the face is facing).
For this `plot.color` needs to be an image (matrix of colors) and `plot.uv_transform` needs to be defined.
The `uv_transform` can either be defined as a Vector per voxel or as a Matrix per voxel and side.
Each element acts as a 2x3 transformation matrix, applied to `Vec3f(uv, 1)`.
That way it can apply scaling, rotation, mirroring, translation etc.
The input uv coordinates are normalized to a 0..1 range for each voxel and oriented such that the v direction matches +z and u extends to the right.
For the top and bottom sides of a voxel u and v align with +x and +y.

```@figure backend=GLMakie
using FileIO
texture = rotr90(FileIO.load(Makie.assetpath("debug_texture.png")))
voxels(ones(UInt8, 1,1,1), uv_transform = [I], color = texture)
```

Here is an example of per-voxel texture mapping.
The texture includes 10 sprites along x direction and 9 along y direction, each with the same square size.

```@figure backend=GLMakie
using FileIO

# load a sprite sheet with 10 x 9 textures
texture = FileIO.load(Makie.assetpath("voxel_spritesheet.png"))

# create a mapping of voxel id -> (translation, scale)
# This is equivalent to using `Makie.Mat{2, 3, Float32}(1/10, 0, 0, 1/9, x, y)`
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

To define texture per side we use a `Matrix` instead, where the first index is the voxel id and the second the side.
The order of sides is: -x, -y, -z, +x, +y, +z.

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
uvt = Matrix{Any}(undef, 4, 6)
uvt[1, :] = [uvs[9],  uvs[9],  uvs[8],  uvs[9],  uvs[9],  uvs[8]]  # 1 -> birch
uvt[2, :] = [uvs[11], uvs[11], uvs[10], uvs[11], uvs[11], uvs[10]] # 2 -> oak
uvt[3, :] = [uvs[2],  uvs[2],  uvs[2],  uvs[2],  uvs[2],  uvs[18]] # 3 -> crafting table
uvt[4, :] = [uvs[1],  uvs[1],  uvs[1],  uvs[1],  uvs[1],  uvs[1]]  # 4 -> planks

chunk = UInt8[
    1 0 1; 0 0 0; 1 0 1;;;
    0 0 0; 0 0 0; 0 0 0;;;
    2 0 2; 0 0 0; 3 0 4;;;
]

voxels(chunk, uv_transform = uvt, color = texture)
```

The textures used in these examples are from [Kenney's Voxel Pack](https://www.kenney.nl/assets/voxel-pack).



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
p.args[end][] = rand(8,8,8)
f
```

Both of these solutions triggers a full replacement of the input array (i.e. `chunk`), the internal representation (`plot.converted[4]`) and the texture on gpu.
This can be quite slow and wasteful if you only want to update a small section of a large chunk.
In that case you should instead update your input data without triggering an update (using `obs.val`) and then call `local_update(plot, is, js, ks)` to process the update:

```@figure backend=GLMakie
chunk = Observable(rand(64, 64, 64))
f, a, p = voxels(chunk, colorrange = (0, 1))
chunk.val[30:34, :, :] .= NaN # or p.args[end].val
Makie.local_update(p, 30:34, :, :)
f
```



#### Picking Voxels

The `pick` function is able to pick individual voxels in a voxel plot.
The returned index is a flat index into the array passed to `voxels`, i.e. `plt.args[end][][idx]` will return the relevant data.
One important thing to note here is that the returned index is a `UInt32` internally and thus has limited range.
Very large voxel plots (~4.3 billion voxels or 2048 x 2048 x 1024) can reach this limit and trigger an integer overflow.

## Attributes

```@attrdocs
Voxels
```
