# image

## Examples

### Orientation

`image` lays the matrix out onto a quad inside the data rectangle. By
convention the quad is oriented top-to-bottom / left-to-right (like the way
you'd describe the size of a picture), which conflicts with a math-style y
axis growing upward — so `image` sets `yreversed = true` as an axis hint on
freshly-created axes to make `image(mat)` render upright by default.

How the array is spread onto that quad is controlled by a single `storage`
attribute: a tuple `(d1, d2)` describing the directions the two array dims
run on the quad. Each entry is one of `:up`, `:down`, `:left`, `:right`;
exactly one must be vertical and one horizontal. Default `(:down, :right)`
matches the typical image-storage convention (`FileIO.load`, NumPy/PIL): the
first array dim runs top-to-bottom and the second runs left-to-right.

Directions are quad-relative, so `:down` always means "towards the bottom of
the image" regardless of `xreversed` / `yreversed` overrides on the axis.

```@figure
using FileIO

img = load(assetpath("cow.png"))

f = Figure()

image(f[1, 1], img,
    axis = (aspect = DataAspect(), title = "(:down, :right) — default",))

image(f[1, 2], img; storage = (:down, :left),
    axis = (aspect = DataAspect(), title = "(:down, :left)\nsecond dim runs right-to-left",))

image(f[2, 1], img; storage = (:up, :right),
    axis = (aspect = DataAspect(), title = "(:up, :right)\nfirst dim runs bottom-to-top",))

image(f[2, 2], img; storage = (:right, :down),
    axis = (aspect = DataAspect(), title = "(:right, :down)\nlegacy Makie: first dim runs along x",))

f
```

For an image that's stored with `image[1, 1]` at the bottom-right and the
first dim running along x (rather than y), use `storage = (:left, :up)` —
the first array dim runs right-to-left, the second bottom-to-top, putting
`image[1, 1]` at the visual bottom-right of the upright rendering.

`storage` only describes how the array is mapped to the quad. Flipping
`xreversed` / `yreversed` on the axis still rotates the visual independently
— the data anchor stays put.
