# Events

Interactive backends such as `GLMakie` and `WGLMakie` pass events to Observables collected in an `Events` struct. By reacting to these one can build up custom interactions.

!!! note
    If you are new to Observables you should first read [Observables](@ref).

## Observables with priority

With Observables, one can add callbacks also with a priority. Furthermore it allows for each listener to stop execution of lower priority listeners by returning `Consume(true)` or simply `Consume()`. Every other return value will be handled as `Consume(false)` meaning that the listener will not block other listeners.

To understand how a `PriorityObserable` works you may try this example:

```@example
using Makie

po = Observable(0)

println("With low priority listener:")
on(po, priority = -1) do x
    println("Low priority: $x")
end
po[] = 1

println("\nWith medium priority listener:")
on(po, priority = 0) do x
    println("Medium blocking priority: $x")
    return Consume()
end
po[] = 2

println("\nWith high priority listener:")
on(po, priority = 1) do x
    println("High Priority: $x")
    return Consume(false)
end
po[] = 3
nothing # hide
```


With only the first listener connected `Low priority: 1` gets printed. In this case the behavior is the same as normal Observables. The second listener we add is a blocking one because it returns `Consume(true)`. Since it has a higher priority than the first one only the second listener will trigger. Thus we get `Medium blocking priority: 2`. The third listener is non-blocking and at yet again higher priority. As such we get a result from both the third and second listener.

## The Events struct

Events from the backend are stored in Observables within the `Events` struct. You can access it with `events(x)` where `x` is a `Figure`, `Axis`, `Axis3`, `LScene`, `FigureAxisPlot` or `Scene`. Regardless of which source you use here you will always get the same struct. This is also true for accessing it directly via `scene.events`. It contains the following fields:

- `window_area::Observable{Rect2i}`: Contains the current size of the window in pixels.
- `window_dpi::Observable{Float64}`: Contains the DPI of the window.
- `window_open::Observable{Bool}`: Contains `true` as long as the window is open.
- `hasfocus::Observable{Bool}`: Contains `true` if the window is focused (in the foreground).
- `entered_window::Observable{Bool}`: Contains true if the mouse is within the window (regardless of whether it is focused), i.e. when it is hovered.
- `mousebutton::Observable{MouseButtonEvent}`: Contains the most recent `MouseButtonEvent` which holds the relevant `button::Mouse.Button` and `action::Mouse.Action`.
- `mousebuttonstate::Set{Mouse.Button}`: Contains all currently pressed mouse buttons.
- `mouseposition::Observable{NTuple{2, Float64}}`: Contains the most recent cursor position in pixel units relative to the root scene/window.
- `scroll::Observable{NTuple{2, Float64}}`: Contains the most recent scroll offset.
- `keyboardbutton::Observable{KeyEvent}`: Contains the most recent `KeyEvent` which holds the relevant `key::Keyboard.Button` and `action::Keyboard.Action`.
- `keyboardstate::Observable{Keyboard.Button}`: Contains all currently pressed keys.
- `unicode_input::Observable{Char}`: Contains the most recently typed character.
- `dropped_files::Observable{Vector{String}}`: Contains a list of filepaths to a collection files dragged into the window.
- `tick::Observable{Makie.Tick}`: Contains the most recent `Makie.Tick`. A `tick` is produced for every frame rendered, i.e. at regular intervals for interactive figures, when a image is saved or when `record()` is used.

## Mouse Interaction

There are three mouse events one can react to:

- `events.mousebutton` which holds a `MouseButtonEvent` with relevant `button` and `action`
- `events.mouseposition` which holds the current cursor position relative to the window as `NTuple{2, Float64}` in pixel
- `events.scroll` which holds an `NTuple{2, Float64}` of the last scroll change

There is also `events.mousebuttonstate` which holds all currently held buttons. This is not an Observable, so you can't react to changes here, but you can check it if you are looking for a specific combination of buttons.

As an example, let us set up a scene where we can draw lines between two points interactively. The first point is selected when the left mouse button gets pressed and the second when it gets released. To simplify things we start with a pixel space scene.

```julia
using GLMakie
GLMakie.activate!() # hide

points = Observable(Point2f[])

scene = Scene(camera = campixel!)
linesegments!(scene, points, color = :black)
scatter!(scene, points, color = :gray)

on(events(scene).mousebutton) do event
    if event.button == Mouse.left
        if event.action == Mouse.press || event.action == Mouse.release
            mp = events(scene).mouseposition[]
            push!(points[], mp)
            notify(points)
        end
    end
end

scene
```

In simple cases like this we don't need a to use a priority for registering our callback to `mousebutton`. Priority and `Consume()` only become important when multiple interactions react to the same source and need to happen in a specific order or interfere with each other.

To make this example nicer, let us update the second point (the end of the line) whenever the mouse moves. For this we should set both the start and end point on `Mouse.press` and update the end point when `events(scene).mouseposition` changes as long as the mouse button is still pressed.

```julia
using GLMakie
GLMakie.activate!() # hide

points = Observable(Point2f[])

scene = Scene(camera = campixel!)
linesegments!(scene, points, color = :black)
scatter!(scene, points, color = :gray)

on(events(scene).mousebutton) do event
    if event.button == Mouse.left && event.action == Mouse.press
        mp = events(scene).mouseposition[]
        push!(points[], mp, mp)
        notify(points)
    end
end

on(events(scene).mouseposition) do mp
    mb = events(scene).mousebutton[]
    if mb.button == Mouse.left && (mb.action == Mouse.press || mb.action == Mouse.repeat)
        points[][end] = mp
        notify(points)
    end
end

scene
```

To give an example on how to use `scroll` let's cycle through colors with the scroll wheel. `scroll` holds two floats describing the last change in x and y direction, typically `+1` or `-1`.

```julia
using GLMakie
GLMakie.activate!() # hide

colors = to_colormap(:cyclic_mrybm_35_75_c68_n256)
idx = Observable(1)
color = map(i -> colors[mod1(i, length(colors))], idx)
points = Observable(Point2f[])

scene = Scene(camera = campixel!)
linesegments!(scene, points, color = color)
scatter!(scene, points, color = :gray, strokecolor = color, strokewidth = 1)

on(events(scene).mousebutton) do event
    if event.button == Mouse.left && event.action == Mouse.press
        mp = events(scene).mouseposition[]
        push!(points[], mp, mp)
        notify(points)
    end
end

on(events(scene).mouseposition) do mp
    mb = events(scene).mousebutton[]
    if mb.button == Mouse.left && (mb.action == Mouse.press || mb.action == Mouse.repeat)
        points[][end] = mp
        notify(points)
    end
end

on(events(scene).scroll) do (dx, dy)
    idx[] = idx[] + sign(dy)
end

scene
```

## Keyboard Interaction

You can use `events.keyboardbutton` to react to a `KeyEvent` and `events.unicode_input` to react to specific characters being typed. Just like for mouse interactions there is also a set `events.keyboardstate` holding all keys that are currently pressed.

Let's continue our example. Currently we can add points with mouse clicks and change colors by scrolling. A feature we are missing is the deletion of points. Let's implement this with keyboard events. Here we chose `backspace` to delete from the end and `delete` to delete from the start.

```julia
using GLMakie
GLMakie.activate!() # hide

colors = to_colormap(:cyclic_mrybm_35_75_c68_n256)
idx = Observable(1)
color = map(i -> colors[mod1(i, length(colors))], idx)
points = Observable(Point2f[])

scene = Scene(camera = campixel!)
linesegments!(scene, points, color = color)
scatter!(scene, points, color = :gray, strokecolor = color, strokewidth = 1)

on(events(scene).mousebutton) do event
    if event.button == Mouse.left && event.action == Mouse.press
        mp = events(scene).mouseposition[]
        push!(points[], mp, mp)
        notify(points)
    end
end

on(events(scene).mouseposition) do mp
    mb = events(scene).mousebutton[]
    if mb.button == Mouse.left && (mb.action == Mouse.press || mb.action == Mouse.repeat)
        points[][end] = mp
        notify(points)
    end
end

on(events(scene).scroll) do (dx, dy)
    idx[] = idx[] + sign(dy)
end

on(events(scene).keyboardbutton) do event
    if event.action == Keyboard.press || event.action == Keyboard.repeat
        length(points[]) > 1 || return nothing
        if event.key == Keyboard.backspace
            pop!(points[])
            pop!(points[])
            notify(points)
        elseif event.key == Keyboard.delete
            popfirst!(points[])
            popfirst!(points[])
            notify(points)
        end
    end
end

scene
```

## Point Picking

Makie provides a function `pick(x[, position = events(x).mouseposition[]])` to get the plot displayed at a certain position with `x` being a `Figure`, `Axis`, `FigureAxisPlot` or `Scene`.
The function returns a primitive plot and an index.
The primitive plots are the base plots drawable in backends:

- scatter
- text
- lines
- linesegments
- mesh
- meshscatter
- surface
- volume
- voxels
- image
- heatmap

Every other plot is build from these somewhere down the line. For example `fig, ax, p = scatterlines(rand(10))` has `Lines` and `Scatter` as it's primitive plots in `p.plots`.

The index returned by `pick()` relates to the main input of the respective primitive plot.
- For `scatter` and `meshscatter` it is an index into the positions given to the plot.
- For `text` it is an index into the merged character array.
- For `lines` and `linesegments` it is the end position of the selected line segment. 
- For `image`, `heatmap` and `surface` it is the linear index into the matrix argument of the plot (i.e. the given image, value or z-value matrix) that is closest to the selected position.
- For `voxels` it is the linear index into the given 3D Array.
- For `mesh` it is the largest vertex index of the picked triangle face.
- For `volume` it is always 0.

Let's implement adding, moving and deleting of scatter markers as an example. We could implement adding and deleting with left and right clicks, however that would overwrite existing axis interactions. To avoid this we implement adding as `a + left click` and removing as `d + left click`. Since these settings are more restrictive we want Makie to check if either of them applies first and default back to normal axis interactions otherwise. This means our interactions should have a higher priority than the defaults and block conditionally.

To gauge the priority of the existing axis interaction we can check `Observables.listeners(events(fig).mousebutton)` after creating an `Axis`. This will show the registered callbacks with their priority. The one with the big number (typemax(Int)) is an interaction at maximum priority which we can ignore. (This keeps `events(fig).mousebuttonstate` up to date.) This leaves `priority = 1` as the priority to beat.

To correctly place a new marker we will also need to get the mouseposition in axis units. Makie provides a function that does just that: `mouseposition([scene = hovered_scene()])`. There is also a convenience function for the pixel space mouseposition relative to a specific scene `mouseposition_px([scene = hovered_scene()])`. Both of these will usually be different from `events.mouseposition` which is always in pixel units and always based on the full window.

Finally for deleting we need to figure out if and which scattered marker the cursor is over. We can do this with the `pick()` function. As mentioned before, `pick(ax)` will return the plot and (for scatter) an index into the position array, matching our marker. With this we can now set up adding and deleting markers.

```julia
using GLMakie

positions = Observable(rand(Point2f, 10))

fig, ax, p = scatter(positions)

on(events(fig).mousebutton, priority = 2) do event
    if event.button == Mouse.left && event.action == Mouse.press
        if Keyboard.d in events(fig).keyboardstate
            # Delete marker
            plt, i = pick(fig)
            if plt == p
                deleteat!(positions[], i)
                notify(positions)
                return Consume(true)
            end
        elseif Keyboard.a in events(fig).keyboardstate
            # Add marker
            push!(positions[], mouseposition(ax))
            notify(positions)
            return Consume(true)
        end
    end
    return Consume(false)
end

fig
```

To implement dragging we need to keep track of some state. When we click on a marker we initiate a drag state. While in this state the hovered marker needs follow the cursor position (in axis coordinates). Once the mouse button is released we need to exit the drag state. All of this needs to again take higher priority than the default axis interactions and block them from happening.

```julia
using GLMakie

positions = Observable(rand(Point2f, 10))
dragging = false
idx = 1

fig, ax, p = scatter(positions)

on(events(fig).mousebutton, priority = 2) do event
    global dragging, idx
    if event.button == Mouse.left
        if event.action == Mouse.press
            plt, i = pick(fig)
            if Keyboard.d in events(fig).keyboardstate && plt == p
                # Delete marker
                deleteat!(positions[], i)
                notify(positions)
                return Consume(true)
            elseif Keyboard.a in events(fig).keyboardstate
                # Add marker
                push!(positions[], mouseposition(ax))
                notify(positions)
                return Consume(true)
            else
                # Initiate drag
                dragging = plt == p
                idx = i
                return Consume(dragging)
            end
        elseif event.action == Mouse.release
            # Exit drag
            dragging = false
            return Consume(false)
        end
    end
    return Consume(false)
end

on(events(fig).mouseposition, priority = 2) do mp
    if dragging
        positions[][idx] = mouseposition(ax)
        notify(positions)
        return Consume(true)
    end
    return Consume(false)
end

fig
```

There are a couple of different methods of and functions related to `pick`. The base method `pick(scene, pos)` picks points exactly. For small markers or thin lines you may instead want to pick the closest plot element within a given range. This can be done with `pick(scene, position, range)`. You can also get all plots and indices within a range sorted by distance with `pick_sorted(scene, position, range)`. This can be useful if you want to filter certain plots out, for example the background of an `Axis`.

If you just want to know whether the cursor is on a certain plot or set of plots you can use `mouseover(scene, plots...)`. This will call `Makie.flatten_plots(plots)` to break down all plots into primitive plots and check against pick. If you want continue using the output from pick you can use `onpick(f, scene, plots...; range=1)` which performs this check and calls `f(plot, index)` if it succeeds.

## The `ispressed` function

If you are implementing interactions based on key events you may want these keys to be adjustable without changing your code directly. A simple way to do this would be to have the hotkey saved in a variable outside the observer function:

```julia
hotkey = Keyboard.a
on(events(fig).keyboardbutton) do event
    if event.key == hotkey
        ...
    end
end
```

This way you can change `hotkey` to any other key without changing the callback function. The problem with this is that you are restricted to just one key. If you want to switch to a combination like ctrl + a you would still have to replace the callback. `ispressed()` is supposed to handle this for you. All you need to do is replace the comparison:

```julia
hotkey = Keyboard.a
on(events(fig).keyboardbutton) do event
    if ispressed(fig, hotkey)
        ...
    end
end
```

With this `hotkey` can now be

- A `Bool` which will be returned directly.
- A single key or mouse button.
- A `Tuple`, `Vector` or `Set` of keys and mouse buttons which all must be pressed.
- A logical expression of keys and mouse buttons with `!`, `&` and `|`. Each key will be checked individually and the result will be combined as the expression dictates.

Furthermore you can wrap any of the above in `Exclusively` to discard matches where additional buttons are pressed. All of these options are order independent. Here are some examples:

- `hotkey = Mouse.left` matches any state with the left mouse button pressed.
- `hotkey = (Keyboard.left_control, Keyboard.a)` matches any state with both left control and a pressed.
- `hotkey = Exclusively((Keyboard.left_control, Keyboard.a))` matches if only left control and a are pressed.
- `hotkey = Keyboard.left_control & Keyboard.a` is equivalent to `(Keyboard.left_control, Keyboard.a)`
- `hotkey = (Keyboard.left_control | Keyboard.right_control) & Keyboard.a` allows either left or right control with a.

Note that the way we used `ispressed` above, the condition will be true for "press" and "repeat" events. You can further restrict to one or the other by checking `event.action`. If you wish to react to a "release" event, you will need to pass `event.key`/`event.button` as a third argument to `ispressed(fig, hotkey, event.key)`. This will tell `ispressed` to assume the key or button is pressed if it is part of the hotkey.

## Interactive Widgets

Makie has a couple of useful interactive widgets like sliders, buttons and menus, which you can learn about in the [Blocks](@ref) section.

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

## Tick Events

Tick events are produced by the renderloop in GLMakie and WGLMakie, as well as `Makie.save` and `Makie.record` for all backends. 
They allow you to synchronize tasks such as animations with rendering. 
A Tick contains the following information:

- `state::Makie.TickState`: Describes the situation in which the tick was produced. These include:
    - `Makie.UnknownTickState`: A catch-all for uncategorized ticks. Currently only used for initialization of the tick event.
    - `Makie.PausedRenderTick`: A tick originating from a paused renderloop in GLMakie. (This refers to the last attempt to draw a frame.)
    - `Makie.SkippedRenderTick`: A tick originating from a `render_on_demand = true` renderloop in GLMakie where the last frame has been reused. (This happens when nothing about the displayed frame has changed. For animation you may consider this a regular render tick.)
    - `Makie.RegularRenderTick`: A tick from a renderloop where the last frame has been redrawn.
    - `Makie.OneTimeRenderTick`: A tick produced before generating an image for `Makie.save` and `Makie.record`.
- `count::Int64`: Number of ticks produced since the first. During `record` this is relative to the first recorded frame.
- `time::Float64`: The time that has passed since the first tick in seconds. During `record` this is relative to the first recorded frame and increments based on the `framerate` set in record.
- `delta_time::Float64`: The time that has passed since the last tick in seconds. During `record` this is `1 / framerate`.

For an animation you will generally not need to worry about tick state. 
You can simply update the relevant data as needed.
```julia
on(events(fig).tick) do tick
    # For a simulation you may want to use delta times for updates:
    position[] = position[] + tick.delta_time * velocity

    # For a solved system you may want to use the total time to compute the current state:
    position[] = trajectory(tick.time)

    # For a data record you may want to use count to move to the next data point(s)
    position[] = position_record[mod1(tick.count, end)]
end
```

For an interactive figure this will produce an animation synchronized with real time. 
Within `record` the tick times match up the set `framerate` such that the animation in the produced video matches up with real time. 

Note that the underlying `VideoStream` filters tick events other than `state = OneTimeRenderTick`.
This is done to prevent jumping (wrong count, time) or acceleration (extra ticks) of animations in videos due to extra ticks.
(This is specifically an issue with WGLMakie, as it still runs a normal renderloop while recording.)
Ticks will no longer be filtered once the `VideoStream` object is deleted or the video is saved.
The behavior can also be turned off by setting `filter_ticks = false`.

For reference, a `tick` generally happens after other events have been processed and before the next frame will be drawn. 
The exception is WGLMakie which runs an independent timer to avoid excessive message passing between Javascript and Julia.