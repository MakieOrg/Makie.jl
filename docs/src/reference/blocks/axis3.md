# Axis3

## Axis3 interactions

Like Axis, Axis3 has a few predefined interactions enabled.

### Rotation

You can rotate the view by left-clicking and dragging.
This interaction is registered as `:dragrotate` and uses the `DragRotate` type.

### Zoom

You can zoom in an axis by scrolling in and out.
By default, the zoom is focused on the center of the Axis.
You can set `zoommode = :cursor` to focus the zoom on the cursor instead.
If you press `x`, `y` or `z` while scrolling, the zoom is restricted to that dimension.
If you press two keys simultaneously, the zoom will be restricted to the corresponding plane instead.
These keys can be changed with the attributes `xzoomkey`, `yzoomkey` and `zzoomkey`.
You can also restrict the zoom dimensions all the time by setting the axis attributes `xzoomlock`, `yzoomlock` or `zzoomlock` to `true`.

With `viewmode = :free` the behavior of the zoom changes.
Instead of affecting just the content of the axis, zooming affects the axis as a whole.
It also disables `zoommode = :cursor`.
This interaction is registered as `:scrollzoom` and uses the `ScrollZoom` type.

### Translation

You can translate the view of the Axis3 by right-clicking and dragging.
If you press `x`, `y` or `z` while translating, the translation is restricted to that dimension.
If you press two keys simultaneously, the translation will be restricted to the corresponding plane instead.
These keys can be changed with the attributes `xtranslationkey`, `ytranslationkey` and `ztranslationkey`.
You can also restrict the translation all the time by setting the axis attributes `xtranslationlock`, `ytranslationlock` or `ztranslationlock` to `true`.

With `viewmode = :free` another option for translation is added.
By pressing `control` while right-click dragging, the translation will affect the placement of the axis in the window instead of the content within the axis.
This interaction is registered as `:translation` and uses the `DragPan` type.

### Limit reset

You can reset the limits, i.e. zoom and translation with `ctrl + left click`.
This is the same as calling `reset_limits!(ax)`.
It sets the limits back to the values stored in `ax.limits`.
If they are `nothing` this computes automatic limits.
If you have previously called `limits!`, `xlims!`, `ylims!` or `zlims!` then `ax.limits` will be set and kept by this interaction.
You can reset the rotation of the axis with `shift + left click`.
If `viewmode = :free` this will also reset the translation of the axis (not just of the content).
If you trigger both simultaneously, i.e. press `ctrl + shift + leftclick`, the axis will be fully reset.
This includes `ax.limits` which are reset to `nothing` via `autolimits!(ax)`
This interaction is registered as `:limitreset` and uses the `LimitReset` type.

### Center on point

You can center the axis on your cursor with `alt + left click`.
Note that depending on the plot type, this may mean different things.
For most, a point on the surface of the plot is used.
For `meshscatter`, `scatter` and derived plots the position of the scattered mesh/marker is used.
This interaction is registered as `:cursorfocus` and uses the `FocusOnCursor` type.



## Attributes

```@attrdocs
Axis3
```
