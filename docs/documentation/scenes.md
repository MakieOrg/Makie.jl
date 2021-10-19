# Scenes

## What is a `Scene`?

`Scene`s are fundamental building blocks of Makie figures.
A Scene is like a container for `Plot`s and other `Scene`s.
`Scenes` have `Plot`s (including an `Axis` if `show_axis = true`) and `Subscenes` associated with them.
Every Scene also has a transformation, made up of _scale_, _translation_, and _rotation_.

!!! note
    Before the introduction of the `Figure` workflow, `Scene`s used to be the main container object which was returned from all plotting functions.
    Now, scenes are mostly an implementation detail for many users, unless they want to build custom solutions that go beyond what the default system offers.

A Scene's plots can be accessed via `scene.plots`.

A Scene's subscenes (also called children) can be accessed through `scene.children`.  This will return an Array of the `Scene`'s child scenes.  A child scene can be created by `childscene = Scene(parentscene)`.

Any `Scene` with an axis also has a `camera` associated with it; this can be accessed through `camera(scene)`, and its controls through `cameracontrols(scene)`.  More documentation about these is in the \myreflink{Cameras} section.

`Scene`'s also have configurable size/resolution. You can set the size in pixels by doing `Scene(resolution = (500, 500))`.

Any keyword argument given to the `Scene` will be propagated to its plots; therefore, you can set the palette or the colormap in the Scene itself.

## Subscenes

A subscene is no different than a normal Scene, except that it is linked to a "parent" Scene.  It inherits the transformations of the parent Scene, but can then be transformed independently of it.

## Scene Attributes

* `raw = false`: A raw scene will not trigger limit updates or center the view.
* `scene.clear = true`: Scenes are drawn parent first onto the same image. If `clear = true` for a (sub)scene it will clear the previously drawn things in its region to its `backgroundcolor`. Otherwise the plots in `scene` will be drawn on top and the backgroundcolor will be ignored. Note that this is not technically an attribute but just a field of `Scene`.
* `show_axis = true`: If `show_axis = false` the scene will not attempt to create axes. Note that this refers to scene axes, not MakieLayouts `Axis()` or `Axis3D()`.
* `backgroundcolor = :white`: Sets the background color of the scene. This only applies to scenes with `clear = true`.
* `update_limits = true`: Controls whether `scene.data_limits` gets updated when new plots are inserted.
* `SSAO = Attributes(bias = 0.025, blur=2, radius=0.5)`: Controls SSAO settings, see lighting documentation.
* `resolution = (800, 600)`: Sets the size of the created window if the scene is the root scene.
* `center = true`: Controls whether the scene gets recentered when new plots are added.


## Modifying A Scene

Makie offers mutation functions to scale, translate and rotate your Scenes on the fly.

{{doc translate!}}
{{doc rotate!}}
{{doc scale!}}

## Updating the Scene

When the Scene is changed, you may need to update several aspects of it.
Makie provides three main updating functions:

{{doc update_cam!}}

## Events

Scenes have several pre-created event "hooks" (through Observables) that you can handle.  These can be accessed through `scene.events`, which returns an \apilink{Events} struct.
