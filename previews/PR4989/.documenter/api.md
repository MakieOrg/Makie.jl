
# API {#API}


<details class='jldocstring custom-block' open>
<summary><a id='Makie.ABLines' href='#Makie.ABLines'><span class="jlbinding">Makie.ABLines</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`ABLines` is the plot type associated with plotting function `ablines`. Check the docstring for `ablines` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Absolute' href='#Makie.Absolute'><span class="jlbinding">Makie.Absolute</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Absolute
```


Force transformation to be absolute, not relative to the current state. This is the default setting.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/layouting/transformation.jl#L99-L104" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Accum' href='#Makie.Accum'><span class="jlbinding">Makie.Accum</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Accum
```


Force transformation to be relative to the current state, not absolute.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/layouting/transformation.jl#L92-L96" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.AmbientLight' href='#Makie.AmbientLight'><span class="jlbinding">Makie.AmbientLight</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
AmbientLight(color) <: AbstractLight
```


A simple ambient light that uniformly lights every object based on its light color.

Availability:
- All backends with `shading = FastShading` or `MultiLightShading`
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/lighting.jl#L21-L28" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Annotations' href='#Makie.Annotations'><span class="jlbinding">Makie.Annotations</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`Annotations` is the plot type associated with plotting function `annotations`. Check the docstring for `annotations` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Arc' href='#Makie.Arc'><span class="jlbinding">Makie.Arc</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`Arc` is the plot type associated with plotting function `arc`. Check the docstring for `arc` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Axis' href='#Makie.Axis'><span class="jlbinding">Makie.Axis</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



**`Makie.Axis <: Block`**

A 2D axis which can be plotted into.

**Constructors**

```julia
Axis(fig_or_scene; palette = nothing, kwargs...)
```


**Attributes**

(type `?Makie.Axis.x` in the REPL for more information about attribute `x`)

`alignmode`, `aspect`, `autolimitaspect`, `backgroundcolor`, `bottomspinecolor`, `bottomspinevisible`, `dim1_conversion`, `dim2_conversion`, `flip_ylabel`, `halign`, `height`, `leftspinecolor`, `leftspinevisible`, `limits`, `panbutton`, `rightspinecolor`, `rightspinevisible`, `spinewidth`, `subtitle`, `subtitlecolor`, `subtitlefont`, `subtitlegap`, `subtitlelineheight`, `subtitlesize`, `subtitlevisible`, `tellheight`, `tellwidth`, `title`, `titlealign`, `titlecolor`, `titlefont`, `titlegap`, `titlelineheight`, `titlesize`, `titlevisible`, `topspinecolor`, `topspinevisible`, `valign`, `width`, `xautolimitmargin`, `xaxisposition`, `xgridcolor`, `xgridstyle`, `xgridvisible`, `xgridwidth`, `xlabel`, `xlabelcolor`, `xlabelfont`, `xlabelpadding`, `xlabelrotation`, `xlabelsize`, `xlabelvisible`, `xminorgridcolor`, `xminorgridstyle`, `xminorgridvisible`, `xminorgridwidth`, `xminortickalign`, `xminortickcolor`, `xminorticks`, `xminorticksize`, `xminorticksvisible`, `xminortickwidth`, `xpankey`, `xpanlock`, `xrectzoom`, `xreversed`, `xscale`, `xtickalign`, `xtickcolor`, `xtickformat`, `xticklabelalign`, `xticklabelcolor`, `xticklabelfont`, `xticklabelpad`, `xticklabelrotation`, `xticklabelsize`, `xticklabelspace`, `xticklabelsvisible`, `xticks`, `xticksize`, `xticksmirrored`, `xticksvisible`, `xtickwidth`, `xtrimspine`, `xzoomkey`, `xzoomlock`, `yautolimitmargin`, `yaxisposition`, `ygridcolor`, `ygridstyle`, `ygridvisible`, `ygridwidth`, `ylabel`, `ylabelcolor`, `ylabelfont`, `ylabelpadding`, `ylabelrotation`, `ylabelsize`, `ylabelvisible`, `yminorgridcolor`, `yminorgridstyle`, `yminorgridvisible`, `yminorgridwidth`, `yminortickalign`, `yminortickcolor`, `yminorticks`, `yminorticksize`, `yminorticksvisible`, `yminortickwidth`, `ypankey`, `ypanlock`, `yrectzoom`, `yreversed`, `yscale`, `ytickalign`, `ytickcolor`, `ytickformat`, `yticklabelalign`, `yticklabelcolor`, `yticklabelfont`, `yticklabelpad`, `yticklabelrotation`, `yticklabelsize`, `yticklabelspace`, `yticklabelsvisible`, `yticks`, `yticksize`, `yticksmirrored`, `yticksvisible`, `ytickwidth`, `ytrimspine`, `yzoomkey`, `yzoomlock`, `zoombutton`


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks.jl#L118-L135" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Axis3' href='#Makie.Axis3'><span class="jlbinding">Makie.Axis3</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



**`Makie.Axis3 <: Block`**

No docstring defined.

**Attributes**

(type `?Makie.Axis3.x` in the REPL for more information about attribute `x`)

`alignmode`, `aspect`, `axis_translation_mod`, `azimuth`, `backgroundcolor`, `clip`, `clip_decorations`, `cursorfocuskey`, `dim1_conversion`, `dim2_conversion`, `dim3_conversion`, `elevation`, `front_spines`, `halign`, `height`, `limits`, `near`, `perspectiveness`, `protrusions`, `targetlimits`, `tellheight`, `tellwidth`, `title`, `titlealign`, `titlecolor`, `titlefont`, `titlegap`, `titlesize`, `titlevisible`, `valign`, `viewmode`, `width`, `xautolimitmargin`, `xgridcolor`, `xgridvisible`, `xgridwidth`, `xlabel`, `xlabelalign`, `xlabelcolor`, `xlabelfont`, `xlabeloffset`, `xlabelrotation`, `xlabelsize`, `xlabelvisible`, `xreversed`, `xspinecolor_1`, `xspinecolor_2`, `xspinecolor_3`, `xspinecolor_4`, `xspinesvisible`, `xspinewidth`, `xtickcolor`, `xtickformat`, `xticklabelcolor`, `xticklabelfont`, `xticklabelpad`, `xticklabelsize`, `xticklabelsvisible`, `xticks`, `xticksize`, `xticksvisible`, `xtickwidth`, `xtranslationkey`, `xtranslationlock`, `xypanelcolor`, `xypanelvisible`, `xzoomkey`, `xzoomlock`, `xzpanelcolor`, `xzpanelvisible`, `yautolimitmargin`, `ygridcolor`, `ygridvisible`, `ygridwidth`, `ylabel`, `ylabelalign`, `ylabelcolor`, `ylabelfont`, `ylabeloffset`, `ylabelrotation`, `ylabelsize`, `ylabelvisible`, `yreversed`, `yspinecolor_1`, `yspinecolor_2`, `yspinecolor_3`, `yspinecolor_4`, `yspinesvisible`, `yspinewidth`, `ytickcolor`, `ytickformat`, `yticklabelcolor`, `yticklabelfont`, `yticklabelpad`, `yticklabelsize`, `yticklabelsvisible`, `yticks`, `yticksize`, `yticksvisible`, `ytickwidth`, `ytranslationkey`, `ytranslationlock`, `yzoomkey`, `yzoomlock`, `yzpanelcolor`, `yzpanelvisible`, `zautolimitmargin`, `zgridcolor`, `zgridvisible`, `zgridwidth`, `zlabel`, `zlabelalign`, `zlabelcolor`, `zlabelfont`, `zlabeloffset`, `zlabelrotation`, `zlabelsize`, `zlabelvisible`, `zoommode`, `zreversed`, `zspinecolor_1`, `zspinecolor_2`, `zspinecolor_3`, `zspinecolor_4`, `zspinesvisible`, `zspinewidth`, `ztickcolor`, `ztickformat`, `zticklabelcolor`, `zticklabelfont`, `zticklabelpad`, `zticklabelsize`, `zticklabelsvisible`, `zticks`, `zticksize`, `zticksvisible`, `ztickwidth`, `ztranslationkey`, `ztranslationlock`, `zzoomkey`, `zzoomlock`


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks.jl#L118-L129" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Band' href='#Makie.Band'><span class="jlbinding">Makie.Band</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`Band` is the plot type associated with plotting function `band`. Check the docstring for `band` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.BarPlot' href='#Makie.BarPlot'><span class="jlbinding">Makie.BarPlot</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`BarPlot` is the plot type associated with plotting function `barplot`. Check the docstring for `barplot` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.BezierPath' href='#Makie.BezierPath'><span class="jlbinding">Makie.BezierPath</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
BezierPath(commands::Vector)
```


Construct a `BezierPath` with a vector of path commands. The available path commands are
- `MoveTo`
  
- `LineTo`
  
- `CurveTo`
  
- `EllipticalArc`
  
- `ClosePath`
  

A `BezierPath` can be used in certain places in Makie as an alternative to a polygon or a collection of lines, for example as an input to `poly` or `lines`, or as a `marker` for `scatter`.

The benefit of using a `BezierPath` is that curves do not need to be converted into a vector of vertices by the user. CairoMakie can use the path commands directly when it writes vector graphics which is more efficient and uses less space than approximating them visually using line segments.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/bezier.jl#L165-L184" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.BezierPath-Tuple{AbstractString}' href='#Makie.BezierPath-Tuple{AbstractString}'><span class="jlbinding">Makie.BezierPath</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
BezierPath(svg::AbstractString; fit = false, bbox = nothing, flipy = false, flipx = false, keep_aspect = true)
```


Construct a `BezierPath` using a string of [SVG path commands](https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/d#path_commands). The commands will be parsed first into `MoveTo`, `LineTo`, `CurveTo`, `EllipticalArc` and `ClosePath` objects which are then passed to the `BezierPath` constructor.

If `fit === true`, the path will be scaled to fit into a square of width 1 centered on the origin. If, additionally, `bbox` is set to some `Rect`, the path will be fit into this rectangle instead. If you want to use a path as a scatter marker, it is usually good to fit it so that it&#39;s centered and of a comparable size relative to other scatter markers.

If `flipy === true` or `flipx === true`, the respective dimensions of the path will be flipped. Makie uses a coordinate system where y=0 is at the bottom and y increases upwards while in SVG, y=0 is at the top and y increases downwards, so for most SVG paths `flipy = true` will be needed.

If `keep_aspect === true`, the path will be fit into the bounding box such that its longer dimension fits and the other one is scaled to retain the original aspect ratio. If you set `keep_aspect = false`, the new boundingbox of the path will be the one it is fit to, but note that this can result in a squished appearance.

**Example**

Construct a triangular `BezierPath` out of a path command string and use it as a scatter marker:

```julia
str = "M 0,0 L 10,0 L 5,10 z"
bp = BezierPath(str, fit = true)
scatter(1:10, marker = bp, markersize = 20)
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/bezier.jl#L330-L359" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Box' href='#Makie.Box'><span class="jlbinding">Makie.Box</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



**`Makie.Box <: Block`**

No docstring defined.

**Attributes**

(type `?Makie.Box.x` in the REPL for more information about attribute `x`)

`alignmode`, `color`, `cornerradius`, `halign`, `height`, `linestyle`, `strokecolor`, `strokevisible`, `strokewidth`, `tellheight`, `tellwidth`, `valign`, `visible`, `width`, `z`


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks.jl#L118-L129" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.BoxPlot' href='#Makie.BoxPlot'><span class="jlbinding">Makie.BoxPlot</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`BoxPlot` is the plot type associated with plotting function `boxplot`. Check the docstring for `boxplot` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Bracket' href='#Makie.Bracket'><span class="jlbinding">Makie.Bracket</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`Bracket` is the plot type associated with plotting function `bracket`. Check the docstring for `bracket` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Button' href='#Makie.Button'><span class="jlbinding">Makie.Button</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



**`Makie.Button <: Block`**

No docstring defined.

**Attributes**

(type `?Makie.Button.x` in the REPL for more information about attribute `x`)

`alignmode`, `buttoncolor`, `buttoncolor_active`, `buttoncolor_hover`, `clicks`, `cornerradius`, `cornersegments`, `font`, `fontsize`, `halign`, `height`, `label`, `labelcolor`, `labelcolor_active`, `labelcolor_hover`, `padding`, `strokecolor`, `strokewidth`, `tellheight`, `tellwidth`, `valign`, `width`


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks.jl#L118-L129" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Camera' href='#Makie.Camera'><span class="jlbinding">Makie.Camera</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Camera(pixel_area)
```


Struct to hold all relevant matrices and additional parameters, to let backends apply camera based transformations.

**Fields**
- `pixel_space::Observable{StaticArraysCore.SMatrix{4, 4, Float64, 16}}`: projection used to convert pixel to device units
  
- `view::Observable{StaticArraysCore.SMatrix{4, 4, Float64, 16}}`: View matrix is usually used to rotate, scale and translate the scene
  
- `projection::Observable{StaticArraysCore.SMatrix{4, 4, Float64, 16}}`: Projection matrix is used for any perspective transformation
  
- `projectionview::Observable{StaticArraysCore.SMatrix{4, 4, Float64, 16}}`: just projection * view
  
- `resolution::Observable{Vec{2, Float32}}`: resolution of the canvas this camera draws to
  
- `view_direction::Observable{Vec{3, Float32}}`: Direction in which the camera looks.
  
- `eyeposition::Observable{Vec{3, Float32}}`: Eye position of the camera, used for e.g. ray tracing.
  
- `upvector::Observable{Vec{3, Float32}}`: Up direction of the current camera (e.g. Vec3f(0, 1, 0) for 2d)
  
- `steering_nodes::Vector{Observables.ObserverFunction}`: To make camera interactive, steering observables are connected to the different matrices. We need to keep track of them, so, that we can connect and disconnect them.
  
- `calculated_values::Dict{Symbol, Observable}`
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/types.jl#L258-L266" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Camera3D-Tuple{Scene}' href='#Makie.Camera3D-Tuple{Scene}'><span class="jlbinding">Makie.Camera3D</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



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
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/camera/camera3d.jl#L25-L113" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Categorical' href='#Makie.Categorical'><span class="jlbinding">Makie.Categorical</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Categorical(colormaplike)
```


Accepts all colormap values that the `colormap` attribute of a plot accepts. Will make sure to map one value to one color and create the correct Colorbar for the plot.

Example:

```julia
fig, ax, pl = barplot(1:3; color=1:3, colormap=Makie.Categorical(:viridis))
```


::: warning Warning

This feature might change outside breaking releases, since the API is not yet finalized

:::


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/colorsampler.jl#L230-L243" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Checkbox' href='#Makie.Checkbox'><span class="jlbinding">Makie.Checkbox</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



**`Makie.Checkbox <: Block`**

No docstring defined.

**Attributes**

(type `?Makie.Checkbox.x` in the REPL for more information about attribute `x`)

`alignmode`, `checkboxcolor_checked`, `checkboxcolor_unchecked`, `checkboxstrokecolor_checked`, `checkboxstrokecolor_unchecked`, `checkboxstrokewidth`, `checked`, `checkmark`, `checkmarkcolor_checked`, `checkmarkcolor_unchecked`, `checkmarksize`, `halign`, `height`, `onchange`, `roundness`, `size`, `tellheight`, `tellwidth`, `valign`, `width`


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks.jl#L118-L129" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.ClosePath' href='#Makie.ClosePath'><span class="jlbinding">Makie.ClosePath</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
ClosePath()
```


A path command for use within a `BezierPath` which closes the current subpath. The resulting path will have an implicit line segment between the last point and the first point if they do not match.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/bezier.jl#L86-L92" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Colorbar' href='#Makie.Colorbar'><span class="jlbinding">Makie.Colorbar</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



**`Makie.Colorbar <: Block`**

Create a colorbar that shows a continuous or categorical colormap with ticks chosen according to the colorrange.

You can set colorrange and colormap manually, or pass a plot object as the second argument to copy its respective attributes.

**Constructors**

```julia
Colorbar(fig_or_scene; kwargs...)
Colorbar(fig_or_scene, plot::AbstractPlot; kwargs...)
Colorbar(fig_or_scene, heatmap::Union{Heatmap, Image}; kwargs...)
Colorbar(fig_or_scene, contourf::Makie.Contourf; kwargs...)
```


**Attributes**

(type `?Makie.Colorbar.x` in the REPL for more information about attribute `x`)

`alignmode`, `bottomspinecolor`, `bottomspinevisible`, `colormap`, `colorrange`, `flip_vertical_label`, `flipaxis`, `halign`, `height`, `highclip`, `label`, `labelcolor`, `labelfont`, `labelpadding`, `labelrotation`, `labelsize`, `labelvisible`, `leftspinecolor`, `leftspinevisible`, `limits`, `lowclip`, `minortickalign`, `minortickcolor`, `minorticks`, `minorticksize`, `minorticksvisible`, `minortickwidth`, `nsteps`, `rightspinecolor`, `rightspinevisible`, `scale`, `size`, `spinewidth`, `tellheight`, `tellwidth`, `tickalign`, `tickcolor`, `tickformat`, `ticklabelalign`, `ticklabelcolor`, `ticklabelfont`, `ticklabelpad`, `ticklabelrotation`, `ticklabelsize`, `ticklabelspace`, `ticklabelsvisible`, `ticks`, `ticksize`, `ticksvisible`, `tickwidth`, `topspinecolor`, `topspinevisible`, `valign`, `vertical`, `width`


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks.jl#L118-L140" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Contour' href='#Makie.Contour'><span class="jlbinding">Makie.Contour</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`Contour` is the plot type associated with plotting function `contour`. Check the docstring for `contour` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Contour3d' href='#Makie.Contour3d'><span class="jlbinding">Makie.Contour3d</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`Contour3d` is the plot type associated with plotting function `contour3d`. Check the docstring for `contour3d` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Contourf' href='#Makie.Contourf'><span class="jlbinding">Makie.Contourf</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`Contourf` is the plot type associated with plotting function `contourf`. Check the docstring for `contourf` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.CrossBar' href='#Makie.CrossBar'><span class="jlbinding">Makie.CrossBar</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`CrossBar` is the plot type associated with plotting function `crossbar`. Check the docstring for `crossbar` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.CurveTo' href='#Makie.CurveTo'><span class="jlbinding">Makie.CurveTo</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
CurveTo(c1::VecTypes, c2::VecTypes, p::VecTypes)
CurveTo(cx1::Real, cy1::Real, cx2::Real, cy2::Real, px::Real, py::Real)
```


A path command for use within a `BezierPath` which continues the current subpath with a cubic bezier curve to point `p`, with the first control point `c1` and the second control point `c2`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/bezier.jl#L26-L32" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Cycled' href='#Makie.Cycled'><span class="jlbinding">Makie.Cycled</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Cycled(i::Int)
```


If a `Cycled` value is passed as an attribute to a plotting function, it is replaced with the value from the cycler for this attribute (as long as there is one defined) at the index `i`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/types.jl#L25-L31" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.DataInspector-Tuple{Any}' href='#Makie.DataInspector-Tuple{Any}'><span class="jlbinding">Makie.DataInspector</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
DataInspector(figure_axis_or_scene = current_figure(); kwargs...)
```


Creates a data inspector which will show relevant information in a tooltip when you hover over a plot.

This functionality can be disabled on a per-plot basis by setting `plot.inspectable[] = false`. The displayed text can be adjusted by setting `plot.inspector_label` to a function `(plot, index, position) -> "my_label"` returning a label. See Makie documentation for more detail.

**Keyword Arguments:**
- `range = 10`: Controls the snapping range for selecting an element of a plot.
  
- `priority = 100`: The priority of creating a tooltip on a mouse movement or   scrolling event.
  
- `enabled = true`: Disables inspection of plots when set to false. Can also be   adjusted with `enable!(inspector)` and `disable!(inspector)`.
  
- `indicator_color = :red`: Color of the selection indicator.
  
- `indicator_linewidth = 2`: Linewidth of the selection indicator.
  
- `indicator_linestyle = nothing`: Linestyle of the selection indicator
  
- `enable_indicators = true`: Enables or disables indicators
  
- `depth = 9e3`: Depth value of the tooltip. This should be high so that the   tooltip is always in front.
  
- `apply_tooltip_offset = true`: Enables or disables offsetting tooltips based   on, for example, markersize.
  
- and all attributes from `Tooltip`
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/interaction/inspector.jl#L219-L245" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.DataShader' href='#Makie.DataShader'><span class="jlbinding">Makie.DataShader</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`DataShader` is the plot type associated with plotting function `datashader`. Check the docstring for `datashader` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Density' href='#Makie.Density'><span class="jlbinding">Makie.Density</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`Density` is the plot type associated with plotting function `density`. Check the docstring for `density` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.DirectionalLight' href='#Makie.DirectionalLight'><span class="jlbinding">Makie.DirectionalLight</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
DirectionalLight(color, direction[, camera_relative = false])
```


A light type which simulates a distant light source with parallel light rays going in the given `direction`.

Availability:
- All backends with `shading = FastShading` or `MultiLightShading`
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/lighting.jl#L84-L92" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.ECDFPlot' href='#Makie.ECDFPlot'><span class="jlbinding">Makie.ECDFPlot</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`ECDFPlot` is the plot type associated with plotting function `ecdfplot`. Check the docstring for `ecdfplot` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.EllipticalArc' href='#Makie.EllipticalArc'><span class="jlbinding">Makie.EllipticalArc</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
EllipticalArc(c::VecTypes, r1::Real, r2::Real, angle::Real, a1::Real, a2::Real)
EllipticalArc(cx::Real, cy::Real, r1::Real, r2::Real, angle::Real, a1::Real, a2::Real)
```


A path command for use within a `BezierPath` which continues the current subpath with an elliptical arc. The ellipse is centered at `c` and has two radii, `r1` and `r2`, the orientation of which depends on `angle`.

If `angle == 0`, `r1` goes in x direction and `r2` in y direction. A positive `angle` in radians rotates the ellipse counterclockwise, and a negative `angle` clockwise.

The angles `a1` and `a2` are the start and stop positions of the arc on the ellipse. A value of `0` is where the radius `r1` points to, `pi/2` is where the radius `r2` points to, and so on. If `a2 > a1`, the arc turns counterclockwise. If `a1 > a2`, it turns clockwise.

If the last position of the subpath does not equal the start of the arc, the resulting path will have an implicit line segment between the two.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/bezier.jl#L56-L73" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.EllipticalArc-Tuple{Any, Any, Any, Any, Any, Any, Any, Bool, Bool}' href='#Makie.EllipticalArc-Tuple{Any, Any, Any, Any, Any, Any, Any, Bool, Bool}'><span class="jlbinding">Makie.EllipticalArc</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
EllipticalArc(x1::Real, y1::Real, x2::Real, y2::Real, rx::Real, ry::Real, ϕ::Real, largearc::Bool, sweepflag::Bool)
```


Construct an `EllipticalArc` using the endpoint parameterization.

`x1, y1` is the starting point and `x2, y2` the end point, `rx` and `ry` are the two ellipse radii. `ϕ` is the angle of `rx` vs the x axis.

Usually, four arcs can be constructed between two points given these ellipse parameters. One of them is chosen using two boolean flags:

If `largearc === true`, the arc will be longer than 180 degrees. If `sweepflag === true`, the arc will sweep through increasing angles.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/bezier.jl#L535-L548" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.EnvironmentLight' href='#Makie.EnvironmentLight'><span class="jlbinding">Makie.EnvironmentLight</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
EnvironmentLight(intensity, image)
```


An environment light that uses a spherical environment map to provide lighting. See: https://en.wikipedia.org/wiki/Reflection_mapping

Availability:
- RPRMakie
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/lighting.jl#L133-L141" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Errorbars' href='#Makie.Errorbars'><span class="jlbinding">Makie.Errorbars</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`Errorbars` is the plot type associated with plotting function `errorbars`. Check the docstring for `errorbars` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Events' href='#Makie.Events'><span class="jlbinding">Makie.Events</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



This struct provides accessible `Observable`s to monitor the events associated with a Scene.

Functions that act on an `Observable` must return `Consume()` if the function consumes an event. When an event is consumed it does not trigger other observer functions. The order in which functions are executed can be controlled via the `priority` keyword (default 0) in `on`.

Example:

```julia
on(events(scene).mousebutton, priority = 20) do event
    if is_correct_event(event)
        do_something()
        return Consume()
    end
    return
end
```


**Fields**
- `window_area::Observable{GeometryBasics.HyperRectangle{2, Int64}}`: The area of the window in pixels, as a `Rect2`.
  
- `window_dpi::Observable{Float64}`: The DPI resolution of the window, as a `Float64`.
  
- `window_open::Observable{Bool}`: The state of the window (open =&gt; true, closed =&gt; false).
  
- `mousebutton::Observable{Makie.MouseButtonEvent}`: Most recently triggered `MouseButtonEvent`. Contains the relevant `event.button` and `event.action` (press/release)
  See also [`ispressed`](/api#Makie.ispressed).
  
- `mousebuttonstate::Set{Makie.Mouse.Button}`: A Set of all currently pressed mousebuttons.
  
- `mouseposition::Observable{Tuple{Float64, Float64}}`: The position of the mouse as a `NTuple{2, Float64}`. Updates once per event poll/frame.
  
- `scroll::Observable{Tuple{Float64, Float64}}`: The direction of scroll
  
- `keyboardbutton::Observable{Makie.KeyEvent}`: Most recently triggered `KeyEvent`. Contains the relevant `event.key` and `event.action` (press/repeat/release)
  See also [`ispressed`](/api#Makie.ispressed).
  
- `keyboardstate::Set{Makie.Keyboard.Button}`: Contains all currently pressed keys.
  
- `unicode_input::Observable{Char}`: Contains the last typed character.
  
- `dropped_files::Observable{Vector{String}}`: Contains a list of filepaths to files dragged into the scene.
  
- `hasfocus::Observable{Bool}`: Whether the Scene window is in focus or not.
  
- `entered_window::Observable{Bool}`: Whether the mouse is inside the window or not.
  
- `tick::Observable{Makie.Tick}`: A `tick` is triggered whenever a new frame is requested, i.e. during normal rendering (even if the renderloop is paused) or when an image is produced for `save` or `record`. A Tick contains:
  - `state` which identifies what caused the tick (see Makie.TickState)
    
  - `count` which increments with every tick
    
  - `time` which is the total time since the screen has been created
    
  - `delta_time` which is the time since the last frame
    
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/types.jl#L58-L80" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Exclusively' href='#Makie.Exclusively'><span class="jlbinding">Makie.Exclusively</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Exclusively(x)
```


Marks a button, button collection or logical expression of buttons as the exclusive subset of buttons that must be pressed for `ispressed` to return true.

For example `Exclusively((Keyboard.left_control, Keyboard.c))` would require left control and c to be pressed without any other buttons.

Boolean expressions are lowered to multiple `Exclusive` sets in an `Or`. It is worth noting that `Not` branches are ignored here, i.e. it assumed that every button under a `Not` must not be pressed and that this follows automatically from the subset of buttons that must be pressed.

See also: [`And`](/api#Makie.And), [`Or`](/api#Makie.Or), [`Not`](/api#Makie.Not), [`ispressed`](/api#Makie.ispressed), `&`, `|`, `!`


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/interaction/events.jl#L147-L163" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.FastPixel' href='#Makie.FastPixel'><span class="jlbinding">Makie.FastPixel</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
FastPixel()
```


Use

```julia
scatter(..., marker=FastPixel())
```


For significantly faster plotting times for large amount of points. Note, that this will draw markers always as 1 pixel.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/conversions.jl#L1913-L1924" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Figure-Tuple{}' href='#Makie.Figure-Tuple{}'><span class="jlbinding">Makie.Figure</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
Figure(; [figure_padding,] kwargs...)
```


Construct a `Figure` which allows to place `Block`s like [`Axis`](/reference/blocks/axis#Axis), [`Colorbar`](/api#Makie.Colorbar) and [`Legend`](/api#Makie.Legend) inside. The outer padding of the figure (the distance of the content to the edges) can be set by passing either one number or a tuple of four numbers for left, right, bottom and top paddings via the `figure_padding` keyword.

All other keyword arguments such as `size` and `backgroundcolor` are forwarded to the [`Scene`](/api#Makie.Scene) owned by the figure which acts as the container for all other visual objects.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/figures.jl#L98-L107" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.HLines' href='#Makie.HLines'><span class="jlbinding">Makie.HLines</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`HLines` is the plot type associated with plotting function `hlines`. Check the docstring for `hlines` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.HSpan' href='#Makie.HSpan'><span class="jlbinding">Makie.HSpan</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`HSpan` is the plot type associated with plotting function `hspan`. Check the docstring for `hspan` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Hexbin' href='#Makie.Hexbin'><span class="jlbinding">Makie.Hexbin</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`Hexbin` is the plot type associated with plotting function `hexbin`. Check the docstring for `hexbin` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Hist' href='#Makie.Hist'><span class="jlbinding">Makie.Hist</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`Hist` is the plot type associated with plotting function `hist`. Check the docstring for `hist` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.IntervalSlider' href='#Makie.IntervalSlider'><span class="jlbinding">Makie.IntervalSlider</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



**`Makie.IntervalSlider <: Block`**

No docstring defined.

**Attributes**

(type `?Makie.IntervalSlider.x` in the REPL for more information about attribute `x`)

`alignmode`, `color_active`, `color_active_dimmed`, `color_inactive`, `halign`, `height`, `horizontal`, `interval`, `linewidth`, `range`, `snap`, `startvalues`, `tellheight`, `tellwidth`, `valign`, `width`


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks.jl#L118-L129" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.IntervalsBetween' href='#Makie.IntervalsBetween'><span class="jlbinding">Makie.IntervalsBetween</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
IntervalsBetween(n::Int, mirror::Bool = true)
```


Indicates to create n-1 minor ticks between every pair of adjacent major ticks.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/types.jl#L124-L128" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.LScene' href='#Makie.LScene'><span class="jlbinding">Makie.LScene</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



**`Makie.LScene <: Block`**

No docstring defined.

**Attributes**

(type `?Makie.LScene.x` in the REPL for more information about attribute `x`)

`alignmode`, `dim1_conversion`, `dim2_conversion`, `dim3_conversion`, `halign`, `height`, `show_axis`, `tellheight`, `tellwidth`, `valign`, `width`


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks.jl#L118-L129" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Label' href='#Makie.Label'><span class="jlbinding">Makie.Label</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



**`Makie.Label <: Block`**

No docstring defined.

**Attributes**

(type `?Makie.Label.x` in the REPL for more information about attribute `x`)

`alignmode`, `color`, `font`, `fontsize`, `halign`, `height`, `justification`, `lineheight`, `padding`, `rotation`, `tellheight`, `tellwidth`, `text`, `valign`, `visible`, `width`, `word_wrap`


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks.jl#L118-L129" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Legend' href='#Makie.Legend'><span class="jlbinding">Makie.Legend</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Legend(fig_or_scene, axis::Union{Axis, Scene, LScene}, title = nothing; merge = false, unique = false, kwargs...)
```


Create a single-group legend with all plots from `axis` that have the attribute `label` set.

If `merge` is `true`, all plot objects with the same label will be layered on top of each other into one legend entry. If `unique` is `true`, all plot objects with the same plot type and label will be reduced to one occurrence.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/legend.jl#L938-L946" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Legend-2' href='#Makie.Legend-2'><span class="jlbinding">Makie.Legend</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Legend(
    fig_or_scene,
    contents::AbstractArray,
    labels::AbstractArray,
    title = nothing;
    kwargs...)
```


Create a legend from `contents` and `labels` where each label is associated to one content element. A content element can be an `AbstractPlot`, an array of `AbstractPlots`, a `LegendElement`, or any other object for which the `legendelements` method is defined.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/legend.jl#L877-L889" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Legend-3' href='#Makie.Legend-3'><span class="jlbinding">Makie.Legend</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



**`Makie.Legend <: Block`**

No docstring defined.

**Attributes**

(type `?Makie.Legend.x` in the REPL for more information about attribute `x`)

`alignmode`, `alpha`, `backgroundcolor`, `bgcolor`, `colgap`, `framecolor`, `framevisible`, `framewidth`, `gridshalign`, `gridsvalign`, `groupgap`, `halign`, `heatmapcolorrange`, `heatmaplimits`, `heatmapvalues`, `height`, `imagecolorrange`, `imagelimits`, `imagevalues`, `label`, `labelcolor`, `labelfont`, `labelhalign`, `labeljustification`, `labelsize`, `labelvalign`, `linecolor`, `linecolormap`, `linecolorrange`, `linepoints`, `linestyle`, `linewidth`, `margin`, `marker`, `markercolor`, `markercolormap`, `markercolorrange`, `markerpoints`, `markersize`, `markerstrokecolor`, `markerstrokewidth`, `mesh`, `meshcolor`, `meshcolormap`, `meshcolorrange`, `meshscattercolor`, `meshscattercolormap`, `meshscattercolorrange`, `meshscattermarker`, `meshscatterpoints`, `meshscatterrotation`, `meshscattersize`, `nbanks`, `orientation`, `padding`, `patchcolor`, `patchlabelgap`, `patchsize`, `patchstrokecolor`, `patchstrokewidth`, `polycolor`, `polycolormap`, `polycolorrange`, `polypoints`, `polystrokecolor`, `polystrokewidth`, `rowgap`, `surfacecolormap`, `surfacecolorrange`, `surfacedata`, `surfacevalues`, `tellheight`, `tellwidth`, `titlecolor`, `titlefont`, `titlegap`, `titlehalign`, `titleposition`, `titlesize`, `titlevalign`, `titlevisible`, `valign`, `width`


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks.jl#L118-L129" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Legend-Tuple{Any, AbstractVector{<:AbstractVector}, AbstractVector{<:AbstractVector}, AbstractVector}' href='#Makie.Legend-Tuple{Any, AbstractVector{<:AbstractVector}, AbstractVector{<:AbstractVector}, AbstractVector}'><span class="jlbinding">Makie.Legend</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
Legend(
    fig_or_scene,
    contentgroups::AbstractVector{<:AbstractVector},
    labelgroups::AbstractVector{<:AbstractVector},
    titles::AbstractVector;
    kwargs...)
```


Create a multi-group legend from `contentgroups`, `labelgroups` and `titles`. Each group from `contentgroups` and `labelgroups` is associated with one title from `titles` (a title can be `nothing` to hide it).

Within each group, each content element is associated with one label. A content element can be an `AbstractPlot`, an array of `AbstractPlots`, a `LegendElement`, or any other object for which the `legendelements` method is defined.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/legend.jl#L907-L922" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.LineTo' href='#Makie.LineTo'><span class="jlbinding">Makie.LineTo</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
LineTo(p::VecTypes)
LineTo(x::Real, y::Real)
```


A path command for use within a `BezierPath` which continues the current subpath with a line to the given point.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/bezier.jl#L13-L19" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.LinearTicks' href='#Makie.LinearTicks'><span class="jlbinding">Makie.LinearTicks</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



LinearTicks with ideally a number of `n_ideal` tick marks.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/types.jl#L36-L38" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Linestyle' href='#Makie.Linestyle'><span class="jlbinding">Makie.Linestyle</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Linestyle(value::Vector{<:Real})
```


A type that can be used as value for the `linestyle` keyword argument of plotting functions to arbitrarily customize the linestyle.

The `value` is a vector specifying the boundaries of the dashes in the line. Values 1 and 2 demarcate the first dash, values 2 and 3 the first gap, and so on. This means that usually, a pattern should have an odd number of values so that there&#39;s always a gap after a dash.

Here&#39;s an example in ASCII code. If we specify `[0, 3, 6, 11, 16]` then we get the following pattern:

```
#  0  3   6   11   16  3  6   11
#   ---   -----     ---   -----
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/conversions.jl#L1131-L1149" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.LogTicks' href='#Makie.LogTicks'><span class="jlbinding">Makie.LogTicks</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
LogTicks{T}(linear_ticks::T)
```


Wraps any other tick object. Used to apply a linear tick searching algorithm on a log-transformed interval.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/types.jl#L114-L119" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Menu' href='#Makie.Menu'><span class="jlbinding">Makie.Menu</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



**`Makie.Menu <: Block`**

A drop-down menu with multiple selectable options. You can pass options with the keyword argument `options`.

Options are given as an iterable of elements. For each element, the option label in the menu is determined with `optionlabel(element)` and the option value with `optionvalue(element)`. These functions can be overloaded for custom types. The default is that tuples of two elements are expected to be label and value, where `string(label)` is used as the label, while for all other objects, label = `string(object)` and value = object.

When an item is selected in the menu, the menu&#39;s `selection` attribute is set to `optionvalue(selected_element)`. When nothing is selected, that value is `nothing`.

You can set the initial selection by passing one of the labels with the `default` keyword.

**Constructors**

```julia
Menu(fig_or_scene; default = nothing, kwargs...)
```


**Examples**

Menu with string entries, second preselected:

```julia
menu1 = Menu(fig[1, 1], options = ["first", "second", "third"], default = "second")
```


Menu with two-element entries, label and function:

```julia
funcs = [sin, cos, tan]
labels = ["Sine", "Cosine", "Tangens"]

menu2 = Menu(fig[1, 1], options = zip(labels, funcs))
```


Executing a function when a selection is made:

```julia
on(menu2.selection) do selected_function
    # do something with the selected function
end
```


**Attributes**

(type `?Makie.Menu.x` in the REPL for more information about attribute `x`)

`alignmode`, `cell_color_active`, `cell_color_hover`, `cell_color_inactive_even`, `cell_color_inactive_odd`, `direction`, `dropdown_arrow_color`, `dropdown_arrow_size`, `fontsize`, `halign`, `height`, `i_selected`, `is_open`, `options`, `prompt`, `scroll_speed`, `selection`, `selection_cell_color_inactive`, `tellheight`, `tellwidth`, `textcolor`, `textpadding`, `valign`, `width`


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks.jl#L118-L166" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.MouseEvent' href='#Makie.MouseEvent'><span class="jlbinding">Makie.MouseEvent</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
MouseEvent
```


Describes a mouse state change. Fields:
- `type`: MouseEventType
  
- `t`: Time of the event
  
- `data`: Mouse position in data coordinates
  
- `px`: Mouse position in px relative to scene origin
  
- `prev_t`: Time of previous event
  
- `prev_data`: Previous mouse position in data coordinates
  
- `prev_px`: Previous mouse position in data coordinates
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/mousestatemachine.jl#L42-L54" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.MoveTo' href='#Makie.MoveTo'><span class="jlbinding">Makie.MoveTo</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
MoveTo(p::VecTypes)
MoveTo(x::Real, y::Real)
```


A path command for use within a `BezierPath` which starts a new subpath at the given point.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/bezier.jl#L1-L6" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.MultiplesTicks' href='#Makie.MultiplesTicks'><span class="jlbinding">Makie.MultiplesTicks</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



Like LinearTicks but for multiples of `multiple`. Example where approximately 5 numbers should be found that are multiples of pi, printed like &quot;1π&quot;, &quot;2π&quot;, etc.:

```julia
MultiplesTicks(5, pi, "π")
```


If `strip_zero == true`, then the resulting labels will be checked and any label that is a multiple of 0 will be set to &quot;0&quot;.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/types.jl#L61-L73" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Pie' href='#Makie.Pie'><span class="jlbinding">Makie.Pie</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`Pie` is the plot type associated with plotting function `pie`. Check the docstring for `pie` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.PlotSpec' href='#Makie.PlotSpec'><span class="jlbinding">Makie.PlotSpec</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
PlotSpec(plottype, args...; kwargs...)
```


Object encoding positional arguments (`args`), a `NamedTuple` of attributes (`kwargs`) as well as plot type `P` of a basic plot.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/specapi.jl#L12-L17" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.PointLight' href='#Makie.PointLight'><span class="jlbinding">Makie.PointLight</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
PointLight(color, position[, attenuation = Vec2f(0)])
PointLight(color, position, range::Real)
```


A point-like light source placed at the given `position` with the given light `color`.

Optionally an attenuation parameter can be used to reduce the brightness of the light source with distance. The reduction is given by `1 / (1 + attenuation[1] * distance + attenuation[2] * distance^2)`. Alternatively you can pass a light `range` to generate matching default attenuation parameters. Note that you may need to set the light intensity, i.e. the light color to values greater than 1 to get satisfying results.

Availability:
- GLMakie with `shading = MultiLightShading`
  
- RPRMakie
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/lighting.jl#L37-L54" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.PolarAxis' href='#Makie.PolarAxis'><span class="jlbinding">Makie.PolarAxis</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



**`Makie.PolarAxis <: Block`**

No docstring defined.

**Attributes**

(type `?Makie.PolarAxis.x` in the REPL for more information about attribute `x`)

`alignmode`, `axis_rotation_button`, `backgroundcolor`, `clip`, `clip_r`, `clipcolor`, `dim1_conversion`, `dim2_conversion`, `direction`, `fixrmin`, `gridz`, `halign`, `height`, `normalize_theta_ticks`, `r_translation_button`, `radius_at_origin`, `rautolimitmargin`, `reset_axis_orientation`, `reset_button`, `rgridcolor`, `rgridstyle`, `rgridvisible`, `rgridwidth`, `rlimits`, `rminorgridcolor`, `rminorgridstyle`, `rminorgridvisible`, `rminorgridwidth`, `rminortickalign`, `rminortickcolor`, `rminorticks`, `rminorticksize`, `rminorticksvisible`, `rminortickwidth`, `rtickalign`, `rtickangle`, `rtickcolor`, `rtickformat`, `rticklabelcolor`, `rticklabelfont`, `rticklabelpad`, `rticklabelrotation`, `rticklabelsize`, `rticklabelstrokecolor`, `rticklabelstrokewidth`, `rticklabelsvisible`, `rticks`, `rticksize`, `rticksmirrored`, `rticksvisible`, `rtickwidth`, `rzoomkey`, `rzoomlock`, `sample_density`, `spinecolor`, `spinestyle`, `spinevisible`, `spinewidth`, `tellheight`, `tellwidth`, `theta_0`, `theta_as_x`, `theta_translation_button`, `thetaautolimitmargin`, `thetagridcolor`, `thetagridstyle`, `thetagridvisible`, `thetagridwidth`, `thetalimits`, `thetaminorgridcolor`, `thetaminorgridstyle`, `thetaminorgridvisible`, `thetaminorgridwidth`, `thetaminortickalign`, `thetaminortickcolor`, `thetaminorticks`, `thetaminorticksize`, `thetaminorticksvisible`, `thetaminortickwidth`, `thetatickalign`, `thetatickcolor`, `thetatickformat`, `thetaticklabelcolor`, `thetaticklabelfont`, `thetaticklabelpad`, `thetaticklabelsize`, `thetaticklabelstrokecolor`, `thetaticklabelstrokewidth`, `thetaticklabelsvisible`, `thetaticks`, `thetaticksize`, `thetaticksmirrored`, `thetaticksvisible`, `thetatickwidth`, `thetazoomkey`, `thetazoomlock`, `title`, `titlealign`, `titlecolor`, `titlefont`, `titlegap`, `titlesize`, `titlevisible`, `valign`, `width`, `zoomspeed`


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks.jl#L118-L129" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.QQNorm' href='#Makie.QQNorm'><span class="jlbinding">Makie.QQNorm</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`QQNorm` is the plot type associated with plotting function `qqnorm`. Check the docstring for `qqnorm` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.QQPlot' href='#Makie.QQPlot'><span class="jlbinding">Makie.QQPlot</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`QQPlot` is the plot type associated with plotting function `qqplot`. Check the docstring for `qqplot` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.RainClouds' href='#Makie.RainClouds'><span class="jlbinding">Makie.RainClouds</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`RainClouds` is the plot type associated with plotting function `rainclouds`. Check the docstring for `rainclouds` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Rangebars' href='#Makie.Rangebars'><span class="jlbinding">Makie.Rangebars</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`Rangebars` is the plot type associated with plotting function `rangebars`. Check the docstring for `rangebars` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.RectLight' href='#Makie.RectLight'><span class="jlbinding">Makie.RectLight</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
RectLight(color, r::Rect2[, direction = -normal])
RectLight(color, center::Point3f, b1::Vec3f, b2::Vec3f[, direction = -normal])
```


Creates a RectLight with a given color. The first constructor derives the light from a `Rect2` extending in x and y directions. The second specifies the `center` of the rect (or more accurately parallelogram) with `b1` and `b2` specifying the width and height vectors (including scale).

Note that RectLight implements `translate!`, `rotate!` and `scale!` to simplify adjusting the light.

Availability:
- GLMakie with `Shading = MultiLightShading`
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/lighting.jl#L147-L161" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Resampler' href='#Makie.Resampler'><span class="jlbinding">Makie.Resampler</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Resampler(matrix; max_resolution=automatic, method=Interpolations.Linear(), update_while_button_pressed=false)
```


Creates a resampling type which can be used with `heatmap`, to display large images/heatmaps. Passed can be any array that supports `array(linrange, linrange)`, as the interpolation interface from Interpolations.jl. If the array doesn&#39;t support this, it will be converted to an interpolation object via: `Interpolations.interpolate(data, Interpolations.BSpline(method))`.
- `max_resolution` can be set to `automatic` to use the full resolution of the screen, or a tuple/integer of the desired resolution.
  
- `method` is the interpolation method used, defaulting to `Interpolations.Linear()`.
  
- `update_while_button_pressed` will update the heatmap while a mouse button is pressed, useful for zooming/panning. Set it to false for e.g. WGLMakie to avoid updating while dragging.
  
- `lowres_background` will always show a low resolution background while the high resolution image is being calculated.
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/basic_recipes/datashader.jl#L524-L534" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Reverse' href='#Makie.Reverse'><span class="jlbinding">Makie.Reverse</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



Reverses the attribute T upon conversion


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/conversions.jl#L1554-L1556" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.ReversibleScale' href='#Makie.ReversibleScale'><span class="jlbinding">Makie.ReversibleScale</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
ReversibleScale
```


Custom scale struct, taking a forward and inverse arbitrary scale function.

**Fields**
- `forward::Function`: forward transformation (e.g. `log10`)
  
- `inverse::Function`: inverse transformation (e.g. `exp10` for `log10` such that inverse ∘ forward ≡ identity)
  
- `limits::Tuple{Float32, Float32}`: default limits (optional)
  
- `interval::IntervalSets.AbstractInterval`: valid limits interval (optional)
  
- `name::Symbol`
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/types.jl#L496-L503" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.ScatterLines' href='#Makie.ScatterLines'><span class="jlbinding">Makie.ScatterLines</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`ScatterLines` is the plot type associated with plotting function `scatterlines`. Check the docstring for `scatterlines` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Scene' href='#Makie.Scene'><span class="jlbinding">Makie.Scene</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Scene TODO document this
```


**Constructors**

**Fields**
- `parent`: The parent of the Scene; if it is a top-level Scene, `parent == nothing`.
  
- `events`: [`Events`](/api#Makie.Events) associated with the Scene.
  
- `viewport`: The current pixel area of the Scene.
  
- `clear`: Whether the scene should be cleared.
  
- `camera`: The `Camera` associated with the Scene.
  
- `camera_controls`: The controls for the camera of the Scene.
  
- `transformation`: The [`Transformation`](/api#Makie.Transformation) of the Scene.
  
- `float32convert`: A transformation rescaling data to a Float32-save range.
  
- `plots`: The plots contained in the Scene.
  
- `theme`
  
- `children`: Children of the Scene inherit its transformation.
  
- `current_screens`: The Screens which the Scene is displayed to.
  
- `backgroundcolor`
  
- `visible`
  
- `ssao`
  
- `lights`
  
- `deregister_callbacks`
  
- `cycler`
  
- `conversions`
  
- `isclosed`
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/scenes.jl#L40-L48" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.SceneSpace' href='#Makie.SceneSpace'><span class="jlbinding">Makie.SceneSpace</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



Unit space of the scene it&#39;s displayed on. Also referred to as data units


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/units.jl#L31-L34" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Series' href='#Makie.Series'><span class="jlbinding">Makie.Series</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`Series` is the plot type associated with plotting function `series`. Check the docstring for `series` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Slider' href='#Makie.Slider'><span class="jlbinding">Makie.Slider</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



**`Makie.Slider <: Block`**

No docstring defined.

**Attributes**

(type `?Makie.Slider.x` in the REPL for more information about attribute `x`)

`alignmode`, `color_active`, `color_active_dimmed`, `color_inactive`, `halign`, `height`, `horizontal`, `linewidth`, `range`, `snap`, `startvalue`, `tellheight`, `tellwidth`, `update_while_dragging`, `valign`, `value`, `width`


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks.jl#L118-L129" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.SliderGrid' href='#Makie.SliderGrid'><span class="jlbinding">Makie.SliderGrid</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



**`Makie.SliderGrid <: Block`**

A grid of one or more horizontal `Slider`s, where each slider has a name label on the left and a value label on the right.

Each `NamedTuple` you pass specifies one `Slider`. You always have to pass `range` and `label`, and optionally a `format` for the value label. Beyond that, you can set any keyword that `Slider` takes, such as `startvalue`.

The `format` keyword can be a `String` with Format.jl style, such as &quot;{:.2f}Hz&quot;, or a function.

**Constructors**

```julia
SliderGrid(fig_or_scene, nts::NamedTuple...; kwargs...)
```


**Examples**

```julia
sg = SliderGrid(fig[1, 1],
    (label = "Amplitude", range = 0:0.1:10, startvalue = 5),
    (label = "Frequency", range = 0:0.5:50, format = "{:.1f}Hz", startvalue = 10),
    (label = "Phase", range = 0:0.01:2pi,
        format = x -> string(round(x/pi, digits = 2), "π"))
)
```


Working with slider values:

```julia
on(sg.sliders[1].value) do val
    # do something with `val`
end
```


**Attributes**

(type `?Makie.SliderGrid.x` in the REPL for more information about attribute `x`)

`alignmode`, `halign`, `height`, `tellheight`, `tellwidth`, `valign`, `value_column_width`, `width`


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks.jl#L118-L158" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.SpotLight' href='#Makie.SpotLight'><span class="jlbinding">Makie.SpotLight</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
SpotLight(color, position, direction, angles)
```


Creates a spot light which illuminates objects in a light cone starting at `position` pointing in `direction`. The opening angle is defined by an inner and outer angle given in `angles`, between which the light intensity drops off.

Availability:
- GLMakie with `shading = MultiLightShading`
  
- RPRMakie
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/lighting.jl#L111-L121" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Spy' href='#Makie.Spy'><span class="jlbinding">Makie.Spy</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`Spy` is the plot type associated with plotting function `spy`. Check the docstring for `spy` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Stairs' href='#Makie.Stairs'><span class="jlbinding">Makie.Stairs</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`Stairs` is the plot type associated with plotting function `stairs`. Check the docstring for `stairs` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Stem' href='#Makie.Stem'><span class="jlbinding">Makie.Stem</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`Stem` is the plot type associated with plotting function `stem`. Check the docstring for `stem` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.StepHist' href='#Makie.StepHist'><span class="jlbinding">Makie.StepHist</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`StepHist` is the plot type associated with plotting function `stephist`. Check the docstring for `stephist` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.StreamPlot' href='#Makie.StreamPlot'><span class="jlbinding">Makie.StreamPlot</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`StreamPlot` is the plot type associated with plotting function `streamplot`. Check the docstring for `streamplot` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.TextLabel' href='#Makie.TextLabel'><span class="jlbinding">Makie.TextLabel</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`TextLabel` is the plot type associated with plotting function `textlabel`. Check the docstring for `textlabel` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Textbox' href='#Makie.Textbox'><span class="jlbinding">Makie.Textbox</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



**`Makie.Textbox <: Block`**

No docstring defined.

**Attributes**

(type `?Makie.Textbox.x` in the REPL for more information about attribute `x`)

`alignmode`, `bordercolor`, `bordercolor_focused`, `bordercolor_focused_invalid`, `bordercolor_hover`, `borderwidth`, `boxcolor`, `boxcolor_focused`, `boxcolor_focused_invalid`, `boxcolor_hover`, `cornerradius`, `cornersegments`, `cursorcolor`, `defocus_on_submit`, `displayed_string`, `focused`, `font`, `fontsize`, `halign`, `height`, `placeholder`, `reset_on_defocus`, `restriction`, `stored_string`, `tellheight`, `tellwidth`, `textcolor`, `textcolor_placeholder`, `textpadding`, `validator`, `valign`, `width`


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks.jl#L118-L129" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.TimeSeries' href='#Makie.TimeSeries'><span class="jlbinding">Makie.TimeSeries</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`TimeSeries` is the plot type associated with plotting function `timeseries`. Check the docstring for `timeseries` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Toggle' href='#Makie.Toggle'><span class="jlbinding">Makie.Toggle</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



**`Makie.Toggle <: Block`**

A switch with two states.

**Constructors**

```julia
Toggle(fig_or_scene; kwargs...)
```


**Examples**

```julia
t_horizontal = Toggle(fig[1, 1])
t_vertical = Toggle(fig[2, 1], orientation = :vertical)
t_diagonal = Toggle(fig[3, 1], orientation = pi/4)
on(t_vertical.active) do switch_is_on
    switch_is_on ? println("good morning!") : println("good night")
end
```


**Attributes**

(type `?Makie.Toggle.x` in the REPL for more information about attribute `x`)

`active`, `alignmode`, `buttoncolor`, `cornersegments`, `framecolor_active`, `framecolor_inactive`, `halign`, `height`, `length`, `markersize`, `orientation`, `rimfraction`, `tellheight`, `tellwidth`, `toggleduration`, `valign`, `width`


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks.jl#L118-L146" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Tooltip' href='#Makie.Tooltip'><span class="jlbinding">Makie.Tooltip</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`Tooltip` is the plot type associated with plotting function `tooltip`. Check the docstring for `tooltip` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Transformation' href='#Makie.Transformation'><span class="jlbinding">Makie.Transformation</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



Holds the transformations for Scenes.

**Fields**
- `parent::Base.RefValue{Transformation}`
  
- `translation::Observable{Vec{3, Float64}}`
  
- `scale::Observable{Vec{3, Float64}}`
  
- `rotation::Observable{Quaternionf}`
  
- `origin::Observable{Vec{3, Float64}}`
  
- `model::Observable{StaticArraysCore.SMatrix{4, 4, Float64, 16}}`
  
- `parent_model::Observable{StaticArraysCore.SMatrix{4, 4, Float64, 16}}`
  
- `transform_func::Observable{Any}`
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/types.jl#L315-L319" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Tricontourf' href='#Makie.Tricontourf'><span class="jlbinding">Makie.Tricontourf</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`Tricontourf` is the plot type associated with plotting function `tricontourf`. Check the docstring for `tricontourf` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Triplot' href='#Makie.Triplot'><span class="jlbinding">Makie.Triplot</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`Triplot` is the plot type associated with plotting function `triplot`. Check the docstring for `triplot` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.VLines' href='#Makie.VLines'><span class="jlbinding">Makie.VLines</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`VLines` is the plot type associated with plotting function `vlines`. Check the docstring for `vlines` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.VSpan' href='#Makie.VSpan'><span class="jlbinding">Makie.VSpan</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`VSpan` is the plot type associated with plotting function `vspan`. Check the docstring for `vspan` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.VideoStream-Tuple{Union{Figure, Makie.FigureAxisPlot, Scene}}' href='#Makie.VideoStream-Tuple{Union{Figure, Makie.FigureAxisPlot, Scene}}'><span class="jlbinding">Makie.VideoStream</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
VideoStream(fig::FigureLike;
        format="mp4", framerate=24, compression=nothing, profile=nothing, pixel_format=nothing, loop=nothing,
        loglevel="quiet", visible=false, connect=false, filter_ticks=true, backend=current_backend(),
        screen_config...)
```


Returns a `VideoStream` which can pipe new frames into the ffmpeg process with few allocations via [`recordframe!(stream)`](/api#Makie.recordframe!-Tuple{VideoStream}). When done, use [`save(path, stream)`](/api#FileIO.save-Tuple{String,%20Union{Figure,%20Makie.FigureAxisPlot,%20Scene}}) to write the video out to a file.

**Arguments**

**Video options**
- `format = "mkv"`: The format of the video. If a path is present, will be inferred from the file extension.   Can be one of the following:
  - `"mkv"`  (open standard, the default)
    
  - `"mp4"`  (good for Web, most supported format)
    
  - `"webm"` (smallest file size)
    
  - `"gif"`  (largest file size for the same quality)
    
  `mp4` and `mk4` are marginally bigger than `webm`. `gif`s can be significantly (as much as   6x) larger with worse quality (due to the limited color palette) and only should be used   as a last resort, for playing in a context where videos aren&#39;t supported.
  
- `framerate = 24`: The target framerate.
  
- `compression = 20`: Controls the video compression via `ffmpeg`&#39;s `-crf` option, with   smaller numbers giving higher quality and larger file sizes (lower compression), and   higher numbers giving lower quality and smaller file sizes (higher compression). The   minimum value is `0` (lossless encoding).
  - For `mp4`, `51` is the maximum. Note that `compression = 0` only works with `mp4` if `profile = "high444"`.
    
  - For `webm`, `63` is the maximum.
    
  - `compression` has no effect on `mkv` and `gif` outputs.
    
  
- `profile = "high422"`: A ffmpeg compatible profile. Currently only applies to `mp4`. If you have issues playing a video, try `profile = "high"` or `profile = "main"`.
  
- `pixel_format = "yuv420p"`: A ffmpeg compatible pixel format (`-pix_fmt`). Currently only applies to `mp4`. Defaults to `yuv444p` for `profile = "high444"`.
  
- `loop = 0`: Number of times the video is repeated, for a `gif` or `html` output. Defaults to `0`, which means infinite looping. A value of `-1` turns off looping, and a value of `n > 0` means `n` repetitions (i.e. the video is played `n+1` times) when supported by backend.
  

::: warning Warning

`profile` and `pixel_format` are only used when `format` is `"mp4"`; a warning will be issued if `format` is not `"mp4"` and those two arguments are not `nothing`. Similarly, `compression` is only valid when `format` is `"mp4"` or `"webm"`.

:::

**Backend options**
- `backend=current_backend()`: backend used to record frames
  
- `visible=false`: make window visible or not
  
- `connect=false`: connect window events or not
  
- `screen_config...`: See `?Backend.Screen` or `Base.doc(Backend.Screen)` for applicable options that can be passed and forwarded to the backend.
  

**Other**
- `filter_ticks`: When true, tick events other than `tick.state = Makie.OneTimeRenderTick` are removed until `save()` is called or the VideoStream object gets deleted.
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/ffmpeg-util.jl#L224-L249" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Violin' href='#Makie.Violin'><span class="jlbinding">Makie.Violin</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`Violin` is the plot type associated with plotting function `violin`. Check the docstring for `violin` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.VolumeSlices' href='#Makie.VolumeSlices'><span class="jlbinding">Makie.VolumeSlices</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`VolumeSlices` is the plot type associated with plotting function `volumeslices`. Check the docstring for `volumeslices` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Voronoiplot' href='#Makie.Voronoiplot'><span class="jlbinding">Makie.Voronoiplot</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`Voronoiplot` is the plot type associated with plotting function `voronoiplot`. Check the docstring for `voronoiplot` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Waterfall' href='#Makie.Waterfall'><span class="jlbinding">Makie.Waterfall</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`Waterfall` is the plot type associated with plotting function `waterfall`. Check the docstring for `waterfall` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.WilkinsonTicks-Tuple{Int64}' href='#Makie.WilkinsonTicks-Tuple{Int64}'><span class="jlbinding">Makie.WilkinsonTicks</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
WilkinsonTicks(
    k_ideal::Int;
    k_min = 2, k_max = 10,
    Q = [(1.0, 1.0), (5.0, 0.9), (2.0, 0.7), (2.5, 0.5), (3.0, 0.2)],
    granularity_weight = 1/4,
    simplicity_weight = 1/6,
    coverage_weight = 1/3,
    niceness_weight = 1/4
)
```


`WilkinsonTicks` is a thin wrapper over `PlotUtils.optimize_ticks`, the docstring of which is reproduced below:

optimize_ticks(xmin, xmax; extend_ticks::Bool = false,                Q = [(1.0,1.0), (5.0, 0.9), (2.0, 0.7), (2.5, 0.5), (3.0, 0.2)],                k_min = 2, k_max = 10, k_ideal = 5,                granularity_weight = 1/4, simplicity_weight = 1/6,                coverage_weight = 1/3, niceness_weight = 1/4,                strict_span = true, span_buffer = nothing)

Find some reasonable values for tick marks.

This is basically Wilkinson&#39;s ad-hoc scoring method that tries to balance tight fit around the data, optimal number of ticks, and simple numbers.

**Arguments:**
- `xmax`:
  The maximum value occurring in the data.
  
- `xmin`:
  The minimum value occurring in the data.
  
- `extend_ticks`:
  Determines whether to extend tick computation. Defaults to false.
  
- `strict_span`:
  True if no ticks should be outside [x_min, x_max]. Defaults to true.
  
- `Q`:
  A distribution of nice numbers from which labellings are sampled. Stored in the form (number, score).
  
- `k_min`:
  The minimum number of ticks.
  
- `k_max`:
  The maximum number of ticks.
  
- `k_ideal`:
  The ideal number of ticks.
  
- `granularity_weight`:
  Encourages returning roughly the number of labels requested.
  
- `simplicity_weight`:
  Encourages nicer labeling sequences by preferring step sizes that appear earlier in Q.   Also rewards labelings that include 0 as a way to ground the sequence.
  
- `coverage_weight`:
  Encourages labelings that do not extend far beyond the range of the data, penalizing unnecessary whitespace.
  
- `niceness_weight`:
  Encourages labellings to produce nice ranges.
  

**Returns:**

`(ticklocations::Vector{Float64}, x_min, x_max)`

**Mathematical details**

Wilkinson’s optimization function is defined as the sum of three components. If the user requests m labels and a possible labeling has k labels, then the components are `simplicity`, `coverage` and `granularity`.

These components are defined as follows:

$

\begin{aligned}   &amp;\text{simplicity} = 1 - \frac{i}{|Q|} + \frac{v}{|Q|}\
  &amp;\text{coverage}   = \frac{x_{max} - x_{min}}{\mathrm{label}_{max} - \mathrm{label}_{min}}\
  &amp;\text{granularity}= 1 - \frac{\left|k - m\right|}{m} \end{aligned} $

and the variables here are:
- `q`: element of `Q`.
  
- `i`: index of `q` ∈ `Q`.
  
- `v`: 1 if label range includes 0, 0 otherwise.
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/ticklocators/wilkinson.jl#L1-L15" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='FileIO.save-Tuple{String, Union{Figure, Makie.FigureAxisPlot, Scene}}' href='#FileIO.save-Tuple{String, Union{Figure, Makie.FigureAxisPlot, Scene}}'><span class="jlbinding">FileIO.save</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
FileIO.save(filename, scene; size = size(scene), pt_per_unit = 0.75, px_per_unit = 1.0)
```


Save a `Scene` with the specified filename and format.

**Supported Formats**
- `GLMakie`: `.png`
  
- `CairoMakie`: `.svg`, `.pdf` and `.png`
  
- `WGLMakie`: `.png`
  

**Supported Keyword Arguments**

**All Backends**
- `size`: `(width::Int, height::Int)` of the scene in dimensionless units.
  
- `update`: Whether the figure should be updated before saving. This resets the limits of all Axes in the figure. Defaults to `true`.
  
- `backend`: Specify the `Makie` backend that should be used for saving. Defaults to the current backend.
  
- `px_per_unit`: The size of one scene unit in `px` when exporting to a bitmap format. This provides a mechanism to export the same scene with higher or lower resolution.
  
- Further keywords will be forwarded to the screen.
  

**CairoMakie**
- `pt_per_unit`: The size of one scene unit in `pt` when exporting to a vector format.
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/display.jl#L275-L300" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='FileIO.save-Tuple{String, VideoStream}' href='#FileIO.save-Tuple{String, VideoStream}'><span class="jlbinding">FileIO.save</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
save(path::String, io::VideoStream)
```


Flushes the video stream and saves it to `path`. Ideally, `path`&#39;s file extension is the same as the format that the `VideoStream` was created with (e.g., if created with format &quot;mp4&quot; then `path`&#39;s file extension must be &quot;.mp4&quot;). Otherwise, the video will get converted to the target format. If using [`record`](/api#Makie.record-Tuple{Any,%20Union{Figure,%20Makie.FigureAxisPlot,%20Scene},%20AbstractString}) then this is handled for you, as the `VideoStream`&#39;s format is deduced from the file extension of the path passed to `record`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/ffmpeg-util.jl#L306-L314" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Pattern-Tuple{Matrix{<:ColorTypes.Colorant}}' href='#Makie.Pattern-Tuple{Matrix{<:ColorTypes.Colorant}}'><span class="jlbinding">Makie.Pattern</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
Pattern(image)
Pattern(mask[; color1, color2])
```


Creates an `ImagePattern` from an `image` (a matrix of colors) or a `mask` (a matrix of real numbers). The pattern can be passed as a `color` to a plot to texture it. If a `mask` is passed, one can specify to colors between which colors are interpolated.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/patterns.jl#L26-L34" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Pattern-Tuple{String}' href='#Makie.Pattern-Tuple{String}'><span class="jlbinding">Makie.Pattern</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
Pattern(style::String = "/"; kwargs...)
Pattern(style::Char = '/'; kwargs...)
```


Creates a line pattern based on the given argument. Available patterns are `'/'`, `'\'`, `'-'`, `'|'`, `'x'`, and `'+'`. All keyword arguments correspond to the keyword arguments for `LinePattern`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/patterns.jl#L99-L106" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Record-Tuple{Any, Any}' href='#Makie.Record-Tuple{Any, Any}'><span class="jlbinding">Makie.Record</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
Record(func, figlike, [iter]; kw_args...)
```


Check [`Makie.record`](/api#Makie.record-Tuple{Any,%20Union{Figure,%20Makie.FigureAxisPlot,%20Scene},%20AbstractString}) for documentation.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/recording.jl#L159-L163" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.ablines' href='#Makie.ablines'><span class="jlbinding">Makie.ablines</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
ablines(intercepts, slopes; attrs...)
```


Creates a line defined by `f(x) = slope * x + intercept` crossing a whole `Scene` with 2D projection at its current limits. You can pass one or multiple intercepts or slopes.

**Plot type**

The plot type alias for the `ablines` function is `ABLines`.

**Attributes**

**`alpha`** =  `1.0`  — The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`color`** =  `@inherit linecolor`  — The color of the line.

**`colormap`** =  `@inherit colormap :viridis`  — Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

**`colorrange`** =  `automatic`  — The values representing the start and end points of `colormap`.

**`colorscale`** =  `identity`  — The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.

**`cycle`** =  `[:color]`  — Sets which attributes to cycle when creating multiple plots.

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`fxaa`** =  `false`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`highclip`** =  `automatic`  — The color for any value above the colorrange.

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`linecap`** =  `@inherit linecap`  — Sets the type of linecap used, i.e. :butt (flat with no extrusion), :square (flat with 1 linewidth extrusion) or :round.

**`linestyle`** =  `nothing`  — Sets the dash pattern of the line. Options are `:solid` (equivalent to `nothing`), `:dot`, `:dash`, `:dashdot` and `:dashdotdot`. These can also be given in a tuple with a gap style modifier, either `:normal`, `:dense` or `:loose`. For example, `(:dot, :loose)` or `(:dashdot, :dense)`.

For custom patterns have a look at [`Makie.Linestyle`](/api#Makie.Linestyle).

**`linewidth`** =  `@inherit linewidth`  — Sets the width of the line in pixel units

**`lowclip`** =  `automatic`  — The color for any value below the colorrange.

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`nan_color`** =  `:transparent`  — The color for NaN values.

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L594" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.ablines!' href='#Makie.ablines!'><span class="jlbinding">Makie.ablines!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`ablines!` is the mutating variant of plotting function `ablines`. Check the docstring for `ablines` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.activate_interaction!-Tuple{Any, Symbol}' href='#Makie.activate_interaction!-Tuple{Any, Symbol}'><span class="jlbinding">Makie.activate_interaction!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
activate_interaction!(parent, name::Symbol)
```


Activate the interaction named `name` registered in `parent`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/interactions.jl#L64-L68" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.addmouseevents!-Tuple{Any, Vararg{Any}}' href='#Makie.addmouseevents!-Tuple{Any, Vararg{Any}}'><span class="jlbinding">Makie.addmouseevents!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
addmouseevents!(scene, elements...)
```


Returns a `MouseEventHandle` with an observable inside which is triggered by all mouse interactions with the `scene` and optionally restricted to all given plot objects in `elements`.

To react to mouse events, use the onmouse... handlers.

Example:

```julia
mouseevents = addmouseevents!(scene, scatterplot)

onmouseleftclick(mouseevents) do event
    # do something with the mouseevent
end
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/mousestatemachine.jl#L104-L122" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.annotations' href='#Makie.annotations'><span class="jlbinding">Makie.annotations</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
annotations(strings::Vector{String}, positions::Vector{Point})
```


Plots an array of texts at each position in `positions`.

**Plot type**

The plot type alias for the `annotations` function is `Annotations`.

**Attributes**

**`align`** =  `(:left, :bottom)`  — Sets the alignment of the string w.r.t. `position`. Uses `:left, :center, :right, :top, :bottom, :baseline` or fractions.

**`alpha`** =  `1.0`  — The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`color`** =  `@inherit textcolor`  — Sets the color of the text. One can set one color per glyph by passing a `Vector{<:Colorant}`, or one colorant for the whole text. If color is a vector of numbers, the colormap args are used to map the numbers to colors.

**`colormap`** =  `@inherit colormap :viridis`  — Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

**`colorrange`** =  `automatic`  — The values representing the start and end points of `colormap`.

**`colorscale`** =  `identity`  — The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`font`** =  `@inherit font`  — Sets the font. Can be a `Symbol` which will be looked up in the `fonts` dictionary or a `String` specifying the (partial) name of a font or the file path of a font file

**`fonts`** =  `@inherit fonts`  — Used as a dictionary to look up fonts specified by `Symbol`, for example `:regular`, `:bold` or `:italic`.

**`fontsize`** =  `@inherit fontsize`  — The fontsize in units depending on `markerspace`.

**`fxaa`** =  `false`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`glowcolor`** =  `(:black, 0.0)`  — Sets the color of the glow effect around the text.

**`glowwidth`** =  `0.0`  — Sets the size of a glow effect around the text.

**`highclip`** =  `automatic`  — The color for any value above the colorrange.

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`justification`** =  `automatic`  — Sets the alignment of text w.r.t its bounding box. Can be `:left, :center, :right` or a fraction. Will default to the horizontal alignment in `align`.

**`lineheight`** =  `1.0`  — The lineheight multiplier.

**`lowclip`** =  `automatic`  — The color for any value below the colorrange.

**`markerspace`** =  `:pixel`  — Sets the space in which `fontsize` acts. See `Makie.spaces()` for possible inputs.

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`nan_color`** =  `:transparent`  — The color for NaN values.

**`offset`** =  `(0.0, 0.0)`  — The offset of the text from the given position in `markerspace` units.

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`position`** =  `(0.0, 0.0)`  — Deprecated: Specifies the position of the text. Use the positional argument to `text` instead.

**`rotation`** =  `0.0`  — Rotates text around the given position

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`strokecolor`** =  `(:black, 0.0)`  — Sets the color of the outline around a marker.

**`strokewidth`** =  `0`  — Sets the width of the outline around a marker.

**`text`** =  `""`  — Specifies one piece of text or a vector of texts to show, where the number has to match the number of positions given. Makie supports `String` which is used for all normal text and `LaTeXString` which layouts mathematical expressions using `MathTeXEngine.jl`.

**`transform_marker`** =  `false`  — Controls whether the model matrix (without translation) applies to the glyph itself, rather than just the positions. (If this is true, `scale!` and `rotate!` will affect the text glyphs.)

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.

**`word_wrap_width`** =  `-1`  — Specifies a linewidth limit for text. If a word overflows this limit, a newline is inserted before it. Negative numbers disable word wrapping.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L615" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.annotations!' href='#Makie.annotations!'><span class="jlbinding">Makie.annotations!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`annotations!` is the mutating variant of plotting function `annotations`. Check the docstring for `annotations` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.arc' href='#Makie.arc'><span class="jlbinding">Makie.arc</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
arc(origin, radius, start_angle, stop_angle; kwargs...)
```


This function plots a circular arc, centered at `origin` with radius `radius`, from `start_angle` to `stop_angle`. `origin` must be a coordinate in 2 dimensions (i.e., a `Point2`); the rest of the arguments must be `<: Number`.

Examples:

`arc(Point2f(0), 1, 0.0, π)` `arc(Point2f(1, 2), 0.3, π, -π)`

**Plot type**

The plot type alias for the `arc` function is `Arc`.

**Attributes**

**`alpha`** =  `1.0`  — The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`color`** =  `@inherit linecolor`  — The color of the line.

**`colormap`** =  `@inherit colormap :viridis`  — Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

**`colorrange`** =  `automatic`  — The values representing the start and end points of `colormap`.

**`colorscale`** =  `identity`  — The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.

**`cycle`** =  `[:color]`  — Sets which attributes to cycle when creating multiple plots.

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`fxaa`** =  `false`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`highclip`** =  `automatic`  — The color for any value above the colorrange.

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`joinstyle`** =  `@inherit joinstyle`  — Controls the rendering at corners. Options are `:miter` for sharp corners, `:bevel` for &quot;cut off&quot; corners, and `:round` for rounded corners. If the corner angle is below `miter_limit`, `:miter` is equivalent to `:bevel` to avoid long spikes.

**`linecap`** =  `@inherit linecap`  — Sets the type of line cap used. Options are `:butt` (flat without extrusion), `:square` (flat with half a linewidth extrusion) or `:round`.

**`linestyle`** =  `nothing`  — Sets the dash pattern of the line. Options are `:solid` (equivalent to `nothing`), `:dot`, `:dash`, `:dashdot` and `:dashdotdot`. These can also be given in a tuple with a gap style modifier, either `:normal`, `:dense` or `:loose`. For example, `(:dot, :loose)` or `(:dashdot, :dense)`.

For custom patterns have a look at [`Makie.Linestyle`](/api#Makie.Linestyle).

**`linewidth`** =  `@inherit linewidth`  — Sets the width of the line in screen units

**`lowclip`** =  `automatic`  — The color for any value below the colorrange.

**`miter_limit`** =  `@inherit miter_limit`  — Sets the minimum inner join angle below which miter joins truncate. See also `Makie.miter_distance_to_angle`.

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`nan_color`** =  `:transparent`  — The color for NaN values.

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`resolution`** =  `361`  — The number of line points approximating the arc.

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L609" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.arc!' href='#Makie.arc!'><span class="jlbinding">Makie.arc!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`arc!` is the mutating variant of plotting function `arc`. Check the docstring for `arc` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.autolimits!' href='#Makie.autolimits!'><span class="jlbinding">Makie.autolimits!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
autolimits!(ax::PolarAxis[, unlock_zoom = true])
```


Calling this tells the PolarAxis to derive limits freely from the plotted data, which allows rmin &gt; 0 and thetalimits spanning less than a full circle. If `unlock_zoom = true` this also unlocks zooming in r and theta direction and allows for translations in r direction.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/polaraxis.jl#L989-L996" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.autolimits!-Tuple{Axis}' href='#Makie.autolimits!-Tuple{Axis}'><span class="jlbinding">Makie.autolimits!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
autolimits!()
autolimits!(la::Axis)
```


Reset manually specified limits of `la` to an automatically determined rectangle, that depends on the data limits of all plot objects in the axis, as well as the autolimit margins for x and y axis. The argument `la` defaults to `current_axis()`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/axis.jl#L923-L929" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.available_gradients-Tuple{}' href='#Makie.available_gradients-Tuple{}'><span class="jlbinding">Makie.available_gradients</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
available_gradients()
```


Prints all available gradient names.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/conversions.jl#L1503-L1507" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.available_marker_symbols-Tuple{}' href='#Makie.available_marker_symbols-Tuple{}'><span class="jlbinding">Makie.available_marker_symbols</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
available_marker_symbols()
```


Displays all available marker symbols.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/conversions.jl#L1901-L1905" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.available_plotting_methods-Tuple{}' href='#Makie.available_plotting_methods-Tuple{}'><span class="jlbinding">Makie.available_plotting_methods</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
available_plotting_methods()
```


Returns an array of all available plotting functions.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/utilities/utilities.jl#L505-L509" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.axis3d-Tuple' href='#Makie.axis3d-Tuple'><span class="jlbinding">Makie.axis3d</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
axis3d(args; kw...)

```


Plots a 3-dimensional OldAxis.

**Attributes**

OldAxis attributes and their defaults for `Plot{Makie.axis3d}` are: 

```
    showaxis: (true, true, true)
    visible: true
    ticks: 
        rotation: (-0.7071067811865475 + -0.0im + -0.0jm - 0.7071067811865476km, -4.371139e-8 + 0.0im + 0.0jm + 1.0km, -3.090861907263062e-8 + 3.090861907263061e-8im + 0.7071067811865475jm + 0.7071067811865476km)
        font: (:regular, :regular, :regular)
        ranges_labels: (MakieCore.Automatic(), MakieCore.Automatic())
        formatter: plain
        textcolor: (RGBA{Float32}(0.5f0,0.5f0,0.5f0,0.6f0), RGBA{Float32}(0.5f0,0.5f0,0.5f0,0.6f0), RGBA{Float32}(0.5f0,0.5f0,0.5f0,0.6f0))
        fontsize: (5, 5, 5)
        align: ((:left, :center), (:right, :center), (:right, :center))
        gap: 3
    fonts: 
        bold: TeX Gyre Heros Makie Bold
        italic: TeX Gyre Heros Makie Italic
        bold_italic: TeX Gyre Heros Makie Bold Italic
        regular: TeX Gyre Heros Makie
    names: 
        axisnames: ("x", "y", "z")
        rotation: (-0.7071067811865475 + -0.0im + -0.0jm - 0.7071067811865476km, -4.371139e-8 + 0.0im + 0.0jm + 1.0km, -3.090861907263062e-8 + 3.090861907263061e-8im + 0.7071067811865475jm + 0.7071067811865476km)
        font: (:regular, :regular, :regular)
        textcolor: (:black, :black, :black)
        fontsize: (6.0, 6.0, 6.0)
        align: ((:left, :center), (:right, :center), (:right, :center))
        gap: 3
    scale: Float32[1.0, 1.0, 1.0]
    clip_planes: Plane3f[]
    showgrid: (true, true, true)
    padding: 0.1
    frame: 
        axiscolor: (:black, :black, :black)
        axislinewidth: (1.5, 1.5, 1.5)
        linewidth: (1, 1, 1)
        linecolor: (RGBA{Float32}(0.5f0,0.5f0,0.5f0,0.4f0), RGBA{Float32}(0.5f0,0.5f0,0.5f0,0.4f0), RGBA{Float32}(0.5f0,0.5f0,0.5f0,0.4f0))
    inspectable: false
    showticks: (true, true, true)
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/basic_recipes/axis.jl#L30-L37" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.axislegend-Tuple{Any, Vararg{Any}}' href='#Makie.axislegend-Tuple{Any, Vararg{Any}}'><span class="jlbinding">Makie.axislegend</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
axislegend(ax, args...; position = :rt, kwargs...)
axislegend(ax, args...; position = (1, 1), kwargs...)
axislegend(ax = current_axis(); kwargs...)
axislegend(title::AbstractString; kwargs...)
axislegend(ax, title::AbstractString; kwargs...)
```


Create a legend that sits inside an Axis&#39;s plot area.

The position can be a Symbol where the first letter controls the horizontal alignment and can be l, r or c, and the second letter controls the vertical alignment and can be t, b or c. Or it can be a tuple where the first element is set as the Legend&#39;s halign and the second element as its valign.

With the keywords merge and unique you can control how plot objects with the same labels are treated. If merge is true, all plot objects with the same label will be layered on top of each other into one legend entry. If unique is true, all plot objects with the same plot type and label will be reduced to one occurrence.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/legend.jl#L1029-L1048" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.band' href='#Makie.band'><span class="jlbinding">Makie.band</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
band(x, ylower, yupper; kwargs...)
band(lower, upper; kwargs...)
band(x, lowerupper; kwargs...)
```


Plots a band from `ylower` to `yupper` along `x`. The form `band(lower, upper)` plots a [ruled surface](https://en.wikipedia.org/wiki/Ruled_surface) between the points in `lower` and `upper`. Both bounds can be passed together as `lowerupper`, a vector of intervals.

**Plot type**

The plot type alias for the `band` function is `Band`.

**Attributes**

**`alpha`** =  `1.0`  — The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

**`backlight`** =  `0.0`  — Sets a weight for secondary light calculation with inverted normals.

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`color`** =  `@inherit patchcolor`  — Sets the color of the mesh. Can be a `Vector{<:Colorant}` for per vertex colors or a single `Colorant`. A `Matrix{<:Colorant}` can be used to color the mesh with a texture, which requires the mesh to contain texture coordinates. A `<: AbstractPattern` can be used to apply a repeated, pixel sampled pattern to the mesh, e.g. for hatching.

**`colormap`** =  `@inherit colormap :viridis`  — Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

**`colorrange`** =  `automatic`  — The values representing the start and end points of `colormap`.

**`colorscale`** =  `identity`  — The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.

**`cycle`** =  `[:color => :patchcolor]`  — _No docs available._

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`diffuse`** =  `1.0`  — Sets how strongly the red, green and blue channel react to diffuse (scattered) light.

**`direction`** =  `:x`  — The direction of the band. If set to `:y`, x and y coordinates will be flipped, resulting in a vertical band. This setting applies only to 2D bands.

**`fxaa`** =  `true`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`highclip`** =  `automatic`  — The color for any value above the colorrange.

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`interpolate`** =  `true`  — sets whether colors should be interpolated

**`lowclip`** =  `automatic`  — The color for any value below the colorrange.

**`matcap`** =  `nothing`  — _No docs available._

**`material`** =  `nothing`  — RPRMakie only attribute to set complex RadeonProRender materials.         _Warning_, how to set an RPR material may change and other backends will ignore this attribute

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`nan_color`** =  `:transparent`  — The color for NaN values.

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`shading`** =  `NoShading`  — Sets the lighting algorithm used. Options are `NoShading` (no lighting), `FastShading` (AmbientLight + PointLight) or `MultiLightShading` (Multiple lights, GLMakie only). Note that this does not affect RPRMakie.

**`shininess`** =  `32.0`  — Sets how sharp the reflection is.

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`specular`** =  `0.2`  — Sets how strongly the object reflects light in the red, green and blue channels.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`uv_transform`** =  `automatic`  — Sets a transform for uv coordinates, which controls how a texture is mapped to a mesh. The attribute can be `I`, `scale::VecTypes{2}`, `(translation::VecTypes{2}, scale::VecTypes{2})`, any of :rotr90, :rotl90, :rot180, :swap_xy/:transpose, :flip_x, :flip_y, :flip_xy, or most generally a `Makie.Mat{2, 3, Float32}` or `Makie.Mat3f` as returned by `Makie.uv_transform()`. They can also be changed by passing a tuple `(op3, op2, op1)`.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L615" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.band!' href='#Makie.band!'><span class="jlbinding">Makie.band!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`band!` is the mutating variant of plotting function `band`. Check the docstring for `band` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.barplot' href='#Makie.barplot'><span class="jlbinding">Makie.barplot</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
barplot(positions, heights; kwargs...)
```


Plots a barplot.

**Plot type**

The plot type alias for the `barplot` function is `BarPlot`.

**Attributes**

**`alpha`** =  `1.0`  — The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

**`bar_labels`** =  `nothing`  — Labels added at the end of each bar.

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`color`** =  `@inherit patchcolor`  — _No docs available._

**`color_over_background`** =  `automatic`  — _No docs available._

**`color_over_bar`** =  `automatic`  — _No docs available._

**`colormap`** =  `@inherit colormap :viridis`  — Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

**`colorrange`** =  `automatic`  — The values representing the start and end points of `colormap`.

**`colorscale`** =  `identity`  — The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.

**`cycle`** =  `[:color => :patchcolor]`  — _No docs available._

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`direction`** =  `:y`  — Controls the direction of the bars, can be `:y` (vertical) or `:x` (horizontal).

**`dodge`** =  `automatic`  — _No docs available._

**`dodge_gap`** =  `0.03`  — _No docs available._

**`fillto`** =  `automatic`  — Controls the baseline of the bars. This is zero in the default `automatic` case unless the barplot is in a log-scaled `Axis`. With a log scale, the automatic default is half the minimum value because zero is an invalid value for a log scale.

**`flip_labels_at`** =  `Inf`  — _No docs available._

**`fxaa`** =  `true`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`gap`** =  `0.2`  — The final width of the bars is calculated as `w * (1 - gap)` where `w` is the width of each bar as determined with the `width` attribute.

**`highclip`** =  `automatic`  — The color for any value above the colorrange.

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`label_align`** =  `automatic`  — _No docs available._

**`label_color`** =  `@inherit textcolor`  — _No docs available._

**`label_font`** =  `@inherit font`  — The font of the bar labels.

**`label_formatter`** =  `bar_label_formatter`  — _No docs available._

**`label_offset`** =  `5`  — The distance of the labels from the bar ends in screen units. Does not apply when `label_position = :center`.

**`label_position`** =  `:end`  — The position of each bar&#39;s label relative to the bar. Possible values are `:end` or `:center`.

**`label_rotation`** =  `0π`  — _No docs available._

**`label_size`** =  `@inherit fontsize`  — The font size of the bar labels.

**`lowclip`** =  `automatic`  — The color for any value below the colorrange.

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`n_dodge`** =  `automatic`  — _No docs available._

**`nan_color`** =  `:transparent`  — The color for NaN values.

**`offset`** =  `0.0`  — _No docs available._

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`stack`** =  `automatic`  — _No docs available._

**`strokecolor`** =  `@inherit patchstrokecolor`  — _No docs available._

**`strokewidth`** =  `@inherit patchstrokewidth`  — _No docs available._

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.

**`width`** =  `automatic`  — The gapless width of the bars. If `automatic`, the width `w` is calculated as `minimum(diff(sort(unique(positions)))`. The actual width of the bars is calculated as `w * (1 - gap)`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L635" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.barplot!' href='#Makie.barplot!'><span class="jlbinding">Makie.barplot!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`barplot!` is the mutating variant of plotting function `barplot`. Check the docstring for `barplot` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.boundingbox' href='#Makie.boundingbox'><span class="jlbinding">Makie.boundingbox</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
boundingbox(plot::AbstractPlot)
```


Returns the data space bounding box of a plot. This include `plot.transformation`, i.e. the `transform_func` and the `model` matrix.

See also: [`data_limits`](/api#Makie.data_limits)


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/layouting/boundingbox.jl#L25-L32" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.boundingbox-2' href='#Makie.boundingbox-2'><span class="jlbinding">Makie.boundingbox</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
boundingbox(scenelike[, exclude = plot -> false])
```


Returns the combined data space bounding box of all plots collected under `scenelike`. This include `plot.transformation`, i.e. the `transform_func` and the `model` matrix. Plots with `exclude(plot) == true` are excluded.

See also: [`data_limits`](/api#Makie.data_limits)


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/layouting/boundingbox.jl#L6-L14" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.boxplot' href='#Makie.boxplot'><span class="jlbinding">Makie.boxplot</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
boxplot(x, y; kwargs...)
```


Draw a Tukey style boxplot. The boxplot has 3 components:
- a `crossbar` spanning the interquartile (IQR) range with a midline marking the   median
  
- an `errorbar` whose whiskers span `range * iqr`
  
- points marking outliers, that is, data outside the whiskers
  

**Arguments**
- `x`: positions of the categories
  
- `y`: variables within the boxes
  

**Plot type**

The plot type alias for the `boxplot` function is `BoxPlot`.

**Attributes**

**`color`** =  `@inherit patchcolor`  — _No docs available._

**`colormap`** =  `@inherit colormap`  — _No docs available._

**`colorrange`** =  `automatic`  — _No docs available._

**`colorscale`** =  `identity`  — _No docs available._

**`cycle`** =  `[:color => :patchcolor]`  — _No docs available._

**`dodge`** =  `automatic`  — Vector of `Integer` (length of data) of grouping variable to create multiple side-by-side boxes at the same `x` position.

**`dodge_gap`** =  `0.03`  — Spacing between dodged boxes.

**`gap`** =  `0.2`  — Shrinking factor, `width -> width * (1 - gap)`.

**`inspectable`** =  `@inherit inspectable`  — _No docs available._

**`marker`** =  `@inherit marker`  — _No docs available._

**`markersize`** =  `@inherit markersize`  — _No docs available._

**`mediancolor`** =  `@inherit linecolor`  — _No docs available._

**`medianlinewidth`** =  `@inherit linewidth`  — _No docs available._

**`n_dodge`** =  `automatic`  — _No docs available._

**`notchwidth`** =  `0.5`  — Multiplier of `width` for narrowest width of notch.

**`orientation`** =  `:vertical`  — Orientation of box (`:vertical` or `:horizontal`).

**`outliercolor`** =  `automatic`  — _No docs available._

**`outlierstrokecolor`** =  `@inherit markerstrokecolor`  — _No docs available._

**`outlierstrokewidth`** =  `@inherit markerstrokewidth`  — _No docs available._

**`range`** =  `1.5`  — Multiple of IQR controlling whisker length.

**`show_median`** =  `true`  — Show median as midline.

**`show_notch`** =  `false`  — Draw the notch.

**`show_outliers`** =  `true`  — Show outliers as points.

**`strokecolor`** =  `@inherit patchstrokecolor`  — _No docs available._

**`strokewidth`** =  `@inherit patchstrokewidth`  — _No docs available._

**`weights`** =  `automatic`  — Vector of statistical weights (length of data). By default, each observation has weight `1`.

**`whiskercolor`** =  `@inherit linecolor`  — _No docs available._

**`whiskerlinewidth`** =  `@inherit linewidth`  — _No docs available._

**`whiskerwidth`** =  `0.0`  — Multiplier of `width` for width of T&#39;s on whiskers, or `:match` to match `width`.

**`width`** =  `automatic`  — Width of the box before shrinking.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L599" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.boxplot!' href='#Makie.boxplot!'><span class="jlbinding">Makie.boxplot!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`boxplot!` is the mutating variant of plotting function `boxplot`. Check the docstring for `boxplot` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.bracket' href='#Makie.bracket'><span class="jlbinding">Makie.bracket</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
bracket(x1, y1, x2, y2; kwargs...)
bracket(x1s, y1s, x2s, y2s; kwargs...)
bracket(point1, point2; kwargs...)
bracket(vec_of_point_tuples; kwargs...)
```


Draws a bracket between each pair of points (x1, y1) and (x2, y2) with a text label at the midpoint.

By default each label is rotated parallel to the line between the bracket points.

**Plot type**

The plot type alias for the `bracket` function is `Bracket`.

**Attributes**

**`align`** =  `(:center, :center)`  — _No docs available._

**`color`** =  `@inherit linecolor`  — _No docs available._

**`font`** =  `@inherit font`  — _No docs available._

**`fontsize`** =  `@inherit fontsize`  — _No docs available._

**`joinstyle`** =  `@inherit joinstyle`  — _No docs available._

**`justification`** =  `automatic`  — _No docs available._

**`linecap`** =  `@inherit linecap`  — _No docs available._

**`linestyle`** =  `:solid`  — _No docs available._

**`linewidth`** =  `@inherit linewidth`  — _No docs available._

**`miter_limit`** =  `@inherit miter_limit`  — _No docs available._

**`offset`** =  `0`  — The offset of the bracket perpendicular to the line from start to end point in screen units.     The direction depends on the `orientation` attribute.

**`orientation`** =  `:up`  — Which way the bracket extends relative to the line from start to end point. Can be `:up` or `:down`.

**`rotation`** =  `automatic`  — _No docs available._

**`style`** =  `:curly`  — _No docs available._

**`text`** =  `""`  — _No docs available._

**`textcolor`** =  `@inherit textcolor`  — _No docs available._

**`textoffset`** =  `automatic`  — _No docs available._

**`width`** =  `15`  — The width of the bracket (perpendicularly away from the line from start to end point) in screen units.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L573" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.bracket!' href='#Makie.bracket!'><span class="jlbinding">Makie.bracket!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`bracket!` is the mutating variant of plotting function `bracket`. Check the docstring for `bracket` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.broadcast_foreach-Tuple{Any, Vararg{Any}}' href='#Makie.broadcast_foreach-Tuple{Any, Vararg{Any}}'><span class="jlbinding">Makie.broadcast_foreach</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
broadcast_foreach(f, args...)
```


Like broadcast but for foreach. Doesn&#39;t care about shape and treats Tuples &amp;&amp; StaticVectors as scalars. This method is meant for broadcasting across attributes that can either have scalar or vector / array form. An example would be a collection of scatter markers that have different sizes but a single color. The length of an attribute is determined with `attr_broadcast_length` and elements are accessed with `attr_broadcast_getindex`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/utilities/utilities.jl#L190-L198" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.cam2d!-Tuple{Union{AbstractScene, MakieCore.ScenePlot}}' href='#Makie.cam2d!-Tuple{Union{AbstractScene, MakieCore.ScenePlot}}'><span class="jlbinding">Makie.cam2d!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
cam2d!(scene::SceneLike, kwargs...)
```


Creates a 2D camera for the given `scene`. The camera implements zooming by scrolling and translation using mouse drag. It also implements rectangle selections.

**Keyword Arguments**
- `zoomspeed = 0.1` sets the zoom speed.
  
- `zoombutton = true` sets a button (combination) which needs to be pressed to enable zooming. By default no button needs to be pressed.
  
- `panbutton = Mouse.right` sets the button used to translate the camera. This must include a mouse button.
  
- `selectionbutton = (Keyboard.space, Mouse.left)` sets the button used for rectangle selection. This must include a mouse button.
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/camera/camera2d.jl#L11-L24" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.cam2d-Tuple{Scene}' href='#Makie.cam2d-Tuple{Scene}'><span class="jlbinding">Makie.cam2d</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



Creates a subscene with a pixel camera


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/scenes.jl#L410-L412" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.cam3d!-Tuple{Any}' href='#Makie.cam3d!-Tuple{Any}'><span class="jlbinding">Makie.cam3d!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
cam3d!(scene[; kwargs...])
```


Creates a `Camera3D` with `zoom_shift_lookat = true` and `fixed_axis = true`. For more information, see [`Camera3D`](/explanations/cameras#Makie.Camera3D)


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/camera/camera3d.jl#L257-L262" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.cam3d_cad!-Tuple{Any}' href='#Makie.cam3d_cad!-Tuple{Any}'><span class="jlbinding">Makie.cam3d_cad!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
cam3d_cad!(scene[; kwargs...])
```


Creates a `Camera3D` with `cad = true`, `zoom_shift_lookat = false` and `fixed_axis = false`. For more information, see [`Camera3D`](/explanations/cameras#Makie.Camera3D)


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/camera/camera3d.jl#L266-L271" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.cam_relative!-Tuple{Scene}' href='#Makie.cam_relative!-Tuple{Scene}'><span class="jlbinding">Makie.cam_relative!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
cam_relative!(scene)
```


Creates a camera for the given `scene` which maps the scene area to a 0..1 by 0..1 range. This camera does not feature controls.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/camera/camera2d.jl#L361-L366" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.campixel!-Tuple{Scene}' href='#Makie.campixel!-Tuple{Scene}'><span class="jlbinding">Makie.campixel!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
campixel!(scene; nearclip=-1000.0, farclip=1000.0)
```


Creates a pixel camera for the given `scene`. This means that the positional data of a plot will be interpreted in pixel units. This camera does not feature controls.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/camera/camera2d.jl#L337-L343" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.categorical_colors-Tuple{AbstractVector{<:ColorTypes.Colorant}, Integer}' href='#Makie.categorical_colors-Tuple{AbstractVector{<:ColorTypes.Colorant}, Integer}'><span class="jlbinding">Makie.categorical_colors</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
categorical_colors(colormaplike, categories::Integer)
```


Creates categorical colors and tries to match `categories`. Will error if color scheme doesn&#39;t contain enough categories. Will drop the n last colors, if request less colors than contained in scheme.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/conversions.jl#L1518-L1523" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.colorbuffer' href='#Makie.colorbuffer'><span class="jlbinding">Makie.colorbuffer</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
colorbuffer(scene, format::ImageStorageFormat = JuliaNative; update=true, backend=current_backend(), screen_config...)
```


Returns the content of the given scene or screen rasterised to a Matrix of Colors. The return type is backend-dependent, but will be some form of RGB or RGBA.
- `backend::Module`: A module which is a Makie backend.  For example, `backend = GLMakie`, `backend = CairoMakie`, etc.
  
- `format = JuliaNative` : Returns a buffer in the format of standard julia images (dims permuted and one reversed)
  
- `format = GLNative` : Returns a more efficient format buffer for GLMakie which can be directly                       used in FFMPEG without conversion
  
- `screen_config`: Backend dependent, look up via `?Backend.Screen`/`Base.doc(Backend.Screen)`
  
- `update=true`: resets/updates limits. Set to false, if you want to preserver camera movements.
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/display.jl#L452-L465" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.colorbuffer-Tuple{Axis}' href='#Makie.colorbuffer-Tuple{Axis}'><span class="jlbinding">Makie.colorbuffer</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
colorbuffer(ax::Axis; include_decorations=true, colorbuffer_kws...)
```


Gets the colorbuffer of the `Axis` in `JuliaNative` image format. If `include_decorations=false`, only the inside of the axis is fetched.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/axis.jl#L1983-L1988" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.contour' href='#Makie.contour'><span class="jlbinding">Makie.contour</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
contour(x, y, z)
contour(z::Matrix)
```


Creates a contour plot of the plane spanning `x::Vector`, `y::Vector`, `z::Matrix`. If only `z::Matrix` is supplied, the indices of the elements in `z` will be used as the `x` and `y` locations when plotting the contour.

`x` and `y` can also be Matrices that define a curvilinear grid, similar to how [`surface`](/reference/plots/surface#surface) works.

**Plot type**

The plot type alias for the `contour` function is `Contour`.

**Attributes**

**`alpha`** =  `1.0`  — The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`color`** =  `nothing`  — The color of the contour lines. If `nothing`, the color is determined by the numerical values of the contour levels in combination with `colormap` and `colorrange`.

**`colormap`** =  `@inherit colormap :viridis`  — Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

**`colorrange`** =  `automatic`  — The values representing the start and end points of `colormap`.

**`colorscale`** =  `identity`  — The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`enable_depth`** =  `true`  — _No docs available._

**`fxaa`** =  `true`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`highclip`** =  `automatic`  — The color for any value above the colorrange.

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`joinstyle`** =  `@inherit joinstyle`  — _No docs available._

**`labelcolor`** =  `nothing`  — Color of the contour labels, if `nothing` it matches `color` by default.

**`labelfont`** =  `@inherit font`  — The font of the contour labels.

**`labelformatter`** =  `contour_label_formatter`  — Formats the numeric values of the contour levels to strings.

**`labels`** =  `false`  — If `true`, adds text labels to the contour lines.

**`labelsize`** =  `10`  — Font size of the contour labels

**`levels`** =  `5`  — Controls the number and location of the contour lines. Can be either
- an `Int` that produces n equally wide levels or bands
  
- an `AbstractVector{<:Real}` that lists n consecutive edges from low to high, which result in n-1 levels or bands
  

**`linecap`** =  `@inherit linecap`  — _No docs available._

**`linestyle`** =  `nothing`  — _No docs available._

**`linewidth`** =  `1.0`  — _No docs available._

**`lowclip`** =  `automatic`  — The color for any value below the colorrange.

**`miter_limit`** =  `@inherit miter_limit`  — _No docs available._

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`nan_color`** =  `:transparent`  — The color for NaN values.

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L616" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.contour!' href='#Makie.contour!'><span class="jlbinding">Makie.contour!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`contour!` is the mutating variant of plotting function `contour`. Check the docstring for `contour` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.contour3d' href='#Makie.contour3d'><span class="jlbinding">Makie.contour3d</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
contour3d(x, y, z)
```


Creates a 3D contour plot of the plane spanning x::Vector, y::Vector, z::Matrix, with z-elevation for each level.

**Plot type**

The plot type alias for the `contour3d` function is `Contour3d`.

**Attributes**

**`alpha`** =  `1.0`  — The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`color`** =  `nothing`  — The color of the contour lines. If `nothing`, the color is determined by the numerical values of the contour levels in combination with `colormap` and `colorrange`.

**`colormap`** =  `@inherit colormap :viridis`  — Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

**`colorrange`** =  `automatic`  — The values representing the start and end points of `colormap`.

**`colorscale`** =  `identity`  — The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`enable_depth`** =  `true`  — _No docs available._

**`fxaa`** =  `true`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`highclip`** =  `automatic`  — The color for any value above the colorrange.

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`joinstyle`** =  `@inherit joinstyle`  — _No docs available._

**`labelcolor`** =  `nothing`  — Color of the contour labels, if `nothing` it matches `color` by default.

**`labelfont`** =  `@inherit font`  — The font of the contour labels.

**`labelformatter`** =  `contour_label_formatter`  — Formats the numeric values of the contour levels to strings.

**`labels`** =  `false`  — If `true`, adds text labels to the contour lines.

**`labelsize`** =  `10`  — Font size of the contour labels

**`levels`** =  `5`  — Controls the number and location of the contour lines. Can be either
- an `Int` that produces n equally wide levels or bands
  
- an `AbstractVector{<:Real}` that lists n consecutive edges from low to high, which result in n-1 levels or bands
  

**`linecap`** =  `@inherit linecap`  — _No docs available._

**`linestyle`** =  `nothing`  — _No docs available._

**`linewidth`** =  `1.0`  — _No docs available._

**`lowclip`** =  `automatic`  — The color for any value below the colorrange.

**`miter_limit`** =  `@inherit miter_limit`  — _No docs available._

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`nan_color`** =  `:transparent`  — The color for NaN values.

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L613" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.contour3d!' href='#Makie.contour3d!'><span class="jlbinding">Makie.contour3d!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`contour3d!` is the mutating variant of plotting function `contour3d`. Check the docstring for `contour3d` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.contourf' href='#Makie.contourf'><span class="jlbinding">Makie.contourf</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
contourf(xs, ys, zs; kwargs...)
```


Plots a filled contour of the height information in `zs` at horizontal grid positions `xs` and vertical grid positions `ys`.

`xs` and `ys` can be vectors for rectilinear grids or matrices for curvilinear grids, similar to how [`surface`](/reference/plots/surface#surface) works.

**Plot type**

The plot type alias for the `contourf` function is `Contourf`.

**Attributes**

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`colormap`** =  `@inherit colormap`  — _No docs available._

**`colorscale`** =  `identity`  — _No docs available._

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`extendhigh`** =  `nothing`  — In `:normal` mode, if you want to show a band from the high edge to `Inf`, set `extendhigh` to `:auto` to give the extension the same color as the last level, or specify a color directly (default `nothing` means no extended band).

**`extendlow`** =  `nothing`  — In `:normal` mode, if you want to show a band from `-Inf` to the low edge, set `extendlow` to `:auto` to give the extension the same color as the first level, or specify a color directly (default `nothing` means no extended band).

**`fxaa`** =  `true`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`levels`** =  `10`  — Can be either
- an `Int` that produces n equally wide levels or bands
  
- an `AbstractVector{<:Real}` that lists n consecutive edges from low to high, which result in n-1 levels or bands
  

If `levels` is an `Int`, the contourf plot will be rectangular as all `zs` values will be covered edge to edge. This is why `Axis` defaults to tight limits for such contourf plots. If you specify `levels` as an `AbstractVector{<:Real}`, however, note that the axis limits include the default margins because the contourf plot can have an irregular shape. You can use `tightlimits!(ax)` to tighten the limits similar to the `Int` behavior.

**`mode`** =  `:normal`  — Determines how the `levels` attribute is interpreted, either `:normal` or `:relative`. In `:normal` mode, the levels correspond directly to the z values. In `:relative` mode, you specify edges by the fraction between minimum and maximum value of `zs`. This can be used for example to draw bands for the upper 90% while excluding the lower 10% with `levels = 0.1:0.1:1.0, mode = :relative`.

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`nan_color`** =  `:transparent`  — _No docs available._

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L595" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.contourf!' href='#Makie.contourf!'><span class="jlbinding">Makie.contourf!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`contourf!` is the mutating variant of plotting function `contourf`. Check the docstring for `contourf` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.crossbar' href='#Makie.crossbar'><span class="jlbinding">Makie.crossbar</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
crossbar(x, y, ymin, ymax; kwargs...)
```


Draw a crossbar. A crossbar represents a range with a (potentially notched) box. It is most commonly used as part of the `boxplot`.

**Arguments**
- `x`: position of the box
  
- `y`: position of the midline within the box
  
- `ymin`: lower limit of the box
  
- `ymax`: upper limit of the box
  

**Plot type**

The plot type alias for the `crossbar` function is `CrossBar`.

**Attributes**

**`color`** =  `@inherit patchcolor`  — _No docs available._

**`colormap`** =  `@inherit colormap`  — _No docs available._

**`colorrange`** =  `automatic`  — _No docs available._

**`colorscale`** =  `identity`  — _No docs available._

**`cycle`** =  `[:color => :patchcolor]`  — _No docs available._

**`dodge`** =  `automatic`  — _No docs available._

**`dodge_gap`** =  `0.03`  — _No docs available._

**`gap`** =  `0.2`  — Shrinking factor, `width -> width * (1 - gap)`.

**`inspectable`** =  `@inherit inspectable`  — _No docs available._

**`midlinecolor`** =  `automatic`  — _No docs available._

**`midlinewidth`** =  `@inherit linewidth`  — _No docs available._

**`n_dodge`** =  `automatic`  — _No docs available._

**`notchmax`** =  `automatic`  — Upper limit of the notch.

**`notchmin`** =  `automatic`  — Lower limit of the notch.

**`notchwidth`** =  `0.5`  — Multiplier of `width` for narrowest width of notch.

**`orientation`** =  `:vertical`  — Orientation of box (`:vertical` or `:horizontal`).

**`show_midline`** =  `true`  — Show midline.

**`show_notch`** =  `false`  — Whether to draw the notch.

**`strokecolor`** =  `@inherit patchstrokecolor`  — _No docs available._

**`strokewidth`** =  `@inherit patchstrokewidth`  — _No docs available._

**`width`** =  `automatic`  — Width of the box before shrinking.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L579" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.crossbar!' href='#Makie.crossbar!'><span class="jlbinding">Makie.crossbar!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`crossbar!` is the mutating variant of plotting function `crossbar`. Check the docstring for `crossbar` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.current_axis!-Tuple{Any}' href='#Makie.current_axis!-Tuple{Any}'><span class="jlbinding">Makie.current_axis!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
current_axis!(ax)
```


Set an axis `ax`, which must be part of a figure, as the figure&#39;s current active axis.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/figures.jl#L77-L81" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.current_axis!-Tuple{Figure, Any}' href='#Makie.current_axis!-Tuple{Figure, Any}'><span class="jlbinding">Makie.current_axis!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
current_axis!(fig::Figure, ax)
```


Set `ax` as the current active axis in `fig`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/figures.jl#L60-L64" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.current_axis-Tuple{}' href='#Makie.current_axis-Tuple{}'><span class="jlbinding">Makie.current_axis</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
current_axis()
```


Returns the current active axis (or the last axis created). Returns `nothing` if there is no current active axis.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/figures.jl#L52-L56" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.current_figure!-Tuple{Any}' href='#Makie.current_figure!-Tuple{Any}'><span class="jlbinding">Makie.current_figure!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
current_figure!(fig)
```


Set `fig` as the current active figure.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/figures.jl#L45-L49" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.current_figure-Tuple{}' href='#Makie.current_figure-Tuple{}'><span class="jlbinding">Makie.current_figure</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
current_figure()
```


Returns the current active figure (or the last figure created). Returns `nothing` if there is no current active figure.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/figures.jl#L37-L42" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.data_limits' href='#Makie.data_limits'><span class="jlbinding">Makie.data_limits</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
data_limits(scenelike[, exclude = plot -> false])
```


Returns the combined data limits of all plots collected under `scenelike` for which `exclude(plot) == false`. This is solely based on the positional data of a plot and thus does not include any transformations.

See also: [`boundingbox`](/api#Makie.boundingbox)


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/layouting/data_limits.jl#L16-L24" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.data_limits-Tuple{AbstractPlot}' href='#Makie.data_limits-Tuple{AbstractPlot}'><span class="jlbinding">Makie.data_limits</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
data_limits(plot::AbstractPlot)
```


Returns the bounding box of a plot based on just its position data.

See also: [`boundingbox`](/api#Makie.boundingbox)


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/layouting/data_limits.jl#L35-L41" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.datashader' href='#Makie.datashader'><span class="jlbinding">Makie.datashader</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
datashader(points::AbstractVector{<: Point})
```


::: warning Warning

This feature might change outside breaking releases, since the API is not yet finalized. Please be wary of bugs in the implementation and open issues if you encounter odd behaviour.

:::

Points can be any array type supporting iteration &amp; getindex, including memory mapped arrays. If you have separate arrays for x and y coordinates and want to avoid conversion and copy, consider using:

```Julia
using Makie.StructArrays
points = StructArray{Point2f}((x, y))
datashader(points)
```


Do pay attention though, that if x and y don&#39;t have a fast iteration/getindex implemented, this might be slower than just copying the data into a new array.

For best performance, use `method=Makie.AggThreads()` and make sure to start julia with `julia -tauto` or have the environment variable `JULIA_NUM_THREADS` set to the number of cores you have.

**Plot type**

The plot type alias for the `datashader` function is `DataShader`.

**Attributes**

**`agg`** =  `AggCount{Float32}()`  — Can be `AggCount()`, `AggAny()` or `AggMean()`. Be sure, to use the correct element type e.g. `AggCount{Float32}()`, which needs to accommodate the output of `local_operation`. User-extensible by overloading:

```julia
struct MyAgg{T} <: Makie.AggOp end
MyAgg() = MyAgg{Float64}()
Makie.Aggregation.null(::MyAgg{T}) where {T} = zero(T)
Makie.Aggregation.embed(::MyAgg{T}, x) where {T} = convert(T, x)
Makie.Aggregation.merge(::MyAgg{T}, x::T, y::T) where {T} = x + y
Makie.Aggregation.value(::MyAgg{T}, x::T) where {T} = x
```


**`alpha`** =  `1.0`  — The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

**`async`** =  `true`  — Will calculate `get_aggregation` in a task, and skip any zoom/pan updates while busy. Great for interaction, but must be disabled for saving to e.g. png or when inlining in Documenter.

**`binsize`** =  `1`  — Factor defining how many bins one wants per screen pixel. Set to n &gt; 1 if you want a coarser image.

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`colormap`** =  `@inherit colormap :viridis`  — Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

**`colorrange`** =  `automatic`  — The values representing the start and end points of `colormap`.

**`colorscale`** =  `identity`  — The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`fxaa`** =  `true`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`highclip`** =  `automatic`  — The color for any value above the colorrange.

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`interpolate`** =  `false`  — If the resulting image should be displayed interpolated. Note that interpolation can make NaN-adjacent bins also NaN in some backends, for example due to interpolation schemes used in GPU hardware. This can make it look like there are more NaN bins than there actually are.

**`local_operation`** =  `identity`  — Function which gets called on each element after the aggregation (`map!(x-> local_operation(x), final_aggregation_result)`).

**`lowclip`** =  `automatic`  — The color for any value below the colorrange.

**`method`** =  `AggThreads()`  — Can be `AggThreads()` or `AggSerial()` for threaded vs. serial aggregation.

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`nan_color`** =  `:transparent`  — The color for NaN values.

**`operation`** =  `automatic`  — Defaults to `Makie.equalize_histogram` function which gets called on the whole get_aggregation array before display (`operation(final_aggregation_result)`).

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`point_transform`** =  `identity`  — Function which gets applied to every point before aggregating it.

**`show_timings`** =  `false`  — Set to `true` to show how long it takes to aggregate each frame.

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L633" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.datashader!' href='#Makie.datashader!'><span class="jlbinding">Makie.datashader!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`datashader!` is the mutating variant of plotting function `datashader`. Check the docstring for `datashader` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.deactivate_interaction!-Tuple{Any, Symbol}' href='#Makie.deactivate_interaction!-Tuple{Any, Symbol}'><span class="jlbinding">Makie.deactivate_interaction!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
deactivate_interaction!(parent, name::Symbol)
```


Deactivate the interaction named `name` registered in `parent`. It can be reactivated with `activate_interaction!`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/interactions.jl#L75-L80" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.density' href='#Makie.density'><span class="jlbinding">Makie.density</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
density(values)
```


Plot a kernel density estimate of `values`.

**Plot type**

The plot type alias for the `density` function is `Density`.

**Attributes**

**`alpha`** =  `1.0`  — The alpha value of the colormap or color attribute. Multiple alphas like in plot(alpha=0.2, color=(:red, 0.5), will get multiplied.

**`bandwidth`** =  `automatic`  — Kernel density bandwidth, determined automatically if `automatic`.

**`boundary`** =  `automatic`  — Boundary of the density estimation, determined automatically if `automatic`.

**`color`** =  `@inherit patchcolor`  — Usually set to a single color, but can also be set to `:x` or `:y` to color with a gradient. If you use `:y` when `direction = :x` (or vice versa), note that only 2-element colormaps can work correctly.

**`colormap`** =  `@inherit colormap`  — _No docs available._

**`colorrange`** =  `Makie.automatic`  — _No docs available._

**`colorscale`** =  `identity`  — _No docs available._

**`cycle`** =  `[:color => :patchcolor]`  — _No docs available._

**`direction`** =  `:x`  — The dimension along which the `values` are distributed. Can be `:x` or `:y`.

**`inspectable`** =  `@inherit inspectable`  — _No docs available._

**`linestyle`** =  `nothing`  — _No docs available._

**`npoints`** =  `200`  — The resolution of the estimated curve along the dimension set in `direction`.

**`offset`** =  `0.0`  — Shift the density baseline, for layering multiple densities on top of each other.

**`strokearound`** =  `false`  — _No docs available._

**`strokecolor`** =  `@inherit patchstrokecolor`  — _No docs available._

**`strokewidth`** =  `@inherit patchstrokewidth`  — _No docs available._

**`weights`** =  `automatic`  — Assign a vector of statistical weights to `values`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L569" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.density!' href='#Makie.density!'><span class="jlbinding">Makie.density!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`density!` is the mutating variant of plotting function `density`. Check the docstring for `density` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.deregister_interaction!-Tuple{Any, Symbol}' href='#Makie.deregister_interaction!-Tuple{Any, Symbol}'><span class="jlbinding">Makie.deregister_interaction!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
deregister_interaction!(parent, name::Symbol)
```


Deregister the interaction named `name` registered in `parent`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/interactions.jl#L42-L46" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.ecdfplot' href='#Makie.ecdfplot'><span class="jlbinding">Makie.ecdfplot</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
ecdfplot(values; npoints=10_000[, weights])
```


Plot the empirical cumulative distribution function (ECDF) of `values`.

`npoints` controls the resolution of the plot. If `weights` for the values are provided, a weighted ECDF is plotted.

**Plot type**

The plot type alias for the `ecdfplot` function is `ECDFPlot`.

**Attributes**

**`alpha`** =  `1.0`  — The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`color`** =  `@inherit linecolor`  — The color of the line.

**`colormap`** =  `@inherit colormap :viridis`  — Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

**`colorrange`** =  `automatic`  — The values representing the start and end points of `colormap`.

**`colorscale`** =  `identity`  — The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.

**`cycle`** =  `[:color]`  — Sets which attributes to cycle when creating multiple plots.

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`fxaa`** =  `false`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`highclip`** =  `automatic`  — The color for any value above the colorrange.

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`joinstyle`** =  `@inherit joinstyle`  — Controls the rendering at corners. Options are `:miter` for sharp corners, `:bevel` for &quot;cut off&quot; corners, and `:round` for rounded corners. If the corner angle is below `miter_limit`, `:miter` is equivalent to `:bevel` to avoid long spikes.

**`linecap`** =  `@inherit linecap`  — Sets the type of line cap used. Options are `:butt` (flat without extrusion), `:square` (flat with half a linewidth extrusion) or `:round`.

**`linestyle`** =  `nothing`  — Sets the dash pattern of the line. Options are `:solid` (equivalent to `nothing`), `:dot`, `:dash`, `:dashdot` and `:dashdotdot`. These can also be given in a tuple with a gap style modifier, either `:normal`, `:dense` or `:loose`. For example, `(:dot, :loose)` or `(:dashdot, :dense)`.

For custom patterns have a look at [`Makie.Linestyle`](/api#Makie.Linestyle).

**`linewidth`** =  `@inherit linewidth`  — Sets the width of the line in screen units

**`lowclip`** =  `automatic`  — The color for any value below the colorrange.

**`miter_limit`** =  `@inherit miter_limit`  — Sets the minimum inner join angle below which miter joins truncate. See also `Makie.miter_distance_to_angle`.

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`nan_color`** =  `:transparent`  — The color for NaN values.

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`step`** =  `:pre`  — The `step` parameter can take the following values:
- `:pre`: horizontal part of step extends to the left of each value in `xs`.
  
- `:post`: horizontal part of step extends to the right of each value in `xs`.
  
- `:center`: horizontal part of step extends halfway between the two adjacent values of `xs`.
  

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L611" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.ecdfplot!' href='#Makie.ecdfplot!'><span class="jlbinding">Makie.ecdfplot!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`ecdfplot!` is the mutating variant of plotting function `ecdfplot`. Check the docstring for `ecdfplot` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.errorbars' href='#Makie.errorbars'><span class="jlbinding">Makie.errorbars</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
errorbars(x, y, error_both; kwargs...)
errorbars(x, y, error_low, error_high; kwargs...)
errorbars(x, y, error_low_high; kwargs...)

errorbars(xy, error_both; kwargs...)
errorbars(xy, error_low, error_high; kwargs...)
errorbars(xy, error_low_high; kwargs...)

errorbars(xy_error_both; kwargs...)
errorbars(xy_error_low_high; kwargs...)
```


Plots errorbars at xy positions, extending by errors in the given `direction`.

If you want to plot intervals from low to high values instead of relative errors, use `rangebars`.

**Plot type**

The plot type alias for the `errorbars` function is `Errorbars`.

**Attributes**

**`alpha`** =  `1.0`  — The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`color`** =  `@inherit linecolor`  — The color of the lines. Can be an array to color each bar separately.

**`colormap`** =  `@inherit colormap :viridis`  — Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

**`colorrange`** =  `automatic`  — The values representing the start and end points of `colormap`.

**`colorscale`** =  `identity`  — The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.

**`cycle`** =  `[:color]`  — _No docs available._

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`direction`** =  `:y`  — The direction in which the bars are drawn. Can be `:x` or `:y`.

**`fxaa`** =  `true`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`highclip`** =  `automatic`  — The color for any value above the colorrange.

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`linecap`** =  `@inherit linecap`  — _No docs available._

**`linewidth`** =  `@inherit linewidth`  — The thickness of the lines in screen units.

**`lowclip`** =  `automatic`  — The color for any value below the colorrange.

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`nan_color`** =  `:transparent`  — The color for NaN values.

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.

**`whiskerwidth`** =  `0`  — The width of the whiskers or line caps in screen units.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L602" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.errorbars!' href='#Makie.errorbars!'><span class="jlbinding">Makie.errorbars!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`errorbars!` is the mutating variant of plotting function `errorbars`. Check the docstring for `errorbars` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.fill_between!-NTuple{4, Any}' href='#Makie.fill_between!-NTuple{4, Any}'><span class="jlbinding">Makie.fill_between!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
fill_between!(scenelike, x, y1, y2; where = nothing, kw_args...)
```


fill the section between 2 lines with the condition `where`


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/basic_recipes/band.jl#L87-L91" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.help-Tuple{Any}' href='#Makie.help-Tuple{Any}'><span class="jlbinding">Makie.help</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
help(func[; extended = false])
```


Welcome to the main help function of `Makie.jl` / `Makie.jl`.

For help on a specific function&#39;s arguments, type `help_arguments(function_name)`.

For help on a specific function&#39;s attributes, type `help_attributes(plot_Type)`.

Use the optional `extended = true` keyword argument to see more details.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/documentation/documentation.jl#L4-L14" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.help_arguments-Tuple{Any}' href='#Makie.help_arguments-Tuple{Any}'><span class="jlbinding">Makie.help_arguments</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
help_arguments([io], func)
```


Returns a list of signatures for function `func`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/documentation/documentation.jl#L54-L58" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.help_attributes-Tuple{Any}' href='#Makie.help_attributes-Tuple{Any}'><span class="jlbinding">Makie.help_attributes</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
help_attributes([io], Union{PlotType, PlotFunction}; extended = false)
```


Returns a list of attributes for the plot type `Typ`. The attributes returned extend those attributes found in the `default_theme`.

Use the optional keyword argument `extended` (default = `false`) to show in addition the default values of each attribute. usage:

```julia
>help_attributes(scatter)
    alpha
    color
    colormap
    colorrange
    distancefield
    glowcolor
    glowwidth
    linewidth
    marker
    marker_offset
    markersize
    overdraw
    rotations
    strokecolor
    strokewidth
    transform_marker
    transparency
    uv_offset_width
    visible
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/documentation/documentation.jl#L73-L104" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.hexbin' href='#Makie.hexbin'><span class="jlbinding">Makie.hexbin</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
hexbin(xs, ys; kwargs...)
```


Plots a heatmap with hexagonal bins for the observations `xs` and `ys`.

**Plot type**

The plot type alias for the `hexbin` function is `Hexbin`.

**Attributes**

**`alpha`** =  `1.0`  — The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

**`bins`** =  `20`  — If an `Int`, sets the number of bins in x and y direction. If a `NTuple{2, Int}`, sets the number of bins for x and y separately.

**`cellsize`** =  `nothing`  — If a `Real`, makes equally-sided hexagons with width `cellsize`. If a `Tuple{Real, Real}` specifies hexagon width and height separately.

**`colormap`** =  `@inherit colormap :viridis`  — Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

**`colorrange`** =  `automatic`  — The values representing the start and end points of `colormap`.

**`colorscale`** =  `identity`  — The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.

**`highclip`** =  `automatic`  — The color for any value above the colorrange.

**`lowclip`** =  `automatic`  — The color for any value below the colorrange.

**`nan_color`** =  `:transparent`  — The color for NaN values.

**`strokecolor`** =  `:black`  — _No docs available._

**`strokewidth`** =  `0`  — _No docs available._

**`threshold`** =  `1`  — The minimal number of observations in the bin to be shown. If 0, all zero-count hexagons fitting into the data limits will be shown.

**`weights`** =  `nothing`  — Weights for each observation.  Can be `nothing` (each observation carries weight 1) or any `AbstractVector{<: Real}` or `StatsBase.AbstractWeights`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L560" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.hexbin!' href='#Makie.hexbin!'><span class="jlbinding">Makie.hexbin!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`hexbin!` is the mutating variant of plotting function `hexbin`. Check the docstring for `hexbin` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.hidedecorations!' href='#Makie.hidedecorations!'><span class="jlbinding">Makie.hidedecorations!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
hidedecorations!(la::Axis; label = true, ticklabels = true, ticks = true,
                 grid = true, minorgrid = true, minorticks = true)
```


Hide decorations of both x and y-axis: label, ticklabels, ticks and grid. Keyword arguments can be used to disable hiding of certain types of decorations.

See also [`hidexdecorations!`], [`hideydecorations!`], [`hidezdecorations!`]


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/axis.jl#L1166-L1174" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.hidedecorations!-Tuple{PolarAxis}' href='#Makie.hidedecorations!-Tuple{PolarAxis}'><span class="jlbinding">Makie.hidedecorations!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
hidedecorations!(ax::PolarAxis; ticklabels = true, grid = true, minorgrid = true)
```


Hide decorations of both r and theta-axis: label, ticklabels, ticks and grid. Keyword arguments can be used to disable hiding of certain types of decorations.

See also [`hiderdecorations!`], [`hidethetadecorations!`], [`hidezdecorations!`]


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/polaraxis.jl#L1073-L1080" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.hiderdecorations!-Tuple{PolarAxis}' href='#Makie.hiderdecorations!-Tuple{PolarAxis}'><span class="jlbinding">Makie.hiderdecorations!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
hiderdecorations!(ax::PolarAxis; ticklabels = true, grid = true, minorgrid = true)
```


Hide decorations of the r-axis: label, ticklabels, ticks and grid. Keyword arguments can be used to disable hiding of certain types of decorations.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/polaraxis.jl#L1037-L1042" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.hidespines!-Tuple{Axis, Vararg{Symbol}}' href='#Makie.hidespines!-Tuple{Axis, Vararg{Symbol}}'><span class="jlbinding">Makie.hidespines!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
hidespines!(la::Axis, spines::Symbol... = (:l, :r, :b, :t)...)
```


Hide all specified axis spines. Hides all spines by default, otherwise choose which sides to hide with the symbols :l (left), :r (right), :b (bottom) and :t (top).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/axis.jl#L1183-L1189" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.hidethetadecorations!-Tuple{PolarAxis}' href='#Makie.hidethetadecorations!-Tuple{PolarAxis}'><span class="jlbinding">Makie.hidethetadecorations!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
hidethetadecorations!(ax::PolarAxis; ticklabels = true, grid = true, minorgrid = true)
```


Hide decorations of the theta-axis: label, ticklabels, ticks and grid. Keyword arguments can be used to disable hiding of certain types of decorations.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/polaraxis.jl#L1055-L1060" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.hidexdecorations!' href='#Makie.hidexdecorations!'><span class="jlbinding">Makie.hidexdecorations!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
hidexdecorations!(la::Axis; label = true, ticklabels = true, ticks = true, grid = true,
    minorgrid = true, minorticks = true)
```


Hide decorations of the x-axis: label, ticklabels, ticks and grid. Keyword arguments can be used to disable hiding of certain types of decorations.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/axis.jl#L1108-L1114" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.hideydecorations!' href='#Makie.hideydecorations!'><span class="jlbinding">Makie.hideydecorations!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
hideydecorations!(la::Axis; label = true, ticklabels = true, ticks = true, grid = true,
    minorgrid = true, minorticks = true)
```


Hide decorations of the y-axis: label, ticklabels, ticks and grid. Keyword arguments can be used to disable hiding of certain types of decorations.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/axis.jl#L1137-L1143" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.hidezdecorations!-Tuple{Axis3}' href='#Makie.hidezdecorations!-Tuple{Axis3}'><span class="jlbinding">Makie.hidezdecorations!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
hidezdecorations!(ax::Axis3; label = true, ticklabels = true, ticks = true, grid = true)
```


Hide decorations of the z-axis: label, ticklabels, ticks and grid. Keyword arguments can be used to disable hiding of certain types of decorations.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/axis3d.jl#L827-L832" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.hist' href='#Makie.hist'><span class="jlbinding">Makie.hist</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
hist(values)
```


Plot a histogram of `values`.

**Plot type**

The plot type alias for the `hist` function is `Hist`.

**Attributes**

**`bar_labels`** =  `nothing`  — _No docs available._

**`bins`** =  `15`  — Can be an `Int` to create that number of equal-width bins over the range of `values`. Alternatively, it can be a sorted iterable of bin edges.

**`color`** =  `@inherit patchcolor`  — Color can either be:
- a vector of `bins` colors
  
- a single color
  
- `:values`, to color the bars with the values from the histogram
  

**`cycle`** =  `[:color => :patchcolor]`  — _No docs available._

**`direction`** =  `:y`  — Set the direction of the bars.

**`fillto`** =  `automatic`  — Defines where the bars start.

**`flip_labels_at`** =  `Inf`  — _No docs available._

**`gap`** =  `0`  — Gap between the bars (see barplot).

**`label_color`** =  `@inherit textcolor`  — _No docs available._

**`label_font`** =  `@inherit font`  — _No docs available._

**`label_formatter`** =  `bar_label_formatter`  — _No docs available._

**`label_offset`** =  `5`  — _No docs available._

**`label_size`** =  `20`  — _No docs available._

**`normalization`** =  `:none`  — Allows to normalize the histogram. Possible values are:
- `:pdf`: Normalize by sum of weights and bin sizes. Resulting histogram  has norm 1 and represents a PDF.
  
- `:density`: Normalize by bin sizes only. Resulting histogram represents  count density of input and does not have norm 1. Will not modify the  histogram if it already represents a density (`h.isdensity == 1`).
  
- `:probability`: Normalize by sum of weights only. Resulting histogram  represents the fraction of probability mass for each bin and does not have  norm 1.
  
- `:none`: Do not normalize.
  

**`offset`** =  `0.0`  — Adds an offset to every value.

**`over_background_color`** =  `automatic`  — _No docs available._

**`over_bar_color`** =  `automatic`  — _No docs available._

**`scale_to`** =  `nothing`  — Allows to scale all values to a certain height. This can also be set to `:flip` to flip the direction of histogram bars without scaling them to a common height.

**`strokecolor`** =  `@inherit patchstrokecolor`  — _No docs available._

**`strokewidth`** =  `@inherit patchstrokewidth`  — _No docs available._

**`weights`** =  `automatic`  — Allows to statistically weight the observations.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L591" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.hist!' href='#Makie.hist!'><span class="jlbinding">Makie.hist!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`hist!` is the mutating variant of plotting function `hist`. Check the docstring for `hist` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.hlines' href='#Makie.hlines'><span class="jlbinding">Makie.hlines</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
hlines(ys; xmin = 0.0, xmax = 1.0, attrs...)
```


Create horizontal lines across a `Scene` with 2D projection. The lines will be placed at `ys` in data coordinates and `xmin` to `xmax` in scene coordinates (0 to 1). All three of these can have single or multiple values because they are broadcast to calculate the final line segments.

**Plot type**

The plot type alias for the `hlines` function is `HLines`.

**Attributes**

**`alpha`** =  `1.0`  — The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`color`** =  `@inherit linecolor`  — The color of the line.

**`colormap`** =  `@inherit colormap :viridis`  — Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

**`colorrange`** =  `automatic`  — The values representing the start and end points of `colormap`.

**`colorscale`** =  `identity`  — The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.

**`cycle`** =  `[:color]`  — Sets which attributes to cycle when creating multiple plots.

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`fxaa`** =  `false`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`highclip`** =  `automatic`  — The color for any value above the colorrange.

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`linecap`** =  `@inherit linecap`  — Sets the type of linecap used, i.e. :butt (flat with no extrusion), :square (flat with 1 linewidth extrusion) or :round.

**`linestyle`** =  `nothing`  — Sets the dash pattern of the line. Options are `:solid` (equivalent to `nothing`), `:dot`, `:dash`, `:dashdot` and `:dashdotdot`. These can also be given in a tuple with a gap style modifier, either `:normal`, `:dense` or `:loose`. For example, `(:dot, :loose)` or `(:dashdot, :dense)`.

For custom patterns have a look at [`Makie.Linestyle`](/api#Makie.Linestyle).

**`linewidth`** =  `@inherit linewidth`  — Sets the width of the line in pixel units

**`lowclip`** =  `automatic`  — The color for any value below the colorrange.

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`nan_color`** =  `:transparent`  — The color for NaN values.

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.

**`xmax`** =  `1`  — The end of the lines in relative axis units (0 to 1) along the x dimension.

**`xmin`** =  `0`  — The start of the lines in relative axis units (0 to 1) along the x dimension.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L598" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.hlines!' href='#Makie.hlines!'><span class="jlbinding">Makie.hlines!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`hlines!` is the mutating variant of plotting function `hlines`. Check the docstring for `hlines` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.hovered_scene-Tuple{}' href='#Makie.hovered_scene-Tuple{}'><span class="jlbinding">Makie.hovered_scene</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
hovered_scene()
```


Returns the `scene` that the mouse is currently hovering over.

Properly identifies the scene for a plot with multiple sub-plots.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/interaction/interactive_api.jl#L231-L237" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.hspan' href='#Makie.hspan'><span class="jlbinding">Makie.hspan</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
hspan(ys_low, ys_high; xmin = 0.0, xmax = 1.0, attrs...)
hspan(ys_lowhigh; xmin = 0.0, xmax = 1.0, attrs...)
```


Create horizontal bands spanning across a `Scene` with 2D projection. The bands will be placed from `ys_low` to `ys_high` in data coordinates and `xmin` to `xmax` in scene coordinates (0 to 1). All four of these can have single or multiple values because they are broadcast to calculate the final spans. Both bounds can be passed together as an interval `ys_lowhigh`.

**Plot type**

The plot type alias for the `hspan` function is `HSpan`.

**Attributes**

**`alpha`** =  `1.0`  — The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`color`** =  `@inherit patchcolor`  — Sets the color of the poly. Can be a `Vector{<:Colorant}` for per vertex colors or a single `Colorant`. A `Matrix{<:Colorant}` can be used to color the mesh with a texture, which requires the mesh to contain texture coordinates. Vector or Matrices of numbers can be used as well, which will use the colormap arguments to map the numbers to colors. One can also use a `<: AbstractPattern`, to cover the poly with a regular pattern, e.g. for hatching.

**`colormap`** =  `@inherit colormap :viridis`  — Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

**`colorrange`** =  `automatic`  — The values representing the start and end points of `colormap`.

**`colorscale`** =  `identity`  — The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.

**`cycle`** =  `[:color => :patchcolor]`  — _No docs available._

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`fxaa`** =  `true`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`highclip`** =  `automatic`  — The color for any value above the colorrange.

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`joinstyle`** =  `@inherit joinstyle`  — _No docs available._

**`linecap`** =  `@inherit linecap`  — _No docs available._

**`linestyle`** =  `nothing`  — Sets the dash pattern of the line. Options are `:solid` (equivalent to `nothing`), `:dot`, `:dash`, `:dashdot` and `:dashdotdot`. These can also be given in a tuple with a gap style modifier, either `:normal`, `:dense` or `:loose`. For example, `(:dot, :loose)` or `(:dashdot, :dense)`.

For custom patterns have a look at [`Makie.Linestyle`](/api#Makie.Linestyle).

**`lowclip`** =  `automatic`  — The color for any value below the colorrange.

**`miter_limit`** =  `@inherit miter_limit`  — _No docs available._

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`nan_color`** =  `:transparent`  — The color for NaN values.

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`shading`** =  `NoShading`  — _No docs available._

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`stroke_depth_shift`** =  `-1.0e-5`  — Depth shift of stroke plot. This is useful to avoid z-fighting between the stroke and the fill.

**`strokecolor`** =  `@inherit patchstrokecolor`  — Sets the color of the outline around a marker.

**`strokecolormap`** =  `@inherit colormap`  — Sets the colormap that is sampled for numeric `color`s.

**`strokewidth`** =  `@inherit patchstrokewidth`  — Sets the width of the outline.

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.

**`xmax`** =  `1`  — The end of the bands in relative axis units (0 to 1) along the x dimension.

**`xmin`** =  `0`  — The start of the bands in relative axis units (0 to 1) along the x dimension.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L616" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.hspan!' href='#Makie.hspan!'><span class="jlbinding">Makie.hspan!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`hspan!` is the mutating variant of plotting function `hspan`. Check the docstring for `hspan` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.is_mouseinside-Tuple{Any}' href='#Makie.is_mouseinside-Tuple{Any}'><span class="jlbinding">Makie.is_mouseinside</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
is_mouseinside(scene)
```


Returns true if the current mouseposition is inside the given scene.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/camera/camera.jl#L114-L118" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.ispressed' href='#Makie.ispressed'><span class="jlbinding">Makie.ispressed</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
ispressed(parent, result::Bool[, waspressed = nothing])
ispressed(parent, button::Union{Mouse.Button, Keyboard.Button[, waspressed = nothing])
ispressed(parent, collection::Union{Set, Vector, Tuple}[, waspressed = nothing])
ispressed(parent, op::BooleanOperator[, waspressed = nothing])
```


This function checks if a button or combination of buttons is pressed.

If given a true or false, `ispressed` will return true or false respectively. This provides a way to turn an interaction &quot;always on&quot; or &quot;always off&quot; from the outside.

Passing a button or collection of buttons such as `Keyboard.enter` or `Mouse.left` will return true if all of the given buttons are pressed.

Parent can be any object that has `get_scene` method implemented, which includes e.g. Figure, Axis, Axis3, Lscene, FigureAxisPlot, and AxisPlot.

For more complicated combinations of buttons they can be combined into boolean expression with `&`, `|` and `!`. For example, you can have `ispressed(parent, !Keyboard.left_control & Keyboard.c))` and `ispressed(parent, Keyboard.left_control & Keyboard.c)` to avoid triggering both cases at the same time.

Furthermore you can also make any button, button collection or boolean expression exclusive by wrapping it in `Exclusively(...)`. With that `ispressed` will only return true if the currently pressed buttons match the request exactly.

For cases where you want to react to a release event you can optionally add a key or mousebutton `waspressed` which is then assumed to be pressed regardless of it&#39;s current state. For example, when reacting to a mousebutton event, you can pass `event.button` so that a key combination including that button still evaluates as true.

See also: [`And`](/api#Makie.And), [`Or`](/api#Makie.Or), [`Not`](/api#Makie.Not), [`Exclusively`](/api#Makie.Exclusively), `&`, `|`, `!`


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/interaction/events.jl#L251-L287" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.labelslider!-Tuple{Any, Any, Any}' href='#Makie.labelslider!-Tuple{Any, Any, Any}'><span class="jlbinding">Makie.labelslider!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
labelslider!(scene, label, range; format = string, sliderkw = Dict(),
labelkw = Dict(), valuekw = Dict(), value_column_width = automatic, layoutkw...)
```


**`labelslider!` is deprecated, use `SliderGrid` instead**

Construct a horizontal GridLayout with a label, a slider and a value label in `scene`.

Returns a `NamedTuple`:

`(slider = slider, label = label, valuelabel = valuelabel, layout = layout)`

Specify a format function for the value label with the `format` keyword or pass a format string used by `Format.format`. The slider is forwarded the keywords from `sliderkw`. The label is forwarded the keywords from `labelkw`. The value label is forwarded the keywords from `valuekw`. You can set the column width for the value label column with the keyword `value_column_width`. By default, the width is determined heuristically by sampling a few values from the slider range. All other keywords are forwarded to the `GridLayout`.

Example:

```julia
ls = labelslider!(scene, "Voltage:", 0:10; format = x -> "$(x)V")
layout[1, 1] = ls.layout
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/helpers.jl#L294-L320" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.labelslidergrid!-Tuple{Any, Any, Any}' href='#Makie.labelslidergrid!-Tuple{Any, Any, Any}'><span class="jlbinding">Makie.labelslidergrid!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
labelslidergrid!(scene, labels, ranges; formats = [string],
    sliderkw = Dict(), labelkw = Dict(), valuekw = Dict(),
    value_column_width = automatic, layoutkw...)
```


**`labelslidergrid!` is deprecated, use `SliderGrid` instead**

Construct a GridLayout with a column of label, a column of sliders and a column of value labels in `scene`. The argument values are broadcast, so you can use scalars if you want to keep labels, ranges or formats constant across rows.

Returns a `NamedTuple`:

`(sliders = sliders, labels = labels, valuelabels = valuelabels, layout = layout)`

Specify format functions for the value labels with the `formats` keyword or pass format strings used by `Format.format`. The sliders are forwarded the keywords from `sliderkw`. The labels are forwarded the keywords from `labelkw`. The value labels are forwarded the keywords from `valuekw`. You can set the column width for the value label column with the keyword `value_column_width`. By default, the width is determined heuristically by sampling a few values from the slider ranges. All other keywords are forwarded to the `GridLayout`.

Example:

```julia
ls = labelslidergrid!(scene, ["Voltage", "Ampere"], Ref(0:0.1:100); format = x -> "$(x)V")
layout[1, 1] = ls.layout
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/helpers.jl#L351-L379" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.left_subsup-Tuple' href='#Makie.left_subsup-Tuple'><span class="jlbinding">Makie.left_subsup</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
left_subsup(subscript, superscript; kwargs...)
```


Create a `RichText` object representing a left subscript/superscript combination, where both scripts are right-aligned against the following text.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/basic_recipes/text.jl#L335-L340" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.limits!-Tuple{Axis, Any, Any}' href='#Makie.limits!-Tuple{Axis, Any, Any}'><span class="jlbinding">Makie.limits!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
limits!(ax::Axis, xlims, ylims)
```


Set the axis limits to `xlims` and `ylims`. If limits are ordered high-low, this reverses the axis orientation.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/axis.jl#L1379-L1384" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.limits!-Tuple{Axis, GeometryBasics.HyperRectangle{2}}' href='#Makie.limits!-Tuple{Axis, GeometryBasics.HyperRectangle{2}}'><span class="jlbinding">Makie.limits!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
limits!(ax::Axis, rect::Rect2)
```


Set the axis limits to `rect`. If limits are ordered high-low, this reverses the axis orientation.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/axis.jl#L1401-L1406" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.limits!-Tuple{Axis, Vararg{Any, 4}}' href='#Makie.limits!-Tuple{Axis, Vararg{Any, 4}}'><span class="jlbinding">Makie.limits!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
limits!(ax::Axis, x1, x2, y1, y2)
```


Set the axis x-limits to `x1` and `x2` and the y-limits to `y1` and `y2`. If limits are ordered high-low, this reverses the axis orientation.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/axis.jl#L1390-L1395" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.limits!-Tuple{Axis3, Any, Any, Any}' href='#Makie.limits!-Tuple{Axis3, Any, Any, Any}'><span class="jlbinding">Makie.limits!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
limits!(ax::Axis3, xlims, ylims, zlims)
```


Set the axis limits to `xlims`, `ylims`, and `zlims`. If limits are ordered high-low, this reverses the axis orientation.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/axis3d.jl#L993-L998" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.limits!-Tuple{Axis3, GeometryBasics.HyperRectangle{3}}' href='#Makie.limits!-Tuple{Axis3, GeometryBasics.HyperRectangle{3}}'><span class="jlbinding">Makie.limits!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
limits!(ax::Axis3, rect::Rect3)
```


Set the axis limits to `rect`. If limits are ordered high-low, this reverses the axis orientation.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/axis3d.jl#L1018-L1023" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.limits!-Tuple{Axis3, Vararg{Any, 6}}' href='#Makie.limits!-Tuple{Axis3, Vararg{Any, 6}}'><span class="jlbinding">Makie.limits!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
limits!(ax::Axis3, x1, x2, y1, y2, z1, z2)
```


Set the axis x-limits to `x1` and `x2`, the y-limits to `y1` and `y2`, and the z-limits to `z1` and `z2`. If limits are ordered high-low, this reverses the axis orientation.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/axis3d.jl#L1005-L1011" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.linkaxes!-Tuple{Vector{<:Axis}}' href='#Makie.linkaxes!-Tuple{Vector{<:Axis}}'><span class="jlbinding">Makie.linkaxes!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
linkaxes!(a::Axis, others...)
```


Link both x and y axes of all given `Axis` so that they stay synchronized.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/axis.jl#L976-L980" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.linkxaxes!-Tuple{Vector{Axis}}' href='#Makie.linkxaxes!-Tuple{Vector{Axis}}'><span class="jlbinding">Makie.linkxaxes!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
linkxaxes!(a::Axis, others...)
```


Link the x axes of all given `Axis` so that they stay synchronized.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/axis.jl#L1063-L1067" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.linkyaxes!-Tuple{Vector{Axis}}' href='#Makie.linkyaxes!-Tuple{Vector{Axis}}'><span class="jlbinding">Makie.linkyaxes!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
linkyaxes!(a::Axis, others...)
```


Link the y axes of all given `Axis` so that they stay synchronized.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/axis.jl#L1071-L1075" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.mouseover-Tuple{Any, Vararg{AbstractPlot}}' href='#Makie.mouseover-Tuple{Any, Vararg{AbstractPlot}}'><span class="jlbinding">Makie.mouseover</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
mouseover(fig/ax/scene, plots::AbstractPlot...)
```


Returns true if the mouse currently hovers any of `plots`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/interaction/interactive_api.jl#L8-L12" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.mouseposition-Tuple{Any}' href='#Makie.mouseposition-Tuple{Any}'><span class="jlbinding">Makie.mouseposition</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
mouseposition(scene = hovered_scene())
```


Return the current position of the mouse in _data coordinates_ of the given `scene`.

By default uses the `scene` that the mouse is currently hovering over.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/interaction/interactive_api.jl#L212-L219" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.old_cam3d!-Tuple{Scene}' href='#Makie.old_cam3d!-Tuple{Scene}'><span class="jlbinding">Makie.old_cam3d!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
old_cam3d!(scene; kwargs...)
```


An alias to [`old_cam3d_turntable!`](/api#Makie.old_cam3d_turntable!-Tuple{Scene}). Creates a 3D camera for `scene`, which rotates around the plot&#39;s axis.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/camera/old_camera3d.jl#L94-L100" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.old_cam3d_cad!-Tuple{Scene}' href='#Makie.old_cam3d_cad!-Tuple{Scene}'><span class="jlbinding">Makie.old_cam3d_cad!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
old_cam3d_cad!(scene; kw_args...)
```


Creates a 3D camera for `scene` which rotates around the _viewer_&#39;s &quot;up&quot; axis - similarly to how it&#39;s done in CAD software cameras.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/camera/old_camera3d.jl#L19-L25" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.old_cam3d_turntable!-Tuple{Scene}' href='#Makie.old_cam3d_turntable!-Tuple{Scene}'><span class="jlbinding">Makie.old_cam3d_turntable!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
old_cam3d_turntable!(scene; kw_args...)
```


Creates a 3D camera for `scene`, which rotates around the plot&#39;s axis.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/camera/old_camera3d.jl#L58-L63" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.onmousedownoutside-Tuple{Any, Makie.MouseEventHandle}' href='#Makie.onmousedownoutside-Tuple{Any, Makie.MouseEventHandle}'><span class="jlbinding">Makie.onmousedownoutside</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



Executes the function f whenever the `MouseEventHandle`&#39;s observable is set to a MouseEvent with `event.type === downoutside`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/mousestatemachine.jl#L87-L90" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.onmouseenter-Tuple{Any, Makie.MouseEventHandle}' href='#Makie.onmouseenter-Tuple{Any, Makie.MouseEventHandle}'><span class="jlbinding">Makie.onmouseenter</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



Executes the function f whenever the `MouseEventHandle`&#39;s observable is set to a MouseEvent with `event.type === enter`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/mousestatemachine.jl#L87-L90" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.onmouseleftclick-Tuple{Any, Makie.MouseEventHandle}' href='#Makie.onmouseleftclick-Tuple{Any, Makie.MouseEventHandle}'><span class="jlbinding">Makie.onmouseleftclick</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



Executes the function f whenever the `MouseEventHandle`&#39;s observable is set to a MouseEvent with `event.type === leftclick`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/mousestatemachine.jl#L87-L90" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.onmouseleftdoubleclick-Tuple{Any, Makie.MouseEventHandle}' href='#Makie.onmouseleftdoubleclick-Tuple{Any, Makie.MouseEventHandle}'><span class="jlbinding">Makie.onmouseleftdoubleclick</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



Executes the function f whenever the `MouseEventHandle`&#39;s observable is set to a MouseEvent with `event.type === leftdoubleclick`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/mousestatemachine.jl#L87-L90" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.onmouseleftdown-Tuple{Any, Makie.MouseEventHandle}' href='#Makie.onmouseleftdown-Tuple{Any, Makie.MouseEventHandle}'><span class="jlbinding">Makie.onmouseleftdown</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



Executes the function f whenever the `MouseEventHandle`&#39;s observable is set to a MouseEvent with `event.type === leftdown`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/mousestatemachine.jl#L87-L90" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.onmouseleftdrag-Tuple{Any, Makie.MouseEventHandle}' href='#Makie.onmouseleftdrag-Tuple{Any, Makie.MouseEventHandle}'><span class="jlbinding">Makie.onmouseleftdrag</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



Executes the function f whenever the `MouseEventHandle`&#39;s observable is set to a MouseEvent with `event.type === leftdrag`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/mousestatemachine.jl#L87-L90" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.onmouseleftdragstart-Tuple{Any, Makie.MouseEventHandle}' href='#Makie.onmouseleftdragstart-Tuple{Any, Makie.MouseEventHandle}'><span class="jlbinding">Makie.onmouseleftdragstart</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



Executes the function f whenever the `MouseEventHandle`&#39;s observable is set to a MouseEvent with `event.type === leftdragstart`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/mousestatemachine.jl#L87-L90" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.onmouseleftdragstop-Tuple{Any, Makie.MouseEventHandle}' href='#Makie.onmouseleftdragstop-Tuple{Any, Makie.MouseEventHandle}'><span class="jlbinding">Makie.onmouseleftdragstop</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



Executes the function f whenever the `MouseEventHandle`&#39;s observable is set to a MouseEvent with `event.type === leftdragstop`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/mousestatemachine.jl#L87-L90" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.onmouseleftup-Tuple{Any, Makie.MouseEventHandle}' href='#Makie.onmouseleftup-Tuple{Any, Makie.MouseEventHandle}'><span class="jlbinding">Makie.onmouseleftup</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



Executes the function f whenever the `MouseEventHandle`&#39;s observable is set to a MouseEvent with `event.type === leftup`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/mousestatemachine.jl#L87-L90" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.onmousemiddleclick-Tuple{Any, Makie.MouseEventHandle}' href='#Makie.onmousemiddleclick-Tuple{Any, Makie.MouseEventHandle}'><span class="jlbinding">Makie.onmousemiddleclick</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



Executes the function f whenever the `MouseEventHandle`&#39;s observable is set to a MouseEvent with `event.type === middleclick`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/mousestatemachine.jl#L87-L90" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.onmousemiddledoubleclick-Tuple{Any, Makie.MouseEventHandle}' href='#Makie.onmousemiddledoubleclick-Tuple{Any, Makie.MouseEventHandle}'><span class="jlbinding">Makie.onmousemiddledoubleclick</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



Executes the function f whenever the `MouseEventHandle`&#39;s observable is set to a MouseEvent with `event.type === middledoubleclick`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/mousestatemachine.jl#L87-L90" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.onmousemiddledown-Tuple{Any, Makie.MouseEventHandle}' href='#Makie.onmousemiddledown-Tuple{Any, Makie.MouseEventHandle}'><span class="jlbinding">Makie.onmousemiddledown</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



Executes the function f whenever the `MouseEventHandle`&#39;s observable is set to a MouseEvent with `event.type === middledown`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/mousestatemachine.jl#L87-L90" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.onmousemiddledrag-Tuple{Any, Makie.MouseEventHandle}' href='#Makie.onmousemiddledrag-Tuple{Any, Makie.MouseEventHandle}'><span class="jlbinding">Makie.onmousemiddledrag</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



Executes the function f whenever the `MouseEventHandle`&#39;s observable is set to a MouseEvent with `event.type === middledrag`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/mousestatemachine.jl#L87-L90" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.onmousemiddledragstart-Tuple{Any, Makie.MouseEventHandle}' href='#Makie.onmousemiddledragstart-Tuple{Any, Makie.MouseEventHandle}'><span class="jlbinding">Makie.onmousemiddledragstart</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



Executes the function f whenever the `MouseEventHandle`&#39;s observable is set to a MouseEvent with `event.type === middledragstart`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/mousestatemachine.jl#L87-L90" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.onmousemiddledragstop-Tuple{Any, Makie.MouseEventHandle}' href='#Makie.onmousemiddledragstop-Tuple{Any, Makie.MouseEventHandle}'><span class="jlbinding">Makie.onmousemiddledragstop</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



Executes the function f whenever the `MouseEventHandle`&#39;s observable is set to a MouseEvent with `event.type === middledragstop`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/mousestatemachine.jl#L87-L90" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.onmousemiddleup-Tuple{Any, Makie.MouseEventHandle}' href='#Makie.onmousemiddleup-Tuple{Any, Makie.MouseEventHandle}'><span class="jlbinding">Makie.onmousemiddleup</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



Executes the function f whenever the `MouseEventHandle`&#39;s observable is set to a MouseEvent with `event.type === middleup`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/mousestatemachine.jl#L87-L90" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.onmouseout-Tuple{Any, Makie.MouseEventHandle}' href='#Makie.onmouseout-Tuple{Any, Makie.MouseEventHandle}'><span class="jlbinding">Makie.onmouseout</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



Executes the function f whenever the `MouseEventHandle`&#39;s observable is set to a MouseEvent with `event.type === out`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/mousestatemachine.jl#L87-L90" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.onmouseover-Tuple{Any, Makie.MouseEventHandle}' href='#Makie.onmouseover-Tuple{Any, Makie.MouseEventHandle}'><span class="jlbinding">Makie.onmouseover</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



Executes the function f whenever the `MouseEventHandle`&#39;s observable is set to a MouseEvent with `event.type === over`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/mousestatemachine.jl#L87-L90" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.onmouserightclick-Tuple{Any, Makie.MouseEventHandle}' href='#Makie.onmouserightclick-Tuple{Any, Makie.MouseEventHandle}'><span class="jlbinding">Makie.onmouserightclick</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



Executes the function f whenever the `MouseEventHandle`&#39;s observable is set to a MouseEvent with `event.type === rightclick`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/mousestatemachine.jl#L87-L90" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.onmouserightdoubleclick-Tuple{Any, Makie.MouseEventHandle}' href='#Makie.onmouserightdoubleclick-Tuple{Any, Makie.MouseEventHandle}'><span class="jlbinding">Makie.onmouserightdoubleclick</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



Executes the function f whenever the `MouseEventHandle`&#39;s observable is set to a MouseEvent with `event.type === rightdoubleclick`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/mousestatemachine.jl#L87-L90" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.onmouserightdown-Tuple{Any, Makie.MouseEventHandle}' href='#Makie.onmouserightdown-Tuple{Any, Makie.MouseEventHandle}'><span class="jlbinding">Makie.onmouserightdown</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



Executes the function f whenever the `MouseEventHandle`&#39;s observable is set to a MouseEvent with `event.type === rightdown`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/mousestatemachine.jl#L87-L90" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.onmouserightdrag-Tuple{Any, Makie.MouseEventHandle}' href='#Makie.onmouserightdrag-Tuple{Any, Makie.MouseEventHandle}'><span class="jlbinding">Makie.onmouserightdrag</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



Executes the function f whenever the `MouseEventHandle`&#39;s observable is set to a MouseEvent with `event.type === rightdrag`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/mousestatemachine.jl#L87-L90" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.onmouserightdragstart-Tuple{Any, Makie.MouseEventHandle}' href='#Makie.onmouserightdragstart-Tuple{Any, Makie.MouseEventHandle}'><span class="jlbinding">Makie.onmouserightdragstart</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



Executes the function f whenever the `MouseEventHandle`&#39;s observable is set to a MouseEvent with `event.type === rightdragstart`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/mousestatemachine.jl#L87-L90" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.onmouserightdragstop-Tuple{Any, Makie.MouseEventHandle}' href='#Makie.onmouserightdragstop-Tuple{Any, Makie.MouseEventHandle}'><span class="jlbinding">Makie.onmouserightdragstop</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



Executes the function f whenever the `MouseEventHandle`&#39;s observable is set to a MouseEvent with `event.type === rightdragstop`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/mousestatemachine.jl#L87-L90" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.onmouserightup-Tuple{Any, Makie.MouseEventHandle}' href='#Makie.onmouserightup-Tuple{Any, Makie.MouseEventHandle}'><span class="jlbinding">Makie.onmouserightup</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



Executes the function f whenever the `MouseEventHandle`&#39;s observable is set to a MouseEvent with `event.type === rightup`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/mousestatemachine.jl#L87-L90" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.onpick' href='#Makie.onpick'><span class="jlbinding">Makie.onpick</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
onpick(func, plot)
```


Calls `func` if one clicks on `plot`. Implemented by the backend.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/interaction/events.jl#L69-L72" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.onpick-Tuple{Any, Any, Vararg{AbstractPlot}}' href='#Makie.onpick-Tuple{Any, Any, Vararg{AbstractPlot}}'><span class="jlbinding">Makie.onpick</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
onpick(f, fig/ax/scene, plots::AbstractPlot...)
```


Calls `f(plot, idx)` whenever the mouse is over any of `plots`. `idx` is an index, e.g. when over a scatter plot, it will be the index of the hovered element


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/interaction/interactive_api.jl#L19-L25" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.origin!-Tuple{MakieCore.Transformable, Vararg{Any}}' href='#Makie.origin!-Tuple{MakieCore.Transformable, Vararg{Any}}'><span class="jlbinding">Makie.origin!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
origin!([mode = Absolute], t::Transformable, xyz...)
origin!([mode = Absolute], t::Transformable, xyz::VecTypes)
```


Sets the origin of the transformable `t` to the given `xyz` value. This affects the origin of `rotate!(t, ...)` and `scale!(t, ...)`. If `mode` is given as `Accum` the origin is translated by the given `xyz` instead.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/layouting/transformation.jl#L195-L202" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.pick' href='#Makie.pick'><span class="jlbinding">Makie.pick</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



Picks a mouse position. Implemented by the backend.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/interaction/events.jl#L59-L61" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.pick-Tuple{Any, GeometryBasics.HyperRectangle{2, Int64}}' href='#Makie.pick-Tuple{Any, GeometryBasics.HyperRectangle{2, Int64}}'><span class="jlbinding">Makie.pick</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
pick(scene::Scene, rect::Rect2i)
```


Return all `(plot, index)` pairs within the given rect. The rect must be within screen boundaries.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/interaction/interactive_api.jl#L188-L193" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.pick-Tuple{Any, Number, Number}' href='#Makie.pick-Tuple{Any, Number, Number}'><span class="jlbinding">Makie.pick</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
pick(fig/ax/scene, x, y[, range])
pick(fig/ax/scene, xy::VecLike[, range])
```


Returns the plot and element index under the given pixel position `xy = Vec(x, y)`. If `range` is given, the nearest plot up to a distance of `range` is returned instead.

The `plot` returned by this function is always a primitive plot, i.e. one that is not composed of other plot types.

The index returned relates to the main input of the respective primitive plot.
- For `scatter` and `meshscatter` it is an index into the positions given to the plot.
  
- For `text` it is an index into the merged character array.
  
- For `lines` and `linesegments` it is the end position of the selected line segment.
  
- For `image`, `heatmap` and `surface` it is the linear index into the matrix argument of the plot (i.e. the given image, value or z-value matrix) that is closest to the selected position.
  
- For `voxels` it is the linear index into the given 3D Array.
  
- For `mesh` it is the largest vertex index of the picked triangle face.
  
- For `volume` it is always 0.
  

See also: `pick_sorted`


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/interaction/interactive_api.jl#L55-L75" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.pie' href='#Makie.pie'><span class="jlbinding">Makie.pie</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
pie(values; kwargs...)
pie(point, values; kwargs...)
pie(x, y, values; kwargs...)
```


Creates a pie chart from the given `values`.

**Plot type**

The plot type alias for the `pie` function is `Pie`.

**Attributes**

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`color`** =  `:gray`  — _No docs available._

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`fxaa`** =  `true`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`inner_radius`** =  `0`  — The inner radius of the pie segments. If this is larger than zero, the pie pieces become ring sections.

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`normalize`** =  `true`  — If `true`, the sum of all values is normalized to 2π (a full circle).

**`offset`** =  `0`  — The angular offset of the first pie segment from the (1, 0) vector in radians.

**`offset_radius`** =  `0`  — The offset of each pie segment from the center along the radius

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`radius`** =  `1`  — The outer radius of the pie segments.

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`strokecolor`** =  `:black`  — _No docs available._

**`strokewidth`** =  `1`  — _No docs available._

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`vertex_per_deg`** =  `1`  — Controls how many polygon vertices are used for one degree of rotation.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L581" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.pie!' href='#Makie.pie!'><span class="jlbinding">Makie.pie!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`pie!` is the mutating variant of plotting function `pie`. Check the docstring for `pie` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.plotlist-Tuple' href='#Makie.plotlist-Tuple'><span class="jlbinding">Makie.plotlist</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
plotlist!(
    [
        PlotSpec(:Scatter, args...; kwargs...),
        PlotSpec(:Lines, args...; kwargs...),
    ]
)
```


Plots a list of PlotSpec&#39;s, which can be an observable, making it possible to create efficiently animated plots with the following API:

**Example**

```julia
using GLMakie
import Makie.SpecApi as S

fig = Figure()
ax = Axis(fig[1, 1])
plots = Observable([S.heatmap(0 .. 1, 0 .. 1, Makie.peaks()), S.lines(0 .. 1, sin.(0:0.01:1); color=:blue)])
pl = plot!(ax, plots)
display(fig)

# Updating the plot dynamically
plots[] = [S.heatmap(0 .. 1, 0 .. 1, Makie.peaks()), S.lines(0 .. 1, sin.(0:0.01:1); color=:red)]
plots[] = [
    S.image(0 .. 1, 0 .. 1, Makie.peaks()),
    S.poly(Rect2f(0.45, 0.45, 0.1, 0.1)),
    S.lines(0 .. 1, sin.(0:0.01:1); linewidth=10, color=Makie.resample_cmap(:viridis, 101)),
]

plots[] = [
    S.surface(0..1, 0..1, Makie.peaks(); colormap = :viridis, translation = Vec3f(0, 0, -1)),
]
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/specapi.jl#L493-L526" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.qqnorm' href='#Makie.qqnorm'><span class="jlbinding">Makie.qqnorm</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
qqnorm(y; kwargs...)
```


Shorthand for `qqplot(Normal(0,1), y)`, i.e., draw a Q-Q plot of `y` against the standard normal distribution. See `qqplot` for more details.

**Plot type**

The plot type alias for the `qqnorm` function is `QQNorm`.

**Attributes**

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`color`** =  `@inherit linecolor`  — Control color of both line and markers (if `markercolor` is not specified).

**`cycle`** =  `[:color]`  — _No docs available._

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`fxaa`** =  `true`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`linestyle`** =  `nothing`  — _No docs available._

**`linewidth`** =  `@inherit linewidth`  — _No docs available._

**`marker`** =  `@inherit marker`  — _No docs available._

**`markercolor`** =  `automatic`  — _No docs available._

**`markersize`** =  `@inherit markersize`  — _No docs available._

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`strokecolor`** =  `@inherit markerstrokecolor`  — _No docs available._

**`strokewidth`** =  `@inherit markerstrokewidth`  — _No docs available._

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L579" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.qqnorm!' href='#Makie.qqnorm!'><span class="jlbinding">Makie.qqnorm!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`qqnorm!` is the mutating variant of plotting function `qqnorm`. Check the docstring for `qqnorm` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.qqplot' href='#Makie.qqplot'><span class="jlbinding">Makie.qqplot</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
qqplot(x, y; kwargs...)
```


Draw a Q-Q plot, comparing quantiles of two distributions. `y` must be a list of samples, i.e., `AbstractVector{<:Real}`, whereas `x` can be
- a list of samples,
  
- an abstract distribution, e.g. `Normal(0, 1)`,
  
- a distribution type, e.g. `Normal`.
  

In the last case, the distribution type is fitted to the data `y`.

The attribute `qqline` (defaults to `:none`) determines how to compute a fit line for the Q-Q plot. Possible values are the following.
- `:identity` draws the identity line.
  
- `:fit` computes a least squares line fit of the quantile pairs.
  
- `:fitrobust` computes the line that passes through the first and third quartiles of the distributions.
  
- `:none` omits drawing the line.
  

Broadly speaking, `qqline = :identity` is useful to see if `x` and `y` follow the same distribution, whereas `qqline = :fit` and `qqline = :fitrobust` are useful to see if the distribution of `y` can be obtained from the distribution of `x` via an affine transformation.

**Plot type**

The plot type alias for the `qqplot` function is `QQPlot`.

**Attributes**

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`color`** =  `@inherit linecolor`  — Control color of both line and markers (if `markercolor` is not specified).

**`cycle`** =  `[:color]`  — _No docs available._

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`fxaa`** =  `true`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`linestyle`** =  `nothing`  — _No docs available._

**`linewidth`** =  `@inherit linewidth`  — _No docs available._

**`marker`** =  `@inherit marker`  — _No docs available._

**`markercolor`** =  `automatic`  — _No docs available._

**`markersize`** =  `@inherit markersize`  — _No docs available._

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`strokecolor`** =  `@inherit markerstrokecolor`  — _No docs available._

**`strokewidth`** =  `@inherit markerstrokewidth`  — _No docs available._

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L594" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.qqplot!' href='#Makie.qqplot!'><span class="jlbinding">Makie.qqplot!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`qqplot!` is the mutating variant of plotting function `qqplot`. Check the docstring for `qqplot` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.rainclouds' href='#Makie.rainclouds'><span class="jlbinding">Makie.rainclouds</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
rainclouds!(ax, category_labels, data_array; plot_boxplots=true, plot_clouds=true, kwargs...)
```


Plot a violin (/histogram), boxplot and individual data points with appropriate spacing between each.

**Arguments**
- `ax`: Axis used to place all these plots onto.
  
- `category_labels`: Typically `Vector{String}` with a label for each element in `data_array`
  
- `data_array`: Typically `Vector{Float64}` used for to represent the datapoints to plot.
  

**Keywords**

**Plot type**

The plot type alias for the `rainclouds` function is `RainClouds`.

**Attributes**

**`boxplot_nudge`** =  `0.075`  — Determines the distance away the boxplot should be placed from the center line when `center_boxplot` is `false`. This is the value used to recentering the boxplot.

**`boxplot_width`** =  `0.1`  — Width of the boxplot on the category axis.

**`center_boxplot`** =  `true`  — Whether or not to center the boxplot on the category.

**`cloud_width`** =  `0.75`  — Determines size of violin plot. Corresponds to `width` keyword arg in `violin`.

**`clouds`** =  `violin`  — [`violin`, `hist`, `nothing`] how to show cloud plots, either as violin or histogram plots, or not at all.

**`color`** =  `@inherit patchcolor`  — A single color, or a vector of colors, one for each point.

**`cycle`** =  `[:color => :patchcolor]`  — _No docs available._

**`dodge`** =  `automatic`  — Vector of `Integer` (length of data) of grouping variable to create multiple side-by-side boxes at the same x position

**`dodge_gap`** =  `0.01`  — Spacing between dodged boxes.

**`gap`** =  `0.2`  — Distance between elements on the main axis (depending on `orientation`).

**`hist_bins`** =  `30`  — If `clouds=hist`, this passes down the number of bins to the histogram call.

**`jitter_width`** =  `0.05`  —  Determines the width of the scatter-plot bar in category x-axis absolute terms.

**`markersize`** =  `2.0`  — Size of marker used for the scatter plot.

**`n_dodge`** =  `automatic`  — The number of categories to dodge (defaults to `maximum(dodge)`)

**`orientation`** =  `:vertical`  — Orientation of rainclouds (`:vertical` or `:horizontal`)

**`plot_boxplots`** =  `true`  — Whether to show boxplots to summarize distribution of data.

**`show_boxplot_outliers`** =  `false`  — Show outliers in the boxplot as points (usually confusing when paired with the scatter plot so the default is to not show them)

**`show_median`** =  `true`  — Determines whether or not to have a line for the median value in the boxplot.

**`side`** =  `:left`  — Can take values of `:left`, `:right`, determines where the violin plot will be, relative to the scatter points

**`side_nudge`** =  `automatic`  — Scatter plot specific.  Default value is 0.02 if `plot_boxplots` is true, otherwise `0.075` default.

**`strokewidth`** =  `1.0`  — Determines the stroke width for the outline of the boxplot.

**`violin_limits`** =  `(-Inf, Inf)`  — Specify values to trim the `violin`. Can be a `Tuple` or a `Function` (e.g. `datalimits=extrema`)

**`whiskerwidth`** =  `0.5`  — The width of the Q1, Q3 whisker in the boxplot. Value as a portion of the `boxplot_width`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L608" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.rainclouds!' href='#Makie.rainclouds!'><span class="jlbinding">Makie.rainclouds!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`rainclouds!` is the mutating variant of plotting function `rainclouds`. Check the docstring for `rainclouds` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.rangebars' href='#Makie.rangebars'><span class="jlbinding">Makie.rangebars</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
rangebars(val, low, high; kwargs...)
rangebars(val, low_high; kwargs...)
rangebars(val_low_high; kwargs...)
```


Plots rangebars at `val` in one dimension, extending from `low` to `high` in the other dimension given the chosen `direction`. The `low_high` argument can be a vector of tuples or intervals.

If you want to plot errors relative to a reference value, use `errorbars`.

**Plot type**

The plot type alias for the `rangebars` function is `Rangebars`.

**Attributes**

**`alpha`** =  `1.0`  — The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`color`** =  `@inherit linecolor`  — The color of the lines. Can be an array to color each bar separately.

**`colormap`** =  `@inherit colormap :viridis`  — Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

**`colorrange`** =  `automatic`  — The values representing the start and end points of `colormap`.

**`colorscale`** =  `identity`  — The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.

**`cycle`** =  `[:color]`  — _No docs available._

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`direction`** =  `:y`  — The direction in which the bars are drawn. Can be `:x` or `:y`.

**`fxaa`** =  `true`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`highclip`** =  `automatic`  — The color for any value above the colorrange.

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`linecap`** =  `@inherit linecap`  — _No docs available._

**`linewidth`** =  `@inherit linewidth`  — The thickness of the lines in screen units.

**`lowclip`** =  `automatic`  — The color for any value below the colorrange.

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`nan_color`** =  `:transparent`  — The color for NaN values.

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.

**`whiskerwidth`** =  `0`  — The width of the whiskers or line caps in screen units.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L595" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.rangebars!' href='#Makie.rangebars!'><span class="jlbinding">Makie.rangebars!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`rangebars!` is the mutating variant of plotting function `rangebars`. Check the docstring for `rangebars` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.record-Tuple{Any, Union{Figure, Makie.FigureAxisPlot, Scene}, AbstractString}' href='#Makie.record-Tuple{Any, Union{Figure, Makie.FigureAxisPlot, Scene}, AbstractString}'><span class="jlbinding">Makie.record</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
record(func, figurelike, path; backend=current_backend(), kwargs...)
record(func, figurelike, path, iter; backend=current_backend(), kwargs...)
```


The first signature provides `func` with a VideoStream, which it should call `recordframe!(io)` on when recording a frame.

The second signature iterates `iter`, calling `recordframe!(io)` internally after calling `func` with the current iteration element.

Both notations require a Figure, FigureAxisPlot or Scene `figure` to work. The animation is then saved to `path`, with the format determined by `path`&#39;s extension.

Under the hood, `record` is just `video_io = Record(func, figurelike, [iter]; same_kw...); save(path, video_io)`. `Record` can be used directly as well to do the saving at a later point, or to inline a video directly into a Notebook (the video supports, `show(video_io, "text/html")` for that purpose).

**Options one can pass via `kwargs...`:**
- `backend::Module = current_backend()`: set the backend to write out video, can be set to `CairoMakie`, `GLMakie`, `WGLMakie`, `RPRMakie`.
  

**Backend options**

See `?Backend.Screen` or `Base.doc(Backend.Screen)` for applicable options that can be passed and forwarded to the backend.

**Video options**
- `format = "mkv"`: The format of the video. If a path is present, will be inferred from the file extension.   Can be one of the following:
  - `"mkv"`  (open standard, the default)
    
  - `"mp4"`  (good for Web, most supported format)
    
  - `"webm"` (smallest file size)
    
  - `"gif"`  (largest file size for the same quality)
    
  `mp4` and `mk4` are marginally bigger than `webm`. `gif`s can be significantly (as much as   6x) larger with worse quality (due to the limited color palette) and only should be used   as a last resort, for playing in a context where videos aren&#39;t supported.
  
- `framerate = 24`: The target framerate.
  
- `compression = 20`: Controls the video compression via `ffmpeg`&#39;s `-crf` option, with   smaller numbers giving higher quality and larger file sizes (lower compression), and   higher numbers giving lower quality and smaller file sizes (higher compression). The   minimum value is `0` (lossless encoding).
  - For `mp4`, `51` is the maximum. Note that `compression = 0` only works with `mp4` if `profile = "high444"`.
    
  - For `webm`, `63` is the maximum.
    
  - `compression` has no effect on `mkv` and `gif` outputs.
    
  
- `profile = "high422"`: A ffmpeg compatible profile. Currently only applies to `mp4`. If you have issues playing a video, try `profile = "high"` or `profile = "main"`.
  
- `pixel_format = "yuv420p"`: A ffmpeg compatible pixel format (`-pix_fmt`). Currently only applies to `mp4`. Defaults to `yuv444p` for `profile = "high444"`.
  
- `loop = 0`: Number of times the video is repeated, for a `gif` or `html` output. Defaults to `0`, which means infinite looping. A value of `-1` turns off looping, and a value of `n > 0` means `n` repetitions (i.e. the video is played `n+1` times) when supported by backend.
  

::: warning Warning

`profile` and `pixel_format` are only used when `format` is `"mp4"`; a warning will be issued if `format` is not `"mp4"` and those two arguments are not `nothing`. Similarly, `compression` is only valid when `format` is `"mp4"` or `"webm"`.

:::

**Typical usage**

```julia
record(figure, "video.mp4", itr) do i
    func(i) # or some other manipulation of the figure
end
```


or, for more tweakability,

```julia
record(figure, "test.gif") do io
    for i = 1:100
        func!(figure)     # animate figure
        recordframe!(io)  # record a new frame
    end
end
```


If you want a more tweakable interface, consider using [`VideoStream`](/api#Makie.VideoStream-Tuple{Union{Figure,%20Makie.FigureAxisPlot,%20Scene}}) and [`save`](/api#FileIO.save-Tuple{String,%20Union{Figure,%20Makie.FigureAxisPlot,%20Scene}}).

**Extended help**

**Examples**

```julia
fig, ax, p = lines(rand(10))
record(fig, "test.gif") do io
    for i in 1:255
        p[:color] = RGBf(i/255, (255 - i)/255, 0) # animate figure
        recordframe!(io)
    end
end
```


or

```julia
fig, ax, p = lines(rand(10))
record(fig, "test.gif", 1:255) do i
    p[:color] = RGBf(i/255, (255 - i)/255, 0) # animate figure
end
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/recording.jl#L81-L145" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.record_events-Tuple{Any, Scene, String}' href='#Makie.record_events-Tuple{Any, Scene, String}'><span class="jlbinding">Makie.record_events</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
record_events(f, scene::Scene, path::String)
```


Records all window events that happen while executing function `f` for `scene` and serializes them to `path`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/event-recorder.jl#L2-L7" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.recordframe!-Tuple{VideoStream}' href='#Makie.recordframe!-Tuple{VideoStream}'><span class="jlbinding">Makie.recordframe!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
recordframe!(io::VideoStream)
```


Adds a video frame to the VideoStream `io`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/ffmpeg-util.jl#L286-L290" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.register_interaction!-Tuple{Any, Symbol, Any}' href='#Makie.register_interaction!-Tuple{Any, Symbol, Any}'><span class="jlbinding">Makie.register_interaction!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
register_interaction!(parent, name::Symbol, interaction)
```


Register `interaction` with `parent` under the name `name`. The parent will call `process_interaction(interaction, event, parent)` whenever suitable events happen.

The interaction can be removed with `deregister_interaction!` or temporarily toggled with `activate_interaction!` / `deactivate_interaction!`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/interactions.jl#L7-L16" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.register_interaction!-Tuple{Function, Any, Symbol}' href='#Makie.register_interaction!-Tuple{Function, Any, Symbol}'><span class="jlbinding">Makie.register_interaction!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
register_interaction!(interaction::Function, parent, name::Symbol)
```


Register `interaction` with `parent` under the name `name`. The parent will call `process_interaction(interaction, event, parent)` whenever suitable events happen. This form with the first `Function` argument is especially intended for `do` syntax.

The interaction can be removed with `deregister_interaction!` or temporarily toggled with `activate_interaction!` / `deactivate_interaction!`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/interactions.jl#L24-L34" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.replace_automatic!-Tuple{Any, Any, Any}' href='#Makie.replace_automatic!-Tuple{Any, Any, Any}'><span class="jlbinding">Makie.replace_automatic!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



Like `get!(f, dict, key)` but also calls `f` and replaces `key` when the corresponding value is nothing


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/utilities/utilities.jl#L38-L41" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.replay_events-Tuple{Scene, String}' href='#Makie.replay_events-Tuple{Scene, String}'><span class="jlbinding">Makie.replay_events</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
replay_events(f, scene::Scene, path::String)
replay_events(scene::Scene, path::String)
```


Replays the serialized events recorded with `record_events` in `path` in `scene`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/event-recorder.jl#L26-L31" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.resample_cmap-Tuple{Any, Integer}' href='#Makie.resample_cmap-Tuple{Any, Integer}'><span class="jlbinding">Makie.resample_cmap</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
resample_cmap(cmap, ncolors::Integer; alpha=1.0)
```

- cmap: anything that `to_colormap` accepts
  
- ncolors: number of desired colors
  
- alpha: additional alpha applied to each color. Can also be an array, matching `colors`, or a tuple giving a start + stop alpha value.
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/utilities/utilities.jl#L17-L23" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.reset_limits!-Tuple{Any}' href='#Makie.reset_limits!-Tuple{Any}'><span class="jlbinding">Makie.reset_limits!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
reset_limits!(ax; xauto = true, yauto = true)
```


Resets the axis limits depending on the value of `ax.limits`. If one of the two components of limits is nothing, that value is either copied from the targetlimits if `xauto` or `yauto` is false, respectively, or it is determined automatically from the plots in the axis. If one of the components is a tuple of two numbers, those are used directly.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/axis.jl#L551-L559" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.resize_to_layout!' href='#Makie.resize_to_layout!'><span class="jlbinding">Makie.resize_to_layout!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
resize_to_layout!(fig::Figure)
```


Resize `fig` so that it fits the current contents of its top `GridLayout`. If a `GridLayout` contains fixed-size content or aspect-constrained columns, for example, it is likely that the solved size of the `GridLayout` differs from the size of the `Figure`. This can result in superfluous whitespace at the borders, or content clipping at the figure edges. Once resized, all content should fit the available space, including the `Figure`&#39;s outer padding.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/figures.jl#L173-L183" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.rich-Tuple' href='#Makie.rich-Tuple'><span class="jlbinding">Makie.rich</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
rich(args...; kwargs...)
```


Create a `RichText` object containing all elements in `args`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/basic_recipes/text.jl#L310-L314" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.rlims!-Tuple{PolarAxis, Union{Nothing, Real, Symbol}}' href='#Makie.rlims!-Tuple{PolarAxis, Union{Nothing, Real, Symbol}}'><span class="jlbinding">Makie.rlims!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
rlims!(ax::PolarAxis[, rmin], rmax)
```


Sets the radial limits of a given `PolarAxis`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/polaraxis.jl#L1015-L1019" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.rotate!-Tuple{MakieCore.Transformable, Vararg{Any}}' href='#Makie.rotate!-Tuple{MakieCore.Transformable, Vararg{Any}}'><span class="jlbinding">Makie.rotate!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
rotate!(t::Transformable, axis_rot::Quaternion)
rotate!(t::Transformable, axis_rot::Real)
rotate!(t::Transformable, axis_rot...)
```


Apply an absolute rotation to the transformable. Rotations are all internally converted to `Quaternion`s.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/layouting/transformation.jl#L153-L159" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.rotate!-Union{Tuple{T}, Tuple{Type{T}, MakieCore.Transformable, Vararg{Any}}} where T' href='#Makie.rotate!-Union{Tuple{T}, Tuple{Type{T}, MakieCore.Transformable, Vararg{Any}}} where T'><span class="jlbinding">Makie.rotate!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
rotate!(Accum, t::Transformable, axis_rot...)
```


Apply a relative rotation to the transformable, by multiplying by the current rotation.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/layouting/transformation.jl#L146-L150" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.rotate_cam!' href='#Makie.rotate_cam!'><span class="jlbinding">Makie.rotate_cam!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
rotate_cam!(scene, cam::Camera3D, angles::Vec3)
```


Rotates the camera by the given `angles` around the camera x- (left, right), y- (up, down) and z-axis (in out). The rotation around the y axis is applied first, then x, then y.

Note that this method reacts to `fix_x_key` etc and `fixed_axis`. The former restrict the rotation around a specific axis when a given key is pressed. The latter keeps the camera y axis fixed as the data space z axis.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/camera/camera3d.jl#L515-L525" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.rotate_cam!-Tuple{Scene, Vararg{Number}}' href='#Makie.rotate_cam!-Tuple{Scene, Vararg{Number}}'><span class="jlbinding">Makie.rotate_cam!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
rotate_cam!(scene::Scene, theta_v::Number...)
rotate_cam!(scene::Scene, theta_v::VecTypes)
```


Rotate the camera of the Scene by the given rotation. Passing `theta_v = (α, β, γ)` will rotate the camera according to the Euler angles (α, β, γ).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/camera/old_camera3d.jl#L299-L305" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.scale!-Tuple{MakieCore.Transformable, Vararg{Any}}' href='#Makie.scale!-Tuple{MakieCore.Transformable, Vararg{Any}}'><span class="jlbinding">Makie.scale!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
scale!([mode = Absolute], t::Transformable, xyz...)
scale!([mode = Absolute], t::Transformable, xyz::VecTypes)
```


Scale the given `t::Transformable` (a Scene or Plot) to the given arguments `xyz`. Any missing dimension will be scaled by 1. If `mode == Accum` the given scaling will be multiplied with the previous one.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/layouting/transformation.jl#L120-L127" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.scatterlines' href='#Makie.scatterlines'><span class="jlbinding">Makie.scatterlines</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
scatterlines(xs, ys, [zs]; kwargs...)
```


Plots `scatter` markers and `lines` between them.

**Plot type**

The plot type alias for the `scatterlines` function is `ScatterLines`.

**Attributes**

**`alpha`** =  `1.0`  — The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`color`** =  `@inherit linecolor`  — The color of the line, and by default also of the scatter markers.

**`colormap`** =  `@inherit colormap :viridis`  — Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

**`colorrange`** =  `automatic`  — The values representing the start and end points of `colormap`.

**`colorscale`** =  `identity`  — The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.

**`cycle`** =  `[:color]`  — _No docs available._

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`fxaa`** =  `true`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`highclip`** =  `automatic`  — The color for any value above the colorrange.

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`joinstyle`** =  `@inherit joinstyle`  — _No docs available._

**`linecap`** =  `@inherit linecap`  — _No docs available._

**`linestyle`** =  `nothing`  — Sets the pattern of the line e.g. `:solid`, `:dot`, `:dashdot`. For custom patterns look at `Linestyle(Number[...])`

**`linewidth`** =  `@inherit linewidth`  — Sets the width of the line in screen units

**`lowclip`** =  `automatic`  — The color for any value below the colorrange.

**`marker`** =  `@inherit marker`  — Sets the scatter marker.

**`markercolor`** =  `automatic`  — _No docs available._

**`markercolormap`** =  `automatic`  — _No docs available._

**`markercolorrange`** =  `automatic`  — _No docs available._

**`markersize`** =  `@inherit markersize`  — Sets the size of the marker.

**`miter_limit`** =  `@inherit miter_limit`  — _No docs available._

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`nan_color`** =  `:transparent`  — The color for NaN values.

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`strokecolor`** =  `@inherit markerstrokecolor`  — Sets the color of the outline around a marker.

**`strokewidth`** =  `@inherit markerstrokewidth`  — Sets the width of the outline around a marker.

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L607" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.scatterlines!' href='#Makie.scatterlines!'><span class="jlbinding">Makie.scatterlines!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`scatterlines!` is the mutating variant of plotting function `scatterlines`. Check the docstring for `scatterlines` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.select_line-Tuple{Any}' href='#Makie.select_line-Tuple{Any}'><span class="jlbinding">Makie.select_line</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
select_line(scene; kwargs...) -> line
```


Interactively select a line (typically an arrow) on a 2D `scene` by clicking the left mouse button, dragging and then un-clicking. Return an **observable** whose value corresponds to the selected line on the scene. In addition the function _plots_ the line on the scene as the user clicks and moves the mouse around. When the button is not clicked any more, the plotted line disappears.

The value of the returned line is updated **only** when the user un-clicks and only if the selected line has non-zero length.

The `kwargs...` are propagated into `lines!` which plots the selected line.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/interaction/interactive_api.jl#L306-L319" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.select_point-Tuple{Any}' href='#Makie.select_point-Tuple{Any}'><span class="jlbinding">Makie.select_point</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
select_point(scene; kwargs...) -> point
```


Interactively select a point on a 2D `scene` by clicking the left mouse button, dragging and then un-clicking. Return an **observable** whose value corresponds to the selected point on the scene. In addition the function _plots_ the point on the scene as the user clicks and moves the mouse around. When the button is not clicked any more, the plotted point disappears.

The value of the returned point is updated **only** when the user un-clicks.

The `kwargs...` are propagated into `scatter!` which plots the selected point.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/interaction/interactive_api.jl#L368-L380" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.select_rectangle-Tuple{Any}' href='#Makie.select_rectangle-Tuple{Any}'><span class="jlbinding">Makie.select_rectangle</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
select_rectangle(scene; kwargs...) -> rect
```


Interactively select a rectangle on a 2D `scene` by clicking the left mouse button, dragging and then un-clicking. The function returns an **observable** `rect` whose value corresponds to the selected rectangle on the scene. In addition the function _plots_ the selected rectangle on the scene as the user clicks and moves the mouse around. When the button is not clicked any more, the plotted rectangle disappears.

The value of the returned observable is updated **only** when the user un-clicks (i.e. when the final value of the rectangle has been decided) and only if the rectangle has area &gt; 0.

The `kwargs...` are propagated into `lines!` which plots the selected rectangle.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/interaction/interactive_api.jl#L241-L255" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.series' href='#Makie.series'><span class="jlbinding">Makie.series</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
series(curves)
```


Curves can be:
- `AbstractVector{<: AbstractVector{<: Point2}}`: the native representation of a series as a vector of lines
  
- `AbstractMatrix`: each row represents y coordinates of the line, while `x` goes from `1:size(curves, 1)`
  
- `AbstractVector, AbstractMatrix`: the same as the above, but the first argument sets the x values for all lines
  
- `AbstractVector{<: Tuple{X<: AbstractVector, Y<: AbstractVector}}`: A vector of tuples, where each tuple contains a vector for the x and y coordinates
  

If any of `marker`, `markersize`, `markercolor`, `strokecolor` or `strokewidth` is set != nothing, a scatterplot is added.

**Plot type**

The plot type alias for the `series` function is `Series`.

**Attributes**

**`color`** =  `:lighttest`  — _No docs available._

**`joinstyle`** =  `@inherit joinstyle`  — _No docs available._

**`labels`** =  `nothing`  — _No docs available._

**`linecap`** =  `@inherit linecap`  — _No docs available._

**`linestyle`** =  `:solid`  — _No docs available._

**`linewidth`** =  `2`  — _No docs available._

**`marker`** =  `nothing`  — _No docs available._

**`markercolor`** =  `automatic`  — _No docs available._

**`markersize`** =  `nothing`  — _No docs available._

**`miter_limit`** =  `@inherit miter_limit`  — _No docs available._

**`solid_color`** =  `nothing`  — _No docs available._

**`space`** =  `:data`  — _No docs available._

**`strokecolor`** =  `nothing`  — _No docs available._

**`strokewidth`** =  `nothing`  — _No docs available._


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L565" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.series!' href='#Makie.series!'><span class="jlbinding">Makie.series!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`series!` is the mutating variant of plotting function `series`. Check the docstring for `series` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.set_close_to!-Tuple{IntervalSlider, Any, Any}' href='#Makie.set_close_to!-Tuple{IntervalSlider, Any, Any}'><span class="jlbinding">Makie.set_close_to!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



Set the `slider` to the values in the slider&#39;s range that are closest to `v1` and `v2`, and return those values ordered min, misl.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/intervalslider.jl#L264-L266" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.set_close_to!-Tuple{Slider, Any}' href='#Makie.set_close_to!-Tuple{Slider, Any}'><span class="jlbinding">Makie.set_close_to!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
set_close_to!(slider, value) -> closest_value
```


Set the `slider` to the value in the slider&#39;s range that is closest to `value` and return this value. This function should be used to set a slider to a value programmatically, rather than mutating its value observable directly, which doesn&#39;t update the slider visually.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/slider.jl#L199-L205" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.set_theme!' href='#Makie.set_theme!'><span class="jlbinding">Makie.set_theme!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
set_theme!(theme; kwargs...)
```


Set the global default theme to `theme` and add / override any attributes given as keyword arguments.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/theming.jl#L196-L201" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.showgradients-Tuple{AbstractVector{Symbol}}' href='#Makie.showgradients-Tuple{AbstractVector{Symbol}}'><span class="jlbinding">Makie.showgradients</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
showgradients(
    cgrads::AbstractVector{Symbol};
    h = 0.0, offset = 0.2, fontsize = 0.7,
    size = (800, length(cgrads) * 84)
)::Scene
```


Plots the given colour gradients arranged as horizontal colourbars. If you change the offsets or the font size, you may need to change the resolution.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/basic_recipes/convenience_functions.jl#L15-L24" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.spy' href='#Makie.spy'><span class="jlbinding">Makie.spy</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
spy(z::AbstractSparseArray)
spy(x_range::NTuple{2, Number}, y_range::NTuple{2, Number}, z::AbstractSparseArray)
spy(x_range::ClosedInterval, y_range::ClosedInterval, z::AbstractSparseArray)
```


Visualizes big sparse matrices. Usage:

```julia
using SparseArrays, GLMakie
N = 200_000
x = sprand(Float64, N, N, (3(10^6)) / (N*N));
spy(x)
# or if you want to specify the range of x and y:
spy(0..1, 0..1, x)
```


**Plot type**

The plot type alias for the `spy` function is `Spy`.

**Attributes**

**`alpha`** =  `1.0`  — The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`color`** =  `nothing`  — Per default the color of the markers will be determined by the value in the matrix, but can be overwritten via `color`.

**`colormap`** =  `@inherit colormap :viridis`  — Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

**`colorrange`** =  `automatic`  — The values representing the start and end points of `colormap`.

**`colorscale`** =  `identity`  — The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`framecolor`** =  `:black`  — By default a frame will be drawn around the data, which uses the `framecolor` attribute for its color.

**`framesize`** =  `1`  — The linewidth of the frame

**`framevisible`** =  `true`  — Whether or not to draw the frame.

**`fxaa`** =  `true`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`highclip`** =  `automatic`  — The color for any value above the colorrange.

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`lowclip`** =  `automatic`  — The color for any value below the colorrange.

**`marker`** =  `Rect`  — Can be any of the markers supported by `scatter!`. Note, for huge sparse arrays, one should use `FastPixel`, which is a very fast, but can only render square markers. So, without `Axis(...; aspect=1)`, the markers won&#39;t have the correct size. Compare:

```julia
data = sprand(10, 10, 0.5)
f = Figure()
spy(f[1, 1], data; marker=FastPixel())
spy(f[1, 2], data; marker=FastPixel(), axis=(; aspect=1))
f
```


**`marker_gap`** =  `0`  — Makes the marker size smaller to create a gap between the markers. The unit of this is in data space.

**`markersize`** =  `automatic`  — markersize=automatic, will make the marker size fit the data - but can also be set manually.

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`nan_color`** =  `:transparent`  — The color for NaN values.

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L622" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.spy!' href='#Makie.spy!'><span class="jlbinding">Makie.spy!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`spy!` is the mutating variant of plotting function `spy`. Check the docstring for `spy` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.stairs' href='#Makie.stairs'><span class="jlbinding">Makie.stairs</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
stairs(xs, ys; kwargs...)
```


Plot a stair function.

The conversion trait of `stairs` is `PointBased`.

**Plot type**

The plot type alias for the `stairs` function is `Stairs`.

**Attributes**

**`alpha`** =  `1.0`  — The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`color`** =  `@inherit linecolor`  — The color of the line.

**`colormap`** =  `@inherit colormap :viridis`  — Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

**`colorrange`** =  `automatic`  — The values representing the start and end points of `colormap`.

**`colorscale`** =  `identity`  — The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.

**`cycle`** =  `[:color]`  — Sets which attributes to cycle when creating multiple plots.

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`fxaa`** =  `false`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`highclip`** =  `automatic`  — The color for any value above the colorrange.

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`joinstyle`** =  `@inherit joinstyle`  — Controls the rendering at corners. Options are `:miter` for sharp corners, `:bevel` for &quot;cut off&quot; corners, and `:round` for rounded corners. If the corner angle is below `miter_limit`, `:miter` is equivalent to `:bevel` to avoid long spikes.

**`linecap`** =  `@inherit linecap`  — Sets the type of line cap used. Options are `:butt` (flat without extrusion), `:square` (flat with half a linewidth extrusion) or `:round`.

**`linestyle`** =  `nothing`  — Sets the dash pattern of the line. Options are `:solid` (equivalent to `nothing`), `:dot`, `:dash`, `:dashdot` and `:dashdotdot`. These can also be given in a tuple with a gap style modifier, either `:normal`, `:dense` or `:loose`. For example, `(:dot, :loose)` or `(:dashdot, :dense)`.

For custom patterns have a look at [`Makie.Linestyle`](/api#Makie.Linestyle).

**`linewidth`** =  `@inherit linewidth`  — Sets the width of the line in screen units

**`lowclip`** =  `automatic`  — The color for any value below the colorrange.

**`miter_limit`** =  `@inherit miter_limit`  — Sets the minimum inner join angle below which miter joins truncate. See also `Makie.miter_distance_to_angle`.

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`nan_color`** =  `:transparent`  — The color for NaN values.

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`step`** =  `:pre`  — The `step` parameter can take the following values:
- `:pre`: horizontal part of step extends to the left of each value in `xs`.
  
- `:post`: horizontal part of step extends to the right of each value in `xs`.
  
- `:center`: horizontal part of step extends halfway between the two adjacent values of `xs`.
  

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L611" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.stairs!' href='#Makie.stairs!'><span class="jlbinding">Makie.stairs!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`stairs!` is the mutating variant of plotting function `stairs`. Check the docstring for `stairs` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.stem' href='#Makie.stem'><span class="jlbinding">Makie.stem</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
stem(xs, ys, [zs]; kwargs...)
```


Plots markers at the given positions extending from `offset` along stem lines.

The conversion trait of `stem` is `PointBased`.

**Plot type**

The plot type alias for the `stem` function is `Stem`.

**Attributes**

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`color`** =  `@inherit markercolor`  — _No docs available._

**`colormap`** =  `@inherit colormap`  — _No docs available._

**`colorrange`** =  `automatic`  — _No docs available._

**`colorscale`** =  `identity`  — _No docs available._

**`cycle`** =  `[[:stemcolor, :color, :trunkcolor] => :color]`  — _No docs available._

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`fxaa`** =  `true`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`marker`** =  `:circle`  — _No docs available._

**`markersize`** =  `@inherit markersize`  — _No docs available._

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`offset`** =  `0`  — Can be a number, in which case it sets `y` for 2D, and `z` for 3D stems. It can be a `Point2` for 2D plots, as well as a `Point3` for 3D plots. It can also be an iterable of any of these at the same length as `xs`, `ys`, `zs`.

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`stemcolor`** =  `@inherit linecolor`  — _No docs available._

**`stemcolormap`** =  `@inherit colormap`  — _No docs available._

**`stemcolorrange`** =  `automatic`  — _No docs available._

**`stemlinestyle`** =  `nothing`  — _No docs available._

**`stemwidth`** =  `@inherit linewidth`  — _No docs available._

**`strokecolor`** =  `@inherit markerstrokecolor`  — _No docs available._

**`strokewidth`** =  `@inherit markerstrokewidth`  — _No docs available._

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`trunkcolor`** =  `@inherit linecolor`  — _No docs available._

**`trunkcolormap`** =  `@inherit colormap`  — _No docs available._

**`trunkcolorrange`** =  `automatic`  — _No docs available._

**`trunklinestyle`** =  `nothing`  — _No docs available._

**`trunkwidth`** =  `@inherit linewidth`  — _No docs available._

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L606" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.stem!' href='#Makie.stem!'><span class="jlbinding">Makie.stem!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`stem!` is the mutating variant of plotting function `stem`. Check the docstring for `stem` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.stephist' href='#Makie.stephist'><span class="jlbinding">Makie.stephist</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
stephist(values)
```


Plot a step histogram of `values`.

**Plot type**

The plot type alias for the `stephist` function is `StepHist`.

**Attributes**

**`bins`** =  `15`  — Can be an `Int` to create that number of equal-width bins over the range of `values`. Alternatively, it can be a sorted iterable of bin edges.

**`color`** =  `@inherit patchcolor`  — _No docs available._

**`cycle`** =  `[:color => :patchcolor]`  — _No docs available._

**`linestyle`** =  `:solid`  — _No docs available._

**`linewidth`** =  `@inherit linewidth`  — _No docs available._

**`normalization`** =  `:none`  — Allows to apply a normalization to the histogram. Possible values are:
- `:pdf`: Normalize by sum of weights and bin sizes. Resulting histogram has norm 1 and represents a PDF.
  
- `:density`: Normalize by bin sizes only. Resulting histogram represents count density of input and does not have norm 1. Will not modify the histogram if it already represents a density (`h.isdensity == 1`).
  
- `:probability`: Normalize by sum of weights only. Resulting histogram represents the fraction of probability mass for each bin and does not have norm 1.
  
- `:none`: Do not normalize.
  

**`scale_to`** =  `nothing`  — Allows to scale all values to a certain height.

**`weights`** =  `automatic`  — Allows to provide statistical weights.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L558" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.stephist!' href='#Makie.stephist!'><span class="jlbinding">Makie.stephist!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`stephist!` is the mutating variant of plotting function `stephist`. Check the docstring for `stephist` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.streamplot' href='#Makie.streamplot'><span class="jlbinding">Makie.streamplot</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
streamplot(f::function, xinterval, yinterval; color = norm, kwargs...)
```


f must either accept `f(::Point)` or `f(x::Number, y::Number)`. f must return a Point2.

Example:

```julia
v(x::Point2{T}) where T = Point2f(x[2], 4*x[1])
streamplot(v, -2..2, -2..2)
```


**Implementation**

See the function `Makie.streamplot_impl` for implementation details.

**Plot type**

The plot type alias for the `streamplot` function is `StreamPlot`.

**Attributes**

**`alpha`** =  `1.0`  — The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

**`arrow_head`** =  `automatic`  — _No docs available._

**`arrow_size`** =  `automatic`  — _No docs available._

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`color`** =  `norm`  — One can choose the color of the lines by passing a function `color_func(dx::Point)` to the `color` attribute. This can be set to any function or composition of functions. The `dx` which is passed to `color_func` is the output of `f` at the point being colored.

**`colormap`** =  `@inherit colormap :viridis`  — Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

**`colorrange`** =  `automatic`  — The values representing the start and end points of `colormap`.

**`colorscale`** =  `identity`  — The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.

**`density`** =  `1.0`  — _No docs available._

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`fxaa`** =  `true`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`gridsize`** =  `(32, 32, 32)`  — _No docs available._

**`highclip`** =  `automatic`  — The color for any value above the colorrange.

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`joinstyle`** =  `@inherit joinstyle`  — _No docs available._

**`linecap`** =  `@inherit linecap`  — _No docs available._

**`linestyle`** =  `nothing`  — _No docs available._

**`linewidth`** =  `@inherit linewidth`  — _No docs available._

**`lowclip`** =  `automatic`  — The color for any value below the colorrange.

**`maxsteps`** =  `500`  — _No docs available._

**`miter_limit`** =  `@inherit miter_limit`  — _No docs available._

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`nan_color`** =  `:transparent`  — The color for NaN values.

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`quality`** =  `16`  — _No docs available._

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`stepsize`** =  `0.01`  — _No docs available._

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L619" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.streamplot!' href='#Makie.streamplot!'><span class="jlbinding">Makie.streamplot!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`streamplot!` is the mutating variant of plotting function `streamplot`. Check the docstring for `streamplot` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.subscript-Tuple' href='#Makie.subscript-Tuple'><span class="jlbinding">Makie.subscript</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
subscript(args...; kwargs...)
```


Create a `RichText` object representing a superscript containing all elements in `args`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/basic_recipes/text.jl#L316-L320" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.subsup-Tuple' href='#Makie.subsup-Tuple'><span class="jlbinding">Makie.subsup</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
subsup(subscript, superscript; kwargs...)
```


Create a `RichText` object representing a right subscript/superscript combination, where both scripts are left-aligned against the preceding text.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/basic_recipes/text.jl#L328-L333" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.superscript-Tuple' href='#Makie.superscript-Tuple'><span class="jlbinding">Makie.superscript</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
superscript(args...; kwargs...)
```


Create a `RichText` object representing a superscript containing all elements in `args`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/basic_recipes/text.jl#L322-L326" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.textlabel' href='#Makie.textlabel'><span class="jlbinding">Makie.textlabel</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
textlabel(positions, text; attributes...)
textlabel(position; text, attributes...)
textlabel(text_position; attributes...)
```


Plots the given text(s) with a background(s) at the given position(s).

**Plot type**

The plot type alias for the `textlabel` function is `TextLabel`.

**Attributes**

**`alpha`** =  `1.0`  — Sets the alpha value (opaqueness) of the background.

**`background_color`** =  `:white`  — Sets the color of the background. Can be a `Vector{<:Colorant}` for per vertex colors, a single `Colorant` or an `<: AbstractPattern` to cover the poly with a regular pattern, e.g. for hatching.

**`clip_planes`** =  `Plane3f[]`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`cornerradius`** =  `5.0`  — Sets the corner radius when given a Rect2 background shape.

**`cornervertices`** =  `10`  — Sets the number of vertices involved in a rounded corner. Must be at least 2.

**`depth_shift`** =  `0.0`  — Adjusts the depth value of the textlabel after all other transformations, i.e. in clip space where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`draw_on_top`** =  `true`  — Controls whether the textlabel is drawn in front (true, default) or at a depth appropriate to its position.

**`font`** =  `@inherit font`  — Sets the font. Can be a `Symbol` which will be looked up in the `fonts` dictionary or a `String` specifying the (partial) name of a font or the file path of a font file

**`fonts`** =  `@inherit fonts`  — Used as a dictionary to look up fonts specified by `Symbol`, for example `:regular`, `:bold` or `:italic`.

**`fontsize`** =  `@inherit fontsize`  — The fontsize in pixel units.

**`fxaa`** =  `false`  — Controls whether the background renders with fxaa (anti-aliasing, GLMakie only). This is set to `false` by default to prevent artifacts around text.

**`inspectable`** =  `@inherit inspectable`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`joinstyle`** =  `@inherit joinstyle`  — Controls the rendering of outline corners. Options are `:miter` for sharp corners, `:bevel` for &quot;cut off&quot; corners, and `:round` for rounded corners. If the corner angle is below `miter_limit`, `:miter` is equivalent to `:bevel` to avoid long spikes.

**`justification`** =  `automatic`  — Sets the alignment of text with respect to its bounding box. Can be `:left, :center, :right` or a fraction. Will default to the horizontal alignment in `text_align`.

**`keep_aspect`** =  `false`  — Controls whether the aspect ratio of the background shape is kept during rescaling

**`lineheight`** =  `1.0`  — The lineheight multiplier.

**`linestyle`** =  `nothing`  — Sets the dash pattern of the outline. Options are `:solid` (equivalent to `nothing`), `:dot`, `:dash`, `:dashdot` and `:dashdotdot`. These can also be given in a tuple with a gap style modifier, either `:normal`, `:dense` or `:loose`. For example, `(:dot, :loose)` or `(:dashdot, :dense)`.

For custom patterns have a look at [`Makie.Linestyle`](/api#Makie.Linestyle).

**`miter_limit`** =  `@inherit miter_limit`  — Sets the minimum inner join angle below which miter joins truncate. See also `Makie.miter_distance_to_angle`.

**`offset`** =  `(0.0, 0.0)`  — The offset of the textlabel from the given position in `markerspace` units.

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`padding`** =  `4`  — Sets the padding between the text bounding box and background shape.

**`position`** =  `(0, 0)`  — Deprecated: Specifies the position of the text. Use the positional argument to `text` instead.

**`shading`** =  `NoShading`  — Controls whether the background reacts to light.

**`shape`** =  `Rect2f(0, 0, 1, 1)`  — Controls the shape of the background. Can be a GeometryPrimitive, mesh or function `(origin, size) -> coordinates`. The former two options are automatically rescaled to the padded bounding box of the rendered text. By default (0, 0) will be the lower left corner and (1, 1) the upper right corner of the padded bounding box. See `shape_limits`.

**`shape_limits`** =  `Rect2f(0, 0, 1, 1)`  — Sets the coordinates in `shape` space that should be transformed to match the size of the text bounding box. For example, `shape_limits = Rect2f(-1, -1, 2, 2)` results in transforming (-1, 1) to the lower left corner of the padded text bounding box and (1, 1) to the upper right corner. If the `shape` contains coordinates outside this range, they will rendered outside the padded text bounding box.

**`space`** =  `:data`  — sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`stroke_alpha`** =  `1.0`  — Sets the alpha value (opaqueness) of the background outline.

**`strokecolor`** =  `:black`  — Sets the color of the outline around the background

**`strokewidth`** =  `1`  — Sets the width of the outline.

**`text`** =  `""`  — Specifies one piece of text or a vector of texts to show, where the number has to match the number of positions given. Makie supports `String` which is used for all normal text and `LaTeXString` which layouts mathematical expressions using `MathTeXEngine.jl`.

**`text_align`** =  `(:center, :center)`  — Sets the alignment of the string with respect to `position`. Uses `:left, :center, :right, :top, :bottom, :baseline` or fractions.

**`text_alpha`** =  `1.0`  — Sets the alpha value (opaqueness) of the text.

**`text_color`** =  `@inherit textcolor`  — Sets the color of the text. One can set one color per glyph by passing a `Vector{<:Colorant}` or one colorant for the whole text.

**`text_fxaa`** =  `false`  — Controls whether the text renders with fxaa (anti-aliasing, GLMakie only). Setting this to true will reduce text quality.

**`text_glowcolor`** =  `(:black, 0.0)`  — Sets the color of the glow effect around text.

**`text_glowwidth`** =  `0.0`  — Sets the size of a glow effect around text.

**`text_rotation`** =  `0.0`  — Rotates the text around the given position. This affects the size of the textlabel but not its rotation

**`text_strokecolor`** =  `(:black, 0.0)`  — Sets the color of the outline around text.

**`text_strokewidth`** =  `0`  — Sets the width of the outline around text.

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.

**`word_wrap_width`** =  `-1`  — Specifies a linewidth limit for text. If a word overflows this limit, a newline is inserted before it. Negative numbers disable word wrapping.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L642" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.textlabel!' href='#Makie.textlabel!'><span class="jlbinding">Makie.textlabel!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`textlabel!` is the mutating variant of plotting function `textlabel`. Check the docstring for `textlabel` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.thetalims!-Tuple{PolarAxis, Union{Nothing, Real}, Union{Nothing, Real}}' href='#Makie.thetalims!-Tuple{PolarAxis, Union{Nothing, Real}, Union{Nothing, Real}}'><span class="jlbinding">Makie.thetalims!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
thetalims!(ax::PolarAxis, thetamin, thetamax)
```


Sets the angular limits of a given `PolarAxis`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/polaraxis.jl#L1027-L1031" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.tight_ticklabel_spacing!' href='#Makie.tight_ticklabel_spacing!'><span class="jlbinding">Makie.tight_ticklabel_spacing!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
tight_ticklabel_spacing!(ax::Axis)
```


Sets the space allocated for the xticklabels and yticklabels of the `Axis` to the minimum that is needed.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/axis.jl#L1227-L1231" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.tight_ticklabel_spacing!-Tuple{Colorbar}' href='#Makie.tight_ticklabel_spacing!-Tuple{Colorbar}'><span class="jlbinding">Makie.tight_ticklabel_spacing!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
space = tight_ticklabel_spacing!(cb::Colorbar)
```


Sets the space allocated for the ticklabels of the `Colorbar` to the minimum that is needed and returns that value.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/colorbar.jl#L427-L431" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.tight_xticklabel_spacing!' href='#Makie.tight_xticklabel_spacing!'><span class="jlbinding">Makie.tight_xticklabel_spacing!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
space = tight_xticklabel_spacing!(ax::Axis)
```


Sets the space allocated for the xticklabels of the `Axis` to the minimum that is needed and returns that value.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/axis.jl#L1217-L1221" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.tight_yticklabel_spacing!' href='#Makie.tight_yticklabel_spacing!'><span class="jlbinding">Makie.tight_yticklabel_spacing!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
space = tight_yticklabel_spacing!(ax::Axis)
```


Sets the space allocated for the yticklabels of the `Axis` to the minimum that is needed and returns that value.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/axis.jl#L1207-L1211" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.tightlimits!-Tuple{Axis, Vararg{Union{Bottom, Left, Right, Top}}}' href='#Makie.tightlimits!-Tuple{Axis, Vararg{Union{Bottom, Left, Right, Top}}}'><span class="jlbinding">Makie.tightlimits!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
tightlimits!(la::Axis, sides::Union{Left, Right, Bottom, Top}...)
```


Sets the autolimit margins to zero on all given sides.

Example:

```julia
tightlimits!(laxis, Bottom())
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/helpers.jl#L103-L113" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.tightlimits!-Tuple{Axis}' href='#Makie.tightlimits!-Tuple{Axis}'><span class="jlbinding">Makie.tightlimits!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
tightlimits!(la::Axis)
```


Sets the autolimit margins to zero on all sides.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/helpers.jl#L92-L96" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.timeseries' href='#Makie.timeseries'><span class="jlbinding">Makie.timeseries</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
timeseries(x::Observable{{Union{Number, Point2}}})
```


Plots a sampled signal.

Usage:

```julia
signal = Observable(1.0)
scene = timeseries(signal)
display(scene)
# @async is optional, but helps to continue evaluating more code
@async while isopen(scene)
    # acquire data from e.g. a sensor:
    data = rand()
    # update the signal
    signal[] = data
    # sleep/ wait for new data/ whatever...
    # It's important to yield here though, otherwise nothing will be rendered
    sleep(1/30)
end

```


**Plot type**

The plot type alias for the `timeseries` function is `TimeSeries`.

**Attributes**

**`alpha`** =  `1.0`  — The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`color`** =  `@inherit linecolor`  — The color of the line.

**`colormap`** =  `@inherit colormap :viridis`  — Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

**`colorrange`** =  `automatic`  — The values representing the start and end points of `colormap`.

**`colorscale`** =  `identity`  — The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.

**`cycle`** =  `[:color]`  — Sets which attributes to cycle when creating multiple plots.

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`fxaa`** =  `false`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`highclip`** =  `automatic`  — The color for any value above the colorrange.

**`history`** =  `100`  — _No docs available._

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`joinstyle`** =  `@inherit joinstyle`  — Controls the rendering at corners. Options are `:miter` for sharp corners, `:bevel` for &quot;cut off&quot; corners, and `:round` for rounded corners. If the corner angle is below `miter_limit`, `:miter` is equivalent to `:bevel` to avoid long spikes.

**`linecap`** =  `@inherit linecap`  — Sets the type of line cap used. Options are `:butt` (flat without extrusion), `:square` (flat with half a linewidth extrusion) or `:round`.

**`linestyle`** =  `nothing`  — Sets the dash pattern of the line. Options are `:solid` (equivalent to `nothing`), `:dot`, `:dash`, `:dashdot` and `:dashdotdot`. These can also be given in a tuple with a gap style modifier, either `:normal`, `:dense` or `:loose`. For example, `(:dot, :loose)` or `(:dashdot, :dense)`.

For custom patterns have a look at [`Makie.Linestyle`](/api#Makie.Linestyle).

**`linewidth`** =  `@inherit linewidth`  — Sets the width of the line in screen units

**`lowclip`** =  `automatic`  — The color for any value below the colorrange.

**`miter_limit`** =  `@inherit miter_limit`  — Sets the minimum inner join angle below which miter joins truncate. See also `Makie.miter_distance_to_angle`.

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`nan_color`** =  `:transparent`  — The color for NaN values.

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L624" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.timeseries!' href='#Makie.timeseries!'><span class="jlbinding">Makie.timeseries!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`timeseries!` is the mutating variant of plotting function `timeseries`. Check the docstring for `timeseries` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.to_align-Tuple{Tuple}' href='#Makie.to_align-Tuple{Tuple}'><span class="jlbinding">Makie.to_align</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
to_align(align[, error_prefix])
```


Converts the given align to a `Vec2f`. Can convert `VecTypes{2}` and two component `Tuple`s with `Real` and `Symbol` elements.

To specify a custom error message you can add an `error_prefix` or use `halign2num(value, error_msg)` and `valign2num(value, error_msg)` respectively.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/conversions.jl#L1305-L1313" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.to_colormap-Tuple{AbstractVector}' href='#Makie.to_colormap-Tuple{AbstractVector}'><span class="jlbinding">Makie.to_colormap</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
to_colormap(b::AbstractVector)
```


An `AbstractVector{T}` with any object that `to_color` accepts.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/conversions.jl#L1566-L1570" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.to_colormap-Tuple{Union{String, Symbol}}' href='#Makie.to_colormap-Tuple{Union{String, Symbol}}'><span class="jlbinding">Makie.to_colormap</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
to_colormap(cs::Union{String, Symbol})::Vector{RGBAf}
```


A Symbol/String naming the gradient. For more on what names are available please see: `available_gradients()`. For now, we support gradients from `PlotUtils` natively.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/conversions.jl#L1579-L1584" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.to_font-Tuple{String}' href='#Makie.to_font-Tuple{String}'><span class="jlbinding">Makie.to_font</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
to_font(str::String)
```


Loads a font specified by `str` and returns a `NativeFont` object storing the font handle. A font can either be specified by a file path, such as &quot;folder/with/fonts/font.otf&quot;, or by a (partial) name such as &quot;Helvetica&quot;, &quot;Helvetica Bold&quot; etc.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/conversions.jl#L1394-L1400" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.to_rotation-Tuple{Quaternionf}' href='#Makie.to_rotation-Tuple{Quaternionf}'><span class="jlbinding">Makie.to_rotation</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
rotation accepts:
to_rotation(b, quaternion)
to_rotation(b, tuple_float)
to_rotation(b, vec4)
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/conversions.jl#L1448-L1453" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.tooltip' href='#Makie.tooltip'><span class="jlbinding">Makie.tooltip</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
tooltip(position, string)
tooltip(x, y, string)
```


Creates a tooltip pointing at `position` displaying the given `string

**Plot type**

The plot type alias for the `tooltip` function is `Tooltip`.

**Attributes**

**`align`** =  `0.5`  — Sets the alignment of the tooltip relative `position`. With `align = 0.5` the tooltip is centered above/below/left/right the `position`.

**`backgroundcolor`** =  `:white`  — Sets the background color of the tooltip.

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`font`** =  `@inherit font`  — Sets the font.

**`fontsize`** =  `16`  — Sets the text size in screen units.

**`fxaa`** =  `true`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`inspectable`** =  `false`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`justification`** =  `:left`  — Sets whether text is aligned to the `:left`, `:center` or `:right` within its bounding box.

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`offset`** =  `10`  — Sets the offset between the given `position` and the tip of the triangle pointing at that position.

**`outline_color`** =  `:black`  — Sets the color of the tooltip outline.

**`outline_linestyle`** =  `nothing`  — Sets the linestyle of the tooltip outline.

**`outline_linewidth`** =  `2.0`  — Sets the linewidth of the tooltip outline.

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`placement`** =  `:above`  — Sets where the tooltip should be placed relative to `position`. Can be `:above`, `:below`, `:left`, `:right`.

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`strokecolor`** =  `:white`  — Sets the text outline color.

**`strokewidth`** =  `0`  — Gives text an outline if set to a positive value.

**`text`** =  `""`  — _No docs available._

**`textcolor`** =  `@inherit textcolor`  — Sets the text color.

**`textpadding`** =  `(4, 4, 4, 4)`  — Sets the padding around text in the tooltip. This is given as `(left, right, bottom, top)` offsets.

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`triangle_size`** =  `10`  — Sets the size of the triangle pointing at `position`.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.

**`xautolimits`** =  `false`  — _No docs available._

**`yautolimits`** =  `false`  — _No docs available._

**`zautolimits`** =  `false`  — _No docs available._


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L600" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.tooltip!' href='#Makie.tooltip!'><span class="jlbinding">Makie.tooltip!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`tooltip!` is the mutating variant of plotting function `tooltip`. Check the docstring for `tooltip` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.translate!-Tuple{MakieCore.Transformable, Union{NTuple{N, T}, StaticArraysCore.StaticArray{Tuple{N}, T, 1}} where {N, T}}' href='#Makie.translate!-Tuple{MakieCore.Transformable, Union{NTuple{N, T}, StaticArraysCore.StaticArray{Tuple{N}, T, 1}} where {N, T}}'><span class="jlbinding">Makie.translate!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
translate!(t::Transformable, xyz::VecTypes)
translate!(t::Transformable, xyz...)
```


Apply an absolute translation to the given `Transformable` (a Scene or Plot), translating it to `x, y, z`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/layouting/transformation.jl#L176-L181" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.translate!-Union{Tuple{T}, Tuple{Type{T}, MakieCore.Transformable, Vararg{Any}}} where T' href='#Makie.translate!-Union{Tuple{T}, Tuple{Type{T}, MakieCore.Transformable, Vararg{Any}}} where T'><span class="jlbinding">Makie.translate!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
translate!(Accum, t::Transformable, xyz...)
```


Translate the given `Transformable` (a Scene or Plot), relative to its current position.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/layouting/transformation.jl#L185-L189" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.translate_cam!-Tuple{Any, Camera3D, Union{NTuple{N, T}, StaticArraysCore.StaticArray{Tuple{N}, T, 1}} where {N, T}}' href='#Makie.translate_cam!-Tuple{Any, Camera3D, Union{NTuple{N, T}, StaticArraysCore.StaticArray{Tuple{N}, T, 1}} where {N, T}}'><span class="jlbinding">Makie.translate_cam!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
translate_cam!(scene, cam::Camera3D, v::Vec3)
```


Translates the camera by the given vector in camera space, i.e. by `v[1]` to the right, `v[2]` to the top and `v[3]` forward.

Note that this method reacts to `fix_x_key` etc. If any of those keys are pressed the translation will be restricted to act in these directions.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/camera/camera3d.jl#L500-L508" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.translate_cam!-Tuple{Scene, Union{NTuple{N, T}, StaticArraysCore.StaticArray{Tuple{N}, T, 1}} where {N, T}}' href='#Makie.translate_cam!-Tuple{Scene, Union{NTuple{N, T}, StaticArraysCore.StaticArray{Tuple{N}, T, 1}} where {N, T}}'><span class="jlbinding">Makie.translate_cam!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
translate_cam!(scene::Scene, translation::VecTypes)
```


Translate the camera by a translation vector given in camera space.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/camera/old_camera3d.jl#L229-L233" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.tricontourf' href='#Makie.tricontourf'><span class="jlbinding">Makie.tricontourf</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
tricontourf(triangles::Triangulation, zs; kwargs...)
tricontourf(xs, ys, zs; kwargs...)
```


Plots a filled tricontour of the height information in `zs` at the horizontal positions `xs` and vertical positions `ys`. A `Triangulation` from DelaunayTriangulation.jl can also be provided instead of `xs` and `ys` for specifying the triangles, otherwise an unconstrained triangulation of `xs` and `ys` is computed.

**Plot type**

The plot type alias for the `tricontourf` function is `Tricontourf`.

**Attributes**

**`alpha`** =  `1.0`  — The alpha value of the colormap or color attribute.

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`colormap`** =  `@inherit colormap`  — Sets the colormap from which the band colors are sampled.

**`colorscale`** =  `identity`  — Color transform function

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`edges`** =  `nothing`  — _No docs available._

**`extendhigh`** =  `nothing`  — This sets the color of an optional additional band from the highest value of `levels` to `maximum(zs)`. If it&#39;s `:auto`, the high end of the colormap is picked and the remaining colors are shifted accordingly. If it&#39;s any color representation, this color is used. If it&#39;s `nothing`, no band is added.

**`extendlow`** =  `nothing`  — This sets the color of an optional additional band from `minimum(zs)` to the lowest value in `levels`. If it&#39;s `:auto`, the lower end of the colormap is picked and the remaining colors are shifted accordingly. If it&#39;s any color representation, this color is used. If it&#39;s `nothing`, no band is added.

**`fxaa`** =  `true`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`levels`** =  `10`  — Can be either an `Int` which results in n bands delimited by n+1 equally spaced levels, or it can be an `AbstractVector{<:Real}` that lists n consecutive edges from low to high, which result in n-1 bands.

**`mode`** =  `:normal`  — Sets the way in which a vector of levels is interpreted, if it&#39;s set to `:relative`, each number is interpreted as a fraction between the minimum and maximum values of `zs`. For example, `levels = 0.1:0.1:1.0` would exclude the lower 10% of data.

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`nan_color`** =  `:transparent`  — _No docs available._

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`triangulation`** =  `DelaunayTriangulation()`  — The mode with which the points in `xs` and `ys` are triangulated. Passing `DelaunayTriangulation()` performs a Delaunay triangulation. You can also pass a preexisting triangulation as an `AbstractMatrix{<:Int}` with size (3, n), where each column specifies the vertex indices of one triangle, or as a `Triangulation` from DelaunayTriangulation.jl.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L603" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.tricontourf!' href='#Makie.tricontourf!'><span class="jlbinding">Makie.tricontourf!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`tricontourf!` is the mutating variant of plotting function `tricontourf`. Check the docstring for `tricontourf` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.triplot' href='#Makie.triplot'><span class="jlbinding">Makie.triplot</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
triplot(x, y; kwargs...)
triplot(positions; kwargs...)
triplot(triangles::Triangulation; kwargs...)
```


Plots a triangulation based on the provided position or `Triangulation` from DelaunayTriangulation.jl.

**Plot type**

The plot type alias for the `triplot` function is `Triplot`.

**Attributes**

**`bounding_box`** =  `automatic`  — Sets the bounding box for truncating ghost edges which can be a `Rect2` (or `BBox`) or a tuple of the form `(xmin, xmax, ymin, ymax)`. By default, the rectangle will be given by `[a - eΔx, b + eΔx] × [c - eΔy, d + eΔy]` where `e` is the `ghost_edge_extension_factor`, `Δx = b - a` and `Δy = d - c` are the lengths of the sides of the rectangle, and `[a, b] × [c, d]` is the bounding box of the points in the triangulation.

**`constrained_edge_color`** =  `:magenta`  — Sets the color of the constrained edges.

**`constrained_edge_linestyle`** =  `@inherit linestyle`  — Sets the linestyle of the constrained edges.

**`constrained_edge_linewidth`** =  `@inherit linewidth`  — Sets the width of the constrained edges.

**`convex_hull_color`** =  `:red`  — Sets the color of the convex hull.

**`convex_hull_linestyle`** =  `:dash`  — Sets the linestyle of the convex hull.

**`convex_hull_linewidth`** =  `@inherit linewidth`  — Sets the width of the convex hull.

**`ghost_edge_color`** =  `:blue`  — Sets the color of the ghost edges.

**`ghost_edge_extension_factor`** =  `0.1`  — Sets the extension factor for the rectangle that the exterior ghost edges are extended onto.

**`ghost_edge_linestyle`** =  `@inherit linestyle`  — Sets the linestyle of the ghost edges.

**`ghost_edge_linewidth`** =  `@inherit linewidth`  — Sets the width of the ghost edges.

**`joinstyle`** =  `@inherit joinstyle`  — _No docs available._

**`linecap`** =  `@inherit linecap`  — _No docs available._

**`linestyle`** =  `:solid`  — Sets the linestyle of triangle edges.

**`marker`** =  `@inherit marker`  — Sets the shape of the points.

**`markercolor`** =  `@inherit markercolor`  — Sets the color of the points.

**`markersize`** =  `@inherit markersize`  — Sets the size of the points.

**`miter_limit`** =  `@inherit miter_limit`  — _No docs available._

**`recompute_centers`** =  `false`  — Determines whether to recompute the representative points for the ghost edge orientation. Note that this will mutate `tri.representative_point_list` directly.

**`show_constrained_edges`** =  `false`  — Determines whether to plot the constrained edges.

**`show_convex_hull`** =  `false`  — Determines whether to plot the convex hull.

**`show_ghost_edges`** =  `false`  — Determines whether to plot the ghost edges.

**`show_points`** =  `false`  — Determines whether to plot the individual points. Note that this will only plot points included in the triangulation.

**`strokecolor`** =  `@inherit patchstrokecolor`  — Sets the color of triangle edges.

**`strokewidth`** =  `1`  — Sets the linewidth of triangle edges.

**`triangle_color`** =  `:transparent`  — Sets the color of the triangles.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L584" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.triplot!' href='#Makie.triplot!'><span class="jlbinding">Makie.triplot!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`triplot!` is the mutating variant of plotting function `triplot`. Check the docstring for `triplot` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.update_cam!' href='#Makie.update_cam!'><span class="jlbinding">Makie.update_cam!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
update_cam!(scene, cam::Camera3D, ϕ, θ[, radius])
```


Set the camera position based on two angles `0 ≤ ϕ ≤ 2π` and `-pi/2 ≤ θ ≤ pi/2` and an optional radius around the current `cam.lookat[]`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/camera/camera3d.jl#L784-L789" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.update_cam!-2' href='#Makie.update_cam!-2'><span class="jlbinding">Makie.update_cam!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
update_cam!(scene::Scene, eyeposition, lookat, up = Vec3d(0, 0, 1))
```


Updates the camera&#39;s controls to point to the specified location.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/camera/old_camera3d.jl#L358-L362" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.update_cam!-Tuple{Union{AbstractScene, MakieCore.ScenePlot}, GeometryBasics.HyperRectangle}' href='#Makie.update_cam!-Tuple{Union{AbstractScene, MakieCore.ScenePlot}, GeometryBasics.HyperRectangle}'><span class="jlbinding">Makie.update_cam!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
update_cam!(scene::SceneLike, area)
```


Updates the camera for the given `scene` to cover the given `area` in 2d.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/camera/camera2d.jl#L54-L58" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.update_cam!-Tuple{Union{AbstractScene, MakieCore.ScenePlot}}' href='#Makie.update_cam!-Tuple{Union{AbstractScene, MakieCore.ScenePlot}}'><span class="jlbinding">Makie.update_cam!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
update_cam!(scene::SceneLike)
```


Updates the camera for the given `scene` to cover the limits of the `Scene`. Useful when using the `Observable` pipeline.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/camera/camera2d.jl#L67-L72" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.update_theme!' href='#Makie.update_theme!'><span class="jlbinding">Makie.update_theme!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
update_theme!(with_theme::Theme; kwargs...)
```


Update the current theme incrementally. This means that only the keys given in `with_theme` or through keyword arguments are changed, the rest is left intact. Nested attributes are either also updated incrementally, or replaced if they are not attributes in the new theme.

**Example**

To change the default colormap to `:greys`, you can pass that attribute as a keyword argument to `update_theme!` as demonstrated below.

```julia
update_theme!(colormap=:greys)
```


This can also be achieved by passing an object of types `Attributes` or `Theme` as the first and only positional argument:

```julia
update_theme!(Attributes(colormap=:greys))
update_theme!(Theme(colormap=:greys))
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/theming.jl#L257-L277" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.viewport-Tuple{Scene}' href='#Makie.viewport-Tuple{Scene}'><span class="jlbinding">Makie.viewport</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
viewport(scene::Scene)
```


Gets the viewport of the scene in device independent units as an `Observable{Rect2{Int}}`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/scenes.jl#L599-L603" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.violin' href='#Makie.violin'><span class="jlbinding">Makie.violin</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
violin(x, y)
```


Draw a violin plot.

**Arguments**
- `x`: positions of the categories
  
- `y`: variables whose density is computed
  

**Plot type**

The plot type alias for the `violin` function is `Violin`.

**Attributes**

**`bandwidth`** =  `automatic`  — _No docs available._

**`boundary`** =  `automatic`  — _No docs available._

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`color`** =  `@inherit patchcolor`  — _No docs available._

**`cycle`** =  `[:color => :patchcolor]`  — _No docs available._

**`datalimits`** =  `(-Inf, Inf)`  — Specify values to trim the `violin`. Can be a `Tuple` or a `Function` (e.g. `datalimits=extrema`).

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`dodge`** =  `automatic`  — _No docs available._

**`dodge_gap`** =  `0.03`  — _No docs available._

**`fxaa`** =  `true`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`gap`** =  `0.2`  — Shrinking factor, `width -> width * (1 - gap)`.

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`max_density`** =  `automatic`  — _No docs available._

**`mediancolor`** =  `@inherit linecolor`  — _No docs available._

**`medianlinewidth`** =  `@inherit linewidth`  — _No docs available._

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`n_dodge`** =  `automatic`  — _No docs available._

**`npoints`** =  `200`  — _No docs available._

**`orientation`** =  `:vertical`  — Orientation of the violins (`:vertical` or `:horizontal`)

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`scale`** =  `:area`  — Scale density by area (`:area`), count (`:count`), or width (`:width`).

**`show_median`** =  `false`  — Show median as midline.

**`side`** =  `:both`  — Specify `:left` or `:right` to only plot the violin on one side.

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`strokecolor`** =  `@inherit patchstrokecolor`  — _No docs available._

**`strokewidth`** =  `@inherit patchstrokewidth`  — _No docs available._

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.

**`weights`** =  `automatic`  — vector of statistical weights (length of data). By default, each observation has weight `1`.

**`width`** =  `automatic`  — Width of the box before shrinking.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L608" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.violin!' href='#Makie.violin!'><span class="jlbinding">Makie.violin!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`violin!` is the mutating variant of plotting function `violin`. Check the docstring for `violin` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.vlines' href='#Makie.vlines'><span class="jlbinding">Makie.vlines</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
vlines(xs; ymin = 0.0, ymax = 1.0, attrs...)
```


Create vertical lines across a `Scene` with 2D projection. The lines will be placed at `xs` in data coordinates and `ymin` to `ymax` in scene coordinates (0 to 1). All three of these can have single or multiple values because they are broadcast to calculate the final line segments.

**Plot type**

The plot type alias for the `vlines` function is `VLines`.

**Attributes**

**`alpha`** =  `1.0`  — The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`color`** =  `@inherit linecolor`  — The color of the line.

**`colormap`** =  `@inherit colormap :viridis`  — Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

**`colorrange`** =  `automatic`  — The values representing the start and end points of `colormap`.

**`colorscale`** =  `identity`  — The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.

**`cycle`** =  `[:color]`  — Sets which attributes to cycle when creating multiple plots.

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`fxaa`** =  `false`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`highclip`** =  `automatic`  — The color for any value above the colorrange.

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`linecap`** =  `@inherit linecap`  — Sets the type of linecap used, i.e. :butt (flat with no extrusion), :square (flat with 1 linewidth extrusion) or :round.

**`linestyle`** =  `nothing`  — Sets the dash pattern of the line. Options are `:solid` (equivalent to `nothing`), `:dot`, `:dash`, `:dashdot` and `:dashdotdot`. These can also be given in a tuple with a gap style modifier, either `:normal`, `:dense` or `:loose`. For example, `(:dot, :loose)` or `(:dashdot, :dense)`.

For custom patterns have a look at [`Makie.Linestyle`](/api#Makie.Linestyle).

**`linewidth`** =  `@inherit linewidth`  — Sets the width of the line in pixel units

**`lowclip`** =  `automatic`  — The color for any value below the colorrange.

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`nan_color`** =  `:transparent`  — The color for NaN values.

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.

**`ymax`** =  `1`  — The start of the lines in relative axis units (0 to 1) along the y dimension.

**`ymin`** =  `0`  — The start of the lines in relative axis units (0 to 1) along the y dimension.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L598" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.vlines!' href='#Makie.vlines!'><span class="jlbinding">Makie.vlines!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`vlines!` is the mutating variant of plotting function `vlines`. Check the docstring for `vlines` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.volumeslices' href='#Makie.volumeslices'><span class="jlbinding">Makie.volumeslices</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
volumeslices(x, y, z, v)
```


Draws heatmap slices of the volume v

**Plot type**

The plot type alias for the `volumeslices` function is `VolumeSlices`.

**Attributes**

**`alpha`** =  `1.0`  — The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

**`bbox_color`** =  `RGBAf(0.5, 0.5, 0.5, 0.5)`  — _No docs available._

**`bbox_visible`** =  `true`  — _No docs available._

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`colormap`** =  `@inherit colormap :viridis`  — Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

**`colorrange`** =  `automatic`  — The values representing the start and end points of `colormap`.

**`colorscale`** =  `identity`  — The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`fxaa`** =  `true`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`highclip`** =  `automatic`  — The color for any value above the colorrange.

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`interpolate`** =  `false`  — Sets whether colors should be interpolated

**`lowclip`** =  `automatic`  — The color for any value below the colorrange.

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`nan_color`** =  `:transparent`  — The color for NaN values.

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L585" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.volumeslices!' href='#Makie.volumeslices!'><span class="jlbinding">Makie.volumeslices!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`volumeslices!` is the mutating variant of plotting function `volumeslices`. Check the docstring for `volumeslices` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.voronoiplot' href='#Makie.voronoiplot'><span class="jlbinding">Makie.voronoiplot</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
voronoiplot(x, y, values; kwargs...)
voronoiplot(values; kwargs...)
voronoiplot(x, y; kwargs...)
voronoiplot(positions; kwargs...)
voronoiplot(vorn::VoronoiTessellation; kwargs...)
```


Generates and plots a Voronoi tessalation from `heatmap`- or point-like data. The tessellation can also be passed directly as a `VoronoiTessellation` from DelaunayTriangulation.jl.

**Plot type**

The plot type alias for the `voronoiplot` function is `Voronoiplot`.

**Attributes**

**`alpha`** =  `1.0`  — The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

**`clip`** =  `automatic`  — Sets the clipping area for the generated polygons which can be a `Rect2` (or `BBox`), `Tuple` with entries `(xmin, xmax, ymin, ymax)` or as a `Circle`. Anything outside the specified area will be removed. If the `clip` is not set it is automatically determined using `unbounded_edge_extension_factor` as a `Rect`.

**`color`** =  `automatic`  — Sets the color of the polygons. If `automatic`, the polygons will be individually colored according to the colormap.

**`colormap`** =  `@inherit colormap :viridis`  — Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

**`colorrange`** =  `automatic`  — The values representing the start and end points of `colormap`.

**`colorscale`** =  `identity`  — The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.

**`highclip`** =  `automatic`  — The color for any value above the colorrange.

**`lowclip`** =  `automatic`  — The color for any value below the colorrange.

**`marker`** =  `@inherit marker`  — Sets the shape of the points.

**`markercolor`** =  `@inherit markercolor`  — Sets the color of the points.

**`markersize`** =  `@inherit markersize`  — Sets the size of the points.

**`nan_color`** =  `:transparent`  — The color for NaN values.

**`show_generators`** =  `true`  — Determines whether to plot the individual generators.

**`smooth`** =  `false`  — _No docs available._

**`strokecolor`** =  `@inherit patchstrokecolor`  — Sets the strokecolor of the polygons.

**`strokewidth`** =  `1.0`  — Sets the width of the polygon stroke.

**`unbounded_edge_extension_factor`** =  `0.1`  — Sets the extension factor for the unbounded edges, used in `DelaunayTriangulation.polygon_bounds`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L572" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.voronoiplot!' href='#Makie.voronoiplot!'><span class="jlbinding">Makie.voronoiplot!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`voronoiplot!` is the mutating variant of plotting function `voronoiplot`. Check the docstring for `voronoiplot` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.vspan' href='#Makie.vspan'><span class="jlbinding">Makie.vspan</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
vspan(xs_low, xs_high; ymin = 0.0, ymax = 1.0, attrs...)
vspan(xs_lowhigh; ymin = 0.0, ymax = 1.0, attrs...)
```


Create vertical bands spanning across a `Scene` with 2D projection. The bands will be placed from `xs_low` to `xs_high` in data coordinates and `ymin` to `ymax` in scene coordinates (0 to 1). All four of these can have single or multiple values because they are broadcast to calculate the final spans. Both bounds can be passed together as an interval `xs_lowhigh`.

**Plot type**

The plot type alias for the `vspan` function is `VSpan`.

**Attributes**

**`alpha`** =  `1.0`  — The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`color`** =  `@inherit patchcolor`  — Sets the color of the poly. Can be a `Vector{<:Colorant}` for per vertex colors or a single `Colorant`. A `Matrix{<:Colorant}` can be used to color the mesh with a texture, which requires the mesh to contain texture coordinates. Vector or Matrices of numbers can be used as well, which will use the colormap arguments to map the numbers to colors. One can also use a `<: AbstractPattern`, to cover the poly with a regular pattern, e.g. for hatching.

**`colormap`** =  `@inherit colormap :viridis`  — Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

**`colorrange`** =  `automatic`  — The values representing the start and end points of `colormap`.

**`colorscale`** =  `identity`  — The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.

**`cycle`** =  `[:color => :patchcolor]`  — _No docs available._

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`fxaa`** =  `true`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`highclip`** =  `automatic`  — The color for any value above the colorrange.

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`joinstyle`** =  `@inherit joinstyle`  — _No docs available._

**`linecap`** =  `@inherit linecap`  — _No docs available._

**`linestyle`** =  `nothing`  — Sets the dash pattern of the line. Options are `:solid` (equivalent to `nothing`), `:dot`, `:dash`, `:dashdot` and `:dashdotdot`. These can also be given in a tuple with a gap style modifier, either `:normal`, `:dense` or `:loose`. For example, `(:dot, :loose)` or `(:dashdot, :dense)`.

For custom patterns have a look at [`Makie.Linestyle`](/api#Makie.Linestyle).

**`lowclip`** =  `automatic`  — The color for any value below the colorrange.

**`miter_limit`** =  `@inherit miter_limit`  — _No docs available._

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`nan_color`** =  `:transparent`  — The color for NaN values.

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`shading`** =  `NoShading`  — _No docs available._

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`stroke_depth_shift`** =  `-1.0e-5`  — Depth shift of stroke plot. This is useful to avoid z-fighting between the stroke and the fill.

**`strokecolor`** =  `@inherit patchstrokecolor`  — Sets the color of the outline around a marker.

**`strokecolormap`** =  `@inherit colormap`  — Sets the colormap that is sampled for numeric `color`s.

**`strokewidth`** =  `@inherit patchstrokewidth`  — Sets the width of the outline.

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.

**`ymax`** =  `1`  — The end of the bands in relative axis units (0 to 1) along the y dimension.

**`ymin`** =  `0`  — The start of the bands in relative axis units (0 to 1) along the y dimension.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L616" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.vspan!' href='#Makie.vspan!'><span class="jlbinding">Makie.vspan!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`vspan!` is the mutating variant of plotting function `vspan`. Check the docstring for `vspan` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.waterfall' href='#Makie.waterfall'><span class="jlbinding">Makie.waterfall</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
waterfall(x, y; kwargs...)
```


Plots a [waterfall chart](https://en.wikipedia.org/wiki/Waterfall_chart) to visualize individual positive and negative components that add up to a net result as a barplot with stacked bars next to each other.

**Plot type**

The plot type alias for the `waterfall` function is `Waterfall`.

**Attributes**

**`color`** =  `@inherit patchcolor`  — _No docs available._

**`cycle`** =  `[:color => :patchcolor]`  — _No docs available._

**`direction_color`** =  `@inherit backgroundcolor`  — _No docs available._

**`dodge`** =  `automatic`  — _No docs available._

**`dodge_gap`** =  `0.03`  — _No docs available._

**`final_color`** =  `plot_color(:grey90, 0.5)`  — _No docs available._

**`final_dodge_gap`** =  `0`  — _No docs available._

**`final_gap`** =  `automatic`  — _No docs available._

**`gap`** =  `0.2`  — _No docs available._

**`marker_neg`** =  `:dtriangle`  — _No docs available._

**`marker_pos`** =  `:utriangle`  — _No docs available._

**`n_dodge`** =  `automatic`  — _No docs available._

**`show_direction`** =  `false`  — _No docs available._

**`show_final`** =  `false`  — _No docs available._

**`stack`** =  `automatic`  — _No docs available._

**`width`** =  `automatic`  — _No docs available._


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L562" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.waterfall!' href='#Makie.waterfall!'><span class="jlbinding">Makie.waterfall!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`waterfall!` is the mutating variant of plotting function `waterfall`. Check the docstring for `waterfall` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.with_theme' href='#Makie.with_theme'><span class="jlbinding">Makie.with_theme</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
with_theme(f, theme = Theme(); kwargs...)
```


Calls `f` with `theme` temporarily activated. Attributes in `theme` can be overridden or extended with `kwargs`. The previous theme is always restored afterwards, no matter if `f` succeeds or fails.

Example:

```julia
my_theme = Theme(size = (500, 500), color = :red)
with_theme(my_theme, color = :blue, linestyle = :dashed) do
    scatter(randn(100, 2))
end
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/theming.jl#L212-L227" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.xlabel!-Tuple{Any, AbstractString}' href='#Makie.xlabel!-Tuple{Any, AbstractString}'><span class="jlbinding">Makie.xlabel!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
xlabel!(scene, xlabel)
```


Set the x-axis label for the given Scene.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/shorthands.jl#L7-L11" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.xlims!' href='#Makie.xlims!'><span class="jlbinding">Makie.xlims!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
xlims!(ax = current_axis())
```


Reset the x-axis limits to be determined automatically from the plots in the axis.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/axis.jl#L1357-L1362" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.xlims!-Tuple{Any, Any, Any}' href='#Makie.xlims!-Tuple{Any, Any, Any}'><span class="jlbinding">Makie.xlims!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
xlims!(ax, low, high)
xlims!(ax; low = nothing, high = nothing)
xlims!(ax, (low, high))
xlims!(ax, low..high)
```


Set the x-axis limits of axis `ax` to `low` and `high` or a tuple `xlims = (low,high)`. If the limits are ordered high-low, the axis orientation will be reversed. If a limit is `nothing` it will be determined automatically from the plots in the axis.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/axis.jl#L1292-L1302" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.xlims!-Tuple{Union{Nothing, Real}, Union{Nothing, Real}}' href='#Makie.xlims!-Tuple{Union{Nothing, Real}, Union{Nothing, Real}}'><span class="jlbinding">Makie.xlims!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
xlims!(low, high)
xlims!(; low = nothing, high = nothing)
```


Set the x-axis limits of the current axis to `low` and `high`. If the limits are ordered high-low, this reverses the axis orientation. A limit set to `nothing` will be determined automatically from the plots in the axis.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/axis.jl#L1329-L1336" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.xticklabels-Tuple{Any}' href='#Makie.xticklabels-Tuple{Any}'><span class="jlbinding">Makie.xticklabels</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
xticklabels(scene)
```


Returns all the x-axis tick labels. See also `ticklabels`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/shorthands.jl#L63-L67" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.xtickrange-Tuple{Any}' href='#Makie.xtickrange-Tuple{Any}'><span class="jlbinding">Makie.xtickrange</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
xtickrange(scene)
```


Returns the tick range along the x-axis. See also `tickranges`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/shorthands.jl#L98-L102" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.xtickrotation!-Tuple{Scene, Any}' href='#Makie.xtickrotation!-Tuple{Scene, Any}'><span class="jlbinding">Makie.xtickrotation!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
xtickrotation!([scene,] xangle)
```


Set the rotation of tick labels along the x-axis. See also `tickrotations!`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/shorthands.jl#L226-L230" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.xtickrotation-Tuple{Any}' href='#Makie.xtickrotation-Tuple{Any}'><span class="jlbinding">Makie.xtickrotation</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
xtickrotation(scene)
```


Returns the rotation of tick labels along the x-axis. See also `tickrotations`


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/shorthands.jl#L190-L194" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.xticks!-Tuple{Scene}' href='#Makie.xticks!-Tuple{Scene}'><span class="jlbinding">Makie.xticks!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
xticks!([scene,]; xtickrange=xtickrange(scene), xticklabels=xticklabel(scene))
```


Set the tick labels and range along the x-axis. See also `ticks!`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/shorthands.jl#L139-L143" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.ylabel!-Tuple{Any, AbstractString}' href='#Makie.ylabel!-Tuple{Any, AbstractString}'><span class="jlbinding">Makie.ylabel!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
ylabel!(scene, ylabel)
```


Set the y-axis label for the given Scene.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/shorthands.jl#L19-L23" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.ylims!' href='#Makie.ylims!'><span class="jlbinding">Makie.ylims!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
ylims!(ax = current_axis())
```


Reset the y-axis limits to be determined automatically from the plots in the axis.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/axis.jl#L1364-L1369" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.ylims!-Tuple{Any, Any, Any}' href='#Makie.ylims!-Tuple{Any, Any, Any}'><span class="jlbinding">Makie.ylims!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
ylims!(ax, low, high)
ylims!(ax; low = nothing, high = nothing)
ylims!(ax, (low, high))
ylims!(ax, low..high)
```


Set the y-axis limits of axis `ax` to `low` and `high` or a tuple `ylims = (low,high)`. If the limits are ordered high-low, the axis orientation will be reversed. If a limit is `nothing` it will be determined automatically from the plots in the axis.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/axis.jl#L1304-L1314" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.ylims!-Tuple{Union{Nothing, Real}, Union{Nothing, Real}}' href='#Makie.ylims!-Tuple{Union{Nothing, Real}, Union{Nothing, Real}}'><span class="jlbinding">Makie.ylims!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
ylims!(low, high)
ylims!(; low = nothing, high = nothing)
```


Set the y-axis limits of the current axis to `low` and `high`. If the limits are ordered high-low, this reverses the axis orientation. A limit set to `nothing` will be determined automatically from the plots in the axis.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/axis.jl#L1338-L1345" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.yticklabels-Tuple{Any}' href='#Makie.yticklabels-Tuple{Any}'><span class="jlbinding">Makie.yticklabels</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
yticklabels(scene)
```


Returns all the y-axis tick labels. See also `ticklabels`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/shorthands.jl#L70-L74" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.ytickrange-Tuple{Any}' href='#Makie.ytickrange-Tuple{Any}'><span class="jlbinding">Makie.ytickrange</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
ytickrange(scene)
```


Returns the tick range along the y-axis. See also `tickranges`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/shorthands.jl#L105-L109" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.ytickrotation!-Tuple{Scene, Any}' href='#Makie.ytickrotation!-Tuple{Scene, Any}'><span class="jlbinding">Makie.ytickrotation!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
ytickrotation!([scene,] yangle)
```


Set the rotation of tick labels along the y-axis. See also `tickrotations!`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/shorthands.jl#L236-L240" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.ytickrotation-Tuple{Any}' href='#Makie.ytickrotation-Tuple{Any}'><span class="jlbinding">Makie.ytickrotation</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
ytickrotation(scene)
```


Returns the rotation of tick labels along the y-axis. See also `tickrotations`


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/shorthands.jl#L197-L201" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.yticks!-Tuple{Scene}' href='#Makie.yticks!-Tuple{Scene}'><span class="jlbinding">Makie.yticks!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
yticks!([scene,]; ytickrange=ytickrange(scene), yticklabels=yticklabel(scene))
```


Set the tick labels and range along all the y-axis. See also `ticks!`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/shorthands.jl#L149-L153" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.zlabel!-Tuple{Any, AbstractString}' href='#Makie.zlabel!-Tuple{Any, AbstractString}'><span class="jlbinding">Makie.zlabel!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
zlabel!(scene, zlabel)
```


Set the z-axis label for the given Scene.

::: warning Warning

The Scene must have an Axis3D.  If not, then this function will error.

:::


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/shorthands.jl#L35-L42" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.zlims!' href='#Makie.zlims!'><span class="jlbinding">Makie.zlims!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
zlims!(ax = current_axis())
```


Reset the z-axis limits to be determined automatically from the plots in the axis.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/axis.jl#L1371-L1376" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.zlims!-Tuple{Any, Any, Any}' href='#Makie.zlims!-Tuple{Any, Any, Any}'><span class="jlbinding">Makie.zlims!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
zlims!(ax, low, high)
zlims!(ax; low = nothing, high = nothing)
zlims!(ax, (low, high))
zlims!(ax, low..high)
```


Set the z-axis limits of axis `ax` to `low` and `high` or a tuple `zlims = (low,high)`. If the limits are ordered high-low, the axis orientation will be reversed. If a limit is `nothing` it will be determined automatically from the plots in the axis.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/axis.jl#L1316-L1326" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.zlims!-Tuple{Union{Nothing, Real}, Union{Nothing, Real}}' href='#Makie.zlims!-Tuple{Union{Nothing, Real}, Union{Nothing, Real}}'><span class="jlbinding">Makie.zlims!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
zlims!(low, high)
zlims!(; low = nothing, high = nothing)
```


Set the z-axis limits of the current axis to `low` and `high`. If the limits are ordered high-low, this reverses the axis orientation. A limit set to `nothing` will be determined automatically from the plots in the axis.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/makielayout/blocks/axis.jl#L1347-L1354" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.zoom!' href='#Makie.zoom!'><span class="jlbinding">Makie.zoom!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
zoom!(scene, cam::Camera3D, zoom_step[, cad = false, zoom_shift_lookat = false])
```


Zooms the camera in or out based on the multiplier `zoom_step`. A `zoom_step` of 1.0 is neutral, larger zooms out and lower zooms in.

If `cad = true` zooming will also apply a rotation based on how far the cursor is from the center of the scene. If `zoom_shift_lookat = true` and `projectiontype = Orthographic` zooming will keep the data under the cursor at the same screen space position.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/camera/camera3d.jl#L534-L544" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.zoom!-Tuple{Any, Union{NTuple{N, T}, StaticArraysCore.StaticArray{Tuple{N}, T, 1}} where {N, T}, Any, Bool}' href='#Makie.zoom!-Tuple{Any, Union{NTuple{N, T}, StaticArraysCore.StaticArray{Tuple{N}, T, 1}} where {N, T}, Any, Bool}'><span class="jlbinding">Makie.zoom!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
zoom!(scene, point, zoom_step, shift_lookat::Bool)
```


Zooms the camera of `scene` in towards `point` by a factor of `zoom_step`. A positive `zoom_step` zooms in while a negative `zoom_step` zooms out.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/camera/old_camera3d.jl#L259-L264" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.zticklabels-Tuple{Any}' href='#Makie.zticklabels-Tuple{Any}'><span class="jlbinding">Makie.zticklabels</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
zticklabels(scene)
```


Returns all the z-axis tick labels. See also `ticklabels`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/shorthands.jl#L77-L81" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.ztickrange-Tuple{Any}' href='#Makie.ztickrange-Tuple{Any}'><span class="jlbinding">Makie.ztickrange</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
ztickrange(scene)
```


Returns the tick range along the z-axis. See also `tickranges`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/shorthands.jl#L112-L116" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.ztickrotation!-Tuple{Scene, Any}' href='#Makie.ztickrotation!-Tuple{Scene, Any}'><span class="jlbinding">Makie.ztickrotation!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
ztickrotation!([scene,] zangle)
```


Set the rotation of tick labels along the z-axis. See also `tickrotations!`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/shorthands.jl#L249-L253" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.ztickrotation-Tuple{Any}' href='#Makie.ztickrotation-Tuple{Any}'><span class="jlbinding">Makie.ztickrotation</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
ztickrotation(scene)
```


Returns the rotation of tick labels along the z-axis. See also `tickrotations`


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/shorthands.jl#L204-L208" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.zticks!-Tuple{Scene}' href='#Makie.zticks!-Tuple{Scene}'><span class="jlbinding">Makie.zticks!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
zticks!([scene,]; ztickranges=ztickrange(scene), zticklabels=zticklabel(scene))
```


Set the tick labels and range along all z-axis. See also `ticks!`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/shorthands.jl#L165-L169" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.convert_arguments-Tuple{GridBased, AbstractVecOrMat{<:Real}, AbstractVecOrMat{<:Real}, AbstractMatrix{<:Union{Real, ColorTypes.Colorant}}}' href='#MakieCore.convert_arguments-Tuple{GridBased, AbstractVecOrMat{<:Real}, AbstractVecOrMat{<:Real}, AbstractMatrix{<:Union{Real, ColorTypes.Colorant}}}'><span class="jlbinding">MakieCore.convert_arguments</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
convert_arguments(ct::GridBased, x::VecOrMat, y::VecOrMat, z::Matrix)
```


If `ct` is `Heatmap` and `x` and `y` are vectors, infer from length of `x` and `y` whether they represent edges or centers of the heatmap bins. If they are centers, convert to edges. Convert eltypes to `Float32` and return outputs as a `Tuple`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/conversions.jl#L337-L344" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.convert_arguments-Tuple{GridBased, Union{Tuple{Real, Real}, IntervalSets.ClosedInterval, AbstractVector}, Union{Tuple{Real, Real}, IntervalSets.ClosedInterval, AbstractVector}, AbstractMatrix{<:Union{Real, ColorTypes.Colorant}}}' href='#MakieCore.convert_arguments-Tuple{GridBased, Union{Tuple{Real, Real}, IntervalSets.ClosedInterval, AbstractVector}, Union{Tuple{Real, Real}, IntervalSets.ClosedInterval, AbstractVector}, AbstractMatrix{<:Union{Real, ColorTypes.Colorant}}}'><span class="jlbinding">MakieCore.convert_arguments</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
convert_arguments(P, x::RangeLike, y::RangeLike, z::AbstractMatrix)
```


Takes one or two ClosedIntervals `x` and `y` and converts them to closed ranges with size(z, 1/2).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/conversions.jl#L353-L358" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.convert_arguments-Tuple{PointBased, AbstractArray{T, N} where {N, T<:Real}, AbstractMatrix{T} where T<:Real, AbstractMatrix{T} where T<:Real}' href='#MakieCore.convert_arguments-Tuple{PointBased, AbstractArray{T, N} where {N, T<:Real}, AbstractMatrix{T} where T<:Real, AbstractMatrix{T} where T<:Real}'><span class="jlbinding">MakieCore.convert_arguments</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
convert_arguments(P, x, y, z)::(Vector)
```


Takes vectors `x`, `y`, and `z` and turns it into a vector of 3D points of the values from `x`, `y`, and `z`. `P` is the plot Type (it is optional).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/conversions.jl#L120-L126" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.convert_arguments-Tuple{PointBased, AbstractArray{T, N} where {N, T<:Real}, AbstractVector{T} where T<:Real, AbstractMatrix{T} where T<:Real}' href='#MakieCore.convert_arguments-Tuple{PointBased, AbstractArray{T, N} where {N, T<:Real}, AbstractVector{T} where T<:Real, AbstractMatrix{T} where T<:Real}'><span class="jlbinding">MakieCore.convert_arguments</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



Enables to use scatter like a surface plot with x::Vector, y::Vector, z::Matrix spanning z over the grid spanned by x y


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/conversions.jl#L101-L104" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.convert_arguments-Tuple{PointBased, GeometryBasics.LineString}' href='#MakieCore.convert_arguments-Tuple{PointBased, GeometryBasics.LineString}'><span class="jlbinding">MakieCore.convert_arguments</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
convert_arguments(PB, LineString)
```


Takes an input `LineString` and decomposes it to points.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/conversions.jl#L200-L205" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.convert_arguments-Tuple{PointBased, GeometryBasics.Polygon}' href='#MakieCore.convert_arguments-Tuple{PointBased, GeometryBasics.Polygon}'><span class="jlbinding">MakieCore.convert_arguments</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
convert_arguments(PB, Polygon)
```


Takes an input `Polygon` and decomposes it to points.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/conversions.jl#L227-L232" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.convert_arguments-Tuple{PointBased, IntervalSets.ClosedInterval, AbstractVector{T} where T<:Real}' href='#MakieCore.convert_arguments-Tuple{PointBased, IntervalSets.ClosedInterval, AbstractVector{T} where T<:Real}'><span class="jlbinding">MakieCore.convert_arguments</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
convert_arguments(P, x, y)::(Vector)
```


Takes vectors `x` and `y` and turns it into a vector of 2D points of the values from `x` and `y`.

`P` is the plot Type (it is optional).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/conversions.jl#L152-L159" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.convert_arguments-Tuple{PointBased, Real, Real}' href='#MakieCore.convert_arguments-Tuple{PointBased, Real, Real}'><span class="jlbinding">MakieCore.convert_arguments</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



Wrap a single point or equivalent object in a single-element array.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/conversions.jl#L65-L67" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.convert_arguments-Tuple{Type{<:Mesh}, AbstractArray, AbstractArray}' href='#MakieCore.convert_arguments-Tuple{Type{<:Mesh}, AbstractArray, AbstractArray}'><span class="jlbinding">MakieCore.convert_arguments</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
convert_arguments(Mesh, vertices, indices)::GLNormalMesh
```


Takes `vertices` and `indices`, and creates a triangle mesh out of those. See `to_vertices` and `to_triangles` for more information about accepted types.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/conversions.jl#L608-L614" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.convert_arguments-Tuple{Type{<:Mesh}, AbstractVector{T} where T<:Real, AbstractVector{T} where T<:Real, AbstractVector{T} where T<:Real, AbstractVector}' href='#MakieCore.convert_arguments-Tuple{Type{<:Mesh}, AbstractVector{T} where T<:Real, AbstractVector{T} where T<:Real, AbstractVector{T} where T<:Real, AbstractVector}'><span class="jlbinding">MakieCore.convert_arguments</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
convert_arguments(Mesh, x, y, z, indices)::GLNormalMesh
```


Takes real vectors x, y, z and constructs a triangle mesh out of those, using the faces in `indices`, which can be integers (every 3 -&gt; one triangle), or GeometryBasics.NgonFace{N, &lt;: Integer}.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/conversions.jl#L594-L599" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.convert_arguments-Tuple{Type{<:Mesh}, AbstractVector{T} where T<:Real, AbstractVector{T} where T<:Real, AbstractVector{T} where T<:Real}' href='#MakieCore.convert_arguments-Tuple{Type{<:Mesh}, AbstractVector{T} where T<:Real, AbstractVector{T} where T<:Real, AbstractVector{T} where T<:Real}'><span class="jlbinding">MakieCore.convert_arguments</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
convert_arguments(Mesh, x, y, z)::GLNormalMesh
```


Takes real vectors x, y, z and constructs a mesh out of those, under the assumption that every 3 points form a triangle.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/conversions.jl#L522-L527" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.convert_arguments-Tuple{Type{<:Mesh}, AbstractVector}' href='#MakieCore.convert_arguments-Tuple{Type{<:Mesh}, AbstractVector}'><span class="jlbinding">MakieCore.convert_arguments</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
convert_arguments(Mesh, xyz::AbstractVector)::GLNormalMesh
```


Takes an input mesh and a vector `xyz` representing the vertices of the mesh, and creates indices under the assumption, that each triplet in `xyz` forms a triangle.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/conversions.jl#L534-L539" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.convert_arguments-Tuple{Union{ImageLike, GridBased}, AbstractVector, AbstractVector, Function}' href='#MakieCore.convert_arguments-Tuple{Union{ImageLike, GridBased}, AbstractVector, AbstractVector, Function}'><span class="jlbinding">MakieCore.convert_arguments</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
convert_arguments(P, x, y, f)::(Vector, Vector, Matrix)
```


Takes vectors `x` and `y` and the function `f`, and applies `f` on the grid that `x` and `y` span. This is equivalent to `f.(x, y')`. `P` is the plot Type (it is optional).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/conversions.jl#L453-L459" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.convert_arguments-Tuple{VolumeLike, AbstractVector{T} where T<:Real, AbstractVector{T} where T<:Real, AbstractVector{T} where T<:Real, Function}' href='#MakieCore.convert_arguments-Tuple{VolumeLike, AbstractVector{T} where T<:Real, AbstractVector{T} where T<:Real, AbstractVector{T} where T<:Real, Function}'><span class="jlbinding">MakieCore.convert_arguments</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
convert_arguments(P, x, y, z, f)::(Vector, Vector, Vector, Matrix)
```


Takes `AbstractVector` `x`, `y`, and `z` and the function `f`, evaluates `f` on the volume spanned by `x`, `y` and `z`, and puts `x`, `y`, `z` and `f(x,y,z)` in a Tuple.

`P` is the plot Type (it is optional).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/conversions.jl#L661-L668" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.convert_arguments-Union{Tuple{E}, Tuple{A}, Tuple{T}, Tuple{N}, Tuple{Type{<:LineSegments}, AbstractVector{E}}} where {N, T, A<:Union{NTuple{N, T}, StaticArraysCore.StaticArray{Tuple{N}, T, 1}}, E<:Union{Pair{A, A}, Tuple{A, A}}}' href='#MakieCore.convert_arguments-Union{Tuple{E}, Tuple{A}, Tuple{T}, Tuple{N}, Tuple{Type{<:LineSegments}, AbstractVector{E}}} where {N, T, A<:Union{NTuple{N, T}, StaticArraysCore.StaticArray{Tuple{N}, T, 1}}, E<:Union{Pair{A, A}, Tuple{A, A}}}'><span class="jlbinding">MakieCore.convert_arguments</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



Accepts a Vector of Pair of Points (e.g. `[Point(0, 0) => Point(1, 1), ...]`) to encode e.g. linesegments or directions.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/conversions.jl#L505-L508" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.convert_arguments-Union{Tuple{T}, Tuple{Dim}, Tuple{PointBased, GeometryBasics.GeometryPrimitive{Dim, T}}} where {Dim, T}' href='#MakieCore.convert_arguments-Union{Tuple{T}, Tuple{Dim}, Tuple{PointBased, GeometryBasics.GeometryPrimitive{Dim, T}}} where {Dim, T}'><span class="jlbinding">MakieCore.convert_arguments</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
convert_arguments(P, x)::(Vector)
```


Takes an input GeometryPrimitive `x` and decomposes it to points. `P` is the plot Type (it is optional).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/conversions.jl#L137-L142" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.convert_arguments-Union{Tuple{T}, Tuple{N}, Tuple{PointBased, Union{GeometryBasics.MultiLineString{N, T}, AbstractVector{<:GeometryBasics.LineString{N, T}}, AbstractVector{<:GeometryBasics.MultiLineString{N, T}}}}} where {N, T}' href='#MakieCore.convert_arguments-Union{Tuple{T}, Tuple{N}, Tuple{PointBased, Union{GeometryBasics.MultiLineString{N, T}, AbstractVector{<:GeometryBasics.LineString{N, T}}, AbstractVector{<:GeometryBasics.MultiLineString{N, T}}}}} where {N, T}'><span class="jlbinding">MakieCore.convert_arguments</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
convert_arguments(PB, Union{Array{<:LineString}, MultiLineString})
```


Takes an input `Array{LineString}` or a `MultiLineString` and decomposes it to points.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/conversions.jl#L210-L214" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.convert_arguments-Union{Tuple{T}, Tuple{N}, Tuple{PointBased, Union{GeometryBasics.MultiPolygon{N, T}, Array{<:GeometryBasics.Polygon{N, T}}}}} where {N, T}' href='#MakieCore.convert_arguments-Union{Tuple{T}, Tuple{N}, Tuple{PointBased, Union{GeometryBasics.MultiPolygon{N, T}, Array{<:GeometryBasics.Polygon{N, T}}}}} where {N, T}'><span class="jlbinding">MakieCore.convert_arguments</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
convert_arguments(PB, Union{Array{<:Polygon}, MultiPolygon})
```


Takes an input `Array{Polygon}` or a `MultiPolygon` and decomposes it to points.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/conversions.jl#L250-L255" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.convert_arguments-Union{Tuple{T}, Tuple{PointBased, GeometryBasics.HyperRectangle{2, T}}} where T' href='#MakieCore.convert_arguments-Union{Tuple{T}, Tuple{PointBased, GeometryBasics.HyperRectangle{2, T}}} where T'><span class="jlbinding">MakieCore.convert_arguments</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
convert_arguments(P, x)::(Vector)
```


Takes an input `Rect` `x` and decomposes it to points.

`P` is the plot Type (it is optional).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/conversions.jl#L164-L170" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.used_attributes-Tuple{Type{<:Plot}, Vararg{Any}}' href='#MakieCore.used_attributes-Tuple{Type{<:Plot}, Vararg{Any}}'><span class="jlbinding">MakieCore.used_attributes</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
used_attributes(args...) = ()
```


Function used to indicate what keyword args one wants to get passed in `convert_arguments`. Those attributes will not be forwarded to the backend, but only used during the conversion pipeline. Usage:

```julia
struct MyType end
used_attributes(::MyType) = (:attribute,)
function convert_arguments(x::MyType; attribute = 1)
    ...
end
# attribute will get passed to convert_arguments
# without keyword_verload, this wouldn't happen
plot(MyType, attribute = 2)
#You can also use the convenience macro, to overload convert_arguments in one step:
@keywords convert_arguments(x::MyType; attribute = 1)
    ...
end
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/interfaces.jl#L283-L304" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Observables.on-Tuple{Any, Camera, Vararg{Observables.AbstractObservable}}' href='#Observables.on-Tuple{Any, Camera, Vararg{Observables.AbstractObservable}}'><span class="jlbinding">Observables.on</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
on(f, c::Camera, observables::Observable...)
```


When mapping over observables for the camera, we store them in the `steering_node` vector, to make it easier to disconnect the camera steering signals later!


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/camera/camera.jl#L54-L59" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.@extract-Tuple{Any, Any}' href='#Makie.@extract-Tuple{Any, Any}'><span class="jlbinding">Makie.@extract</span></a> <Badge type="info" class="jlObjectType jlMacro" text="Macro" /></summary>



```julia
@extract scene (a, b, c, d)
```


This becomes

```julia
begin
    a = scene[:a]
    b = scene[:b]
    c = scene[:d]
    d = scene[:d]
    (a, b, c, d)
end
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/utilities/utilities.jl#L91-L105" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.@extractvalue-Tuple{Any, Any}' href='#Makie.@extractvalue-Tuple{Any, Any}'><span class="jlbinding">Makie.@extractvalue</span></a> <Badge type="info" class="jlObjectType jlMacro" text="Macro" /></summary>



usage @extractvalue scene (a, b, c, d) will become:

```julia
begin
    a = to_value(scene[:a])
    b = to_value(scene[:b])
    c = to_value(scene[:c])
    (a, b, c)
end
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/utilities/utilities.jl#L148-L159" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.@get_attribute-Tuple{Any, Any}' href='#Makie.@get_attribute-Tuple{Any, Any}'><span class="jlbinding">Makie.@get_attribute</span></a> <Badge type="info" class="jlObjectType jlMacro" text="Macro" /></summary>



```julia
@get_attribute scene (a, b, c, d)
```


This will extract attribute `a`, `b`, `c`, `d` from `scene` and apply the correct attribute conversions + will extract the value if it&#39;s a signal. It will make those attributes available as variables and return them as a tuple. So the above is equal to: will become:

```julia
begin
    a = get_attribute(scene, :a)
    b = get_attribute(scene, :b)
    c = get_attribute(scene, :c)
    (a, b, c)
end
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/utilities/utilities.jl#L110-L126" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.@lift-Tuple{Any}' href='#Makie.@lift-Tuple{Any}'><span class="jlbinding">Makie.@lift</span></a> <Badge type="info" class="jlObjectType jlMacro" text="Macro" /></summary>



Replaces an expression with `lift(argtuple -> expression, args...)`, where `args` are all expressions inside the main one that begin with $.

**Example:**

```julia
x = Observable(rand(100))
y = Observable(rand(100))
```


**before**

```julia
z = lift((x, y) -> x .+ y, x, y)
```


**after**

```julia
z = @lift($x .+ $y)
```


You can also use parentheses around an expression if that expression evaluates to an observable.

```julia
nt = (x = Observable(1), y = Observable(2))
@lift($(nt.x) + $(nt.y))
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/interaction/liftmacro.jl#L44-L71" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.Arrows' href='#MakieCore.Arrows'><span class="jlbinding">MakieCore.Arrows</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`Arrows` is the plot type associated with plotting function `arrows`. Check the docstring for `arrows` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.Heatmap' href='#MakieCore.Heatmap'><span class="jlbinding">MakieCore.Heatmap</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`Heatmap` is the plot type associated with plotting function `heatmap`. Check the docstring for `heatmap` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.Image' href='#MakieCore.Image'><span class="jlbinding">MakieCore.Image</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`Image` is the plot type associated with plotting function `image`. Check the docstring for `image` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.LineSegments' href='#MakieCore.LineSegments'><span class="jlbinding">MakieCore.LineSegments</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`LineSegments` is the plot type associated with plotting function `linesegments`. Check the docstring for `linesegments` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.Lines' href='#MakieCore.Lines'><span class="jlbinding">MakieCore.Lines</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`Lines` is the plot type associated with plotting function `lines`. Check the docstring for `lines` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.Mesh' href='#MakieCore.Mesh'><span class="jlbinding">MakieCore.Mesh</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`Mesh` is the plot type associated with plotting function `mesh`. Check the docstring for `mesh` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.MeshScatter' href='#MakieCore.MeshScatter'><span class="jlbinding">MakieCore.MeshScatter</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`MeshScatter` is the plot type associated with plotting function `meshscatter`. Check the docstring for `meshscatter` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.Poly' href='#MakieCore.Poly'><span class="jlbinding">MakieCore.Poly</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`Poly` is the plot type associated with plotting function `poly`. Check the docstring for `poly` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.Scatter' href='#MakieCore.Scatter'><span class="jlbinding">MakieCore.Scatter</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`Scatter` is the plot type associated with plotting function `scatter`. Check the docstring for `scatter` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.Surface' href='#MakieCore.Surface'><span class="jlbinding">MakieCore.Surface</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`Surface` is the plot type associated with plotting function `surface`. Check the docstring for `surface` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.Text' href='#MakieCore.Text'><span class="jlbinding">MakieCore.Text</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`Text` is the plot type associated with plotting function `text`. Check the docstring for `text` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.Volume' href='#MakieCore.Volume'><span class="jlbinding">MakieCore.Volume</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`Volume` is the plot type associated with plotting function `volume`. Check the docstring for `volume` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.Voxels' href='#MakieCore.Voxels'><span class="jlbinding">MakieCore.Voxels</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`Voxels` is the plot type associated with plotting function `voxels`. Check the docstring for `voxels` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.Wireframe' href='#MakieCore.Wireframe'><span class="jlbinding">MakieCore.Wireframe</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



`Wireframe` is the plot type associated with plotting function `wireframe`. Check the docstring for `wireframe` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.arrows' href='#MakieCore.arrows'><span class="jlbinding">MakieCore.arrows</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
arrows(points, directions; kwargs...)
arrows(x, y, u, v)
arrows(x::AbstractVector, y::AbstractVector, u::AbstractMatrix, v::AbstractMatrix)
arrows(x, y, z, u, v, w)
arrows(x, y, [z], f::Function)
```


Plots arrows at the specified points with the specified components. `u` and `v` are interpreted as vector components (`u` being the x and `v` being the y), and the vectors are plotted with the tails at `x`, `y`.

If `x, y, u, v` are `<: AbstractVector`, then each &#39;row&#39; is plotted as a single vector.

If `u, v` are `<: AbstractMatrix`, then `x` and `y` are interpreted as specifications for a grid, and `u, v` are plotted as arrows along the grid.

`arrows` can also work in three dimensions.

If a `Function` is provided in place of `u, v, [w]`, then it must accept a `Point` as input, and return an appropriately dimensioned `Point`, `Vec`, or other array-like output.

**Plot type**

The plot type alias for the `arrows` function is `Arrows`.

**Attributes**

**`align`** =  `:origin`  — Sets how arrows are positioned. By default arrows start at the given positions and extend along the given directions. If this attribute is set to `:head`, `:lineend`, `:tailend`, `:headstart` or `:center` the given positions will be between the head and tail of each arrow instead.

**`alpha`** =  `1.0`  — The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

**`arrowcolor`** =  `automatic`  — Sets the color of the arrow head. Will copy `color` if set to `automatic`.

**`arrowhead`** =  `automatic`  — Defines the marker (2D) or mesh (3D) that is used as the arrow head. The default for is `'▲'` in 2D and a cone mesh in 3D. For the latter the mesh should start at `Point3f(0)` and point in positive z-direction.

**`arrowsize`** =  `automatic`  — Scales the size of the arrow head. This defaults to `0.3` in the 2D case and `Vec3f(0.2, 0.2, 0.3)` in the 3D case. For the latter the first two components scale the radius (in x/y direction) and the last scales the length of the cone. If the arrowsize is set to 1, the cone will have a diameter and length of 1.

**`arrowtail`** =  `automatic`  — Defines the mesh used to draw the arrow tail in 3D. It should start at `Point3f(0)` and extend in negative z-direction. The default is a cylinder. This has no effect on the 2D plot.

**`backlight`** =  `0.0`  — Sets a weight for secondary light calculation with inverted normals.

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`color`** =  `:black`  — Sets the color of arrowheads and lines. Can be overridden separately using `linecolor` and `arrowcolor`.

**`colormap`** =  `@inherit colormap :viridis`  — Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

**`colorrange`** =  `automatic`  — The values representing the start and end points of `colormap`.

**`colorscale`** =  `identity`  — The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`diffuse`** =  `1.0`  — Sets how strongly the red, green and blue channel react to diffuse (scattered) light.

**`fxaa`** =  `automatic`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`highclip`** =  `automatic`  — The color for any value above the colorrange.

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`lengthscale`** =  `1.0`  — Scales the length of the arrow tail.

**`linecolor`** =  `automatic`  — Sets the color used for the arrow tail which is represented by a line in 2D. Will copy `color` if set to `automatic`.

**`linestyle`** =  `nothing`  — Sets the linestyle used in 2D. Does not apply to 3D plots.

**`linewidth`** =  `automatic`  — Scales the width/diameter of the arrow tail. Defaults to `1` for 2D and `0.05` for the 3D case.

**`lowclip`** =  `automatic`  — The color for any value below the colorrange.

**`markerspace`** =  `:pixel`  — _No docs available._

**`material`** =  `nothing`  — RPRMakie only attribute to set complex RadeonProRender materials.         _Warning_, how to set an RPR material may change and other backends will ignore this attribute

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`nan_color`** =  `:transparent`  — The color for NaN values.

**`normalize`** =  `false`  — By default the lengths of the directions given to `arrows` are used to scale the length of the arrow tails. If this attribute is set to true the directions are normalized, skipping this scaling.

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`quality`** =  `32`  — Defines the number of angle subdivisions used when generating the arrow head and tail meshes. Consider lowering this if you have performance issues. Only applies to 3D plots.

**`shading`** =  `automatic`  — Sets the lighting algorithm used. Options are `NoShading` (no lighting), `FastShading` (AmbientLight + PointLight) or `MultiLightShading` (Multiple lights, GLMakie only). Note that this does not affect RPRMakie.

**`shininess`** =  `32.0`  — Sets how sharp the reflection is.

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`specular`** =  `0.2`  — Sets how strongly the object reflects light in the red, green and blue channels.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`transform_marker`** =  `automatic`  — Controls whether marker attributes get transformed by the model matrix.

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L656" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.arrows!' href='#MakieCore.arrows!'><span class="jlbinding">MakieCore.arrows!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`arrows!` is the mutating variant of plotting function `arrows`. Check the docstring for `arrows` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.heatmap' href='#MakieCore.heatmap'><span class="jlbinding">MakieCore.heatmap</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
heatmap(x, y, matrix)
heatmap(x, y, func)
heatmap(matrix)
heatmap(xvector, yvector, zvector)
```


Plots a heatmap as a collection of rectangles. `x` and `y` can either be of length `i` and `j` where `(i, j)` is `size(matrix)`, in this case the rectangles will be placed around these grid points like voronoi cells. Note that for irregularly spaced `x` and `y`, the points specified by them are not centered within the resulting rectangles.

`x` and `y` can also be of length `i+1` and `j+1`, in this case they are interpreted as the edges of the rectangles.

Colors of the rectangles are derived from `matrix[i, j]`. The third argument may also be a `Function` (i, j) -&gt; v which is then evaluated over the grid spanned by `x` and `y`.

Another allowed form is using three vectors `xvector`, `yvector` and `zvector`. In this case it is assumed that no pair of elements `x` and `y` exists twice. Pairs that are missing from the resulting grid will be treated as if `zvector` had a `NaN`     element at that position.

If `x` and `y` are omitted with a matrix argument, they default to `x, y = axes(matrix)`.

Note that `heatmap` is slower to render than `image` so `image` should be preferred for large, regularly spaced grids.

**Plot type**

The plot type alias for the `heatmap` function is `Heatmap`.

**Attributes**

**`alpha`** =  `1.0`  — The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`colormap`** =  `@inherit colormap :viridis`  — Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

**`colorrange`** =  `automatic`  — The values representing the start and end points of `colormap`.

**`colorscale`** =  `identity`  — The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`fxaa`** =  `true`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`highclip`** =  `automatic`  — The color for any value above the colorrange.

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`interpolate`** =  `false`  — Sets whether colors should be interpolated

**`lowclip`** =  `automatic`  — The color for any value below the colorrange.

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`nan_color`** =  `:transparent`  — The color for NaN values.

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L603" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.heatmap!' href='#MakieCore.heatmap!'><span class="jlbinding">MakieCore.heatmap!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`heatmap!` is the mutating variant of plotting function `heatmap`. Check the docstring for `heatmap` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.image' href='#MakieCore.image'><span class="jlbinding">MakieCore.image</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
image(x, y, image)
image(image)
```


Plots an image on a rectangle bounded by `x` and `y` (defaults to size of image).

**Plot type**

The plot type alias for the `image` function is `Image`.

**Attributes**

**`alpha`** =  `1.0`  — The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`colormap`** =  `[:black, :white]`  — Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

**`colorrange`** =  `automatic`  — The values representing the start and end points of `colormap`.

**`colorscale`** =  `identity`  — The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`fxaa`** =  `false`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`highclip`** =  `automatic`  — The color for any value above the colorrange.

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`interpolate`** =  `true`  — Sets whether colors should be interpolated between pixels.

**`lowclip`** =  `automatic`  — The color for any value below the colorrange.

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`nan_color`** =  `:transparent`  — The color for NaN values.

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`uv_transform`** =  `automatic`  — Sets a transform for uv coordinates, which controls how the image is mapped to its rectangular area. The attribute can be `I`, `scale::VecTypes{2}`, `(translation::VecTypes{2}, scale::VecTypes{2})`, any of :rotr90, :rotl90, :rot180, :swap_xy/:transpose, :flip_x, :flip_y, :flip_xy, or most generally a `Makie.Mat{2, 3, Float32}` or `Makie.Mat3f` as returned by `Makie.uv_transform()`. They can also be changed by passing a tuple `(op3, op2, op1)`.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L587" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.image!' href='#MakieCore.image!'><span class="jlbinding">MakieCore.image!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`image!` is the mutating variant of plotting function `image`. Check the docstring for `image` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.lines' href='#MakieCore.lines'><span class="jlbinding">MakieCore.lines</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
lines(positions)
lines(x, y)
lines(x, y, z)
```


Creates a connected line plot for each element in `(x, y, z)`, `(x, y)` or `positions`.

`NaN` values are displayed as gaps in the line.

**Plot type**

The plot type alias for the `lines` function is `Lines`.

**Attributes**

**`alpha`** =  `1.0`  — The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`color`** =  `@inherit linecolor`  — The color of the line.

**`colormap`** =  `@inherit colormap :viridis`  — Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

**`colorrange`** =  `automatic`  — The values representing the start and end points of `colormap`.

**`colorscale`** =  `identity`  — The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.

**`cycle`** =  `[:color]`  — Sets which attributes to cycle when creating multiple plots.

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`fxaa`** =  `false`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`highclip`** =  `automatic`  — The color for any value above the colorrange.

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`joinstyle`** =  `@inherit joinstyle`  — Controls the rendering at corners. Options are `:miter` for sharp corners, `:bevel` for &quot;cut off&quot; corners, and `:round` for rounded corners. If the corner angle is below `miter_limit`, `:miter` is equivalent to `:bevel` to avoid long spikes.

**`linecap`** =  `@inherit linecap`  — Sets the type of line cap used. Options are `:butt` (flat without extrusion), `:square` (flat with half a linewidth extrusion) or `:round`.

**`linestyle`** =  `nothing`  — Sets the dash pattern of the line. Options are `:solid` (equivalent to `nothing`), `:dot`, `:dash`, `:dashdot` and `:dashdotdot`. These can also be given in a tuple with a gap style modifier, either `:normal`, `:dense` or `:loose`. For example, `(:dot, :loose)` or `(:dashdot, :dense)`.

For custom patterns have a look at [`Makie.Linestyle`](/api#Makie.Linestyle).

**`linewidth`** =  `@inherit linewidth`  — Sets the width of the line in screen units

**`lowclip`** =  `automatic`  — The color for any value below the colorrange.

**`miter_limit`** =  `@inherit miter_limit`  — Sets the minimum inner join angle below which miter joins truncate. See also `Makie.miter_distance_to_angle`.

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`nan_color`** =  `:transparent`  — The color for NaN values.

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L605" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.lines!' href='#MakieCore.lines!'><span class="jlbinding">MakieCore.lines!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`lines!` is the mutating variant of plotting function `lines`. Check the docstring for `lines` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.linesegments' href='#MakieCore.linesegments'><span class="jlbinding">MakieCore.linesegments</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
linesegments(positions)
linesegments(vector_of_2tuples_of_points)
linesegments(x, y)
linesegments(x, y, z)
```


Plots a line for each pair of points in `(x, y, z)`, `(x, y)`, or `positions`.

**Plot type**

The plot type alias for the `linesegments` function is `LineSegments`.

**Attributes**

**`alpha`** =  `1.0`  — The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`color`** =  `@inherit linecolor`  — The color of the line.

**`colormap`** =  `@inherit colormap :viridis`  — Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

**`colorrange`** =  `automatic`  — The values representing the start and end points of `colormap`.

**`colorscale`** =  `identity`  — The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.

**`cycle`** =  `[:color]`  — Sets which attributes to cycle when creating multiple plots.

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`fxaa`** =  `false`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`highclip`** =  `automatic`  — The color for any value above the colorrange.

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`linecap`** =  `@inherit linecap`  — Sets the type of linecap used, i.e. :butt (flat with no extrusion), :square (flat with 1 linewidth extrusion) or :round.

**`linestyle`** =  `nothing`  — Sets the dash pattern of the line. Options are `:solid` (equivalent to `nothing`), `:dot`, `:dash`, `:dashdot` and `:dashdotdot`. These can also be given in a tuple with a gap style modifier, either `:normal`, `:dense` or `:loose`. For example, `(:dot, :loose)` or `(:dashdot, :dense)`.

For custom patterns have a look at [`Makie.Linestyle`](/api#Makie.Linestyle).

**`linewidth`** =  `@inherit linewidth`  — Sets the width of the line in pixel units

**`lowclip`** =  `automatic`  — The color for any value below the colorrange.

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`nan_color`** =  `:transparent`  — The color for NaN values.

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L595" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.linesegments!' href='#MakieCore.linesegments!'><span class="jlbinding">MakieCore.linesegments!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`linesegments!` is the mutating variant of plotting function `linesegments`. Check the docstring for `linesegments` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.mesh' href='#MakieCore.mesh'><span class="jlbinding">MakieCore.mesh</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
mesh(x, y, z)
mesh(mesh_object)
mesh(x, y, z, faces)
mesh(xyz, faces)
```


Plots a 3D or 2D mesh. Supported `mesh_object`s include `Mesh` types from [GeometryBasics.jl](https://github.com/JuliaGeometry/GeometryBasics.jl).

**Plot type**

The plot type alias for the `mesh` function is `Mesh`.

**Attributes**

**`alpha`** =  `1.0`  — The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

**`backlight`** =  `0.0`  — Sets a weight for secondary light calculation with inverted normals.

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`color`** =  `@inherit patchcolor`  — Sets the color of the mesh. Can be a `Vector{<:Colorant}` for per vertex colors or a single `Colorant`. A `Matrix{<:Colorant}` can be used to color the mesh with a texture, which requires the mesh to contain texture coordinates. A `<: AbstractPattern` can be used to apply a repeated, pixel sampled pattern to the mesh, e.g. for hatching.

**`colormap`** =  `@inherit colormap :viridis`  — Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

**`colorrange`** =  `automatic`  — The values representing the start and end points of `colormap`.

**`colorscale`** =  `identity`  — The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.

**`cycle`** =  `[:color => :patchcolor]`  — _No docs available._

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`diffuse`** =  `1.0`  — Sets how strongly the red, green and blue channel react to diffuse (scattered) light.

**`fxaa`** =  `true`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`highclip`** =  `automatic`  — The color for any value above the colorrange.

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`interpolate`** =  `true`  — sets whether colors should be interpolated

**`lowclip`** =  `automatic`  — The color for any value below the colorrange.

**`matcap`** =  `nothing`  — _No docs available._

**`material`** =  `nothing`  — RPRMakie only attribute to set complex RadeonProRender materials.         _Warning_, how to set an RPR material may change and other backends will ignore this attribute

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`nan_color`** =  `:transparent`  — The color for NaN values.

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`shading`** =  `automatic`  — Sets the lighting algorithm used. Options are `NoShading` (no lighting), `FastShading` (AmbientLight + PointLight) or `MultiLightShading` (Multiple lights, GLMakie only). Note that this does not affect RPRMakie.

**`shininess`** =  `32.0`  — Sets how sharp the reflection is.

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`specular`** =  `0.2`  — Sets how strongly the object reflects light in the red, green and blue channels.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`uv_transform`** =  `automatic`  — Sets a transform for uv coordinates, which controls how a texture is mapped to a mesh. The attribute can be `I`, `scale::VecTypes{2}`, `(translation::VecTypes{2}, scale::VecTypes{2})`, any of :rotr90, :rotl90, :rot180, :swap_xy/:transpose, :flip_x, :flip_y, :flip_xy, or most generally a `Makie.Mat{2, 3, Float32}` or `Makie.Mat3f` as returned by `Makie.uv_transform()`. They can also be changed by passing a tuple `(op3, op2, op1)`.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L612" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.mesh!' href='#MakieCore.mesh!'><span class="jlbinding">MakieCore.mesh!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`mesh!` is the mutating variant of plotting function `mesh`. Check the docstring for `mesh` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.meshscatter' href='#MakieCore.meshscatter'><span class="jlbinding">MakieCore.meshscatter</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
meshscatter(positions)
meshscatter(x, y)
meshscatter(x, y, z)
```


Plots a mesh for each element in `(x, y, z)`, `(x, y)`, or `positions` (similar to `scatter`). `markersize` is a scaling applied to the primitive passed as `marker`.

**Plot type**

The plot type alias for the `meshscatter` function is `MeshScatter`.

**Attributes**

**`alpha`** =  `1.0`  — The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

**`backlight`** =  `0.0`  — Sets a weight for secondary light calculation with inverted normals.

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`color`** =  `@inherit markercolor`  — Sets the color of the marker.

**`colormap`** =  `@inherit colormap :viridis`  — Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

**`colorrange`** =  `automatic`  — The values representing the start and end points of `colormap`.

**`colorscale`** =  `identity`  — The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.

**`cycle`** =  `[:color]`  — _No docs available._

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`diffuse`** =  `1.0`  — Sets how strongly the red, green and blue channel react to diffuse (scattered) light.

**`fxaa`** =  `true`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`highclip`** =  `automatic`  — The color for any value above the colorrange.

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`lowclip`** =  `automatic`  — The color for any value below the colorrange.

**`marker`** =  `:Sphere`  — Sets the scattered mesh.

**`markersize`** =  `0.1`  — Sets the scale of the mesh. This can be given as a `Vector` to apply to each scattered mesh individually.

**`material`** =  `nothing`  — RPRMakie only attribute to set complex RadeonProRender materials.         _Warning_, how to set an RPR material may change and other backends will ignore this attribute

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`nan_color`** =  `:transparent`  — The color for NaN values.

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`rotation`** =  `0.0`  — Sets the rotation of the mesh. A numeric rotation is around the z-axis, a `Vec3f` causes the mesh to rotate such that the the z-axis is now that vector, and a quaternion describes a general rotation. This can be given as a Vector to apply to each scattered mesh individually.

**`shading`** =  `automatic`  — Sets the lighting algorithm used. Options are `NoShading` (no lighting), `FastShading` (AmbientLight + PointLight) or `MultiLightShading` (Multiple lights, GLMakie only). Note that this does not affect RPRMakie.

**`shininess`** =  `32.0`  — Sets how sharp the reflection is.

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`specular`** =  `0.2`  — Sets how strongly the object reflects light in the red, green and blue channels.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`transform_marker`** =  `true`  — Controls whether the (complete) model matrix applies to the scattered mesh, rather than just the positions. (If this is false, `scale!`, `rotate!` and `translate!()` will not affect the scattered mesh.)

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`uv_transform`** =  `automatic`  — Sets a transform for uv coordinates, which controls how a texture is mapped to the scattered mesh. Note that the mesh needs to include uv coordinates for this, which is not the case by default for geometry primitives. You can use `GeometryBasics.uv_normal_mesh(prim)` with, for example `prim = Rect2f(0, 0, 1, 1)`. The attribute can be `I`, `scale::VecTypes{2}`, `(translation::VecTypes{2}, scale::VecTypes{2})`, any of :rotr90, :rotl90, :rot180, :swap_xy/:transpose, :flip_x, :flip_y, :flip_xy, or most generally a `Makie.Mat{2, 3, Float32}` or `Makie.Mat3f` as returned by `Makie.uv_transform()`. It can also be set per scattered mesh by passing a `Vector` of any of the above and operations can be changed by passing a tuple `(op3, op2, op1)`.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L615" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.meshscatter!' href='#MakieCore.meshscatter!'><span class="jlbinding">MakieCore.meshscatter!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`meshscatter!` is the mutating variant of plotting function `meshscatter`. Check the docstring for `meshscatter` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.poly' href='#MakieCore.poly'><span class="jlbinding">MakieCore.poly</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
poly(vertices, indices; kwargs...)
poly(points; kwargs...)
poly(shape; kwargs...)
poly(mesh; kwargs...)
```


Plots a polygon based on the arguments given. When vertices and indices are given, it functions similarly to `mesh`. When points are given, it draws one polygon that connects all the points in order. When a shape is given (essentially anything decomposable by `GeometryBasics`), it will plot `decompose(shape)`.

```
poly(coordinates, connectivity; kwargs...)
```


Plots polygons, which are defined by `coordinates` (the coordinates of the vertices) and `connectivity` (the edges between the vertices).

**Plot type**

The plot type alias for the `poly` function is `Poly`.

**Attributes**

**`alpha`** =  `1.0`  — The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`color`** =  `@inherit patchcolor`  — Sets the color of the poly. Can be a `Vector{<:Colorant}` for per vertex colors or a single `Colorant`. A `Matrix{<:Colorant}` can be used to color the mesh with a texture, which requires the mesh to contain texture coordinates. Vector or Matrices of numbers can be used as well, which will use the colormap arguments to map the numbers to colors. One can also use a `<: AbstractPattern`, to cover the poly with a regular pattern, e.g. for hatching.

**`colormap`** =  `@inherit colormap :viridis`  — Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

**`colorrange`** =  `automatic`  — The values representing the start and end points of `colormap`.

**`colorscale`** =  `identity`  — The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.

**`cycle`** =  `[:color => :patchcolor]`  — _No docs available._

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`fxaa`** =  `true`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`highclip`** =  `automatic`  — The color for any value above the colorrange.

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`joinstyle`** =  `@inherit joinstyle`  — _No docs available._

**`linecap`** =  `@inherit linecap`  — _No docs available._

**`linestyle`** =  `nothing`  — Sets the dash pattern of the line. Options are `:solid` (equivalent to `nothing`), `:dot`, `:dash`, `:dashdot` and `:dashdotdot`. These can also be given in a tuple with a gap style modifier, either `:normal`, `:dense` or `:loose`. For example, `(:dot, :loose)` or `(:dashdot, :dense)`.

For custom patterns have a look at [`Makie.Linestyle`](/api#Makie.Linestyle).

**`lowclip`** =  `automatic`  — The color for any value below the colorrange.

**`miter_limit`** =  `@inherit miter_limit`  — _No docs available._

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`nan_color`** =  `:transparent`  — The color for NaN values.

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`shading`** =  `NoShading`  — _No docs available._

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`stroke_depth_shift`** =  `-1.0e-5`  — Depth shift of stroke plot. This is useful to avoid z-fighting between the stroke and the fill.

**`strokecolor`** =  `@inherit patchstrokecolor`  — Sets the color of the outline around a marker.

**`strokecolormap`** =  `@inherit colormap`  — Sets the colormap that is sampled for numeric `color`s.

**`strokewidth`** =  `@inherit patchstrokewidth`  — Sets the width of the outline.

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L621" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.poly!' href='#MakieCore.poly!'><span class="jlbinding">MakieCore.poly!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`poly!` is the mutating variant of plotting function `poly`. Check the docstring for `poly` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.scatter' href='#MakieCore.scatter'><span class="jlbinding">MakieCore.scatter</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
scatter(positions)
scatter(x, y)
scatter(x, y, z)
```


Plots a marker for each element in `(x, y, z)`, `(x, y)`, or `positions`.

**Plot type**

The plot type alias for the `scatter` function is `Scatter`.

**Attributes**

**`alpha`** =  `1.0`  — The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`color`** =  `@inherit markercolor`  — Sets the color of the marker. If no color is set, multiple calls to `scatter!` will cycle through the axis color palette.

**`colormap`** =  `@inherit colormap :viridis`  — Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

**`colorrange`** =  `automatic`  — The values representing the start and end points of `colormap`.

**`colorscale`** =  `identity`  — The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.

**`cycle`** =  `[:color]`  — Sets which attributes to cycle when creating multiple plots

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`depthsorting`** =  `false`  — Enables depth-sorting of markers which can improve border artifacts. Currently supported in GLMakie only.

**`distancefield`** =  `nothing`  — Optional distancefield used for e.g. font and bezier path rendering. Will get set automatically.

**`font`** =  `@inherit markerfont`  — Sets the font used for character markers. Can be a `String` specifying the (partial) name of a font or the file path of a font file

**`fxaa`** =  `false`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`glowcolor`** =  `(:black, 0.0)`  — Sets the color of the glow effect around the marker.

**`glowwidth`** =  `0.0`  — Sets the size of a glow effect around the marker.

**`highclip`** =  `automatic`  — The color for any value above the colorrange.

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`lowclip`** =  `automatic`  — The color for any value below the colorrange.

**`marker`** =  `@inherit marker`  — Sets the scatter marker.

**`marker_offset`** =  `Vec3f(0)`  — The offset of the marker from the given position in `markerspace` units. An offset of 0 corresponds to a centered marker.

**`markersize`** =  `@inherit markersize`  — Sets the size of the marker by scaling it relative to its base size which can differ for each marker. A `Real` scales x and y dimensions by the same amount. A `Vec` or `Tuple` with two elements scales x and y separately. An array of either scales each marker separately. Humans perceive the area of a marker as its size which grows quadratically with `markersize`, so multiplying `markersize` by 2 results in a marker that is 4 times as large, visually.

**`markerspace`** =  `:pixel`  — Sets the space in which `markersize` is given. See `Makie.spaces()` for possible inputs

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`nan_color`** =  `:transparent`  — The color for NaN values.

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`rotation`** =  `Billboard()`  — Sets the rotation of the marker. A `Billboard` rotation is always around the depth axis.

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`strokecolor`** =  `@inherit markerstrokecolor`  — Sets the color of the outline around a marker.

**`strokewidth`** =  `@inherit markerstrokewidth`  — Sets the width of the outline around a marker.

**`transform_marker`** =  `false`  — Controls whether the model matrix (without translation) applies to the marker itself, rather than just the positions. (If this is true, `scale!` and `rotate!` will affect the marker.

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`uv_offset_width`** =  `(0.0, 0.0, 0.0, 0.0)`  — _No docs available._

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L617" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.scatter!' href='#MakieCore.scatter!'><span class="jlbinding">MakieCore.scatter!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`scatter!` is the mutating variant of plotting function `scatter`. Check the docstring for `scatter` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.surface' href='#MakieCore.surface'><span class="jlbinding">MakieCore.surface</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
surface(x, y, z)
surface(z)
```


Plots a surface, where `(x, y)` define a grid whose heights are the entries in `z`. `x` and `y` may be `Vectors` which define a regular grid, **or** `Matrices` which define an irregular grid.

**Plot type**

The plot type alias for the `surface` function is `Surface`.

**Attributes**

**`alpha`** =  `1.0`  — The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

**`backlight`** =  `0.0`  — Sets a weight for secondary light calculation with inverted normals.

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`color`** =  `nothing`  — Can be set to an `Matrix{<: Union{Number, Colorant}}` to color surface independent of the `z` component. If `color=nothing`, it defaults to `color=z`. Can also be a `Makie.AbstractPattern`.

**`colormap`** =  `@inherit colormap :viridis`  — Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

**`colorrange`** =  `automatic`  — The values representing the start and end points of `colormap`.

**`colorscale`** =  `identity`  — The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`diffuse`** =  `1.0`  — Sets how strongly the red, green and blue channel react to diffuse (scattered) light.

**`fxaa`** =  `true`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`highclip`** =  `automatic`  — The color for any value above the colorrange.

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`interpolate`** =  `true`  — [(W)GLMakie only] Specifies whether the surface matrix gets sampled with interpolation.

**`invert_normals`** =  `false`  — Inverts the normals generated for the surface. This can be useful to illuminate the other side of the surface.

**`lowclip`** =  `automatic`  — The color for any value below the colorrange.

**`material`** =  `nothing`  — RPRMakie only attribute to set complex RadeonProRender materials.         _Warning_, how to set an RPR material may change and other backends will ignore this attribute

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`nan_color`** =  `:transparent`  — The color for NaN values.

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`shading`** =  `automatic`  — Sets the lighting algorithm used. Options are `NoShading` (no lighting), `FastShading` (AmbientLight + PointLight) or `MultiLightShading` (Multiple lights, GLMakie only). Note that this does not affect RPRMakie.

**`shininess`** =  `32.0`  — Sets how sharp the reflection is.

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`specular`** =  `0.2`  — Sets how strongly the object reflects light in the red, green and blue channels.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`uv_transform`** =  `automatic`  — Sets a transform for uv coordinates, which controls how a texture is mapped to a surface. The attribute can be `I`, `scale::VecTypes{2}`, `(translation::VecTypes{2}, scale::VecTypes{2})`, any of :rotr90, :rotl90, :rot180, :swap_xy/:transpose, :flip_x, :flip_y, :flip_xy, or most generally a `Makie.Mat{2, 3, Float32}` or `Makie.Mat3f` as returned by `Makie.uv_transform()`. They can also be changed by passing a tuple `(op3, op2, op1)`.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L605" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.surface!' href='#MakieCore.surface!'><span class="jlbinding">MakieCore.surface!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`surface!` is the mutating variant of plotting function `surface`. Check the docstring for `surface` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.text' href='#MakieCore.text'><span class="jlbinding">MakieCore.text</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
text(positions; text, kwargs...)
text(x, y; text, kwargs...)
text(x, y, z; text, kwargs...)
```


Plots one or multiple texts passed via the `text` keyword. `Text` uses the `PointBased` conversion trait.

**Plot type**

The plot type alias for the `text` function is `Text`.

**Attributes**

**`align`** =  `(:left, :bottom)`  — Sets the alignment of the string w.r.t. `position`. Uses `:left, :center, :right, :top, :bottom, :baseline` or fractions.

**`alpha`** =  `1.0`  — The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`color`** =  `@inherit textcolor`  — Sets the color of the text. One can set one color per glyph by passing a `Vector{<:Colorant}`, or one colorant for the whole text. If color is a vector of numbers, the colormap args are used to map the numbers to colors.

**`colormap`** =  `@inherit colormap :viridis`  — Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

**`colorrange`** =  `automatic`  — The values representing the start and end points of `colormap`.

**`colorscale`** =  `identity`  — The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`font`** =  `@inherit font`  — Sets the font. Can be a `Symbol` which will be looked up in the `fonts` dictionary or a `String` specifying the (partial) name of a font or the file path of a font file

**`fonts`** =  `@inherit fonts`  — Used as a dictionary to look up fonts specified by `Symbol`, for example `:regular`, `:bold` or `:italic`.

**`fontsize`** =  `@inherit fontsize`  — The fontsize in units depending on `markerspace`.

**`fxaa`** =  `false`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`glowcolor`** =  `(:black, 0.0)`  — Sets the color of the glow effect around the text.

**`glowwidth`** =  `0.0`  — Sets the size of a glow effect around the text.

**`highclip`** =  `automatic`  — The color for any value above the colorrange.

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`justification`** =  `automatic`  — Sets the alignment of text w.r.t its bounding box. Can be `:left, :center, :right` or a fraction. Will default to the horizontal alignment in `align`.

**`lineheight`** =  `1.0`  — The lineheight multiplier.

**`lowclip`** =  `automatic`  — The color for any value below the colorrange.

**`markerspace`** =  `:pixel`  — Sets the space in which `fontsize` acts. See `Makie.spaces()` for possible inputs.

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`nan_color`** =  `:transparent`  — The color for NaN values.

**`offset`** =  `(0.0, 0.0)`  — The offset of the text from the given position in `markerspace` units.

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`position`** =  `(0.0, 0.0)`  — Deprecated: Specifies the position of the text. Use the positional argument to `text` instead.

**`rotation`** =  `0.0`  — Rotates text around the given position

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`strokecolor`** =  `(:black, 0.0)`  — Sets the color of the outline around a marker.

**`strokewidth`** =  `0`  — Sets the width of the outline around a marker.

**`text`** =  `""`  — Specifies one piece of text or a vector of texts to show, where the number has to match the number of positions given. Makie supports `String` which is used for all normal text and `LaTeXString` which layouts mathematical expressions using `MathTeXEngine.jl`.

**`transform_marker`** =  `false`  — Controls whether the model matrix (without translation) applies to the glyph itself, rather than just the positions. (If this is true, `scale!` and `rotate!` will affect the text glyphs.)

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.

**`word_wrap_width`** =  `-1`  — Specifies a linewidth limit for text. If a word overflows this limit, a newline is inserted before it. Negative numbers disable word wrapping.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L616" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.text!' href='#MakieCore.text!'><span class="jlbinding">MakieCore.text!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`text!` is the mutating variant of plotting function `text`. Check the docstring for `text` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.volume' href='#MakieCore.volume'><span class="jlbinding">MakieCore.volume</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
volume(volume_data)
volume(x, y, z, volume_data)
```


Plots a volume with optional physical dimensions `x, y, z`.

All volume plots are derived from casting rays for each drawn pixel. These rays intersect with the volume data to derive some color, usually based on the given colormap. How exactly the color is derived depends on the algorithm used.

**Plot type**

The plot type alias for the `volume` function is `Volume`.

**Attributes**

**`absorption`** =  `1.0`  — Absorption multiplier for algorithm = :absorption, :absorptionrgba and :indexedabsorption. This changes how much light each voxel absorbs.

**`algorithm`** =  `:mip`  — Sets the volume algorithm that is used. Available algorithms are:
- `:iso`: Shows an isovalue surface within the given float data. For this only samples within `isovalue - isorange .. isovalue + isorange` are included in the final color of a pixel.
  
- `:absorption`: Accumulates color based on the float values sampled from volume data. At each ray step (starting from the front) a value is sampled from the volume data and then used to sample the colormap. The resulting color is weighted by the ray step size and blended the previously accumulated color. The weight of each step can be adjusted with the multiplicative `absorption` attribute.
  
- `:mip`: Shows the maximum intensity projection of the given float data. This derives the color of a pixel from the largest value sampled from the respective ray.
  
- `:absorptionrgba`: This algorithm matches :absorption, but samples colors directly from RGBA volume data. For each ray step a color is sampled from the data, weighted by the ray step size and blended with the previously accumulated color. Also considers `absorption`.
  
- `:additive`: Accumulates colors using `accumulated_color = 1 - (1 - accumulated_color) * (1 - sampled_color)` where `sampled_color` is a sample of volume data at the current ray step.
  
- `:indexedabsorption`: This algorithm acts the same as :absorption, but interprets the volume data as indices. They are used as direct indices to the colormap. Also considers `absorption`.
  

**`alpha`** =  `1.0`  — The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

**`backlight`** =  `0.0`  — Sets a weight for secondary light calculation with inverted normals.

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`colormap`** =  `@inherit colormap :viridis`  — Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

**`colorrange`** =  `automatic`  — The values representing the start and end points of `colormap`.

**`colorscale`** =  `identity`  — The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`diffuse`** =  `1.0`  — Sets how strongly the red, green and blue channel react to diffuse (scattered) light.

**`enable_depth`** =  `true`  — Enables depth write for :iso so that volume correctly occludes other objects.

**`fxaa`** =  `true`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`highclip`** =  `automatic`  — The color for any value above the colorrange.

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`interpolate`** =  `true`  — Sets whether the volume data should be sampled with interpolation.

**`isorange`** =  `0.05`  — Sets the maximum accepted distance from the isovalue for the :iso algorithm. `accepted = isovalue - isorange < value < isovalue + isorange`

**`isovalue`** =  `0.5`  — Sets the target value for the :iso algorithm. `accepted = isovalue - isorange < value < isovalue + isorange`

**`lowclip`** =  `automatic`  — The color for any value below the colorrange.

**`material`** =  `nothing`  — RPRMakie only attribute to set complex RadeonProRender materials.         _Warning_, how to set an RPR material may change and other backends will ignore this attribute

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`nan_color`** =  `:transparent`  — The color for NaN values.

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`shading`** =  `automatic`  — Sets the lighting algorithm used. Options are `NoShading` (no lighting), `FastShading` (AmbientLight + PointLight) or `MultiLightShading` (Multiple lights, GLMakie only). Note that this does not affect RPRMakie.

**`shininess`** =  `32.0`  — Sets how sharp the reflection is.

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`specular`** =  `0.2`  — Sets how strongly the object reflects light in the red, green and blue channels.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L614" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.volume!' href='#MakieCore.volume!'><span class="jlbinding">MakieCore.volume!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`volume!` is the mutating variant of plotting function `volume`. Check the docstring for `volume` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.voxels' href='#MakieCore.voxels'><span class="jlbinding">MakieCore.voxels</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
voxels(x, y, z, chunk::Array{<:Real, 3})
voxels(chunk::Array{<:Real, 3})
```


Plots a chunk of voxels centered at 0. Optionally the placement and scaling of the chunk can be given as range-like x, y and z. (Only the extrema are considered here. Voxels are always uniformly sized.)

Internally voxels are represented as 8 bit unsigned integer, with `0x00` always being an invisible &quot;air&quot; voxel. Passing a chunk with matching type will directly set those values. Note that color handling is specialized for the internal representation and may behave a bit differently than usual.

Note that `voxels` is currently considered experimental and may still see breaking changes in patch releases.

**Plot type**

The plot type alias for the `voxels` function is `Voxels`.

**Attributes**

**`alpha`** =  `1.0`  — The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

**`backlight`** =  `0.0`  — Sets a weight for secondary light calculation with inverted normals.

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`color`** =  `nothing`  — Sets colors per voxel id, skipping `0x00`. This means that a voxel with id 1 will grab `plot.colors[1]` and so on up to id 255. This can also be set to a Matrix of colors, i.e. an image for texture mapping.

**`colormap`** =  `@inherit colormap :viridis`  — Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

**`colorrange`** =  `automatic`  — The values representing the start and end points of `colormap`.

**`colorscale`** =  `identity`  — The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.

**`depth_shift`** =  `0.0`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`depthsorting`** =  `false`  — Controls the render order of voxels. If set to `false` voxels close to the viewer are rendered first which should reduce overdraw and yield better performance. If set to `true` voxels are rendered back to front enabling correct order for transparent voxels.

**`diffuse`** =  `1.0`  — Sets how strongly the red, green and blue channel react to diffuse (scattered) light.

**`fxaa`** =  `true`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`gap`** =  `0.0`  — Sets the gap between adjacent voxels in units of the voxel size. This needs to be larger than 0.01 to take effect.

**`highclip`** =  `automatic`  — The color for any value above the colorrange.

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`interpolate`** =  `false`  — Controls whether the texture map is sampled with interpolation (i.e. smoothly) or not (i.e. pixelated).

**`is_air`** =  `x->begin         #= /home/runner/work/Makie.jl/Makie.jl/MakieCore/src/basic_plots.jl:626 =#         isnothing(x) || (ismissing(x) || isnan(x))     end`  — A function that controls which values in the input data are mapped to invisible (air) voxels.

**`lowclip`** =  `automatic`  — The color for any value below the colorrange.

**`material`** =  `nothing`  — RPRMakie only attribute to set complex RadeonProRender materials.         _Warning_, how to set an RPR material may change and other backends will ignore this attribute

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`nan_color`** =  `:transparent`  — The color for NaN values.

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`shading`** =  `automatic`  — Sets the lighting algorithm used. Options are `NoShading` (no lighting), `FastShading` (AmbientLight + PointLight) or `MultiLightShading` (Multiple lights, GLMakie only). Note that this does not affect RPRMakie.

**`shininess`** =  `32.0`  — Sets how sharp the reflection is.

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`specular`** =  `0.2`  — Sets how strongly the object reflects light in the red, green and blue channels.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`uv_transform`** =  `nothing`  — To use texture mapping `uv_transform` needs to be defined and `color` needs to be an image. The `uv_transform` can be given as a `Vector` where each index maps to a `UInt8` voxel id (skipping 0), or as a `Matrix` where the second index maps to a side following the order `(-x, -y, -z, +x, +y, +z)`. Each element acts as a `Mat{2, 3, Float32}` which is applied to `Vec3f(uv, 1)`, where uv&#39;s are generated to run from 0..1 for each voxel. The result is then used to sample the texture. UV transforms have a bunch of shorthands you can use, for example `(Point2f(x, y), Vec2f(xscale, yscale))`. They are listed in `?Makie.uv_transform`.

**`uvmap`** =  `nothing`  — Deprecated - use uv_transform

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L632" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.voxels!' href='#MakieCore.voxels!'><span class="jlbinding">MakieCore.voxels!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`voxels!` is the mutating variant of plotting function `voxels`. Check the docstring for `voxels` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.wireframe' href='#MakieCore.wireframe'><span class="jlbinding">MakieCore.wireframe</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
wireframe(x, y, z)
wireframe(positions)
wireframe(mesh)
```


Draws a wireframe, either interpreted as a surface or as a mesh.

**Plot type**

The plot type alias for the `wireframe` function is `Wireframe`.

**Attributes**

**`alpha`** =  `1.0`  — The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

**`clip_planes`** =  `automatic`  — Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

**`color`** =  `@inherit linecolor`  — The color of the line.

**`colormap`** =  `@inherit colormap :viridis`  — Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

**`colorrange`** =  `automatic`  — The values representing the start and end points of `colormap`.

**`colorscale`** =  `identity`  — The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.

**`cycle`** =  `[:color]`  — Sets which attributes to cycle when creating multiple plots.

**`depth_shift`** =  `-1.0e-5`  — Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

**`fxaa`** =  `false`  — Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

**`highclip`** =  `automatic`  — The color for any value above the colorrange.

**`inspectable`** =  `@inherit inspectable`  — Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

**`inspector_clear`** =  `automatic`  — Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

**`inspector_hover`** =  `automatic`  — Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

**`inspector_label`** =  `automatic`  — Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

**`linecap`** =  `@inherit linecap`  — Sets the type of linecap used, i.e. :butt (flat with no extrusion), :square (flat with 1 linewidth extrusion) or :round.

**`linestyle`** =  `nothing`  — Sets the dash pattern of the line. Options are `:solid` (equivalent to `nothing`), `:dot`, `:dash`, `:dashdot` and `:dashdotdot`. These can also be given in a tuple with a gap style modifier, either `:normal`, `:dense` or `:loose`. For example, `(:dot, :loose)` or `(:dashdot, :dense)`.

For custom patterns have a look at [`Makie.Linestyle`](/api#Makie.Linestyle).

**`linewidth`** =  `@inherit linewidth`  — Sets the width of the line in pixel units

**`lowclip`** =  `automatic`  — The color for any value below the colorrange.

**`model`** =  `automatic`  — Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

**`nan_color`** =  `:transparent`  — The color for NaN values.

**`overdraw`** =  `false`  — Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

**`space`** =  `:data`  — Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

**`ssao`** =  `false`  — Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

**`transformation`** =  `:automatic`  — _No docs available._

**`transparency`** =  `false`  — Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

**`visible`** =  `true`  — Controls whether the plot will be rendered or not.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L520-L594" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='MakieCore.wireframe!' href='#MakieCore.wireframe!'><span class="jlbinding">MakieCore.wireframe!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



`wireframe!` is the mutating variant of plotting function `wireframe`. Check the docstring for `wireframe` for further information.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/MakieCore/src/recipes.jl#L522" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.And' href='#Makie.And'><span class="jlbinding">Makie.And</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
And(left, right[, rest...])
```


Creates an `And` struct with the left and right argument for later evaluation. If more than two arguments are given a tree of `And` structs is created.

See also: [`Or`](/api#Makie.Or), [`Not`](/api#Makie.Not), [`ispressed`](/api#Makie.ispressed), `&`


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/interaction/events.jl#L105-L112" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Not' href='#Makie.Not'><span class="jlbinding">Makie.Not</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Not(x)
```


Creates a `Not` struct with the given argument for later evaluation.

See also: [`And`](/api#Makie.And), [`Or`](/api#Makie.Or), [`ispressed`](/api#Makie.ispressed), `!`


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/interaction/events.jl#L135-L141" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Makie.Or' href='#Makie.Or'><span class="jlbinding">Makie.Or</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Or(left, right[, rest...])
```


Creates an `Or` struct with the left and right argument for later evaluation. If more than two arguments are given a tree of `Or` structs is created.

See also: [`And`](/api#Makie.And), [`Not`](/api#Makie.Not), [`ispressed`](/api#Makie.ispressed), `|`


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/406a09fe6f430d0a43f0f3cf1a876583e9bafbf5/src/interaction/events.jl#L120-L127" target="_blank" rel="noreferrer">source</a></Badge>

</details>

