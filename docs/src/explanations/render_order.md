# Render Order

## Plots

The goal is to render plots based on the distance from the camera/viewer.
Plots that are further away should appear behind plots that are closer.
When this distinction can not be made plots are rendered in the order were created in.

### Depth

The distance from the camera/viewer follows from the plots coordinates after all transformation and projections were applied.
This distance is generally referred to as depth.
It is influenced by:
- plot arguments which generally define the position of the plot.
- `plot.transformations` which include `translate!()`, `scale!()`, `rotate!()` and transform functions.
- `plot.space` which defines how to interpret the plots position.
- `scene.camera` (if `space == :data`) which define camera/viewer based transformations.
- `plot.depth_shift` which defines a final offset added to the plots depth. (Depth is define in a -1 .. 1 range.)

In 2D the `camera` does not include 3D rotations and therefore affects every plot (of the same scene and `space`) in the same way.
Therefore it does not influence the visual order.
Here, the order is typically based on `translate!` and z values in plot arguments and plot creation/insertion order.

In 3D the `camera` usually includes 3D rotations which mix coordinates and influence which plot appears in front.
The visual order is mainly influenced by the coordinates of the plot relative to the camera/viewer.

```@figure
scene = Scene(backgroundcolor = :gray, clear = true, size = (300, 300), camera = campixel!)

# z = 10, front
p1 = scatter!(scene, 100, 150, 10, markersize = 250, color = :black)

# z = 0, insertion order
p2 = scatter!(scene, 150, 100, 0, markersize = 250, color = :darkred)
p3 = scatter!(scene, 200, 150, 0, markersize = 250, color = :darkgreen)

# z = -10, back
p4 = scatter!(scene, 150, 200, -10, markersize = 250, color = :darkblue)

scene
```

### CairoMakie

CairoMakie generally can't resolve visual order pixel by pixel.
Instead it is resolved plot by plot, using the depth of the center of the plots bounding box.
This depth estimate is influenced by the same inputs as the depth value discussed above.
It is additionally influenced by `zorder_shift` which acts just like `depth_shift`.

In simpler terms, CairoMakie can render 2D plots but may not be able to render 3D plots correctly.

```@figure backend=CairoMakie
scene = Scene(backgroundcolor = :gray, clear = true, size = (300, 300), camera = campixel!)
p = scatter!(scene, 150, 150, 0, marker = Rect, markersize = 150, color = :black)

# Lower average depth than p, draws below
p1 = scatter!(
    scene, [75, 150, 225], fill(225, 3), -11:10:9, color = :darkred, markersize = 50
)

# Same average depth as p, follows insertion order
p2 = scatter!(
    scene, [75, 150, 225], fill(175, 3), -10:10:10, color = :blue, markersize = 50
)

# Lower average depth, shifted above (compare CairoMakie.cairo_zindex(plot))
# Note: depth_shift can be used here instead of zorder_shift
p3 = scatter!(
    scene, [75, 150, 225], fill(125, 3), fill(-10, 3), color = :green,
    markersize = 50, zorder_shift = 0.001
)

# Higher average depth, shifted below
# Note: depth_shift can be used here instead of zorder_shift
p4 = scatter!(
    scene, [75, 150, 225], fill(75, 3), fill(-10, 3), color = RGBf(0.25, 0, 0.5),
    markersize = 50, zorder_shift = -0.001
)

scene
```

### GLMakie and WGLMakie

GLMakie and WGLMakie both use a "depth buffer" for rendering.
The depth buffer keeps track of each pixels depth as plots are drawn.
The color values of a pixel only change when a plot draws over the recorded depth.
This allows the GL backends to correctly order plots that draw partially in front and partially behind each other.

```@figure backend=GLMakie
scene = Scene(backgroundcolor = :gray, clear = true, size = (300, 300), camera = campixel!)

mesh!(
    scene,
    Point3f[(50, 50, -10), (50, 200, -10), (250, 200, 10), (250, 50, 10)],
    [1 2 3; 3 4 1],
    color = :darkred, shading = false
)

mesh!(
    scene,
    Point3f[(50, 100, 10), (50, 250, 10), (250, 250, -10), (250, 100, -10)],
    [1 2 3; 3 4 1],
    color = :darkblue, shading = false
)

scene
```

#### `zorder_shift`

While opaque plots can draw in any order thanks to the depth buffer, transparent plots still need to draw in back-to-front order.
Otherwise a transparent pixel will blend with and incomplete background and block the missing background pixels from drawing.
This may be visible as the scene background bleeding through in-between plots when mixing with a semi-transparent plot or an anti-aliasing border.

The draw order is defined by the depth of the center of the plots bounding box and `zorder_shift` just like in CairoMakie.
Note that here `zorder_shift` only influences the draw order ("when"), but not the pixel depths ("where").
Therefore `zorder_shift` can be used to resolve draw order issues without affecting the order imposed by the depth buffer.

```@figure backend=GLMakie
GLMakie.activate!(px_per_unit = 1.0) # hide
scene = Scene(backgroundcolor = :gray, clear = true, size = (300, 300), camera = campixel!)
p = scatter!(scene, 150, 150, 0, marker = Rect, markersize = 200, color = :black)

# Drawn before p, because p1.gl_zindex[] ≈ -0.00045 < p.gl_zindex[] = 0
# This causes blending with the gray background instead of the black Rect scatter
p1 = scatter!(scene, [100, 150, 200], [200, 200, 200], [-10, 1, 1], color = :blue, markersize = 50)

# Drawn after p, because zorder_shift pushes p2.gl_zindex[] ≈ 0.00055 above p.gl_zindex[]
# This results in correct blending
p2 = scatter!(
    scene, [100, 150, 200], [100, 100, 100], [-10, 1, 1], color = :green, markersize = 50,
    zorder_shift = 0.001
)

scene
```

#### `overdraw`

The `overdraw` attribute effectively make GLMakie and WGLMakie draw the way CairoMakie does.
It disables depth tests and writes, i.e. stops the pixel-by-pixel depth checks and prevents the pixel depths from being overwritten.
With this a plot will just draw all of its content when its draw call is issued.
This can be useful for drawing background or foreground elements that should not be obstructed or obstruct any other plot.

```@figure backend=GLMakie
GLMakie.activate!(px_per_unit = 1.0) # hide
scene = Scene(backgroundcolor = :gray, clear = true, size = (300, 300), camera = campixel!)
p = scatter!(scene, 150, 150, 0, marker = Rect, markersize = 150, color = :black)

# Draws after p but still behind p, causing incorrect blending of p with the background
p1 = scatter!(
    scene, [75, 150, 225], fill(225, 3), fill(-10, 3), color = :darkred,
    markersize = 50, zorder_shift = 1.0
)

# Draws before p, so it can't draw over p
p2 = scatter!(
    scene, [75, 150, 225], fill(150, 3), fill(-10, 3), color = :green,
    markersize = 50, zorder_shift = -1.0, overdraw = true
)

# Draws after p and ignores depth, causing it to draw over p
p3 = scatter!(
    scene, [75, 150, 225], fill(75, 3), fill(-10, 3), color = :blue,
    markersize = 50, zorder_shift = 1.0, overdraw = true
)

scene
```

#### Draw Order

Backends are allowed some freedom in their draw order.
For GLMakie and WGLMakie it is preferable to draw opaque objects front to back (to avoid drawing over a pixel multiple times) and semi-transparent objects later (to not draw under opaque objects), in back to front order (to correctly order transparent pixels).
This is done by adding bias to their zorder, resulting in a few islands:
- `-1 .. 1` are opaque plots
- `19 .. 21` are opaque scatter, text, lines and linesegment plots which have a little bit of transparency in their anti-aliasing
- `29 .. 31` are transparent plots as volume plots

Smaller `zorder_shift` values will only affect the order of plots in the same island.
Larger shifts may move a plot from one island or another.
If you need a transparent plot to render before another transparent plot, a shift by `-0.01` might be enough.
If you need a transparent plot to render before an opaque text plot, you'll need a shift on the order of `-10`.
If you you want to firmly place a plot into the background and draw with `overdraw = true` you may use large shifts like `-10_000` (the full Float64 range is usable here).

Note that you can query the final zorder value with `plot.gl_zindex` on primitive plots.
High values are drawn late (in front), low values early (behind).

## Scenes

A scene is drawn in three steps.
1. If `clear == true` the scene will erase everything drawn in its `viewport` and replace it with its `backgroundcolor`. Otherwise the previously drawn content is kept.
2. The scene will draw all the plots attached to it. This happens independently of the plots drawn by previous scenes. (I.e. the depth buffer will be cleared beforehand.)
3. The scene will iterate through its children, drawing each child scene.

```@figure
root = Scene(backgroundcolor = :gray, clear = true, size = (500, 300))

child1 = Scene(root, backgroundcolor = :darkred, clear = true, viewport = Rect2i(50, 25, 200, 200))
child2 = Scene(root, backgroundcolor = :darkgreen, clear = true, viewport = Rect2i(250, 75, 200, 200))

# child of child1 instead of root, draws before child2 as it is part of drawing child1
Scene(child1, backgroundcolor = :darkblue, clear = true, viewport = Rect2i(150, 50, 200, 200))

root
```

!!! note
    We currently do not require or enforce that the viewport of a child scene is fully contained in the viewport of its parent.
    (I.e. the blue scene currently draws outside its parent red scene in the example.)
    It is however generally assumed that child scenes are inside their parent and we may require this in the future.

The order of scenes in `parent.children` is based on a integer `zindex`.
It can be set when the child scene is created with `Scene(parent, ..., zindex = ...)`.
This allows for e.g. an overlay scene to be created within the context of a parent scene by setting `zindex > 0`.

```@figure
root = Scene(backgroundcolor = :gray, clear = true, size = (500, 300))

# ordered above/after
Scene(root, zindex = 1, backgroundcolor = :orange, clear = true, viewport = Rect2i(30, 145, 440, 10))

# defaults to zindex = 0
child1 = Scene(root, backgroundcolor = :darkred, clear = true, viewport = Rect2i(50, 25, 200, 200))
child2 = Scene(root, backgroundcolor = :darkgreen, clear = true, viewport = Rect2i(250, 75, 200, 200))
Scene(child1, backgroundcolor = :darkblue, clear = true, viewport = Rect2i(150, 50, 200, 200))

# ordered below/before
Scene(root, zindex = -1, backgroundcolor = :black, clear = true, viewport = Rect2i(25, 140, 450, 20))

root
```

Scenes naturally act as overlays. If scene B is ordered after scene A, every plot in B will draw on top of the plots from scene A, regardless of depth, overdraw, etc.

```@figure
ps = [Point2f(x, y) for x in -40:20:320 for y in -40:20:100]

# in front based on depth_shift (less far), zorder_shift (draw later) and
# translate!() (higher z)
root = Scene(backgroundcolor = :gray, clear = true, size = (300, 300), camera = campixel!)
p1 = scatter!(root, ps, markersize = 25, color = :black, depth_shift = -0.1, zorder_shift = 1000)
translate!(p1, 0, 0, 1000)

# behind based on depth attributes, but part of an overlayed sceen
# -> draws in front
child = Scene(root, viewport = Rect2i(50, 50, 200, 200), camera = campixel!)
p2 = scatter!(child, ps, markersize = 25, color = :red, depth_shift = 0.1, zorder_shift = -1000)
translate!(p2, 0, 0, -1000)

# cleared scene erases what's behind it (only root, because zindex orders it before child)
Scene(root, viewport = Rect2i(175, 25, 100, 150), backgroundcolor = :navy, zindex = -1, clear = true)

root
```
