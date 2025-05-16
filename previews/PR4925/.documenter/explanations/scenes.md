
# Scenes {#Scenes}

## What is a `Scene`? {#What-is-a-Scene?}

`Scene`s are fundamental building blocks of Makie figures. A Scene is like a container for `Plot`s and other `Scene`s. `Scenes` have `Plot`s and `Subscenes` associated with them. Every Scene also has a transformation, made up of _scale_, _translation_, and _rotation_.

::: tip Note

Before the introduction of the `Figure` workflow, `Scene`s used to be the main container object which was returned from all plotting functions. Now, scenes are mostly an implementation detail for many users, unless they want to build custom solutions that go beyond what the default system offers.

:::

A Scene&#39;s plots can be accessed via `scene.plots`.

A Scene&#39;s subscenes (also called children) can be accessed through `scene.children`.  This will return an Array of the `Scene`&#39;s child scenes.  A child scene can be created by `childscene = Scene(parentscene)`.

Any `Scene` with an axis also has a `camera` associated with it; this can be accessed through `camera(scene)`, and its controls through `cameracontrols(scene)`.  More documentation about these is in the [Cameras](/explanations/cameras#Cameras) section.

`Scene`s have a configurable size. You can set the size in device-independent pixels by doing `Scene(size = (500, 500))`. (More about sizes, resolutions and units in [Figure size and resolution](/explanations/figure#Figure-size-and-resolution) or [How to match figure size, font sizes and dpi](/how-to/match-figure-size-font-sizes-and-dpi#How-to-match-figure-size,-font-sizes-and-dpi))

Any keyword argument given to the `Scene` will be propagated to its plots; therefore, you can set the palette or the colormap in the Scene itself.

## Subscenes {#Subscenes}

A subscene is no different than a normal Scene, except that it is linked to a &quot;parent&quot; Scene.  It inherits the transformations of the parent Scene, but can then be transformed independently of it.

## Scene Attributes {#Scene-Attributes}
- `scene.clear = true`: Scenes are drawn parent first onto the same image. If `clear = true` for a (sub)scene it will clear the previously drawn things in its region to its `backgroundcolor`. Otherwise the plots in `scene` will be drawn on top and the backgroundcolor will be ignored. Note that this is not technically an attribute but just a field of `Scene`.
  
- `ssao = SSAO(bias = 0.025, blur=2, radius=0.5)`: Controls SSAO settings, see lighting documentation.
  
- `size = (800, 600)`: Sets the size of the created window if the scene is the root scene.
  

## Modifying A Scene {#Modifying-A-Scene}

Makie offers mutation functions to scale, translate and rotate your Scenes on the fly.
<details class='jldocstring custom-block' open>
<summary><a id='Makie.translate!-explanations-scenes' href='#Makie.translate!-explanations-scenes'><span class="jlbinding">Makie.translate!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
translate!(t::Transformable, xyz::VecTypes)
translate!(t::Transformable, xyz...)
```


Apply an absolute translation to the given `Transformable` (a Scene or Plot), translating it to `x, y, z`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/f5fbbfb4328fb1bb82ddf663ef4cba4b04da2f84/src/layouting/transformation.jl#L176-L181" target="_blank" rel="noreferrer">source</a></Badge>



```julia
translate!(Accum, t::Transformable, xyz...)
```


Translate the given `Transformable` (a Scene or Plot), relative to its current position.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/f5fbbfb4328fb1bb82ddf663ef4cba4b04da2f84/src/layouting/transformation.jl#L185-L189" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.rotate!-explanations-scenes' href='#Makie.rotate!-explanations-scenes'><span class="jlbinding">Makie.rotate!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
rotate!(Accum, t::Transformable, axis_rot...)
```


Apply a relative rotation to the transformable, by multiplying by the current rotation.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/f5fbbfb4328fb1bb82ddf663ef4cba4b04da2f84/src/layouting/transformation.jl#L146-L150" target="_blank" rel="noreferrer">source</a></Badge>



```julia
rotate!(t::Transformable, axis_rot::Quaternion)
rotate!(t::Transformable, axis_rot::Real)
rotate!(t::Transformable, axis_rot...)
```


Apply an absolute rotation to the transformable. Rotations are all internally converted to `Quaternion`s.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/f5fbbfb4328fb1bb82ddf663ef4cba4b04da2f84/src/layouting/transformation.jl#L153-L159" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.scale!-explanations-scenes' href='#Makie.scale!-explanations-scenes'><span class="jlbinding">Makie.scale!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
scale!([mode = Absolute], t::Transformable, xyz...)
scale!([mode = Absolute], t::Transformable, xyz::VecTypes)
```


Scale the given `t::Transformable` (a Scene or Plot) to the given arguments `xyz`. Any missing dimension will be scaled by 1. If `mode == Accum` the given scaling will be multiplied with the previous one.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/f5fbbfb4328fb1bb82ddf663ef4cba4b04da2f84/src/layouting/transformation.jl#L120-L127" target="_blank" rel="noreferrer">source</a></Badge>

</details>


## Updating the Scene {#Updating-the-Scene}

When the Scene is changed, you may need to update several aspects of it. Makie provides three main updating functions:
<details class='jldocstring custom-block' open>
<summary><a id='Makie.update_cam!' href='#Makie.update_cam!'><span class="jlbinding">Makie.update_cam!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
update_cam!(scene::SceneLike, area)
```


Updates the camera for the given `scene` to cover the given `area` in 2d.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/f5fbbfb4328fb1bb82ddf663ef4cba4b04da2f84/src/camera/camera2d.jl#L54-L58" target="_blank" rel="noreferrer">source</a></Badge>



```julia
update_cam!(scene::SceneLike)
```


Updates the camera for the given `scene` to cover the limits of the `Scene`. Useful when using the `Observable` pipeline.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/f5fbbfb4328fb1bb82ddf663ef4cba4b04da2f84/src/camera/camera2d.jl#L67-L72" target="_blank" rel="noreferrer">source</a></Badge>



```julia
update_cam!(scene, cam::Camera3D, ϕ, θ[, radius])
```


Set the camera position based on two angles `0 ≤ ϕ ≤ 2π` and `-pi/2 ≤ θ ≤ pi/2` and an optional radius around the current `cam.lookat[]`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/f5fbbfb4328fb1bb82ddf663ef4cba4b04da2f84/src/camera/camera3d.jl#L784-L789" target="_blank" rel="noreferrer">source</a></Badge>



```julia
update_cam!(scene::Scene, eyeposition, lookat, up = Vec3d(0, 0, 1))
```


Updates the camera&#39;s controls to point to the specified location.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/f5fbbfb4328fb1bb82ddf663ef4cba4b04da2f84/src/camera/old_camera3d.jl#L358-L362" target="_blank" rel="noreferrer">source</a></Badge>

</details>


## Events {#Events}

Scenes have several pre-created event &quot;hooks&quot; (through Observables) that you can handle.  These can be accessed through `scene.events`, which returns an [`Events`](/api#Makie.Events) struct.
