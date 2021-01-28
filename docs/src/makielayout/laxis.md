```@eval
using CairoMakie
CairoMakie.activate!(type = "png")
```

## Creating an Axis

The `Axis` is a 2D axis that works well with automatic layouts.
Here's how you create one 

```@example laxis
using CairoMakie

scene, layout = layoutscene(resolution = (1200, 900))

ax = layout[1, 1] = Axis(scene, xlabel = "x label", ylabel = "y label",
    title = "Title")

save("basic_axis.svg", scene) # hide
nothing # hide
```

![basic axis](basic_axis.svg)

## Plotting Into an Axis

You can use all the normal mutating 2D plotting functions with an `Axis`.
The only difference is, that they return the created plot object and not
the axis (like Makie's base functions return the `Scene`). This is so
that it is more convenient to save and manipulate the plot objects.


```@example laxis
lineobject = lines!(ax, 0..10, sin, color = :red)

save("basic_axis_plotting.svg", scene) # hide
nothing # hide
```

![basic axis plotting](basic_axis_plotting.svg)


## Setting Axis Limits and Reversing Axes

You can set axis limits with the functions `xlims!`, `ylims!` or `limits!`. The
numbers are meant in the order left right for `xlims!`, and bottom top for `ylims!`.
Therefore, if the second number is smaller than the first, the respective axis
will reverse. You can manually reverse an axis by setting `ax.xreversed = true` or
`ax.yreversed = true`.

Note that if you enforce an aspect ratio between x-axis and y-axis using `autolimitaspect`,
the values you set with these functions will probably not be exactly what you get,
but they will be changed to fit the chosen ratio.

```@example
using CairoMakie

scene, layout = layoutscene(resolution = (1200, 900))

axes = layout[] = [Axis(scene) for i in 1:2, j in 1:3]

xs = LinRange(0, 2pi, 50)
for (i, ax) in enumerate(axes)
    ax.title = "Axis $i"
    lines!(ax, xs, sin.(xs))
end

xlims!(axes[1], [0, 2pi]) # as vector
xlims!(axes[2], 2pi, 0) # separate, reversed
ylims!(axes[3], -1, 1) # separate
ylims!(axes[4], (1, -1)) # as tuple, reversed
limits!(axes[5], 0, 2pi, -1, 1) # x1, x2, y1, y2
limits!(axes[6], BBox(0, 2pi, -1, 1)) # as rectangle

save("example_axis_limits.svg", scene) # hide
nothing # hide
```

![axis limits](example_axis_limits.svg)

## Modifying Ticks

To control ticks, you can set the axis attributes `xticks/yticks` and `xtickformat/ytickformat`.

You can overload one or more of these three functions to implement custom ticks:

```julia
tickvalues, ticklabels = MakieLayout.get_ticks(ticks, formatter, vmin, vmax)
tickvalues = MakieLayout.get_tickvalues(ticks, vmin, vmax)
ticklabels = MakieLayout.get_ticklabels(formatter, tickvalues)
```

If you overload `get_ticks`, you have to compute both tickvalues and ticklabels directly as a vector of floats and strings, respectively.
Otherwise the result of `get_tickvalues` is passed to `get_ticklabels` by default.
The limits of the respective axis are passed as `vmin` and `vmax`.

A couple of behaviors are implemented by default.
You can specify static ticks by passing an iterable of numbers.
You can also pass a tuple with tick values and tick labels directly, bypassing the formatting step.

As a third option you can pass a function taking minimum and maximum axis value as arguments and returning either a vector of tickvalues which are then passed to the current formatter, or a tuple with tickvalues and ticklabels which are then used directly.

For formatting, you can pass a function which takes a vector of numbers and outputs a vector of strings.
You can also pass a format string which is passed to `Formatting.format` from [Formatting.jl](https://github.com/JuliaIO/Formatting.jl), where you can mix the formatted numbers with other text like in `"{:.2f}ms"`.

### Predefined Ticks

The default tick type is `LinearTicks(n)`, where `n` is the target number of ticks which the algorithm tries to return.

```@example
using CairoMakie

fig = Figure(resolution = (1200, 900))
for (i, n) in enumerate([2, 5, 9])
    lines(fig[i, 1], 0..20, sin, axis = (xticks = LinearTicks(n),))
end
fig
```

There's also `WilkinsonTicks` which uses the alternative Wilkinson algorithm.

`MultiplesTicks` can be used when an axis should be marked at multiples of a certain number.
A common scenario is plotting a trigonometric function which should be marked at pi intervals.

```@example
using CairoMakie

lines(0..20, sin, axis = (xticks = MultiplesTicks(4, pi, "π"),))
```

Here are a couple of examples that show off different settings for ticks and formats.

```@example
using CairoMakie

scene, layout = layoutscene(resolution = (1200, 900))

axes = layout[] = [Axis(scene) for i in 1:2, j in 1:2]

xs = LinRange(0, 2pi, 50)
for (i, ax) in enumerate(axes)
    ax.title = "Axis $i"
    lines!(ax, xs, sin.(xs))
end

axes[1].xticks = 0:6

axes[2].xticks = 0:pi:2pi
axes[2].xtickformat = xs -> ["$(x/pi)π" for x in xs]

axes[3].xticks = (0:pi:2pi, ["start", "middle", "end"])

axes[4].xticks = 0:pi:2pi
axes[4].xtickformat = "{:.2f}ms"
axes[4].xlabel = "Time"


save("example_axis_ticks.svg", scene) # hide
nothing # hide
```

![axis ticks](example_axis_ticks.svg)

## Minor Ticks and Grids

You can show minor ticks and grids by setting `x/yminorticksvisible = true` and `x/yminorgridvisible = true` which are off by default.
You can set size, color, width, align etc. like for the normal ticks, but there are no labels.
The `x/yminorticks` attributes control how minor ticks are computed given major ticks and axis limits.
For that purpose you can create your own minortick type and overload `MakieLayout.get_minor_tickvalues(minorticks, tickvalues, vmin, vmax)`.

The default minor tick type is `IntervalsBetween(n, mirror = true)` where `n` gives the number of intervals each gap between major ticks is divided into with minor ticks, and `mirror` decides if outside of the major ticks there are more minor ticks with the same intervals as the adjacent gaps.

```@example
using CairoMakie

theme = Attributes(
    Axis = (
        xminorticksvisible = true,
        yminorticksvisible = true,
        xminorgridvisible = true,
        yminorgridvisible = true,
    )
)

fig = with_theme(theme) do
    fig = Figure(resolution = (800, 800))
    axs = [Axis(fig[fldmod1(n, 2)...],
        title = "IntervalsBetween($(n+1))",
        xminorticks = IntervalsBetween(n+1),
        yminorticks = IntervalsBetween(n+1)) for n in 1:4]
    fig
end
save("example_minor_ticks.svg", fig) # hide
nothing # hide
```

![minor ticks](example_minor_ticks.svg)


## Hiding Axis Spines and Decorations

You can hide all axis elements manually, by setting their specific visibility attributes to `false`, like
`xticklabelsvisible`, but that can be tedious. There are a couple of convenience functions for this.

To hide spines, you can use `hidespines!`.

```@example
using CairoMakie

scene, layout = layoutscene(resolution = (1200, 900))

ax1 = layout[1, 1] = Axis(scene, title = "Axis 1")
ax2 = layout[1, 2] = Axis(scene, title = "Axis 2")

hidespines!(ax1)
hidespines!(ax2, :t, :r) # only top and right

save("example_axis_hidespines.svg", scene) # hide
nothing # hide
```

![axis hide spines](example_axis_hidespines.svg)

To hide decorations, you can use `hidedecorations!`, or the specific `hidexdecorations!` and `hideydecorations!`.
When hiding, you can set `label = false`, `ticklabels = false`, `ticks = false`, `grid = false`, `minorgrid = false` or `minorticks = false` as keyword
arguments if you want to keep those elements.
It's common, e.g., to hide everything but the grid lines in facet plots.

## Controlling Axis Aspect Ratios

If you're plotting images, you might want to force a specific aspect ratio
of an axis, so that the images are not stretched. The default is that an axis
uses all of the available space in the layout. You can use `AxisAspect` and
`DataAspect` to control the aspect ratio. For example, `AxisAspect(1)` forces a
square axis and `AxisAspect(2)` results in a rectangle with a width of two
times the height.
`DataAspect` uses the currently chosen axis limits and brings the axes into the
same aspect ratio. This is the easiest to use with images.
A different aspect ratio can only reduce the axis space that is being used, also
it necessarily has to break the layout a little bit.


```@example
using CairoMakie
using FileIO
using Random # hide
Random.seed!(1) # hide

scene, layout = layoutscene(resolution = (1200, 900))

axes = [Axis(scene) for i in 1:2, j in 1:3]
tightlimits!.(axes)
layout[1:2, 1:3] = axes

img = rotr90(load("../assets/cow.png"))

for ax in axes
    image!(ax, img)
end

axes[1, 1].title = "Default"

axes[1, 2].title = "DataAspect"
axes[1, 2].aspect = DataAspect()

axes[1, 3].title = "AxisAspect(418/348)"
axes[1, 3].aspect = AxisAspect(418/348)

axes[2, 1].title = "AxisAspect(1)"
axes[2, 1].aspect = AxisAspect(1)

axes[2, 2].title = "AxisAspect(2)"
axes[2, 2].aspect = AxisAspect(2)

axes[2, 3].title = "AxisAspect(0.5)"
axes[2, 3].aspect = AxisAspect(0.5)

save("example_axis_aspects.svg", scene) # hide
nothing # hide
```

![axis aspects](example_axis_aspects.svg)


## Controlling Data Aspect Ratios

If you want the content of an axis to adhere to a certain data aspect ratio, there is
another way than forcing the aspect ratio of the whole axis to be the same, and
possibly breaking the layout. This works via the axis attribute `autolimitaspect`.
It can either be set to `nothing` which means the data limits can have any arbitrary
aspect ratio. Or it can be set to a number, in which case the targeted limits of the
axis (that are computed by `autolimits!`) are enlarged to have the correct aspect ratio.

You can see the different ways to get a plot with an unstretched circle, using
different ways of setting aspect ratios, in the following example.

```@example
using CairoMakie
using Animations



# scene setup for animation
###########################################################

container_scene = Scene(camera = campixel!, resolution = (1200, 1200))

t = Node(0.0)

a_width = Animation([1, 7], [1200.0, 800], sineio(n=2, yoyo=true, postwait=0.5))
a_height = Animation([2.5, 8.5], [1200.0, 800], sineio(n=2, yoyo=true, postwait=0.5))

scene_area = lift(t) do t
    IRect(0, 0, round(Int, a_width(t)), round(Int, a_height(t)))
end

scene = Scene(container_scene, scene_area, camera = campixel!)

rect = poly!(scene, scene_area,
    raw=true, color=RGBf0(0.97, 0.97, 0.97), strokecolor=:transparent, strokewidth=0)

outer_layout = GridLayout(scene, alignmode = Outside(30))




# example begins here
###########################################################

layout = outer_layout[1, 1] = GridLayout()

titles = ["aspect enforced\nvia layout", "axis aspect\nset directly", "no aspect enforced", "data aspect conforms\nto axis size"]
axs = layout[1:2, 1:2] = [Axis(scene, title = t) for t in titles]

for a in axs
    lines!(a, Circle(Point2f0(0, 0), 100f0))
end

rowsize!(layout, 1, Fixed(400))
# force the layout cell [1, 1] to be square
colsize!(layout, 1, Aspect(1, 1))

axs[2].aspect = 1
axs[4].autolimitaspect = 1

rects = layout[1:2, 1:2] = [Box(scene, color = (:black, 0.05),
    strokecolor = :transparent) for _ in 1:4]

record(container_scene, "example_circle_aspect_ratios.mp4", 0:1/30:9; framerate=30) do ti
    t[] = ti
end
nothing # hide
```

![example circle aspect ratios](example_circle_aspect_ratios.mp4)


## Linking axes

You can link axes to each other. Every axis simply keeps track of a list of other
axes which it updates when it is changed itself. You can link x and y dimensions
separately.

```@example
using CairoMakie

scene, layout = layoutscene(resolution = (1200, 900))

layout[1, 1:3] = axs = [Axis(scene) for i in 1:3]
linkxaxes!(axs[1:2]...)
linkyaxes!(axs[2:3]...)

axs[1].title = "x linked"
axs[2].title = "x & y linked"
axs[3].title = "y linked"

for i in 1:3
    lines!(axs[i], 1:10, 1:10, color = "green")
    if i != 1
        lines!(axs[i], 1:10, 11:20, color = "blue")
    end
    if i != 3
        lines!(axs[i], 11:20, 1:10, color = "red")
    end
end

save("example_linked_axes.svg", scene) # hide
nothing # hide
```

![linked axes](example_linked_axes.svg)


## Axis interaction

An Axis has a couple of predefined interactions enabled.

### Scroll Zoom

You can zoom in an axis by scrolling in and out.
If you press x or y while scrolling, the zoom movement is restricted to that dimension.
These keys can be changed with the attributes `xzoomkey` and `yzoomkey`.
You can also restrict the zoom dimensions all the time by setting the axis attributes `xzoomlock` or `yzoomlock` to `true`.

### Drag Pan

You can pan around the axis by right-clicking and dragging.
If you press x or y while panning, the pan movement is restricted to that dimension.
These keys can be changed with the attributes `xpankey` and `ypankey`.
You can also restrict the pan dimensions all the time by setting the axis attributes `xpanlock` or `ypanlock` to `true`.

### Limit Reset

You can reset the limits with `ctrl + leftclick`. Alternatively, you can call
`autolimits!` on the axis to achieve the same effect programmatically.

### Rectangle Selection Zoom

Left-click and drag zooms into the selected rectangular area.
If you press x or y while panning, only the respective dimension is affected.
You can also restrict the selection zoom dimensions all the time by setting the axis attributes `xrectzoom` or `yrectzoom` to `true`.

### Custom Interactions

The interaction system is an additional abstraction upon Makie's low-level event system to make it easier to quickly create your own interaction patterns.


#### Registering and deregistering interactions

To register a new interaction, call `register_interaction!(ax, name::Symbol, interaction)`.
The `interaction` argument can be of any type.

To remove an existing interaction completely, call `deregister_interaction!(ax, name::Symbol)`.
You can check which interactions are currently active by calling `interactions(ax)`.

#### Activating and deactivating interactions

Often, you don't want to remove an interaction entirely but only disable it for a moment, then reenable it again.
You can use the functions `activate_interaction!(ax, name::Symbol)` and `deactivate_interaction!(ax, name::Symbol)` for that.

#### `Function` Interaction 
If `interaction` is a `Function`, it should accept two arguments, which correspond to an event and the axis.
This function will then be called whenever the axis generates an event.

Here's an example of such a function. Note that we use the special dispatch signature for Functions that allows to use the `do`-syntax:

```julia
register_interaction!(ax, :my_interaction) do event::MouseEvent, axis
    if event.type === MouseEventTypes.leftclick
        println("You clicked on the axis!")
    end
end
```

As you can see, it's possible to restrict the type parameter of the event argument.
Choices are one of `MouseEvent`, `KeysEvent` or `ScrollEvent` if you only want to handle a specific class.
Your function can also have multiple methods dealing with each type.

#### Custom Object Interaction

The function option is most suitable for interactions that don't involve much state.
A more verbose but flexible option is available.
For this, you define a new type which typically holds all the state variables you're interested in.

Whenever the axis generates an event, it calls `process_interaction(interaction, event, axis)` on all 
stored interactions.
By defining `process_interaction` for specific types of interaction and event, you can create more complex interaction patterns.

Here's an example with simple state handling where we allow left clicks while l is pressed, and right clicks while r is pressed:

```julia
mutable struct MyInteraction
    allow_left_click::Bool
    allow_right_click::Bool
end

function MakieLayout.process_interaction(interaction::MyInteraction, event::MouseEvent, axis)
    if interaction.use_left_click && event.type === MouseEventTypes.leftclick
        println("Left click in correct mode")
    end
    if interaction.allow_right_click && event.type === MouseEventTypes.rightclick
        println("Right click in correct mode")
    end
end

function MakieLayout.process_interaction(interaction::MyInteraction, event::KeysEvent, axis)
    interaction.allow_left_click = Keyboard.l in event.keys
    interaction.allow_right_click = Keyboard.r in event.keys
end

register_interaction!(ax, :left_and_right, MyInteraction(false, false))
```

#### Setup and Cleanup

Some interactions might have more complex state involving plot objects that need to be setup or removed.
For those purposes, you can overload the methods `registration_setup!(parent, interaction)` and `deregistration_cleanup!(parent, interaction)` which are called during registration and deregistration, respectively.


## Special Plots

A few special plot functions currently only work specifically with the `Axis` type.

### Vertical / Horizontal Lines

Often, it's useful to mark horizontal or vertical locations in a plot with lines that span
a certain percentage of the axis, not the data. There are two functions `hlines!` and `vlines!`
which work with `Axis` instances.

The positional argument gives one or many locations in data coordinates, while
the keyword arguments `xmin` and `xmax` (for hlines) or `ymin` and `ymax` (for vlines)
specify the extent along the axis. These values can also be a single number or an iterable.

```@example
using CairoMakie

scene, layout = layoutscene(resolution = (1400, 900))
ax1 = layout[1, 1] = Axis(scene, title = "vlines")

lines!(ax1, 0..4pi, sin)
vlines!(ax1, [pi, 2pi, 3pi], color = :red)

ax2 = layout[1, 2] = Axis(scene, title = "hlines")
hlines!(ax2, [1, 2, 3, 4], xmax = [0.25, 0.5, 0.75, 1], color = :blue)

scene
save("example_vlines.svg", scene); nothing # hide
```

![example vlines](example_vlines.svg)

```@eval
using GLMakie
GLMakie.activate!()
```