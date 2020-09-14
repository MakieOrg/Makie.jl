# Scenes

## What is a `Scene`?

A `Scene` is basically a container for `Plot`s and other `Scene`s.  `Scenes` have `Plot`s (including an `Axis` if `show_axis = true`) and `Subscenes` associated with them.  Every Scene has a transformation, made up of _scale_, _translation_, and _rotation_.

Plots associated with a Scene can be accessed through `scene.plots`, which returns an Array of the plots associated with the `Scene`.  Note that if `scene` has no plots (if it was created by layouting, or is an empty scene), then `scene.plots` will be a _0-element array_!

If a scene is not explicitly declared prior to one of the `plot!` commands being called, a `Scene` will be created by default as follows:  `lines(args...) = lines!(Scene(), args...)`.

In this example, `lines` becomes the parent of all of the following `plot!` commands since it was called prior to a `Scene` being explicitly created.

A Scene's subscenes (also called children) can be accessed through `scene.children`.  This will return an Array of the `Scene`'s child scenes.  A child scene can be created by `childscene = Scene(parentscene)`.

Any `Scene` with an axis also has a `camera` associated with it; this can be accessed through `scene.camera`, and its controls through `scene.camera.cameracontrols`.  More documentation about these is in the [Cameras](@ref) section.

`Scene`'s also have configurable size/resolution. You can set the size in pixels by doing `Scene(resolution = (500, 500))`.

Any keyword argument given to the `Scene` will be propagated to its plots; therefore, you can set the palette or the colormap in the Scene itself.

## Subscenes

A subscene is no different than a normal Scene, except that it is linked to a "parent" Scene.  It inherits the transformations of the parent Scene, but can then be transformed independently of it.

<!--TODO add universe example here-->

## Current Scene

Knowing what Scene you are working with at any given moment is paramount as you work with more complex Makie implementations containing multiple Scenes. You can check your current scene by doing `AbstractPlotting.current_scene()` which will return the current active scene (the last scene that got created). 

## Modifying the Scene

Makie offers mutation functions to scale, translate and rotate your Scenes on the fly.

```@docs
translate!
rotate!
scale!
```

## Updating the Scene

When the Scene is changed, you may need to update several aspects of it.  
Makie provides three main updating functions:

```@docs
update!
update_limits!
update_cam!
```

In general, `update!` is to be used to keep data in sync, and `update_cam!` and `update_limits!` update the camera and limits respectively (to show all the data).

## Events

Scenes have several pre-created event "hooks" (through Observables) that you can handle.  These can be accessed through `scene.events`, which returns an `Events` struct:
```@docs
Events
```
