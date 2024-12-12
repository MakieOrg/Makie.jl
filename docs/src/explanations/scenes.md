# Scenes

## What is a `Scene`?

`Scene`s are fundamental building blocks of Makie figures.
A Scene is like a container for `Plot`s and other `Scene`s.
`Scenes` have `Plot`s and `Subscenes` associated with them.
Every Scene also has a transformation, made up of _scale_, _translation_, and _rotation_.

!!! note
    Before the introduction of the `Figure` workflow, `Scene`s used to be the main container object which was returned from all plotting functions.
    Now, scenes are mostly an implementation detail for many users, unless they want to build custom solutions that go beyond what the default system offers.

A Scene's plots can be accessed via `scene.plots`.

A Scene's subscenes (also called children) can be accessed through `scene.children`.  This will return an Array of the `Scene`'s child scenes.  A child scene can be created by `childscene = Scene(parentscene)`.

Any `Scene` with an axis also has a `camera` associated with it; this can be accessed through `camera(scene)`, and its controls through `cameracontrols(scene)`.  More documentation about these is in the [Cameras](@ref) section.

`Scene`s have a configurable size. You can set the size in device-independent pixels by doing `Scene(size = (500, 500))`. (More about sizes, resolutions and units in [Figure size and resolution](@ref) or [How to match figure size, font sizes and dpi](@ref))

Any keyword argument given to the `Scene` will be propagated to its plots; therefore, you can set the palette or the colormap in the Scene itself.

## Subscenes

A subscene is no different than a normal Scene, except that it is linked to a "parent" Scene.  It inherits the transformations of the parent Scene, but can then be transformed independently of it.

## Scene Attributes

* `scene.clear = true`: Scenes are drawn parent first onto the same image. If `clear = true` for a (sub)scene it will clear the previously drawn things in its region to its `backgroundcolor`. Otherwise the plots in `scene` will be drawn on top and the backgroundcolor will be ignored. Note that this is not technically an attribute but just a field of `Scene`.
* `ssao = SSAO(bias = 0.025, blur=2, radius=0.5)`: Controls SSAO settings, see lighting documentation.
* `size = (800, 600)`: Sets the size of the created window if the scene is the root scene.

## Modifying A Scene

Makie offers mutation functions to scale, translate and rotate your Scenes on the fly.

```@docs; canonical=false
translate!
rotate!
scale!
```

## Updating the Scene

When the Scene is changed, you may need to update several aspects of it.
Makie provides three main updating functions:

```@docs
update_cam!
```

## Events

Scenes have several pre-created event "hooks" (through Observables) that you can handle.  These can be accessed through `scene.events`, which returns an [`Events`](@ref) struct.
