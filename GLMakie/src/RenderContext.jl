struct GLSceneGroup
    # This does not need to be a WeakRef because
    # 1. child scene cleanup no longer relies on GC. If a child scene is removed
    # from the scene tree on the Makie side it must be explicitly removed in the
    # backend as well to ensure they stay in sync.
    # 2. The root scene is also kept in `Screen` as a direct reference, so it
    # can not be cleaned up through GC alone. It is only detached by
    # `empty!(screen)` which also clears the full render context
    scenes::Vector{Scene}
    renderobjects::Vector{Tuple{Int, RenderObject}}
end

function Base.show(io::IO, glscene::GLSceneGroup)
    print(io, "GLSceneGroup($(length(glscene.scenes)) Scenes, $(length(glscene.renderobjects)) render objects)")
end
# Base.show(io::IO, ::MIME"text/plain", group::GLScene)

GLSceneGroup(scene::Scene) = GLSceneGroup(Scene[scene], RenderObject[])
GLSceneGroup() = GLSceneGroup(Scene[], RenderObject[])

function collect_renderobjects!(buffer, scenes::Vector)
    @assert isempty(buffer)
    for (idx, scene) in enumerate(scenes)
        collect_renderobjects!(buffer, idx, scene)
    end
    return buffer
end

function collect_renderobjects!(buffer, scene_idx, scene::Scene)
    for plot in scene.plots
        collect_renderobjects!(buffer, scene_idx, plot)
    end
    return buffer
end

function collect_renderobjects!(buffer, scene_idx, plot::AbstractPlot)
    if haskey(plot, :gl_renderobject)
        push!(buffer, (scene_idx, plot.gl_renderobject[]))
    end
    for child in plot.plots
        collect_renderobjects!(buffer, scene_idx, child)
    end
    return buffer
end

Base.isempty(group::GLSceneGroup) = isempty(group.scenes)


"""
    shift_robj_scene_idx!(group, pivot, by = 1)

Goes through all `group.renderobjects` and adds `by` to their scene index if
that scene index is `<= pivot`. E.g.
- `shift_robj_scene_idx!(group, 1, 1)` will increment all scene indices by 1
- `shift_robj_scene_idx!(group, 5, 1)` will increment 5..N to 6..N+1, making 5 available for a new scene
"""
function shift_robj_scene_idx!(group::GLSceneGroup, pivot, by = 1)
    for i in eachindex(group.renderobjects)
        scene_idx, robj = group.renderobjects[i]
        group.renderobjects[i] = (scene_idx + by * Int(scene_idx >= pivot), robj)
    end
    return
end

function delete_scene!(group::GLSceneGroup, scene::Scene)
    for (i, choice) in enumerate(group.scenes)
        if choice === scene
            filter!(x -> x[1] != i, group.renderobjects)
            shift_robj_scene_idx!(group, i, -1)
            deleteat!(group.scenes, i)
            return true
        end
    end
    return false
end

# Just deletes tracking. OpenGL destruction happens up the call stack
function delete_robj!(group::GLSceneGroup, robj::RenderObject)
    filter!(x -> x[2] !== robj, group.renderobjects)
    return
end

################################################################################

struct RenderContext
    # Needed for plot (and scene?) insertion?
    # Needed for scene insertion?
    # Is objectid ok?
    # GC'd scenes call delete!(screen, scene), which cleans up entries here.
    # Even if an entry remains past GC, it should only be addressed with scenes
    # that have been added before, which overwrites/updates id collisions.
    # And even if that doesn't work, we check scene equality in scenes
    scene2group::Dict{UInt64, Int}

    # sorted back (first) to front (last)
    # iterate normally to get the background (root scene) first
    # iterate in reverse to get the front most scene first
    groups::Vector{GLSceneGroup}
    # Note for future:
    # If we want multiple render pipelines in the future we should probably
    # group GLScenes by pipeline (continuous groups)
end

RenderContext() = RenderContext(Dict{UInt64, Int}(), GLSceneGroup[])

function Base.show(io::IO, ctx::RenderContext)
    print(io, "RenderContext($(length(ctx.groups)) Scene Groups)")
    return io
end

function Base.show(io::IO, ::MIME"text/plain", ctx::RenderContext)
    print(io, "RenderContext")
    for group in ctx.groups
        print(io, "\n  ", group)
    end
    return io
end

function Base.empty!(ctx::RenderContext)
    empty!(ctx.scene2group)
    empty!(ctx.groups)
    return
end

Base.isempty(ctx::RenderContext) = isempty(ctx.groups)

"""
    recreate!(render_context, root_scene)

Empties the render context and refills it according to the given scene tree.
"""
function recreate!(ctx::RenderContext, root::Scene)
    empty!(ctx)
    push!(ctx.groups, GLSceneGroup())
    Makie.collect_scenes!(ctx, root) do ctx, scene
        group = ctx.groups[end]
        if !isempty(group) && scene.clear[]
            group = GLSceneGroup()
            push!(ctx.groups, group)
        end
        push!(group.scenes, scene)
        ctx.scene2group[objectid(scene)] = length(ctx.groups)
    end
    return
end

"""
    split_group!(render_context, group_idx, scene_idx)

Splits the scene group referenced by `group_idx` into two groups `1 .. scene_idx-1`
and `scene_idx .. end`. This also moves the respective render objects, adds
the group to `render_context.groups` and updates `render_context.scene2group`.
"""
function split_group!(ctx::RenderContext, group_idx, scene_idx)
    prev_group = ctx.groups[group_idx]

    # Move scenes and associated renderobjects after scene_idx to new group
    next_group = GLSceneGroup(
        splice!(prev_group.scenes, scene_idx : length(prev_group.scenes)),
        filter(prev_group.renderobjects) do (i, robj)
            return i >= scene_idx
        end
    )
    shift_robj_scene_idx!(next_group, 1, 1 - scene_idx)
    # Add new group after old group
    insert!(ctx.groups, group_idx + 1, next_group)

    # remove moved renderobjects from old group
    filter!(prev_group.renderobjects) do (i, robj)
        return i < scene_idx
    end

    # Update group indices for all scene => group pairs that are out of date
    map!(idx -> idx + Int(idx > group_idx), values(ctx.scene2group))
    for scene in next_group.scenes
        ctx.scene2group[objectid(scene)] = group_idx + 1
    end

    return
end

"""
    merge_group_with_previous!(render_context, group_idx)

Adds the scenes and render objects of the previous group into the group referenced
by `group_idx`. The previous group is then removed from `render_context` and
bookkeeping is updated. If no next group exists this will silently exit.
"""
function merge_group_with_previous!(ctx, group_idx)
    group_idx == 1 && return

    prev = ctx.groups[group_idx - 1]
    prev_Ns = length(prev.scenes)

    next = ctx.groups[group_idx]

    # Move scenes and renderobjects
    prepend!(next.scenes, prev.scenes)
    shift_robj_scene_idx!(next, 1, prev_Ns)
    prepend!(next.renderobjects, prev.renderobjects)

    # update references
    map!(i -> ifelse(i >= group_idx, i - 1, i), values(ctx.scene2group))

    # Cleanup
    deleteat!(ctx.groups, group_idx - 1)
    empty!(prev.scenes)
    empty!(prev.renderobjects)

    return
end

"""
    regroup!(render_context, scene, new_clear)

Updates the grouping of the scene based on its new clear value. This may split
or merge groups.
"""
function regroup!(ctx::RenderContext, scene::Scene, new_clear)
    group_idx = ctx.scene2group[objectid(scene)]
    group = ctx.groups[group_idx]
    scene_idx = findfirst(x -> x === scene, group.scenes)
    if new_clear == true
        split_group!(ctx, group_idx, scene_idx)
    else
        merge_group_with_next!(ctx, group_idx)
    end
    return
end

"""
    repair_group!(render_context, group_idx)

Checks the group referenced by `group_idx` for incorrect state. If it contains
multiple clear commands, the group is split. If it contains no clear commands
and is not the final group, it is merged with a later group. This will
recursively call itself until the group becomes valid.
"""
function repair_group!(ctx::RenderContext, group_idx)
    is_group_valid(ctx, group_idx) && return
    group = ctx.groups[group_idx]
    if !first(group.scenes).clear[] && (group_idx > 1)
        merge_group_with_previous!(ctx, group_idx)
        # There might be multiple faults with this group, so recheck it
        repair_group!(ctx, group_idx)
    else
        scene_idx = findlast(x -> x.clear[], group.scenes)::Int64
        split_group!(ctx, group_idx, scene_idx)
        # If there are multiple faults they will be in the group that got split off
        repair_group!(ctx, group_idx)
    end
    return
end

"""
    is_group_valid(render_context, group_idx)

Checks if a group is valid. It is if the first scene clears and all others don't.
The first group is allowed to not start with a clearing scene.
"""
function is_group_valid(ctx::RenderContext, group_idx)
    group = ctx.groups[group_idx]
    isempty(group) && error("There should be no empty scene groups.")
    valid = (group_idx == 1) || first(group.scenes).clear[]
    for scene in @view(group.scenes[2:end])
        valid = valid && !scene.clear[]
    end
    return valid
end

function Makie.insert_scene!(ctx::RenderContext, screen, scene)
    # verify that scenes don't get added multiple times
    if haskey(ctx.scene2group, objectid(scene))
        error("Duplicate scene insertion is not allowed")
    end

    # The given scene renders after "previous" in back to front render order.
    previous = Makie.find_previous_scene(scene)
    if !haskey(ctx.scene2group, objectid(previous))
        error("Cannot insert scene that is not part of the tracked scene tree")
    end

    group_idx = ctx.scene2group[objectid(previous)]
    group = ctx.groups[group_idx]

    # Insert the scene after previous
    scene_idx = findfirst(x -> x === previous, group.scenes)::Int64 + 1
    insert!(group.scenes, scene_idx, scene)
    shift_robj_scene_idx!(group, scene_idx, +1)
    ctx.scene2group[objectid(scene)] = group_idx

    # If that insertion was invalid, fix it
    repair_group!(ctx, group_idx)

    screen.requires_update = true
    onany(
        (args...) -> screen.requires_update = true,
        scene,
        scene.visible, scene.backgroundcolor, scene.clear,
        scene.ssao.bias, scene.ssao.blur, scene.ssao.radius, scene.camera.projectionview,
        scene.camera.resolution
    )

    # When clear changes we need to
    on(clear -> regroup!(ctx, scene, clear), scene.clear)

    return
end

function delete_scene!(ctx::RenderContext, scene::Scene)
    if haskey(ctx.scene2group, objectid(scene))
        group_idx = pop!(ctx.scene2group, objectid(scene))
        group = ctx.groups[group_idx]
        delete_scene!(group, scene)
        if isempty(group)
            popat!(ctx.groups, group_idx)
            for (key, i) in ctx.scene2group
                ctx.scene2group[key] = i - Int(i > group_idx)
            end
        elseif scene.clear[]
            # Deleting a scene can only cause its group to become incomplete
            merge_group_with_previous!(ctx, group_idx)
        end
    end
    return
end

function insert_robj!(ctx::RenderContext, scene, robj)
    if haskey(ctx.scene2group, objectid(scene))
        group_idx = ctx.scene2group[objectid(scene)]
        group = ctx.groups[group_idx]
        scene_idx = findfirst(x -> x === scene, group.scenes)::Int64
        push!(group.renderobjects, (scene_idx, robj))
    else
        # TODO: We're probably adding robjs before scenes when creating a Screen
        # from a finished scene graph...
        @error "Failed to insert robj because parent scene is missing"
    end
    return
end

function delete_robj!(ctx::RenderContext, scene::Scene, robj::RenderObject)
    if haskey(ctx.scene2group, objectid(scene))
        group_idx = ctx.scene2group[objectid(scene)]
        group = ctx.groups[group_idx]
        delete_robj!(group, robj)
    end
    return
end