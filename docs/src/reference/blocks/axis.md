

# Axis

## Creating an Axis

The `Axis` is a 2D axis that works well with automatic layouts.
Here's how you create one

```@figure axis

f = Figure()

ax = Axis(f[1, 1], xlabel = "x label", ylabel = "y label",
    title = "Title")

f
```

## Plotting into an Axis

You can use all the normal mutating 2D plotting functions with an `Axis`.
These functions return the created plot object.
Omitting the `ax` argument plots into the `current_axis()`, which is usually the axis that was last created.

```@figure axis
lineobject = lines!(ax, 0..10, sin, color = :red)
scatobject = scatter!(0:0.5:10, cos, color = :orange)

f
```

## Deleting plots

You can delete a plot object directly via `delete!(ax, plotobj)`.
You can also remove all plots with `empty!(ax)`.

```@figure
f = Figure()

axs = [Axis(f[1, i]) for i in 1:3]

scatters = map(axs) do ax
    [scatter!(ax, 0:0.1:10, x -> sin(x) + i) for i in 1:3]
end

delete!(axs[2], scatters[2][2])
empty!(axs[3])

f
```


## Hiding Axis spines and decorations

You can hide all axis elements manually, by setting their specific visibility attributes to `false`, like
`xticklabelsvisible`, but that can be tedious. There are a couple of convenience functions for this.

To hide spines, you can use `hidespines!`.

```@figure
f = Figure()

ax1 = Axis(f[1, 1], title = "Axis 1")
ax2 = Axis(f[1, 2], title = "Axis 2")

hidespines!(ax1)
hidespines!(ax2, :t, :r) # only top and right

f
```

To hide decorations, you can use `hidedecorations!`, or the specific `hidexdecorations!` and `hideydecorations!`.
When hiding, you can set `label = false`, `ticklabels = false`, `ticks = false`, `grid = false`, `minorgrid = false` or `minorticks = false` as keyword
arguments if you want to keep those elements.
It's common, e.g., to hide everything but the grid lines in facet plots.

```@figure

f = Figure()

ax1 = Axis(f[1, 1], title = "Axis 1")
ax2 = Axis(f[1, 2], title = "Axis 2")
ax3 = Axis(f[1, 3], title = "Axis 3")

hidedecorations!(ax1)
hidexdecorations!(ax2, grid = false)
hideydecorations!(ax3, ticks = false)

f
```


## Linking axes

You can link axes to each other. Every axis simply keeps track of a list of other
axes which it updates when it is changed itself. You can link x and y dimensions
separately.

```@figure

f = Figure()

ax1 = Axis(f[1, 1])
ax2 = Axis(f[1, 2])
ax3 = Axis(f[2, 2])

linkyaxes!(ax1, ax2)
linkxaxes!(ax2, ax3)

ax1.title = "y linked"
ax2.title = "x & y linked"
ax3.title = "x linked"

for (i, ax) in enumerate([ax1, ax2, ax3])
    lines!(ax, 1:10, 1:10, color = "green")
    if i != 1
        lines!(ax, 11:20, 1:10, color = "red")
    end
    if i != 3
        lines!(ax, 1:10, 11:20, color = "blue")
    end
end

f
```


## Aligning neighboring axis labels

When placing axes with different ticks next to each other it can be desirable to visually align the labels of these axes.
By default, the space allocated for the ticklabels is minimized.
This value can be fixed by using the functions [`tight_xticklabel_spacing!`](@ref), [`tight_yticklabel_spacing!`](@ref) or [`tight_ticklabel_spacing!`](@ref) for both.

Note how x and y labels are misaligned in this figure due to different tick label lengths.

```@figure labels

f = Figure()

ax1 = Axis(f[1, 1], title = "Axis 1", ylabel = "y label", ytickformat = "{:.3f}")
ax2 = Axis(f[2, 1], title = "Axis 2", ylabel = "y label", xlabel = "x label")
ax3 = Axis(f[2, 2], title = "Axis 3", xlabel = "x label", xtickformat = "{:.3f}", xticklabelrotation = pi/4)

f
```


To align the labels, we can set the `xticklabelspace` or `yticklabelspace` attributes of the linked axes to the maximum space.

```@figure labels
yspace = maximum(tight_yticklabel_spacing!, [ax1, ax2])
xspace = maximum(tight_xticklabel_spacing!, [ax2, ax3])

ax1.yticklabelspace = yspace
ax2.yticklabelspace = yspace

ax2.xticklabelspace = xspace
ax3.xticklabelspace = xspace

f
```


## Creating a twin axis

There is currently no dedicated function to do this, but you can simply add an Axis on top of another, then hide everything but the second axis.

Here's an example how to do this with a second y axis on the right.

```@figure

f = Figure()

ax1 = Axis(f[1, 1], yticklabelcolor = :blue)
ax2 = Axis(f[1, 1], yticklabelcolor = :red, yaxisposition = :right)
hidespines!(ax2)
hidexdecorations!(ax2)

lines!(ax1, 0..10, sin, color = :blue)
lines!(ax2, 0..10, x -> 100 * cos(x), color = :red)

f
```

## Axis interaction

An Axis has a couple of predefined interactions enabled.

### Scroll zoom

You can zoom in an axis by scrolling in and out.
If you press x or y while scrolling, the zoom movement is restricted to that dimension.
These keys can be changed with the attributes `xzoomkey` and `yzoomkey`.
You can also restrict the zoom dimensions all the time by setting the axis attributes `xzoomlock` or `yzoomlock` to `true`.

### Drag pan

You can pan around the axis by right-clicking and dragging.
If you press x or y while panning, the pan movement is restricted to that dimension.
These keys can be changed with the attributes `xpankey` and `ypankey`.
You can also restrict the pan dimensions all the time by setting the axis attributes `xpanlock` or `ypanlock` to `true`.

### Limit reset

You can reset the limits with `ctrl + leftclick`. This is the same as doing `reset_limits!(ax)`. This sets the limits back to the values stored in `ax.limits`, and if they are `nothing`, computes them automatically. If you have previously called `limits!`, `xlims!` or `ylims!`, these settings therefore stay intact when doing a limit reset.

You can alternatively press `ctrl + shift + leftclick`, which is the same as calling `autolimits!(ax)`.
This function ignores previously set limits and computes them all anew given the axis content.

### Rectangle selection zoom

Left-click and drag zooms into the selected rectangular area.
If you press x or y while panning, only the respective dimension is affected.
You can also restrict the selection zoom dimensions all the time by setting the axis attributes `xrectzoom` or `yrectzoom` to `true`.

### Custom interactions

The interaction system is an additional abstraction upon Makie's low-level event system to make it easier to quickly create your own interaction patterns.

#### Registering and deregistering interactions

To register a new interaction, call `register_interaction!(ax, name::Symbol, interaction)`.
The `interaction` argument can be of any type.

To remove an existing interaction completely, call `deregister_interaction!(ax, name::Symbol)`.
You can check which interactions are currently active by calling `interactions(ax)`. The default interactions are `:dragpan`, `:limitreset`, `:rectanglezoom` and `:scrollzoom`.

#### Activating and deactivating interactions

Often, you don't want to remove an interaction entirely but only disable it for a moment, then re-enable it again.
You can use the functions `activate_interaction!(ax, name::Symbol)` and `deactivate_interaction!(ax, name::Symbol)` for that.

#### `Function` interaction

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

#### Custom object interaction

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

function Makie.process_interaction(interaction::MyInteraction, event::MouseEvent, axis)
    if interaction.allow_left_click && event.type === MouseEventTypes.leftclick
        println("Left click in correct mode")
    end
    if interaction.allow_right_click && event.type === MouseEventTypes.rightclick
        println("Right click in correct mode")
    end
end

function Makie.process_interaction(interaction::MyInteraction, event::KeysEvent, axis)
    interaction.allow_left_click = Keyboard.l in event.keys
    interaction.allow_right_click = Keyboard.r in event.keys
end

register_interaction!(ax, :left_and_right, MyInteraction(false, false))
```

#### Setup and cleanup

Some interactions might have more complex state involving plot objects that need to be setup or removed.
For those purposes, you can overload the methods `registration_setup!(parent, interaction)` and `deregistration_cleanup!(parent, interaction)` which are called during registration and deregistration, respectively.


## Attributes

```@attrdocs
Axis
```
