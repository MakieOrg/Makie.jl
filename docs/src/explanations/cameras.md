# Cameras

Generally speaking, the camera controls the range of coordinates that are shown and from what perspective they are shown.
For example, a 2D camera will give us a 2D perspective, meaning one where x extends right, y extends up and z extend towards the viewer.
The range of x and y values shown on the screen is also controlled by the camera.

## Overview

The term "camera" in Makie can be quite confusing as there are multiple things controlling, processing and storing camera related objects.

Before `Block`s like `Axis` were introduced, scenes were the main building block users interacted with.
Every Block still relies on them internally, and `LScene` specifically is just a light wrapper around `Scene`.
Up until Makie 0.24 every scene contained two fields related to cameras - `camera(scene)` and `cameracontrols(scene)`.
The `camera(scene)::Camera` stores camera matrices like `projectionview`.
Over time it has grown to also include `eyeposition`, `view_direction` and `upvector`, which describe the orientation and placement of the camera.
The `cameracontrols(scene) <: AbstractCamera` are, as the name implies, an object that controls the camera.
They generate the matrices stored in `camera(scene)` which means they are responsible for the range of visible coordinates and the perspective from which they are shown.
They also process user input like mouse drags if that has an effect on the camera, and they may include settings.

`Block`s have their own interaction system, which is also used to control the camera.
This effectively replaces `cameracontrols(scene)`.
For example, if you check `cameracontrols(ax.scene)` for `Axis` and `PolarAxis` you will find an `EmptyCamera`.
`LScene` still uses `cameracontrols(scene)` as it is just a wrapper around `Scene`.

Makie 0.24 brought in another layer with the scenes `ComputeGraph` in `scene.compute`.
Currently the compute graph is fed by `camera(scene)` to (lazily) calculate all the projection matrices needed to resolve the `space` and `markerspace` attributes.
It is effectively now the final output of the camera pipeline.

## Camera Controls

The `cameracontrols(scene)` control how plot data is shown in `Scene` and `LScene`.
They determine 2D vs 3D projections, the range of shown coordinates, the perspective and how these things react to user interaction.

Currently, we offer the following camera controllers/constructors

- [`campixel!`](@ref): A 2D camera using pixel coordinates
- [`cam_relative!`](@ref): A 2D camera using relative (0..1) coordinates
- [`cam2d!`](@ref): A 2D camera using dynamic coordinate ranges
- [`Camera3D`](@ref): A general, highly adjustable 3D camera
- [`cam3d!`](@ref): A `Camera3D` with default settings
- [`cam3d_cad!`](@ref): A `Camera3D` with CAD-like settings

To specify the camera controller you can set the `camera` attribute in a `Scene`.

```julia
Scene(..., camera = cam3d!)
LScene(..., scenekw = (camera = cam3d!, ))
```

You can replace and existing camera in a scene:

```julia
scene = Scene(...)
cam3d!(scene)

ax = LScene(...)
cam3d!(ax.scene)
```

### Pixel Camera

The pixel camera ([`campixel!`](@ref)) projects the scene in pixel space, i.e. each integer step in the displayed data will correspond to one pixel. There are no controls for this camera.
The z clipping limits are set to `(-10_000, 10_000)`.

### Relative Camera

The relative camera ([`cam_relative!`](@ref)) projects the scene into a 0..1 by 0..1 space. There are no controls for this camera.
The z clipping limits are set to `(-10_000, 10_000)`.

### 2D Camera

The 2D camera ([`cam2d!`](@ref)) uses an orthographic projection with a fixed rotation and aspect ratio. You can set the following attributes via keyword arguments in `cam2d!` or by accessing the camera struct `cam = cameracontrols(scene)`:

- `zoomspeed = 0.10f0` sets the speed of mouse wheel zooms.
- `zoombutton = nothing` sets an additional key that needs to be pressed in order to zoom. Defaults to no key.
- `panbutton = Mouse.right` sets the mouse button that needs to be pressed to translate the view.
- `selectionbutton = (Keyboard.space, Mouse.left)` sets a set of buttons that need to be pressed to perform rectangle zooms.

The z clipping limits are set to `(-10_000, 10_000)`.

!!! warning
    This camera is not used by `Axis`. It is used, by default, for 2D `LScene`s and `Scene`s.

### 3D Camera

`Camera3D` is a generalized 3D camera with a large number of options.
[`cam3d!`](@ref) and [`cam3d_cad!`](@ref) are specialized versions.
The former is the default camera for 3D scenes.
The latter is a camera that tries to mimic CAD-style cameras.

```@docs
Camera3D
```

!!! warning
    This camera is not used by `Axis3`. It is used, by default, for 3D `LScene`s and `Scene`s.

## Camera and Projections

Sometimes you may need to interact with camera matrices to project data into a different space.
As of Makie 0.24 you can get all the relevant matrices for this from `scene.compute` using the helper functions:

- `Makie.get_projectionview(scene, space)`
- `Makie.get_projection(scene, space)`
- `Makie.get_view(scene, space)`
- `Makie.get_preprojection(scene, space, markerspace)`
- `Makie.get_space_to_space_matrix(scene, input_space, output_space)`


## Example - Visualizing the camera's view box

```@figure backend=GLMakie
using GeometryBasics, LinearAlgebra

function frustum_snapshot(cam)
    r = Rect3f(-1, -1, -1, 2, 2, 2)
    rect_ps = Makie.convert_arguments(Lines, r)[1]
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

# Set up Scene shown by a camera
scene = LScene(fig[1, 1])
cc = Makie.Camera3D(scene.scene, projectiontype = Makie.Perspective, center = false)

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

# Set up scene visualizing the cameras view
scene = LScene(fig[1, 2])
_cc = Makie.Camera3D(scene.scene, projectiontype = Makie.Orthographic, center = false)
lines!(scene, frustum, color = :blue, linestyle = :dot)
scatter!(scene, eyeposition, color = :black)
scatter!(scene, lookat, color = :black)

linesegments!(scene,
    [-ex, ex, -ey, ey, -ez, ez],
    color = [:red, :red, :green, :green, :blue, :blue]
)
linesegments!(scene, Rect3f(Point3f(-1), Vec3f(2)), color = :black)

# Tweak initial camera position
update_cam!(scene.scene, Vec3f(4.5, 2.5, 3.5), Vec3f(0))
update_cam!(scene.scene, Vec3f(6, 8, 5), Vec3f(0))

fig
```

## General Remarks

Buttons passed to the 2D and 3D camera are forwarded to `ispressed`. As such you can pass `false` to disable an interaction, `true` to ignore a modifier, any button, collection of buttons or even logical expressions of buttons. See the events documentation for more details.
