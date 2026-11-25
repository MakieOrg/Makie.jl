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

Find the visible scene that has `captures_mouse = true` and covers `mp`.
Current ordering follows scene translations until scene render order is available.
"""
function find_topmost_cover(scene::Scene, mp)::Union{Nothing, Scene}
    scene.visible[] || return nothing
    (Vec(mp) in scene.viewport[]) || return nothing
    best::Union{Nothing, Scene} = scene.captures_mouse ? scene : nothing
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

# Keep the normal Observables priorities across scenes that share Events.
function receives_events(scene::Scene)
    scene_visible(scene) || return false
    active = find_topmost_cover(root(scene), scene.events.mouseposition[])
    active === nothing && return true
    return is_ancestor_or_equal(active, scene) ||
        is_ancestor_or_equal(scene, active)
end

mouse_over_scene(x) = mouse_over_scene(get_scene(x))
function mouse_over_scene(scene::Scene)
    clip = effective_clip(scene)
    return all(>(0), widths(clip)) && Vec(scene.events.mouseposition[]) in clip && receives_events(scene)
end
