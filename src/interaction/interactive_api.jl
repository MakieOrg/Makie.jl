export mouseover, mouse_selection, mouseposition, hovered_scene
export select_rectangle

mouseover() = error("not implemented")


# What does this function do?
function mouse_in_scene(scene)
    p = rootparent(scene)
    lift(pixelarea(p), pixelarea(scene), events(scene).mouseposition) do pa, sa, mp
        Vec(mp) .- minimum(sa)
    end
end


"""
    mouse_selection(scene)

Returns the plot under the current mouse position in `scene`.
"""
function mouse_selection
    # TODO this needs to be implemented here via select_mouse_native
end

"""
Return the plot under pixel position x y
"""
pick(scene::SceneLike, x, y) = pick(scene, Float64.((x, y)))

# What does this function do?
to_screen(scene, mpos) = Point2f0(mpos) .- Point2f0(minimum(pixelarea(scene)[]))

"""
    mouseposition(scene = hovered_scene()) -> pos
Return the current position of the mouse `pos` in _data points_ of the
given `scene`.

By default uses the `scene` that the mouse is currently hovering over.
"""
function mouseposition(scene = hovered_scene())
    to_world(scene, to_screen(scene, events(scene).mouseposition[]))
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
