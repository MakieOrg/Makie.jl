export mouseover, mouse_selection, mouseposition, hovered_scene


mouseover() = error("not implemented")


# What does this function do?
function mouse_in_scene(scene)
    p = rootparent(scene)
    lift(pixelarea(p), pixelarea(scene), events(scene).mouseposition) do pa, sa, mp
        Vec(mp) .- minimum(sa)
    end
end

function mouse_selection end

# What does this function do?
to_screen(scene, mpos) = Point2f0(mpos) .- Point2f0(minimum(pixelarea(scene)[]))

"""
    mouseposition(scene = hovered_scene()) -> pos
Return the current position of the mouse `pos` in _data points_ of the
given `scene`.

By default uses the `scene` that the mouse is currently hovering over.
"""
mouseposition(scene) = to_world(scene, to_screen(scene, events(scene).mouseposition[]))


"""
    hovered_scene()
Return the `scene` that the mouse is currently hovering over.

Properly identifies the scene for a plot with multiple sub-plots.
"""
hovered_scene() = error("not implemented")
