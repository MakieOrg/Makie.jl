# Axis3

## Axis3 interaction

Like Axis, Axis3 has a few predefined interactions enabled.

### Drag Rotate

You can rotate the view by left-clicking and dragging. 
This interaction is registered as `:dragrotate` and uses the `DragRotate` type.

### Scroll zoom

You can zoom in an axis by scrolling in and out.
By default, the zoom is centered on the center of the Axis.
Alternatively you can set `zoommode = :cursor` to approximately center the zoom on the cursor instead.
If you press x, y or z while scrolling, the zoom is restricted to that dimension.
If you press two keys simulatenously, the zoom will be restricted to the corresponding plane instead.
These keys can be changed with the attributes `xzoomkey`, `yzoomkey` and `zzoomkey`.
You can also restrict the zoom dimensions all the time by setting the axis attributes `xzoomlock`, `yzoomlock` or `zzoomlock` to `true`.
This interaction is registered as `:scrollzoom` and uses the `ScrollZoom` type.

### Translation

You can translate the view of the Axis3 by right-clicking and dragging.
If you press x, y or z while translating, the translation is restricted to that dimension.
If you press two keys simulatenously, the translation will be restricted to the corresponding plane instead.
These keys can be changed with the attributes `xtranslationkey`, `ytranslationkey` and `ztranslationkey`.
You can also restrict the translation all the time by setting the axis attributes `xtranslationlock`, `ytranslationlock` or `ztranslationlock` to `true`.
This interaction is registered as `:translation` and uses the `DragPan` type.

### Limit reset

You can reset the limits with `ctrl + leftclick`. 
This is the same as calling `reset_limits!(ax)`. 
It sets the limits back to the values stored in `ax.limits`, and if they are `nothing`, computes them automatically. 
If you have previously called `limits!`, `xlims!`, `ylims!` or `zlimes!`, these settings therefore stay intact when doing a limit reset.

You can alternatively press `ctrl + shift + leftclick`, which is the same as calling `autolimits!(ax)`.
This function ignores previously set limits and computes them all anew given the axis content.

## Attributes

```@attrdocs
Axis3
```
