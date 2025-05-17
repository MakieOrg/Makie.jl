
# Cameras {#Cameras}

A `Camera` is simply a viewport through which the Scene is visualized. `Makie` offers 2D and 3D projections, and 2D plots can be projected in 3D!

To specify the camera you want to use for your Scene, you can set the `camera` attribute. Currently, we offer the following cameras/constructors

[`campixel!`](/api#Makie.campixel!-Tuple{Scene}) [`cam_relative!`](/api#Makie.cam_relative!-Tuple{Scene}) [`cam2d!`](/api#Makie.cam2d!-Tuple{Union{AbstractScene,%20MakieCore.ScenePlot}}) [`Camera3D`](/explanations/cameras#Makie.Camera3D) [`cam3d!`](/api#Makie.cam3d!-Tuple{Any}) [`cam3d_cad!`](/api#Makie.cam3d_cad!-Tuple{Any})

which will mutate the camera of the Scene into the specified type.

## Pixel Camera {#Pixel-Camera}

The pixel camera ([`campixel!`](/api#Makie.campixel!-Tuple{Scene})) projects the scene in pixel space, i.e. each integer step in the displayed data will correspond to one pixel. There are no controls for this camera. The clipping limits are set to `(-10_000, 10_000)`.

## Relative Camera {#Relative-Camera}

The relative camera ([`cam_relative!`](/api#Makie.cam_relative!-Tuple{Scene})) projects the scene into a 0..1 by 0..1 space. There are no controls for this camera. The clipping limits are set to `(-10_000, 10_000)`.

## 2D Camera {#2D-Camera}

The 2D camera ([`cam2d!`](/api#Makie.cam2d!-Tuple{Union{AbstractScene,%20MakieCore.ScenePlot}})) uses an orthographic projection with a fixed rotation and aspect ratio. You can set the following attributes via keyword arguments in `cam2d!` or by accessing the camera struct `cam = cameracontrols(scene)`:
- `zoomspeed = 0.10f0` sets the speed of mouse wheel zooms.
  
- `zoombutton = nothing` sets an additional key that needs to be pressed in order to zoom. Defaults to no key.
  
- `panbutton = Mouse.right` sets the mouse button that needs to be pressed to translate the view.
  
- `selectionbutton = (Keyboard.space, Mouse.left)` sets a set of buttons that need to be pressed to perform rectangle zooms.
  

Note that this camera is not used by `Axis`. It is used, by default, for 2D `LScene`s and `Scene`s.

## 3D Camera {#3D-Camera}
<details class='jldocstring custom-block' open>
<summary><a id='Makie.Camera3D' href='#Makie.Camera3D'><span class="jlbinding">Makie.Camera3D</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Camera3D(scene[; kwargs...])
```


Sets up a 3D camera with mouse and keyboard controls.

The behavior of the camera can be adjusted via keyword arguments or the fields `settings` and `controls`.

**Settings**

Settings include anything that isn&#39;t a mouse or keyboard button.
- `projectiontype = Perspective` sets the type of the projection. Can be `Orthographic` or `Perspective`.
  
- `rotation_center = :lookat` sets the default center for camera rotations. Currently allows `:lookat` or `:eyeposition`.
  
- `fixed_axis = true`: If true panning uses the (world/plot) z-axis instead of the camera up direction.
  
- `zoom_shift_lookat = true`: If true keeps the data under the cursor when zooming.
  
- `cad = false`: If true rotates the view around `lookat` when zooming off-center.
  
- `clipping_mode = :adaptive`: Controls how `near` and `far` get processed. Options:
  - `:static` passes `near` and `far` as is
    
  - `:adaptive` scales `near` by `norm(eyeposition - lookat)` and passes `far` as is
    
  - `:view_relative` scales `near` and `far` by `norm(eyeposition - lookat)`
    
  - `:bbox_relative` scales `near` and `far` to the scene bounding box as passed to the camera with `update_cam!(..., bbox)`. (More specifically `far = 1` is scaled to the furthest point of a bounding sphere and `near` is generally overwritten to be the closest point.)
    
  
- `center = true`: Controls whether the camera placement gets reset when calling `center!(scene)`, which is called when a new plot is added.
  
- `keyboard_rotationspeed = 1.0` sets the speed of keyboard based rotations.
  
- `keyboard_translationspeed = 0.5` sets the speed of keyboard based translations.
  
- `keyboard_zoomspeed = 1.0` sets the speed of keyboard based zooms.
  
- `mouse_rotationspeed = 1.0` sets the speed of mouse rotations.
  
- `mouse_translationspeed = 0.5` sets the speed of mouse translations.
  
- `mouse_zoomspeed = 1.0` sets the speed of mouse zooming (mousewheel).
  
- `circular_rotation = (false, false, false)` enables circular rotations for (fixed x, fixed y, fixed z) rotation axis. (This means drawing a circle with your mouse around the center of the scene will result in a continuous rotation.)
  

**Controls**

Controls include any kind of hotkey setting.
- `up_key   = Keyboard.r` sets the key for translations towards the top of the screen.
  
- `down_key = Keyboard.f` sets the key for translations towards the bottom of the screen.
  
- `left_key  = Keyboard.a` sets the key for translations towards the left of the screen.
  
- `right_key = Keyboard.d` sets the key for translations towards the right of the screen.
  
- `forward_key  = Keyboard.w` sets the key for translations into the screen.
  
- `backward_key = Keyboard.s` sets the key for translations out of the screen.
  
- `zoom_in_key   = Keyboard.u` sets the key for zooming into the scene (translate eyeposition towards lookat).
  
- `zoom_out_key  = Keyboard.o` sets the key for zooming out of the scene (translate eyeposition away from lookat).
  
- `increase_fov_key = Keyboard.b` sets the key for increasing the fov.
  
- `decrease_fov_key = Keyboard.n` sets the key for decreasing the fov.
  
- `pan_left_key  = Keyboard.j` sets the key for rotations around the screens vertical axis.
  
- `pan_right_key = Keyboard.l` sets the key for rotations around the screens vertical axis.
  
- `tilt_up_key   = Keyboard.i` sets the key for rotations around the screens horizontal axis.
  
- `tilt_down_key = Keyboard.k` sets the key for rotations around the screens horizontal axis.
  
- `roll_clockwise_key        = Keyboard.e` sets the key for rotations of the screen.
  
- `roll_counterclockwise_key = Keyboard.q` sets the key for rotations of the screen.
  
- `fix_x_key = Keyboard.x` sets the key for fixing translations and rotations to the (world/plot) x-axis.
  
- `fix_y_key = Keyboard.y` sets the key for fixing translations and rotations to the (world/plot) y-axis.
  
- `fix_z_key = Keyboard.z` sets the key for fixing translations and rotations to the (world/plot) z-axis.
  
- `reset = Keyboard.left_control & Mouse.left` sets the key for resetting the camera. This equivalent to calling `center!(scene)`.
  
- `reposition_button = Keyboard.left_alt & Mouse.left` sets the key for focusing the camera on a plot object.
  
- `translation_button = Mouse.right` sets the mouse button for drag-translations. (up/down/left/right)
  
- `scroll_mod = true` sets an additional modifier button for scroll-based zoom. (true being neutral)
  
- `rotation_button = Mouse.left` sets the mouse button for drag-rotations. (pan, tilt)
  

**Other kwargs**

Some keyword arguments are used to initialize fields. These include
- `eyeposition = Vec3d(3)`: The position of the camera.
  
- `lookat = Vec3d(0)`: The point the camera is focused on.
  
- `upvector = Vec3d(0, 0, 1)`: The world direction corresponding to the up direction of the screen.
  
- `fov = 45.0` is the field of view. This is irrelevant if the camera uses an orthographic projection.
  
- `near = automatic` sets the position of the near clip plane. Anything between the camera and the near clip plane is hidden. Must be greater 0. Usage depends on `clipping_mode`.
  
- `far = automatic` sets the position of the far clip plane. Anything further away than the far clip plane is hidden. Usage depends on `clipping_mode`. Defaults to `1` for `clipping_mode = :bbox_relative`, `2` for `:view_relative` or a value derived from limits for `:static`.
  

Note that updating these observables in an active camera requires a call to `update_cam(scene)` for them to be applied. For updating `eyeposition`, `lookat` and/or upvector `update_cam!(scene, eyeposition, lookat, upvector = Vec3d(0,0,1))` is preferred.

The camera position and orientation can also be adjusted via the functions
- `translate_cam!(scene, v)` will translate the camera by the given vector `v`.
  
- `rotate_cam!(scene, angles)` will rotate the camera around its axes with the corresponding angles. The first angle will rotate around the cameras &quot;right&quot; that is the screens horizontal axis, the second around the up vector/vertical axis or `Vec3d(0, 0, +-1)` if `fixed_axis = true`, and the third will rotate around the view direction i.e. the axis out of the screen. The rotation respects the current `rotation_center` of the camera.
  
- `zoom!(scene, zoom_step)` will change the zoom level of the scene without translating or rotating the scene. `zoom_step` applies multiplicatively to `cam.zoom_mult` which is used as a multiplier to the fov (perspective projection) or width and height (orthographic projection).
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/c1ff276792827f16c26b5ad51ea371f8a3759971/src/camera/camera3d.jl#L25-L113" target="_blank" rel="noreferrer">source</a></Badge>

</details>


`cam3d!` and `cam3d_cad!` but create a `Camera3D` with some specific options.

## Example - Visualizing the cameras view box {#Example-Visualizing-the-cameras-view-box}

```julia
using GeometryBasics, LinearAlgebra

function frustum_snapshot(cam)
    r = Rect3f(Point3f(-1, -1, -1), Vec3f(2, 2, 2))
    rect_ps = coordinates(r) .|> Point3f
    insert!(rect_ps, 13, Point3f(1, -1, 1)) # fix bad line

    inv_pv = inv(cam.projectionview[])
    return map(rect_ps) do p
        p = inv_pv * to_ndim(Point4f, p, 1)
        return p[Vec(1,2,3)] / p[4]
    end
end


ex = Point3f(1,0,0)
ey = Point3f(0,1,0)
ez = Point3f(0,0,1)

fig = Figure()
scene = LScene(fig[1, 1])
cc = Makie.Camera3D(scene.scene, projectiontype = Makie.Perspective)

linesegments!(scene, Rect3f(Point3f(-1), Vec3f(2)), color = :black)
linesegments!(scene,
    [-ex, ex, -ey, ey, -ez, ez],
    color = [:red, :red, :green, :green, :blue, :blue]
)
center!(scene.scene)

cam = scene.scene.camera
eyeposition = cc.eyeposition
lookat = cc.lookat
frustum = map(pv -> frustum_snapshot(cam), cam.projectionview)

scene = LScene(fig[1, 2])
_cc = Makie.Camera3D(scene.scene, projectiontype = Makie.Orthographic)
lines!(scene, frustum, color = :blue, linestyle = :dot)
scatter!(scene, eyeposition, color = :black)
scatter!(scene, lookat, color = :black)

linesegments!(scene,
    [-ex, ex, -ey, ey, -ez, ez],
    color = [:red, :red, :green, :green, :blue, :blue]
)
linesegments!(scene, Rect3f(Point3f(-1), Vec3f(2)), color = :black)

fig
```


## General Remarks {#General-Remarks}

To force a plot to be visualized in 3D, you can set the limits to have a nonzero (z)-axis interval, or ensure that a 3D camera type is used. For example, you could pass the keyword argument `limits = Rect([0,0,0],[1,1,1])`, or `camera = cam3d!`.

Often, when modifying the Scene, the camera can get &quot;out of sync&quot; with the Scene. To fix this, you can call the [`update_cam!`](/explanations/scenes#Makie.update_cam!) function on the Scene.

Buttons passed to the 2D and 3D camera are forwarded to `ispressed`. As such you can pass `false` to disable an interaction, `true` to ignore a modifier, any button, collection of buttons or even logical expressions of buttons. See the events documentation for more details.
