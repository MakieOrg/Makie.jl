export mouseover, mouse_selection, mouseposition, hovered_scene
export select_rectangle


"""
    mouseover(scene::SceneLike, plots::AbstractPlot...)

Returns true if the mouse currently hovers any of `plots`.
"""
function mouseover(scene::SceneLike, plots::AbstractPlot...)
    p, idx = mouse_selection(scene)
    return p in flatten_plots(plots)
end

"""
    onpick(f, scene::SceneLike, plots::AbstractPlot...)

Calls `f(idx)`` whenever the mouse is over any of `plots`.
`idx` is an index, e.g. when over a scatter plot, it will be the index of the
hovered element
"""
function onpick(f, scene::SceneLike, plots::AbstractPlot...)
    fplots = flatten_plots(plots)
    map_once(events(scene).mouseposition) do mp
        p, idx = mouse_selection(scene)
        (p in fplots) && f(idx)
        return
    end
end

"""
    mouse_selection(scene::Scene)
Returns the plot that is under the current mouse position
"""
function mouse_selection(scene::SceneLike)
    pick(scene, events(scene).mouseposition[])
end

function flatten_plots(x::Atomic, plots = AbstractPlot[])
    if isempty(x.plots)
        push!(plots, x)
    else
        flatten_plots(x.plots, plots)
    end
    plots
end

function flatten_plots(x::Combined, plots = AbstractPlot[])
    for elem in x.plots
        flatten_plots(elem, plots)
    end
    plots
end

function flatten_plots(array, plots = AbstractPlot[])
    for elem in array
        flatten_plots(elem, plots)
    end
    plots
end

"""
    mouse_in_scene(scene::Scene)
returns the mouseposition relative to `scene`
"""
function mouse_in_scene(scene::SceneLike)
    p = rootparent(scene)
    lift(pixelarea(p), pixelarea(scene), events(scene).mouseposition) do pa, sa, mp
        Vec(mp) .- minimum(sa)
    end
end


"""
Return the plot under pixel position x y
"""
function pick(scene::SceneLike, x::Number, y::Number)
    return pick(scene, Vec{2, Float64}(x, y))
end


"""
    pick(scene::Scene, xy::VecLike)
Return the plot under pixel position xy
"""
function pick(scene::SceneLike, xy)
    screen = getscreen(scene)
    screen === nothing && return (nothing, 0)
    pick(scene, screen, Vec{2, Float64}(xy))
end

"""
Normalizes mouse position relative to the screen rectangle
"""
function screen_relative(scene::Scene, mpos)
    return Point2f0(mpos) .- Point2f0(minimum(pixelarea(scene)[]))
end

"""
    mouseposition(scene = hovered_scene()) -> pos
Return the current position of the mouse `pos` in _data points_ of the
given `scene`.

By default uses the `scene` that the mouse is currently hovering over.
"""
function mouseposition(scene = hovered_scene())
    to_world(
        scene,
        screen_relative(
            scene,
            events(scene).mouseposition[]
        )
    )
end

"""
    hovered_scene()
Return the `scene` that the mouse is currently hovering over.

Properly identifies the scene for a plot with multiple sub-plots.
"""
hovered_scene() = error("hoevered_scene is not implemented yet.")

"""
    select_rectangle(scene; kwargs...) -> rect
Interactively select a rectangle on a `scene` by clicking the left mouse button,
dragging and then un-clicking. The function returns an **observable** `rect` whose
value corresponds to the selected rectangle on the scene. In addition the function
_plots_ the selected rectangle on the scene as the user clicks and moves the mouse
around. When the button is not clicked any more, the plotted rectangle disappears.

The value of the returned observable is updated **only** when the user un-clicks
(i.e. when the final value of the rectangle has been decided) and only if the
rectangle has area > 0.

The `kwargs...` are propagated into `lines!` which plots the selected rectangle.
"""
function select_rectangle(scene; kwargs...)
    key = Mouse.left
    waspressed = Node(false)
    rect = Node(FRect(0, 0, 1, 1)) # plotted rectangle
    rect_ret = Node(FRect(0, 0, 1, 1)) # returned rectangle

    # Create an initially hidden rectangle
    rect_vis = lines!(
        scene, rect, raw = true, visible = false, kwargs...,
    )[end] # Why do I have to do [end] ?

    on(events(scene).mousedrag) do drag
        if ispressed(scene, key) && is_mouseinside(scene)
            mp = mouseposition(scene)
            if drag == Mouse.down
                waspressed[] = true
                rect_vis[:visible] = true # start displaying
                rect[] = FRect(mp, 0.0, 0.0)
            elseif drag == Mouse.pressed
                mini = minimum(rect[])
                rect[] = FRect(mini, mp - mini)
            end
        else
            if drag == Mouse.up && waspressed[] # User has selected the rectangle
                waspressed[] = false
                r = absrect(rect[])
                w, h = widths(r)
                if w > 0.0 && h > 0.0 # Ensure that the rectangle has non0 size.
                    rect_ret[] = r
                end
            end
            # always hide if not the right key is pressed
            rect_vis[:visible] = false # make the plotted rectangle invisible
        end
        return rect_ret
    end
    return rect_ret
end
