# Cameras

A `Camera` is simply a viewport through which the Scene is visualized.  `Makie` offers 2D and 3D projections, and 2D plots can be projected in 3D!

To specify the camera you want to use for your Scene, you can set the `camera` attribute.  Currently, we offer four types of camera:

[`campixel!`](@ref)
[`cam2d!`](@ref)
`cam3d!`
`cam3d_cad!`

which will mutate the camera of the Scene into the specified type.

## Pixel Camera

The pixel camera ([`campixel!(scene)`](@ref)) projects the scene in pixel space, i.e. each integer step in the displayed data will correspond to one pixel. There are no controls for this camera. The clipping limits are set to `(-10_000, 10_000)`.

## 2D Camera

The 2D camera ([`cam2d!(scene)`](@ref)) uses an orthographic projection with a fixed rotation and aspect ratio. You can set the following attributes via keyword arguments in `cam2d!` or by accessing the camera struct `cam = cameracontrols(scene)`:

- `zoomspeed = 0.10f0` sets the speed of mouse wheel zooms.
- `zoombutton = nothing` sets an additional key that needs to be pressed in order to zoom. Defaults to no key.
- `panbutton = Mouse.right` sets the mouse button that needs to be pressed to translate the view.
- `selectionbutton = (Keyboard.space, Mouse.left)` sets a set of buttons that need to be pressed to perform rectangle zooms.

Note that this camera is not used by MakieLayout `Axis`. It is used, by default, for 2D `LScene`s and `Scene`s.

## 3D Camera

{{doc Camera3D}}

## General Remarks

To force a plot to be visualized in 3D, you can set the limits to have a nonzero \(z\)-axis interval, or ensure that a 3D camera type is used.
For example, you could pass the keyword argument `limits = Rect([0,0,0],[1,1,1])`, or `camera = cam3d!`.

To ensure that the camera's view is not modified, you can pass the attribute `raw = true`.

Often, when modifying the Scene, the camera can get "out of sync" with the Scene. To fix this, you can call the [`update_cam!`](@ref) function on the Scene.
