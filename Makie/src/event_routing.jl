"""
    covers_pointer(scene::Scene) -> Bool

True when `scene` is the topmost layer over its viewport: visible, with
`clear[] == true` (paints its own background) AND a positive world-z. A
scene with only one signal — a Legend lifted to z=10, or an Axis whose
theme sets `clear=true` at z=0 — is layered for rendering only and does
not claim pointer input.

Scenes that paint a translucent backdrop via plots instead of an opaque
`clear = true` background (e.g. a modal dialog's overlay) can opt in
explicitly with `scene.captures_mouse = true`.
"""
function covers_pointer(scene::Scene)
    scene.visible[] || return false
    scene.captures_mouse && return true
    return scene.clear[] && z_world(scene) > 0
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
"""
function receives_events(scene::Scene)
    scene.visible[] || return false
    active = find_topmost_cover(root(scene), scene.events.mouseposition[])
    active === nothing && return true
    return is_ancestor_or_equal(active, scene) ||
        is_ancestor_or_equal(scene, active)
end
