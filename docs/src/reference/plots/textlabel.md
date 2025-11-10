# textlabel

```
f, ax, pl = textlabel(args...; kw...) # return a new figure, axis, and plot
   ax, pl = textlabel(f[row, col], args...; kw...) # creates an axis in a subfigure grid position
       pl = textlabel!(ax::Union{Scene, AbstractAxis}, args...; kw...) # Creates a plot in the given axis or scene.
SpecApi.Textlabel(args...; kw...) # Creates a SpecApi plot, which can be used in `S.Axis(plots=[plot])`.
```

## Examples

```@figure
using CairoMakie
using FileIO

f, a, p = image(rotr90(load(assetpath("cow.png"))))
textlabel!(a, Point2f(200, 150), text = "Cow", fontsize = 20)
f
```

```@figure
using CairoMakie
using DelimitedFiles
loc = readdlm(assetpath("airportlocations.csv"))

f, a, p = scatter(
    loc[1:5004:end, :], marker = '✈', markersize = 20, color = :black
)
textlabel!(
    a, loc[1:5004:end, :], text = ["A$i" for i in axes(loc[1:5004:end, :], 1)],
    offset = (0, -20), text_align = (:center, :top)
)

xlims!(a, -140, 150)
ylims!(a, -5, 65)

f
```

### Custom Background Shapes

The background shape can be adjusted with the `shape` attribute. It can be anything that converts to a vector of points through `convert_arguments`, e.g. a GeometryPrimitive, a BezierPath, a vector of points, etc. These points are then transformed to fit the text bounding box of the label. More specifically, they are transformed such that `shape_limits` gets scaled up to the text bounding box plus padding.

Let's consider using a `Circle(Point2f(0), 1f0)` as our background shape. We want the text to fit inside the circle, so we want the text boundingbox to relate to an inner bounding box of the circle. We can choose this to be a square from `-sqrt(0.5) .. sqrt(0.5)` resulting in `shape_limits = Rect2f(-sqrt(0.5), -sqrt(0.5), sqrt(2), sqrt(2))`:

```@figure
using CairoMakie

ps = Point2f[
    (0, 0),
    (-1, -1), (1, -1),
    (-1.5, -2), (-0.5, -2), (0.5, -2), (1.5, -2)
]
f,a,p = textlabel(
    ps,
    ["A", "B", "C", "D",  "E", "F", "G"],
    fontsize = 20, padding = 0,
    shape = Circle(Point2f(0), 1f0),
    shape_limits = Rect2f(-sqrt(0.5), -sqrt(0.5), sqrt(2), sqrt(2)),
    keep_aspect = true
)
linesegments!(a, [
    ps[1], ps[2], ps[1], ps[3],
    ps[2], ps[4], ps[2], ps[5], ps[3], ps[6], ps[3], ps[7]
], linewidth = 4)

xlims!(a, -2, 2)
ylims!(a, -2.5, 0.5)
f
```

Another option for `shape` is to pass a function that constructs an already transformed vector of points from a translation and scale. If `shape_limits = Rect2f(0,0,1,1)` those are the origin and size of text boundingbox plus padding. This can be used, for example, to construct a circle that more tightly fits the text bounding box:

```@figure
using CairoMakie
using GeometryBasics
using LinearAlgebra

function build_shape(origin, size)
    radius = norm(0.5 * size)
    center = Point2f(origin + 0.5 * size)
    return coordinates(Circle(center, radius))
end

f, a, p = textlabel(
    [-1, 0, 1], [1, 1, 1], ["long label", "A", "t\na\nl\nl"],
    shape = build_shape, fontsize = 20, padding = 0
)
textlabel!(
    a, [-1, 0, 1], [-1, -1, -1], ["long label", "A", "t\na\nl\nl"],
    shape = Circle(Point2f(0), 1f0), fontsize = 20, padding = 0,
    shape_limits = Rect2f(-sqrt(0.5), -sqrt(0.5), sqrt(2), sqrt(2)),
    keep_aspect = true
)
xlims!(a, -1.5, 1.5)
ylims!(a, -1.75, 1.75)
f
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/textlabel) for rendered examples.

## Attributes

### `alpha`

**Default:** `1.0`

Sets the alpha value (opaqueness) of the background.

### `strokecolor`

**Default:** `:black`

Sets the color of the outline around the background

### `text_color`

**Default:** `@inherit textcolor`

Sets the color of the text. One can set one color per glyph by passing a `Vector{<:Colorant}` or one colorant for the whole text.

### `background_color`

**Default:** `:white`

Sets the color of the background. Can be a `Vector{<:Colorant}` for per vertex colors, a single `Colorant` or an `<: AbstractPattern` to cover the poly with a regular pattern, e.g. for hatching.

### `text_strokewidth`

**Default:** `0`

Sets the width of the outline around text.

### `text`

**Default:** `""`

Specifies one piece of text or a vector of texts to show, where the number has to match the number of positions given. Makie supports `String` which is used for all normal text and `LaTeXString` which layouts mathematical expressions using `MathTeXEngine.jl`.

### `clip_planes`

**Default:** `Plane3f[]`

Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

### `joinstyle`

**Default:** `@inherit joinstyle`

Controls the rendering of outline corners. Options are `:miter` for sharp corners, `:bevel` for "cut off" corners, and `:round` for rounded corners. If the corner angle is below `miter_limit`, `:miter` is equivalent to `:bevel` to avoid long spikes.

### `inspector_label`

**Default:** `automatic`

Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

### `keep_aspect`

**Default:** `false`

Controls whether the aspect ratio of the background shape is kept during rescaling

### `strokewidth`

**Default:** `1`

Sets the width of the outline.

### `depth_shift`

**Default:** `0.0`

Adjusts the depth value of the textlabel after all other transformations, i.e. in clip space where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

### `fontsize`

**Default:** `@inherit fontsize`

The fontsize in pixel units.

### `inspector_clear`

**Default:** `automatic`

Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

### `shape`

**Default:** `Rect2f(0, 0, 1, 1)`

Controls the shape of the background. Can be a GeometryPrimitive, mesh or function `(origin, size) -> coordinates`. The former two options are automatically rescaled to the padded bounding box of the rendered text. By default (0, 0) will be the lower left corner and (1, 1) the upper right corner of the padded bounding box. See `shape_limits`.

### `position`

**Default:** `(0, 0)`

Deprecated: Specifies the position of the text. Use the positional argument to `text` instead.

### `visible`

**Default:** `true`

Controls whether the plot will be rendered or not.

### `draw_on_top`

**Default:** `true`

Controls whether the textlabel is drawn in front (true, default) or at a depth appropriate to its position.

### `linestyle`

**Default:** `nothing`

Sets the dash pattern of the outline. Options are `:solid` (equivalent to `nothing`), `:dot`, `:dash`, `:dashdot` and `:dashdotdot`. These can also be given in a tuple with a gap style modifier, either `:normal`, `:dense` or `:loose`. For example, `(:dot, :loose)` or `(:dashdot, :dense)`.

For custom patterns have a look at [`Makie.Linestyle`](@ref).

### `overdraw`

**Default:** `false`

Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

### `miter_limit`

**Default:** `@inherit miter_limit`

Sets the minimum inner join angle below which miter joins truncate. See also `Makie.miter_distance_to_angle`.

### `text_strokecolor`

**Default:** `(:black, 0.0)`

Sets the color of the outline around text.

### `transparency`

**Default:** `false`

Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

### `space`

**Default:** `:data`

sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

### `fonts`

**Default:** `@inherit fonts`

Used as a dictionary to look up fonts specified by `Symbol`, for example `:regular`, `:bold` or `:italic`.

### `justification`

**Default:** `automatic`

Sets the alignment of text with respect to its bounding box. Can be `:left, :center, :right` or a fraction. Will default to the horizontal alignment in `text_align`.

### `text_glowcolor`

**Default:** `(:black, 0.0)`

Sets the color of the glow effect around text.

### `text_glowwidth`

**Default:** `0.0`

Sets the size of a glow effect around text.

### `lineheight`

**Default:** `1.0`

The lineheight multiplier.

### `text_rotation`

**Default:** `0.0`

Rotates the text around the given position. This affects the size of the textlabel but not its rotation

### `cornerradius`

**Default:** `5.0`

Sets the corner radius when given a Rect2 background shape.

### `padding`

**Default:** `4`

Sets the padding between the text bounding box and background shape.

### `shape_limits`

**Default:** `Rect2f(0, 0, 1, 1)`

Sets the coordinates in `shape` space that should be transformed to match the size of the text bounding box. For example, `shape_limits = Rect2f(-1, -1, 2, 2)` results in transforming (-1, 1) to the lower left corner of the padded text bounding box and (1, 1) to the upper right corner. If the `shape` contains coordinates outside this range, they will rendered outside the padded text bounding box.

### `fxaa`

**Default:** `false`

Controls whether the background renders with fxaa (anti-aliasing, GLMakie only). This is set to `false` by default to prevent artifacts around text.

### `stroke_alpha`

**Default:** `1.0`

Sets the alpha value (opaqueness) of the background outline.

### `text_alpha`

**Default:** `1.0`

Sets the alpha value (opaqueness) of the text.

### `inspector_hover`

**Default:** `automatic`

Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

### `word_wrap_width`

**Default:** `-1`

Specifies a linewidth limit for text. If a word overflows this limit, a newline is inserted before it. Negative numbers disable word wrapping.

### `text_fxaa`

**Default:** `false`

Controls whether the text renders with fxaa (anti-aliasing, GLMakie only). Setting this to true will reduce text quality.

### `font`

**Default:** `@inherit font`

Sets the font. Can be a `Symbol` which will be looked up in the `fonts` dictionary or a `String` specifying the (partial) name of a font or the file path of a font file

### `offset`

**Default:** `(0.0, 0.0)`

The offset of the textlabel from the given position in `markerspace` units.

### `shading`

**Default:** `NoShading`

Controls whether the background reacts to light.

### `inspectable`

**Default:** `@inherit inspectable`

Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

### `text_align`

**Default:** `(:center, :center)`

Sets the alignment of the string with respect to `position`. Uses `:left, :center, :right, :top, :bottom, :baseline` or fractions.

### `cornervertices`

**Default:** `10`

Sets the number of vertices involved in a rounded corner. Must be at least 2.
