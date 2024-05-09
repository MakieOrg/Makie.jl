# voxels

{{doc voxels}}

### Examples



#### Basic Example

\begin{examplefigure}{}
```julia
using GLMakie
GLMakie.activate!() # hide

# Same as volume example
r = LinRange(-1, 1, 100)
cube = [(x.^2 + y.^2 + z.^2) for x = r, y = r, z = r]
cube_with_holes = cube .* (cube .> 1.4)

# To match the volume example with isovalue=1.7 and isorange=0.05 we map all
# values outside the range (1.65..1.75) to invisible air blocks with is_air
f, a, p = voxels(-1..1, -1..1, -1..1, cube_with_holes, is_air = x -> !(1.65 <= x <= 1.75))
```
\end{examplefigure}


#### Gap Attribute

The `gap` attribute allows you to specify a gap size between adjacent voxels.
It is given in units of the voxel size (at `gap = 0`) so that `gap = 0` creates no gaps and `gap = 1` reduces the voxel size to 0.
Note that this attribute only takes effect at values `gap > 0.01`.

\begin{examplefigure}{}
```julia
using GLMakie
GLMakie.activate!() # hide

chunk = reshape(collect(1:27), 3, 3, 3)
voxels(chunk, gap = 0.33)
```
\end{examplefigure}


#### Color and the internal representation

Voxels are represented as an `Array{UInt8, 3}` of voxel ids internally.
In this representation the voxel id `0x00` is defined as an invisible air block.
All other ids (0x01 - 0xff or 1 - 255) are visible and derive their color from the various color attributes.
For `plot.color` specifically the voxel id acts as an index into an array of colors:

\begin{examplefigure}{}
```julia
using GLMakie
GLMakie.activate!() # hide

chunk = UInt8[
    1 0 2; 0 0 0; 3 0 4;;;
    0 0 0; 0 0 0; 0 0 0;;;
    5 0 6; 0 0 0; 7 0 8;;;
]
f, a, p = voxels(chunk, color = [:white, :red, :green, :blue, :black, :orange, :cyan, :magenta])
```
\end{examplefigure}


#### Colormaps

With non `UInt8` inputs, colormap attributes (colormap, colorrange, highclip, lowclip and colorscale) work as usual, with the exception of `nan_color` which is not applicable:

\begin{examplefigure}{}
```julia
using GLMakie
GLMakie.activate!() # hide

chunk = reshape(collect(1:512), 8, 8, 8)

f, a, p = voxels(chunk,
    colorrange = (65, 448), colorscale = log10,
    lowclip = :red, highclip = :orange,
    colormap = [:blue, :green]
)
```
\end{examplefigure}

When passing voxel ids directly (i.e. an `Array{UInt8, 3}`) they are used to index a vector `[lowclip; sampled_colormap; highclip]`.
This means id 1 maps to lowclip, 2..254 to colors of the colormap and 255 to highclip.
`colorrange` and `colorscale` are ignored in this case.


#### Texturemaps

You can also map a texture to voxels based on their id (and optionally the direction the face is facing).
For this `plot.color` needs to be an image (matrix of colors) and `plot.uvmap` needs to be defined.
The `uvmap` can take two forms here.
The first is a `Vector{Vec4f}` which maps voxel ids (starting at 1) to normalized uv coordinates, formatted left-right-bottom-top.

\begin{examplefigure}{}
```julia
using GLMakie, FileIO
GLMakie.activate!() # hide

# load a sprite sheet with 10 x 9 textures
texture = FileIO.load(Makie.assetpath("voxel_spritesheet.png"))

# create a map idx -> LRBT coordinate of the textures, normalized to a 0..1 range
uv_map = [
    Vec4f(x, x+1/10, y, y+1/9)
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
f, a, p = voxels(chunk, uvmap = uv_map, color = texture)
```
\end{examplefigure}

The second format allows you define sides in the second dimension of the uvmap.
The order of sides is: -x, -y, -z, +x, +y, +z.

\begin{examplefigure}{}
```julia
using GLMakie, FileIO
GLMakie.activate!() # hide

texture = FileIO.load(Makie.assetpath("voxel_spritesheet.png"))

# idx -> uv LRBT map for convenience. Note the change in order loop order
uvs = [
    Vec4f(x, x+1/10, y, y+1/9)
    for y in range(0.0, 1.0, length = 10)[1:end-1]
    for x in range(0.0, 1.0, length = 11)[1:end-1]
]

# Create uvmap with sides (-x -y -z x y z) in second dimension
uv_map = Matrix{Vec4f}(undef, 4, 6)
uv_map[1, :] = [uvs[9],  uvs[9],  uvs[8],  uvs[9],  uvs[9],  uvs[8]]  # 1 -> birch
uv_map[2, :] = [uvs[11], uvs[11], uvs[10], uvs[11], uvs[11], uvs[10]] # 2 -> oak
uv_map[3, :] = [uvs[2],  uvs[2],  uvs[2],  uvs[2],  uvs[2],  uvs[18]] # 3 -> crafting table
uv_map[4, :] = [uvs[1],  uvs[1],  uvs[1],  uvs[1],  uvs[1],  uvs[1]]  # 4 -> planks

chunk = UInt8[
    1 0 1; 0 0 0; 1 0 1;;;
    0 0 0; 0 0 0; 0 0 0;;;
    2 0 2; 0 0 0; 3 0 4;;;
]

f, a, p = voxels(chunk, uvmap = uv_map, color = texture)
```
\end{examplefigure}

The textures used in these examples are from [Kenney's Voxel Pack](https://www.kenney.nl/assets/voxel-pack).



#### Updating Voxels

The voxel plot is a bit different from other plot types which affects how you can and should update its data.

First you *can* pass your data as an `Observable` and update that observable as usual:

\begin{examplefigure}{}
```julia
using GLMakie
GLMakie.activate!() # hide

chunk = Observable(ones(8,8,8))
f, a, p = voxels(chunk, colorrange = (0, 1))
chunk[] = rand(8,8,8)
f
```
\end{examplefigure}

You can also update the data contained in the plot object.
For this you can't index into the plot though, since that will return the converted voxel id data.
Instead you need to index into `p.args`.

\begin{examplefigure}{}
```julia
using GLMakie
GLMakie.activate!() # hide

f, a, p = voxels(ones(8,8,8), colorrange = (0, 1))
p.args[end][] = rand(8,8,8)
f
```
\end{examplefigure}

Both of these solutions triggers a full replacement of the input array (i.e. `chunk`), the internal representation (`plot.converted[4]`) and the texture on gpu.
This can be quite slow and wasteful if you only want to update a small section of a large chunk.
In that case you should instead update your input data without triggering an update (using `obs.val`) and then call `local_update(plot, is, js, ks)` to process the update:

\begin{examplefigure}{}
```julia
using GLMakie
GLMakie.activate!() # hide

chunk = Observable(rand(64, 64, 64))
f, a, p = voxels(chunk, colorrange = (0, 1))
chunk.val[30:34, :, :] .= NaN # or p.args[end].val
Makie.local_update(p, 30:34, :, :)
f
```
\end{examplefigure}



#### Picking Voxels

The `pick` function is able to pick individual voxels in a voxel plot.
The returned index is a flat index into the array passed to `voxels`, i.e. `plt.args[end][][idx]` will return the relevant data.
One important thing to note here is that the returned index is a `UInt32` internally and thus has limited range.
Very large voxel plots (~4.3 billion voxels or 2048 x 2048 x 1024) can reach this limit and trigger an integer overflow.
