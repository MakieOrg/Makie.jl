# Blocks

`Blocks` are objects which can be added to a `Figure` or `Scene` and have their location and size controlled by a `GridLayout`. In of itself, a `Block` is an abstract type.
A `Figure` has its own internal `GridLayout` and therefore offers simplified syntax for adding blocks to it.
If you want to work with a bare `Scene`, you can attach a `GridLayout` to its pixel area.

!!! note
    A layout only controls an object's position or bounding box.
    A `Block` can be controlled by the GridLayout of a Figure but not be added as a visual to the Figure.
    A `Block` can also be added to a Scene without being inside any GridLayout, if you specify the bounding box yourself.

## Adding to a `Figure`

Here's one way to add a `Block`, in this case an `Axis`, to a Figure.

```@figure
f = Figure()
ax = Axis(f[1, 1])
f
```

## Specifying a boundingbox directly

Sometimes you just want to place a `Block` in a specific location, without it being controlled by a dynamic layout.
You can do this by setting the `bbox` parameter, which is usually controlled by the layout, manually.
The boundingbox should be a 2D `Rect`, and can also be an Observable if you plan to change it dynamically.
The function `BBox` creates an `Rect2f`, but instead of passing origin and widths, you pass left, right, bottom and top boundaries directly.

Here's an example where two axes are placed manually:

```@figure
f = Figure()
Axis(f, bbox = BBox(50, 200, 50, 300), title = "Axis 1")
Axis(f, bbox = BBox(250, 550, 100, 350), title = "Axis 2")
f
```

## Deleting blocks

To remove blocks from their layout and the figure or scene, use `delete!(block)`.
