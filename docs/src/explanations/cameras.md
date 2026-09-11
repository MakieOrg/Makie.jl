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
- [`stage_cam!`](@ref): A [`StageCamera`](@ref), a 3D camera with photographic settings

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

### Stage Camera

The [`StageCamera`](@ref) ([`stage_cam!`](@ref)) is a 3D camera modelled on how a photographer works a
scene, one decision at a time:

- pick a subject and how much around it belongs in the shot: `lookat` and `stage_size`
- pick an angle: `azimuth` and `elevation`
- pick a perspective, and with it how much background comes along: `mm` (or `fov`)
- place the subject in the frame: `relative_offset`

A photographer picks a distance and a focal length, and those two together produce the first and third
item at once. This camera swaps the parameters around: you state the stage, a region of `stage_size`
diameter around `lookat` that is guaranteed to stay in frame, and the distance is derived from it and
the lens. So the third decision no longer disturbs the first.

The examples below all use the same scene, a cat standing in the Sponza atrium, and differ only in
camera settings.

```@figure stagecam backend=GLMakie
using FileIO
using LinearAlgebra: normalize, cross # `using LinearAlgebra` would clash with Makie's `rotate!`

sponza = load(assetpath("sponza/sponza.obj"), uvtype = Vec2f)
sponza[:material_names][4] = "sp_01_stub_baza" # seems to be incorrect in the file
catmesh = load(assetpath("cat.obj"))
catcolor = load(assetpath("diffusemap.png"))

LOOKAT = Point3d(0.91, 0.12, 0.65) # the cat's eye
AZIMUTH, ELEVATION = -8.9, -5
PANEL = (width = 360, height = 280)

function atrium!(lscene)
    building = mesh!(lscene, sponza)
    rotate!(building, Vec3f(1, 0, 0), pi / 2) # the model is y-up, Makie is z-up

    cat = mesh!(lscene, catmesh, color = catcolor)
    rotate!(cat, qrotation(Vec3f(0, 0, 1), deg2rad(100)) * qrotation(Vec3f(1, 0, 0), pi / 2))
    translate!(cat, 0, 0, 0.1)
    return lscene
end

new_panel(gridpos) = atrium!(LScene(gridpos, show_axis = false, scenekw = (; camera = stage_cam!)))

function photo_panel(gridpos; kwargs...)
    lscene = new_panel(gridpos)
    stage_cam!(
        lscene.scene;
        lookat = LOOKAT, stage_size = 1.15, azimuth = AZIMUTH, elevation = ELEVATION, mm = 50,
        kwargs...
    )
    return lscene
end

fig = Figure(size = (PANEL.width * 2, PANEL.height * 2))
photo_panel(fig[1, 1])
fig
```

`lookat` is on the cat's eye, and `stage_size` spans about twice the cat's height around it, so the
whole cat is in frame with the eye at the center.

`stage_size` is how much of the subject's immediate surroundings you want in view, measured in the
plane through `lookat`. That is usually the easiest thing to state about a shot: a person among trees
with the neighbouring trunks fully in frame is a stage of some 15 metres, a portrait of the same person
down to the shoulders is a stage of one metre.

On a real camera that framing comes out of distance and focal length together, and either one can
change it: stepping back widens the stage, and so does shortening the lens without moving. Neither
number says much on its own, whereas what you care about is how large the subject is and where it sits,
how much of its surroundings comes along, and how much background at what perspective. So the stage is
what you state here, and the distance follows from whichever lens is mounted. That is what leaves the
framing intact while you work on the lens.

The stage says nothing about the far background, which is the lens's business: a distant tree can fill
the frame at any stage size.

To see what the camera does, the next figures pair each shot with a view of the same scene from the
side, drawing the stage circle, the frame it is inscribed in and the rays through the frame's corners.
The camera itself is the small box:

```@figure stagecam backend=GLMakie
function frustum_panel(gridpos; stage_size = 1.15, mm = 50)
    lscene = new_panel(gridpos)

    # 36mm is the width of a full-frame sensor, so this is the distance at which
    # the stage fills the frame, exactly as `stage_cam!` computes it
    distance = stage_size * mm / 36
    direction = Vec3d(
        cosd(ELEVATION) * cosd(AZIMUTH), cosd(ELEVATION) * sind(AZIMUTH), sind(ELEVATION)
    )
    eye = LOOKAT + distance * direction

    # the frame lies in the plane through `lookat`, spanned by `u` (horizontal) and `v`
    u = normalize(cross(direction, Vec3d(0, 0, 1)))
    v = cross(direction, u)
    half = 0.5 * stage_size
    aspect = PANEL.width / PANEL.height
    corners = [LOOKAT + a * half * aspect * u + b * half * v for (a, b) in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    circle = [LOOKAT + half * (cos(t) * u + sin(t) * v) for t in range(0, 2pi, length = 65)]
    rays = [p for c in corners for p in (eye, eye + 8 * (c - eye))]

    # drawn twice, the second pass with `overdraw` so the hidden parts stay faintly visible
    for (alpha, overdraw) in ((1.0, false), (0.25, true))
        transparency = overdraw
        linesegments!(lscene, Point3f.(rays), color = (:dodgerblue, 0.8alpha), linewidth = 1; overdraw, transparency)
        lines!(lscene, Point3f.([corners; [corners[1]]]), color = (:dodgerblue, alpha), linewidth = 1.5; overdraw, transparency)
        lines!(lscene, Point3f.(circle), color = (:dodgerblue, alpha), linewidth = 2.5; overdraw, transparency)
        mesh!(
            lscene, Rect3f(Vec3f(eye) .- 0.09f0, Vec3f(0.18)), color = (:grey20, alpha),
            shading = NoShading; overdraw, transparency
        )
    end

    stage_cam!(
        lscene.scene; lookat = LOOKAT + 1.8 * direction, stage_size = 5,
        azimuth = AZIMUTH + 60, elevation = 30, mm = 24
    )
    return lscene
end

function comparison(labels, panels)
    fig = Figure(size = (3 * PANEL.width + 40, 2 * PANEL.height + 60))
    for (i, (label, settings)) in enumerate(zip(labels, panels))
        Label(fig[1, i], label, halign = :left, tellwidth = false)
        photo_panel(fig[2, i]; settings...)
        frustum_panel(fig[3, i]; settings...)
        colsize!(fig.layout, i, Fixed(PANEL.width))
    end
    rowsize!(fig.layout, 2, Fixed(PANEL.height))
    rowsize!(fig.layout, 3, Fixed(PANEL.height))
    rowgap!(fig.layout, 1, 4)
    rowgap!(fig.layout, 2, 8)
    return fig
end

stage_sizes = [0.29, 1.15, 2.43]
comparison(["stage_size = $s" for s in stage_sizes], [(; stage_size) for stage_size in stage_sizes])
```

The lens is the same in all three, so the frame keeps its shape while it grows, and the camera slides
back along the same axis to keep it filled.

Choosing a lens is the separate decision. Since the stage has to fit either way, `mm` (or `fov`) leaves
the cat and its immediate surroundings at the size they are and changes where the camera has to stand,
which is what decides how much of the distant atrium is compressed into the frame: a wide lens comes
close and pushes the arches away, a long lens backs off and pulls them in flat behind the cat. This is
the setting to reach for when the subject is framed the way you want but the background is not.

```@figure stagecam backend=GLMakie
focal_lengths = [24, 50, 100]
comparison(["mm = $mm" for mm in focal_lengths], [(; mm) for mm in focal_lengths])
```

Here the circle and the frame are identical in all three panels. What changes is the camera, which
moves from 0.8 to 3.2 units away while its frustum narrows from a splayed wedge to an almost parallel
tube. That is the whole difference between the three photographs above.

`azimuth` and `elevation` walk the camera around the stage. Looking down from a higher elevation puts
the cat in the middle of the frame with a lot of empty floor below it:

```@figure stagecam backend=GLMakie
fig = Figure(size = (PANEL.width * 2, PANEL.height * 2))
Label(fig[1, 1], "azimuth = 0.5, elevation = 14.2", halign = :left, tellwidth = false)
photo_panel(fig[2, 1], stage_size = 2.43, azimuth = 0.5, elevation = 14.2)
rowgap!(fig.layout, 4)
fig
```

Fixing that by moving `lookat` would defeat the purpose, since `lookat` is the subject and everything
rotates around it. Instead `relative_offset` pan and tilt the camera in
fractions of the distance from the frame center to its edge, which drops the cat to the bottom of the
frame and brings the arches in above it, without touching what the camera is pointed at:

```@figure stagecam backend=GLMakie
fig = Figure(size = (PANEL.width * 2, PANEL.height * 2))
Label(fig[1, 1], "relative_offset = (0, 0.555)", halign = :left, tellwidth = false)
photo_panel(fig[2, 1], stage_size = 2.43, azimuth = 0.5, elevation = 14.2, relative_offset = (0, 0.555))
rowgap!(fig.layout, 4)
fig
```

Because the fractions are relative to the frame, the same value composes the same way on any lens,
and `1/3` lands on a rule-of-thirds line whatever is mounted.

```@docs
StageCamera
stage_cam!
```

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
