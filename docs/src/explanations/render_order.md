# Render Order

To explain the render order in Makie we will go through the different parts that affect it, adding more concepts as we progress.

## Scene Render Order

Let's first consider scenes without plots with `scene.clear = true`.
These scenes will render their `scene.backgroundcolor` to their `scene.viewport`.
The render order follows the order scenes are visited in in a depth first search:
1. A parent scene renders before its children.
2. Child scenes render in the order they appear in `scene.children`

```@figure
root = Scene(backgroundcolor = :gray, clear = true, size = (500, 300))

child1 = Scene(root, backgroundcolor = :darkred, clear = true, viewport = Rect2i(50, 25, 200, 200))
child2 = Scene(root, backgroundcolor = :darkgreen, clear = true, viewport = Rect2i(250, 75, 200, 200))

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

# ordered above
Scene(root, zindex = 1, backgroundcolor = :orange, clear = true, viewport = Rect2i(30, 145, 440, 10))

# defaults to zindex = 0
child1 = Scene(root, backgroundcolor = :darkred, clear = true, viewport = Rect2i(50, 25, 200, 200))
child2 = Scene(root, backgroundcolor = :darkgreen, clear = true, viewport = Rect2i(250, 75, 200, 200))
Scene(child1, backgroundcolor = :darkblue, clear = true, viewport = Rect2i(150, 50, 200, 200))

# ordered below
Scene(root, zindex = -1, backgroundcolor = :black, clear = true, viewport = Rect2i(25, 140, 450, 20))

root
```

## Plot Rendering in Cleared Scenes

Plots are always associated with a scene.
They are restricted to draw within their parent scenes `viewport`.
If the parent scenes clears, i.e. draws a background, then plots will draw on top of the background.
If a scene B with `clear = true` covers scene A, then it also covers the plots in scene A.

```@figure
ps = [Point2f(x, y) for x in -40:20:320 for y in -40:20:100]

root = Scene(backgroundcolor = :gray, clear = true, size = (300, 300), camera = campixel!)
scatter!(root, ps, markersize = 20, color = :black)

child = Scene(
    root, backgroundcolor = :darkred, clear = true,
    viewport = Rect2i(50, 50, 200, 200), camera = campixel!
)
scatter!(child, ps, markersize = 20, color = :red)

root
```

## Plot Render Order

2D plots (constant z/depth value after all transformations) are ordered based on:
1. Their depth which typically follows from `translate!(plot, 0, 0, z)` or rarely z values given in plot arguments.
2. The order plots were created in.

Note that this order does not match the order in `scene.plots` as the depth value can be changed dynamically.

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

In 3D the render order depends on the backend to a degree.

### GLMakie and WGLMakie Details

GLMakie and WGLMakie keep track of the depth of each drawn pixel.
A plot only draws to a pixel if it is in front of what is already there.
So a plot can be both in front of and behind another plot.

The per pixel depth is a result of interpolating the plots coordinates (typically given as arguments), its transformations (transform function, model transformations), camera matrices (i.e. the perspective the plot is seen from) and the `depth_shift` attribute.
The latter is meant to resolve overlap issues (z-fighting) by nudging a plots depth values closer to the viewer (negative) or further away (positive).
If the final depth value falls outside a 0 .. 1 range the plot is clipped, meaning that the pixel won't be drawn.

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

Beyond this, there is still the order in which plots are drawn which mostly matters for plots with transparency which blend with what has already been drawn.
GLMakie and WGLMakie attempt to optimize the draw order based on plot type, transparency and average depth.
Sometimes it can be useful to nudge the draw order as well.
This can be done with the `zorder_shift` attribute.
Small shifts (abs < 1) can be used to adjust the order of the same group of plots (e.g. plots with transparency) while large shifts (abs > 100) can be used to push plots out of their group.
A positive `zorder_shift` makes a plot draw later, a negative shift earlier.

```@figure backend=GLMakie
GLMakie.activate!(px_per_unit = 1.0) # hide
scene = Scene(backgroundcolor = :gray, clear = true, size = (300, 300), camera = campixel!)
p = scatter!(scene, 150, 150, 0, marker = Rect, markersize = 200, color = :black)

# Drawn before p, because p1.gl_zindex[] ≈ -0.00045 < p.gl_zindex[] = 0
# This causes blending with the gray background instead of the red scatter marker
p1 = scatter!(scene, [100, 150, 200], [200, 200, 200], [-10, 1, 1], color = :blue, markersize = 50)

# Drawn after p, because zorder_shift pushes p2.gl_zindex[] ≈ 0.00055 above p.gl_zindex[]
# This results in correct blending
p2 = scatter!(
    scene, [100, 150, 200], [100, 100, 100], [-10, 1, 1], color = :green, markersize = 50,
    zorder_shift = 0.001
)

scene
```

One more attribute that should be mentioned here is `overdraw`.
Setting it to `true` disables depth tests, i.e. the per-pixel depth checks.
This will cause the plot to draw regardless of there its pixel depth is above what is already drawn, and it will stop it from writing its own depth to the pixel.
Whether a plot with `overdraw = true` covers another is then entirely based on when it draws.

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

### CairoMakie Details

CairoMakie does not have a depth buffer.
It simply draws one (primitive) plot after another.
The order of (primitive) plots follows from their depth value (which includes `depth_shift`) and their `zorder_shift`.

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

# Lower average depth, shifter above (compare CairoMakie.cairo_zindex(plot))
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

## Uncleared Scenes

When `scene.clear = false`, the scene does not "clear" its viewport with its background color.
Any plots and scenes under it will thus remain visible.
It also does not clear the per-pixel depth values that GLMakie and WGLMakie use.
As a result plots can reorder in groups of scenes starting with a `clear = true` scene and ending before the next `clear = true` scene.
This is also true in CairoMakie.

```@figure
ps = [Point2f(x, y) for x in 0:50:300 for y in 0:50:300]

parent = Scene(backgroundcolor = :gray, clear = true, size = (300, 300), camera = campixel!)
p1 = scatter!(parent, ps, color = :darkred, markersize = 50)

# This scene does not draw a background and is grouped with parent. Plots from
# both scenes are pooled and order together
child = Scene(
    parent, backgroundcolor = :red, clear = false,
    viewport = Rect2i(50, 50, 200, 200), camera = campixel!
)

p2 = scatter!(child, ps, color = :green, markersize = 50)
translate!(p2, 25, 0, -1) # below p1 despite being in the child scene

p3 = scatter!(child, ps, color = :blue, markersize = 50)
translate!(p3, 0, 25, 1) # above p1 despite being in the child scene

parent
```
