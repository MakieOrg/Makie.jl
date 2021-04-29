# Observables & Interaction

Interaction and animations in Makie are handled using [`Observables.jl`](https://juliagizmos.github.io/Observables.jl/stable/).
`Observable`s are called `Node`s in Makie for historical reasons and the two terms are used interchangeably.
An `Observable` is a container object whose stored value you can update interactively.
You can create functions that are executed whenever an observable changes.
You can also create observables whose values are updated whenever other observables change.
This way you can easily build dynamic and interactive visualizations.

On this page you will learn how the `Node`s pipeline and the event-based interaction system work.

## The `Node` structure

A `Node` is an object that allows its value to be updated interactively.
Let's start by creating one:

```@example 1
using GLMakie, AbstractPlotting

x = Node(0.0)
```

Each `Node` has a type parameter, which determines what kind of objects it can store.
If you create one like we did above, the type parameter will be the type of the argument.
Keep in mind that sometimes you want a wider parametric type because you intend to update the `Node` later with objects of different types.
You could for example write:

```julia
x2 = Node{Real}(0.0)
x3 = Node{Any}(0.0)
```

This is often the case when dealing with attributes that can come in different forms.
For example, a color could be `:red` or `RGB(1,0,0)`.

## Triggering A Change

You change the value of a Node with empy index notation:

```@example 1
x[] = 3.34
nothing # hide
```

This was not particularly interesting.
But Nodes allow you to register functions that are executed whenever the Node's content is changed.

One such function is `on`. Let's register something on our Node `x` and change `x`'s value:

```@example 1
on(x) do x
    println("New value of x is $x")
end

x[] = 5.0
nothing # hide
```

!!! note
    All registered functions in a `Node` are executed synchronously in the order of registration.
    This means that if you change two Nodes after one another, all effects of the first change will happen before the second change.

There are two ways to access the value of a `Node`.
You can use the indexing syntax or the `to_value` function:

```julia
value = x[]
value = to_value(x)
```

The advantage of using `to_value` is that you can use it in situations where you could either be dealing with Nodes or normal values. In the latter case, `to_value` just returns the original value, like `identity`.

## Chaining `Node`s With `lift`

You can create a Node depending on another Node using [`lift`](@ref).
The first argument of `lift` must be a function that computes the value of the output Node given the values of the input Nodes.

```@example 1
f(x) = x^2
y = lift(f, x)
```

Now, whenever `x` changes, the derived `Node` `y` will immediately hold the value `f(x)`.
In turn, `y`'s change could trigger the update of other observables, if any have been connected.
Let's connect one more observable and update x:

```@example 1
z = lift(y) do y
    -y
end

x[] = 10.0

@show x[]
@show y[]
@show z[]
nothing # hide
```

If `x` changes, so does `y` and then `z`.

Note, though, that changing `y` does not change `x`.
There is no guarantee that chained Nodes are always synchronized, because they
can be mutated in different places, even sidestepping the change trigger mechanism.

```@example 1
y[] = 20.0

@show x[]
@show y[]
@show z[]
nothing # hide
```


## Shorthand Macro For `lift`

When using [`lift`](@ref), it can be tedious to reference each participating `Node`
at least three times, once as an argument to `lift`, once as an argument to the closure that
is the first argument, and at least once inside the closure:

```julia
x = Node(rand(100))
y = Node(rand(100))
z = lift((x, y) -> x .+ y, x, y)
```

To circumvent this, you can use the `@lift` macro. You simply write the operation
you want to do with the lifted `Node`s and prepend each `Node` variable
with a dollar sign $. The macro will lift every Node variable it finds and wrap
the whole expression in a closure. The equivalent to the above statement using `@lift` is:

```julia
z = @lift($x .+ $y)
```

This also works with multiline statements and tuple or array indexing:

```julia
multiline_node = @lift begin
    a = $x[1:50] .* $y[51:100]
    b = sum($z)
    a .- b
end
```

If the Node you want to reference is the result of some expression, just use `$` with parentheses around that expression.

```example
container = (x = Node(1), y = Node(2))

@lift($(container.x) + $(container.y))
```

## Problems With Synchronous Updates

One very common problem with a pipeline based on multiple observables is that you can only change observables one by one.
Theoretically, each observable change triggers its listeners immediately.
If a function depends on two or more observables, changing one right after the other would trigger it multiple times, which is often not what you want.

Here's an example where we define two nodes and lift a third one from them:

```julia
xs = Node(1:10)
ys = Node(rand(10))

zs = @lift($xs .+ $ys)
```

Now let's update both `xs` and `ys`:

```julia
xs[] = 2:11
ys[] = rand(10)
```

We just triggered `zs` twice, even though we really only intended one data update.
But this double triggering is only part of the problem.

Both `xs` and `ys` in this example had length 10, so they could still be added without a problem.
If we want to append values to xs and ys, the moment we change the length of one of them, the function underlying `zs` will error because of a shape mismatch.
Sometimes the only way to fix this situation, is to mutate the content of one observable without triggering its listeners, then triggering the second one.

```julia
xs.val = 1:11 # mutate without triggering listeners
ys[] = rand(11) # trigger listeners of ys (in this case the same as xs)
```

Use this technique sparingly, as it increases the complexity of your code and can make reasoning about it more difficult.
It also only works if you can still trigger all listeners correctly.
For example, if another observable listened only to `xs`, we wouldn't have updated it correctly in the above workaround.
Often, you can avoid length change problems by using arrays of containers like `Point2f0` or `Vec3f0` instead of synchronizing two or three observables of single element vectors manually.


## Inspecting Data

Makie provides a data inspection tool via `DataInspector(x)` where x can be a 
Figure, Axis or Scene. With it you can get a floating tooltip with relevant 
information for various plots by hovering over its elements. 

By default the inspector will be able to pick any plot other than `text` and
`volume` based plots. If you wish to ignore a plot, you can set its attribute
`plot.inspectable[] = false`. With that the next closest plot (in range) will be
picked. 


### Attributes of `DataInspector`

The `inspector = DataInspector(fig)` contains the following attributes:

- `range = 10`: Controls the snapping range for selecting an element of a plot.
- `enabled = true`: Disables inspection of plots when set to false. Can also be adjusted with `enable!(inspector)` and `disable!(inspector)`.
- `text_padding = Vec4f0(5, 5, 3, 3)`: Padding for the box drawn around the tooltip text. (left, right, bottom, top)
- `text_align = (:left, :bottom)`: Alignment of text within the tooltip. This does not affect the alignment of the tooltip relative to the cursor.
- `textcolor = :black`: Tooltip text color.
- `textsize = 20`: Tooltip text size.
- `font = "Dejavu Sans"`: Tooltip font.
- `background_color = :white`: Background color of the tooltip.
- `outline_color = :grey`: Outline color of the tooltip.
- `outline_linestyle = nothing`: Linestyle of the tooltip outline.
- `outline_linewidth = 2`: Linewidth of the tooltip outline.
- `indicator_color = :red`: Color of the selection indicator.
- `indicator_linewidth = 2`: Linewidth of the selection indicator.
- `indicator_linestyle = nothing`: Linestyle of the selection indicator  
- `tooltip_align = (:center, :top)`: Default position of the tooltip relative to the cursor or current selection. The real align may adjust to keep the tooltip in view.
- `tooltip_offset = Vec2f0(20)`: Offset from the indicator to the tooltip.  
- `depth = 9e3`: Depth value of the tooltip. This should be high so that the tooltip is always in front.


### Extending the `DataInspector`

The inspector implements tooltips for primitive plots and a few non-primitive
(i.e. a recipe) plots. All other plots will fall back to tooltips of their 
hovered child. While this means that most plots have a tooltip it also means 
many may not have a fitting one. If you wish to implement a more fitting tooltip
for non-primitive plot you may do so by creating a method 

```julia
function show_data(inspector::DataInspector, my_plot::MyPlot, idx, primitive_child::SomePrimitive)
    ...
end
```

Here `my_plot` is the plot you want to create a custom tooltip for, 
`primitive_child` is one of the primitives your plot is made from and `idx` is
the index into that primitive plot. The latter two are the result from 
`pick_sorted` at the mouseposition. In general you will need to adjust `idx` to 
be useful for `MyPlot`.

Let's take a look at the `BarPlot` overload, which also powers `hist`. It 
contains two primitive plots - `Mesh` and `Lines`. The `idx` from picking a 
`Mesh` is based on vertices, which there are four per rectangle. From `Lines` we
get an index based on the end point of the line. To draw the outline of a 
rectangle we need 5 points and a seperator, totaling 6. We thus implement

```julia
import AbstractPlotting: show_data

function show_data(inspector::DataInspector, plot::BarPlot, idx, ::Lines)
    return show_barplot(inspector, plot, div(idx-1, 6)+1)
end

function show_data(inspector::DataInspector, plot::BarPlot, idx, ::Mesh)
    return show_barplot(inspector, plot, div(idx-1, 4)+1)
end
```

to map the primitive `idx` to one relevant for `BarPlot`. With this we can now
get the position of the hovered bar with `plot[1][][idx]`. To align the tooltip
to the selection we need to compute the relevant position in screen space and
update the tooltip position. 

```julia
using AbstractPlotting: parent_scene, shift_project, update_tooltip_alignment!, position2string

function show_barplot(inspector::DataInspector, plot::BarPlot, idx)
    # All the attributes of DataInspector are here
    a = inspector.plot.attributes
    
    # Get the scene BarPlot lives in
    scene = parent_scene(plot)
    
    # Get the hovered world-space position
    pos = plot[1][][idx]
    # project to screen space and shift it to be correct on the root scene
    proj_pos = shift_project(scene, to_ndim(Point3f0, pos, 0))
    # anchor the tooltip at the projected position
    update_tooltip_alignment!(inspector, proj_pos)

    # Update the final text of the tooltip
    # position2string is just an `@sprintf`
    a._display_text[] = position2string(pos)
    # Show the tooltip
    a._visible[] = true

    # return true to indicate that we have updated the tooltip
    return true
end
```

Next we need to mark the rectangle we are hovering. In this case we can use the
rectangles which `BarPlot` passes to `Poly`, i.e. `plot.plots[1][1][][idx]`. The
`DataInspector` contains some functionality for keeping track of temporary plots, 
so we can plot the indicator to the same `scene` that `BarPlot` uses. Doing so
results in

```julia
using AbstractPlotting: 
    parent_scene, shift_project, update_tooltip_alignment!, position2string,
    clear_temporary_plots!


function show_barplot(inspector::DataInspector, plot::BarPlot, idx)
    a = inspector.plot.attributes
    scene = parent_scene(plot)
        
    pos = plot[1][][idx]
    proj_pos = shift_project(scene, to_ndim(Point3f0, pos, 0))
    update_tooltip_alignment!(inspector, proj_pos)

    # Get the rectangle BarPlot generated for Poly
    # `_bbox2D` is a node meant for saving a `Rect2D` indicator. There is also 
    # a `_bbox3D`. Here we keep `_bbox2D` updated and use it as a source for
    # our custom indicator.
    a._bbox2D[] = plot.plots[1][1][][idx]
    a._model[] = plot.model[]

    # Only plot the indicator once. It'll be updated via `_bbox2D`.
    if inspector.selection != plot
        # Clear any old temporary plots (i.e. other indicators like this)
        # this also updates inspector.selection.
        clear_temporary_plots!(inspector, plot)

        # create the indicator using a bunch of the DataInspector attributes.
        # Note that temporary plots only cleared when a new one is created. To
        # control whether indicator is visible or not `a._bbox_visible` is set
        # instead, so it should be in any custom indicator like this.
        p = wireframe!(
            scene, a._bbox2D, model = a._model, color = a.indicator_color, 
            strokewidth = a.indicator_linewidth, linestyle = a.indicator_linestyle,
            visible = a._bbox_visible, show_axis = false, inspectable = false
        )

        # Make sure this draws on top
        translate!(p, Vec3f0(0, 0, a.depth[]))

        # register this indicator for later cleanup.
        push!(inspector.temp_plots, p)
    end

    a._display_text[] = position2string(pos)
    a._visible[] = true

    # Show our custom indicator
    a._bbox_visible[] = true
    # Don't show the default screen space indicator
    a._px_bbox_visible[] = false

    return true
end
```

which finishes the implementation of a custom tooltip for `BarPlot`.


## Mouse Interaction

Each `Scene` has an Events struct that holds a few predefined Nodes (see them in `scene.events`)
To use them in your interaction pipeline, you can use them with `lift` or `on`.

For example, for interaction with the mouse cursor, use the `mouseposition` Node.

```julia
on(scene.events.mouseposition) do mpos
    # do something with the mouse position
end
```

## Keyboard Interaction

You can use `scene.events.keyboardbuttons` to react to raw keyboard events and `scene.events.unicode_input` to react to specific characters being typed.

The `keyboardbuttons` Node, for example, contains an enum that can be used to implement a keyboard event handler.

```julia
on(scene.events.keyboardbuttons) do button
    ispressed(button, Keyboard.left) && move_left()
    ispressed(button, Keyboard.up) && move_up()
    ispressed(button, Keyboard.right) && move_right()
    ispressed(button, Keyboard.down) && move_down()
end
```

## Interactive Widgets

Makie has a couple of useful interactive widgets like sliders, buttons and menus, which you can read about in the [Layoutables](@ref) section.

## Recording Animations with Interactions

You can record a `Scene` while you're interacting with it.
Just use the [`record`](@ref) function (also see the [Animations](@ref) page) and allow interaction by `sleep`ing in the loop.

In this example, we sample from the Scene `scene` for 10 seconds, at a rate of 10 frames per second.

```julia
fps = 10
record(scene, "test.mp4"; framerate = fps) do io
    for i = 1:100
        sleep(1/fps)
        recordframe!(io)
    end
end
```
