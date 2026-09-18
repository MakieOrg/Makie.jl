# image

## Examples

```@figure
using FileIO
image(load(assetpath("cow.png")))
```

Row 1 of the matrix appears at the visual top, column 1 at the left — matching
what an image viewer would show. This works because `image` sets `yreversed = true`
as a hint on the freshly-created axis.

!!! warning "`image!` does not flip the y axis"

    The `yreversed = true` hint only applies when `image` creates a new axis.
    If you call `image!` to add into an existing axis, the y direction follows
    whatever that axis already had. Set `yreversed = true` on the axis
    yourself if you want the same upright orientation.

### Keeping the original aspect ratio

By default the axis stretches the image to fill its allocated space. Pass
`axis = (; aspect = DataAspect())` to keep the pixels at their natural 1:1
aspect ratio. See the "Aspect ratios and automatic figure sizes" tutorial for
more on how aspect ratios interact with the rest of the layout.

```@figure
using FileIO
image(load(assetpath("cow.png")); axis = (; aspect = DataAspect()))
```

### Handling different image layouts

`image` lays the matrix of pixels out onto a rectangle in data space. By
convention we think of the quad as oriented top-to-bottom / left-to-right,
which is why `image` sets `yreversed = true` as an axis hint when you call
`image(array)`. The directions below are stated relative to that top-down y
axis.

The default `orientation = (:down, :right)` matches the convention used by
`FileIO.load`, NumPy, PIL, OpenCV and the like: `image[1, 1]` is the top-left
pixel, the first array dim runs top-to-bottom, the second runs left-to-right.
If your image was stored differently, for example because it was recorded by
an unusual scientific instrument, you may need to adjust the `orientation`
setting.

`orientation` is a tuple `(d1, d2)` of directions describing how the first and
second array dims run on the rectangle in the data space where y goes down
and x to the right. Each entry is one of `:up`, `:down`, `:left`, `:right`;
exactly one must be vertical and one horizontal. Below is a downscaled cow
rendered at four different `orientation` values, with each cell labelled by
its `(i, j)` index in the user matrix — following the indices in order shows
which direction each array dim spreads. Note that `(:down, :right)` and
`(:right, :down)` are not the same: in the first the rows of the matrix run
downward and the columns rightward, while in the second the rows run rightward
and the columns downward (a transpose of the layout).

Only `(:down, :right)` (the default) leads to a correct upright image of the
cow; one of the other settings may be appropriate if the image you are
dealing with was stored differently.

```@figure hide_code=true
using FileIO

function pixelate(img; max_side = 15)
    h, w = size(img)
    stride = max(1, max(h, w) ÷ max_side)
    return img[1:stride:end, 1:stride:end]
end

luminance(c) = let rgb = convert(Makie.Colors.RGB{Float32}, c)
    0.2126f0 * rgb.r + 0.7152f0 * rgb.g + 0.0722f0 * rgb.b
end

img = pixelate(load(assetpath("cow.png")))
h, w = size(img)
vertical = (:up, :down)
function cell_pos(i, j, orientation)
    d1, d2 = orientation
    if d1 in vertical
        y = d1 === :down ? i : (h - i + 1)
        x = d2 === :right ? j : (w - j + 1)
    else
        x = d1 === :right ? i : (h - i + 1)
        y = d2 === :down ? j : (w - j + 1)
    end
    return Point2f(x - 0.5, y - 0.5)
end
getticks(n) = 0:n

f = Figure(size = (1100, 950))
for (n, s) in enumerate([(:down, :right), (:down, :left), (:up, :right), (:right, :down)])
    row, col = divrem(n - 1, 2) .+ (1, 1)
    x_cells, y_cells = s[1] in vertical ? (w, h) : (h, w)
    ax = Axis(f[row, col]; aspect = DataAspect(), title = "orientation = $(s)",
        yreversed = true,
        xticks = getticks(x_cells), yticks = getticks(y_cells),
        xautolimitmargin = (0, 0), yautolimitmargin = (0, 0))
    image!(ax, img; orientation = s, interpolate = false)
    indices = vec(CartesianIndices(img))
    positions = [cell_pos(I[1], I[2], s) for I in indices]
    labels = [string("(", I[1], ",", I[2], ")") for I in indices]
    colors = [luminance(img[I]) > 0.5 ? :black : :white for I in indices]
    text!(ax, positions; text = labels, align = (:center, :center),
        color = colors, fontsize = 9)
end
f
```

### Explicit x/y bounds

When you pass `image(xs, ys, mat)` with explicit `xs`/`ys`, those bounds
replace the orientation-derived defaults, but `orientation` still determines
the direction each array dim runs on the quad and `image` still sets
`yreversed = true` as an axis hint. If the explicit y bounds are meant to be
shown the conventional way (low y at the bottom), set `yreversed = false`
yourself.
