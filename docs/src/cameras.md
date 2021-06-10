# Cameras

A `Camera` is simply a viewport through which the Scene is visualized.  `Makie` offers 2D and 3D projections, and 2D plots can be projected in 3D!

To specify the camera you want to use for your Scene, you can set the `camera` attribute.  Currently, we offer four types of camera:

[`campixel!`](@ref)
[`cam2d!`](@ref)
[`cam3d!`](@ref)
[`cam3d_cad!`](@ref)

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

The 3D camera is (or can be) unrestricted in terms of rotations and translations. Both [`cam3d!(scene)`](@ref) and [`cam3d_cad!(scene)`](@ref) create this camera type. Unlike the 2D camera, settings and controls are stored in the `cam.attributes` field rather than in the struct directly, but can still be passed as keyword arguments. The general camera settings include

- `fov = 45f0` sets the "neutral" field of view, i.e. the fov corresponding to no zoom. This is irrelevant if the camera uses an orthographic projection. 
- `near = automatic` sets the value of the near clip. By default this will be chosen based on the scenes bounding box. The final value is in `cam.near`.
- `far = automatic` sets the value of the far clip. By default this will be chosen based on the scenes bounding box. The final value is in `cam.far`.
- `rotation_center = :lookat` sets the default center for camera rotations. Currently allows `:lookat` or `:eyeposition`.
- `projectiontype = Perspective` sets the type of the projection. Can be `Orthographic` or `Perspective`.
- `fixed_axis = false`: If true panning uses the (world/plot) z-axis instead of the camera up direction.
- `zoom_shift_lookat = true`: If true attempts to keep data under the cursor in view when zooming.
- `cad = false`: If true rotates the view around `lookat` when zooming off-center.

The camera view follows from the position of the camera `eyeposition`, the point which the camera focuses `lookat` and the up direction of the camera `upvector`. These can be accessed as `cam.eyeposition` etc and adjusted via `update_cam!(scene, cameracontrols(scene), eyeposition, lookat[, upvector = Vec3f0(0, 0, 1)])`. They can also be passed as keyword arguments when the camera is constructed.

The camera can be controlled by keyboard and mouse. The keyboard has the following available attributes

- `up_key   = Keyboard.left_shift` sets the key for translations towards the top of the screen.
- `down_key = Keyboard.left_control` sets the key for translations towards the bottom of the screen.
- `left_key  = Keyboard.a` sets the key for translations towards the left of the screen.
- `right_key = Keyboard.d` sets the key for translations towards the right of the screen.
- `forward_key  = Keyboard.w` sets the key for translations into the screen.
- `backward_key = Keyboard.s` sets the key for translations out of the screen.

- `zoom_in_key   = Keyboard.i` sets the key for zooming into the scene (enlarge, via fov).
- `zoom_out_key  = Keyboard.k` sets the key for zooming out of the scene (shrink, via fov).
- `stretch_view_key  = Keyboard.page_up` sets the key for moving `eyepostion` away from `lookat`.
- `contract_view_key = Keyboard.page_down` sets the key for moving `eyeposition` towards `lookat`.

- `pan_left_key  = Keyboard.j` sets the key for rotations around the screens vertical axis.
- `pan_right_key = Keyboard.l` sets the key for rotations around the screens vertical axis.
- `tilt_up_key   = Keyboard.r` sets the key for rotations around the screens horizontal axis.
- `tilt_down_key = Keyboard.f` sets the key for rotations around the screens horizontal axis.
- `roll_clockwise_key        = Keyboard.e` sets the key for rotations of the screen.
- `roll_counterclockwise_key = Keyboard.q` sets the key for rotations of the screen.

- `keyboard_rotationspeed = 1f0` sets the speed of keyboard based rotations.
- `keyboard_translationspeed = 0.5f0` sets the speed of keyboard based translations.
- `keyboard_zoomspeed = 1f0` sets the speed of keyboard based zooms.
- `update_rate = 1/30` sets the rate at which keyboard based camera updates are evaluated.

and mouse interactions are controlled by

- `translation_button   = Mouse.right` sets the mouse button for drag-translations. (up/down/left/right)
- `translation_modifier = nothing` sets additional keys that need to be held for mouse translations.
- `rotation_button    = Mouse.left` sets the mouse button for drag-rotations. (pan, tilt)
- `rotation_modifier  = nothing` sets additional keys that need to be held for mouse rotations.

- `mouse_rotationspeed = 1f0` sets the speed of mouse rotations.
- `mouse_translationspeed = 0.5f0` sets the speed of mouse translations.
- `mouse_zoomspeed = 1f0` sets the speed of mouse zooming (mousewheel).
- `circular_rotation = (true, true, true)` enables circular rotations for (fixed x, fixed y, fixed z) rotation axis. (This means drawing a circle with your mouse around the center of the scene will result in a continuous rotation.)

There are also a few generally applicable controls:

- `fix_x_key = Keyboard.x` sets the key for fixing translations and rotations to the (world/plot) x-axis.
- `fix_y_key = Keyboard.y` sets the key for fixing translations and rotations to the (world/plot) y-axis.
- `fix_z_key = Keyboard.z` sets the key for fixing translations and rotations to the (world/plot) z-axis.
- `reset = Keyboard.home` sets the key for fully resetting the camera. This equivalent to setting `lookat = Vec3f0(0)`, `upvector = Vec3f0(0, 0, 1)`, `eyeposition = Vec3f0(3)` and then calling `center!(scene)`.

You can also make adjustments to the camera position, rotation and zoom by calling relevant functions:

- `translate_cam!(scene, v)` will translate the camera by the given world/plot space vector `v`. 
- `rotate_cam!(scene, angles)` will rotate the camera around its axes with the corresponding angles. The first angle will rotate around the cameras "right" that is the screens horizontal axis, the second around the up vector/vertical axis or `Vec3f0(0, 0, +-1)` if `fixed_axis = true`, and the third will rotate around the view direction i.e. the axis out of the screen. The rotation respects the the current `rotation_center` of the camera. 
- `zoom!(scene, zoom_step)` will change the zoom level of the scene without translating or rotating the scene. `zoom_step` applies multiplicatively to `cam.zoom_mult` which is used as a multiplier to the fov (perspective projection) or width and height (orthographic projection).

## General Remarks

To force a plot to be visualized in 3D, you can set the limits to have a nonzero \(z\)-axis interval, or ensure that a 3D camera type is used.
For example, you could pass the keyword argument `limits = Rect([0,0,0],[1,1,1])`, or `camera = cam3d!`.

To ensure that the camera's view is not modified, you can pass the attribute `raw = true`.

Often, when modifying the Scene, the camera can get "out of sync" with the Scene. To fix this, you can call the [`update_cam!`](@ref) function on the Scene.
