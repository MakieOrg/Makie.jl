# arrows

`arrows` is deprecated. Use [arrows2d](@ref) or [arrows3d](@ref) instead.

Arrows are split into two plot types, `arrows2d` and `arrows3d`.
They differ in the arrow markers they create - `arrows2d` creates 2D arrows and `arrows3d` creates 3D arrows.
Both can be used with 2D and 3D coordinates.

## Arrow Components & Details

![Arrow Components](../../assets/arrow_components.png)

### Arrow Length

The target size of each arrow is determined by its direction vector (second plot argument), `normalize` and `lengthscale`.
From tail to tip, the length is given as `lengthscale * norm(direction)`.
If `normalize = true` the direction is normalized first, i.e. the length becomes just `lengthscale`.

There is also the option to treat the second plot argument as the arrows endpoint with `argmode = :endpoint`.
In this case the directions are determined as `direction = endpoint - startpoint` and then follow the same principles.

### Scaling

Arrow markers are separated into 3 components, a tail, a shaft and a tip.
Each component comes with a length and width/radius (2D/3D) which determines its size.
In 2D the sizes are given in pixel units by default (dependent on `markerspace`).
In 3D they are given in relative units if `markerscale = automatic` (default) or data space units scaled by `markerscale` otherwise.
To fit arrows to the length determined by `directions`, `lengthscale` and `normalize`, the `shaftlength` varies between `minshaftlength` and `maxshaftlength` if it is not explicitly set.
Outside of this range or if it is explicitly set, all arrow lengths and widths/radii are scaled by a common factor instead.

### Shapes

The base shape of each component is given by the `tail`, `shaft` and `tip` attributes.
For arrows2d these can be anything compatible with `poly`, e.g. a 2D mesh, Polygon or Vector of points.
Each component should be defined in a 0..1 x -0.5..0.5 range, where +x is the direction of the arrow.
The shape can also be constructed by a callback function `f(length, width, metrics)` returning something poly-compatible.
It is given the final length and width of the component as well as the all the other final lengths and widths through metrics.
For arrows3d they should be a mesh or GeometryPrimitive defined in a -0.5..0.5 x -0.5..0.5 x 0..1 range.
Here +z is the direction of the arrow.
