# Cameras

A `Camera` is simply a viewport through which the Scene is visualized.  `Makie` offers 2D and 3D projections, and 2D plots can be projected in 3D!

To specify the camera you want to use for your Scene, you can set the `camera` attribute.  Currently, we offer four types of camera:

[`cam2d!`](@ref)
[`cam3d!`](@ref)
[`campixel!`](@ref)
[`cam3d_cad!`](@ref)

which will mutate the camera of the Scene into the specified type.

## Controlling the camera

We offer several functions to control the camera programatically.  
You can rotate, translate, zoom and change the speed of the camera, as well as setting it to "look at" a certain point.

[`translate_cam!`](@ref)
[`rotate_cam!`](@ref)
[`zoom!`](@ref)


In addition, the camera can be configured by setting the fields of `cam = cameracontrols(scene)`:

- `pan_button`: The mouse button used for panning.
- `rotate_button`: The mouse button used for rotating the camera.
- `translationspeed`: This parameter allows to customize the panning speed.
- `rotationspeed`: This parameter allows to customize the camera rotation speed

The other fields control camera positioning, and the camera needs to be updated (with [`update_cam!`](@ref)) after changing these:

- `lookat`: The camera is directed at this point.
- `eyeposition`: The camera is at this point.
- `upvector`: The camera's "up" direction follows this vector (normalized internally).
- `fov`: The field of view of the camera (not used for zooming internally).

As an example, to set the rotation speed of the camera, simply execute `cam.rotationspeed[] = 0.05`.

## 3D Camera

To force a plot to be visualized in 3D, you can set the limits to have a nonzero \(z\)-axis interval, or ensure that a 3D camera type is used.
For example, you could pass the keyword argument `limits = Rect([0,0,0],[1,1,1])`, or `camera = cam3d!`.

You can use the camera given by [`campixel!`](@ref) (also called a pixel camera), to create a plot which looks like a 2D plot from the user perspective (it generates a subscene with an orthographic view, aligned to pixel space).
To ensure that the camera's view is not modified, you can pass the attribute `raw = true`.

## Updating the camera

Often, when modifying the Scene, the camera can get "out of sync" with the Scene.  To fix this, you can call the [`update_cam!`](@ref) function on the Scene.
