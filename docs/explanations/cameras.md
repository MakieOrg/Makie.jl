# Cameras

A `Camera` is simply a viewport through which the Scene is visualized. `Makie` offers 2D and 3D projections, and 2D plots can be projected in 3D!

To specify the camera you want to use for your Scene, you can set the `camera` attribute. Currently, we offer the following cameras/constructors

\apilink{campixel!}
\apilink{cam_relative!}
\apilink{cam2d!}
\apilink{Camera3D}
\apilink{cam3d!}
\apilink{cam3d_cad!}

which will mutate the camera of the Scene into the specified type.

## Pixel Camera

The pixel camera (\apilink{campixel!(scene)}) projects the scene in pixel space, i.e. each integer step in the displayed data will correspond to one pixel. There are no controls for this camera. The clipping limits are set to `(-10_000, 10_000)`.

## Relative Camera

The relative camera (\apilink{cam_relative!(scene)}) projects the scene into a 0..1 by 0..1 space. There are no controls for this camera. The clipping limits are set to `(-10_000, 10_000)`.

## 2D Camera

The 2D camera (\apilink{cam2d!(scene)}) uses an orthographic projection with a fixed rotation and aspect ratio. You can set the following attributes via keyword arguments in `cam2d!` or by accessing the camera struct `cam = cameracontrols(scene)`:

- `zoomspeed = 0.10f0` sets the speed of mouse wheel zooms.
- `zoombutton = nothing` sets an additional key that needs to be pressed in order to zoom. Defaults to no key.
- `panbutton = Mouse.right` sets the mouse button that needs to be pressed to translate the view.
- `selectionbutton = (Keyboard.space, Mouse.left)` sets a set of buttons that need to be pressed to perform rectangle zooms.

Note that this camera is not used by `Axis`. It is used, by default, for 2D `LScene`s and `Scene`s.

## 3D Camera

{{doc Camera3D}}

`cam3d!` and `cam3d_cad!` but create a `Camera3D` with some specific options.

## Example - Visualizing the cameras view box

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
cc = Makie.Camera3D(scene.scene, projectiontype = Makie.Perspective, far = 3.0)

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

## General Remarks

To force a plot to be visualized in 3D, you can set the limits to have a nonzero \(z\)-axis interval, or ensure that a 3D camera type is used.
For example, you could pass the keyword argument `limits = Rect([0,0,0],[1,1,1])`, or `camera = cam3d!`.

Often, when modifying the Scene, the camera can get "out of sync" with the Scene. To fix this, you can call the \apilink{update_cam!} function on the Scene.

Buttons passed to the 2D and 3D camera are forwarded to `ispressed`. As such you can pass `false` to disable an interaction, `true` to ignore a modifier, any button, collection of buttons or even logical expressions of buttons. See the events documentation for more details.
