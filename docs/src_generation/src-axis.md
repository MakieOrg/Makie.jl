# Integrated Axes (Axis2D / Axis3D)

!!! note
    Axis2D refers to the old Makie workflow in which the `Scene` was the main object for
    users to interact with. Back then, the default 2D axis was created like a plot object and
    therefore had many usability issues that were resolved with the new layout system and the new `Axis` type.
    Currently, the 3D axis still uses the old workflow, although you usually embed a scene with a 3D axis
    in a layout using the `LScene` wrapper.

The Axis2D or Axis3D is just a scene object, making it easy to manipulate and share between plots.
These objects also contain the mapping you want to apply to the data and can interactively be changed.
They can be created from any boundingbox and inserted into any plot.

There are two types of plot-like axes: `Axis2D` and `Axis3D`.

## Interacting with the integrated axis

One can quite easily interact with the attributes of the axis like with any other plot.

You can access the axis of a `scene` by doing

```
axis = scene[OldAxis]
```

The axis attributes are nested, and there are different attributes depending on whether it is an `Axis2D` or `Axis3D` object.

You can access the nested attributes in multiple ways. Take the nested attribute `axis -> :names -> :axisnames`, for example:

1. `axis[:names, :axisnames] = ("x", "y", "z")`
1. `axis[:names][:axisnames] = ("x", "y", "z")`
1. `axis = (names = (axisnames = ("x", "y", "z"),),)`

## Convenience functions for integrated axes

Makie offers some convenience functions to make manipulating the Axis2D / Axis3D easier. 

```@docs
xlims!
ylims!
zlims!
xlabel!
ylabel!
zlabel!
xticklabels
yticklabels
zticklabels
xtickrange
ytickrange
ztickrange
xticks!
yticks!
zticks!
xtickrotation
ytickrotation
ztickrotation
xtickrotation!
ytickrotation!
ztickrotation!
```
