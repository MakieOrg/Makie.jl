"""
    covers_pointer(scene::Scene) -> Bool

Whether `scene` claims the pointer, blocking input to the scenes it overlaps.

A scene claims the pointer only by opting in explicitly with
`scene.captures_mouse = true` (e.g. a modal dialog's translucent overlay).
Coverage is deliberately *not* inferred from rendering properties like
`clear` or world-z: those are unreliable across backends (`clear` behaves
differently per backend) and meaningless in 3D (z ≠ depth), so a scene that
merely paints on top does not silently swallow input.
"""
function covers_pointer(scene::Scene)
    return scene.visible[] && scene.captures_mouse
end

"World z = accumulated z-translation along the ancestor chain."
function z_world(scene::Scene)
    z = translation(scene)[][3]
    p = parent(scene)
    return p === nothing ? z : z + z_world(p)
end

function depth_in_tree(scene::Scene)
    d = 0
    s = scene
    while !isroot(s)
        s = parent(s)
        d += 1
    end
    return d
end

"Ordering for `find_topmost_cover`: higher world-z, then deeper subtree."
function wins_over(a::Scene, b::Scene)
    za, zb = z_world(a), z_world(b)
    za != zb && return za > zb
    return depth_in_tree(a) > depth_in_tree(b)
end

"""
    find_topmost_cover(scene::Scene, mp) -> Union{Nothing, Scene}

Deepest visible covering scene in `scene`'s subtree whose viewport contains
the mouse position `mp`, or `nothing` if none exists.
"""
function find_topmost_cover(scene::Scene, mp)::Union{Nothing, Scene}
    scene.visible[] || return nothing
    (Vec(mp) in scene.viewport[]) || return nothing
    best::Union{Nothing, Scene} = covers_pointer(scene) ? scene : nothing
    for child in scene.children
        cand = find_topmost_cover(child, mp)
        cand === nothing && continue
        if best === nothing || wins_over(cand, best)
            best = cand
        end
    end
    return best
end

function is_ancestor_or_equal(ancestor::Scene, scene::Scene)
    s::Union{Nothing, Scene} = scene
    while s !== nothing
        s === ancestor && return true
        s = parent(s)
    end
    return false
end

"""
    receives_events(scene::Scene) -> Bool

Whether pointer-event handlers attached to `scene` should fire right now.
Returns `true` when `scene` is visible AND either no scene currently covers
the mouse, or the covering scene shares a root-to-leaf path with `scene`.

Visibility is checked with `scene_visible`, i.e. including ancestors: a `Block`
force-shows its own scene in `unhide!`, so a widget inside a hidden container
(an inactive tab, a closed modal) keeps `scene.visible[] == true` and would
otherwise keep consuming input it is not drawn for.
"""
function receives_events(scene::Scene)
    scene_visible(scene) || return false
    active = find_topmost_cover(root(scene), scene.events.mouseposition[])
    active === nothing && return true
    return is_ancestor_or_equal(active, scene) ||
        is_ancestor_or_equal(scene, active)
end
