# Represents multiple Makie Scenes that render with the same RenderPipeline and
# without clearing parts of itself. This should:
# - avoid resetting the render pipeline
# - allow shared depth buffers
# - allow accumulation of negative stencils (draw this, then exclude it from the next group)
# - allow merging of scenes w.r.t depth buffers
struct RenderGroup
    gl_pipeline::GLRenderPipeline
    scenes::Vector{WeakRef}
    renderobjects::Vector{Tuple{Int, RenderObject}}
end

function Base.show(io::IO, group::RenderGroup)
    print(io, "RenderGroup($(length(group.scenes)) Scenes, $(length(group.renderobjects)) render objects)")
end
# Base.show(io::IO, ::MIME"text/plain", group::RenderGroup)

function RenderGroup(pipeline)
    return RenderGroup(pipeline, WeakRef[], Tuple{Int, RenderObject}[])
end

function RenderGroup(pipeline, scenes::AbstractVector{Scene})
    return RenderGroup(pipeline, WeakRef.(scenes))
end

function RenderGroup(pipeline, scenes::AbstractVector{WeakRef})
    return RenderGroup(
        pipeline, scenes, collect_renderobjects!(Tuple{Int, RenderObject}[], scenes)
    )
end

function collect_renderobjects!(buffer, scenes::Vector)
    @assert isempty(buffer)
    for (idx, scene) in enumerate(scenes)
        collect_renderobjects!(buffer, idx, scene)
    end
    return buffer
end

function collect_renderobjects!(buffer, scene_idx, scene::WeakRef)
    return collect_renderobjects!(buffer, scene_idx, scene.value)
end

collect_renderobjects!(buffer, scene_idx, ::Nothing) = nothing

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

isfinished(group::RenderGroup) = last(group.scenes).value.clear[]

function push_scene!(group::RenderGroup, screen, scene::Scene)
    push!(group.scenes, WeakRef(scene))
    # for plot in scene.plots
    #     insert!(screen, group.renderobjects, plot)
    # end
    collect_renderobjects!(group.renderobjects, length(group.scenes), scene)
    return
end

Base.isempty(group::RenderGroup) = isempty(group.scenes)

function delete_scene!(group::RenderGroup, scene::Scene)
    for (i, ref) in enumerate(group.scenes)
        if ref === nothing || ref.value === scene
            filter!(x -> x[1] != i, group.renderobjects)
            for (j, (scene_idx, robj)) in enumerate(group.renderobjects)
                if scene_idx > i
                    group.renderobjects[j] = (scene_idx - 1, robj)
                end
            end
            deleteat!(group.scenes, i)
            # Repeat in case we have GC'd weakrefs alongside the deleted scene
            return delete_scene!(group, scene)
        end
    end
    return
end

function delete_robj!(group::RenderGroup, robj::RenderObject)
    filter!(x -> x[2] !== robj, group.renderobjects)
    return
end

# Manages all the rendering stuff
struct RenderContext
    # Needed for plot (and scene?) insertion?
    # Needed for scene insertion?
    # Is objectid ok?
    # GC'd scenes call delete!(screen, scene), which cleans up entries here.
    # Even if an entry remains past GC, it should only be addressed with scenes
    # that have been added before, which overwrites/updates id collisions.
    # And even if that doesn't work, we check scene equality in groups
    scene2group::Dict{UInt64, Int}

    groups::Vector{RenderGroup}
end
function Base.show(io::IO, ctx::RenderContext)
    print(io, "RenderContext($(length(ctx.groups)) groups)")
    return io
end
function Base.show(io::IO, ::MIME"text/plain", ctx::RenderContext)
    print(io, "RenderContext")
    for group in ctx.groups
        print(io, "\n  ", group)
    end
    return io
end

function RenderContext()
    return RenderContext(Dict{UInt64, Int}(), RenderGroup[])
end

function Base.empty!(ctx::RenderContext)
    empty!(ctx.scene2group)
    empty!(ctx.groups)
    return
end

Base.isempty(ctx::RenderContext) = isempty(ctx.groups)

function recreate!(ctx::RenderContext, screen, root::Scene)
    empty!(ctx)
    build_groups!(ctx, screen, root)
    return
end

function build_groups!(ctx::RenderContext, screen, scene)
    for child in reverse(scene.children)
        build_groups!(ctx, screen, child)
    end
    if isempty(ctx.groups) || isfinished(last(ctx.groups)) # || pipeline missmatch
        push!(ctx.groups, RenderGroup(screen.render_pipeline))
    end
    group = last(ctx.groups)
    push_scene!(group, screen, scene)
    ctx.scene2group[objectid(scene)] = length(ctx.groups)
    return
end

# function insert_plot!(ctx::RenderContext, screen, scene, plot)
#     @assert haskey(ctx.scene2group, objectid(scene))
#     idx = ctx.scene2group[objectid(scene)]
#     # just needs some management updates in insert!(screen, scene, plot)?
#     # insert_plot!(ctx.groups[idx], screen, plot)
# end

function insert_robj!(ctx::RenderContext, scene, robj)
    if haskey(ctx.scene2group, objectid(scene))
        idx = ctx.scene2group[objectid(scene)]
        @assert idx isa Integer
        group = ctx.groups[idx]
        scene_idx = findfirst(x -> x.value === scene, group.scenes)
        @assert scene_idx isa Integer
        push!(group.renderobjects, (scene_idx, robj))
    else
        # TODO: We're probably adding robjs before scenes when creating a Screen
        # from a finished scene graph...
        @error "Failed to insert robj because parent scene is missing"
    end
    return
end

"""
    find_previous_scene(scene)

Returns the scene that should render immediately before `scene` assuming depth
first ordering. This is either the scene immediately before `scene` in
`parent.children` or the parent itself. The returned scene might be covered by
the given scene, but doesn't need to be.
"""
function find_previous_scene(scene::Scene)
    _parent = parent(scene)
    idx = findfirst(x -> x === scene, _parent.children)
    return idx === 1 ? _parent : _parent.children[idx - 1]
end

function Makie.insert_scene!(ctx::RenderContext, screen, scene)
    # TODO: verify that scenes don't get added multiple times

    # The given scene renders before "previous" in front to back rendering order.
    # Therefore it takes its spot in `group.scenes`
    previous = find_previous_scene(scene)
    group_idx = ctx.scene2group[objectid(previous)]
    group = ctx.groups[group_idx]
    scene_idx = findfirst(x -> x.value === previous, group.scenes)
    insert!(group.scenes, scene_idx, WeakRef(scene))
    ctx.scene2group[objectid(scene)] = group_idx

    # The group needs to be broken if the added scene clears
    # TODO: improve coverage checks
    # TODO: render pipeline checks
    if scene.clear[]
        new_group = RenderGroup(group.gl_pipeline, group.scenes[scene_idx+1 : end])

        old_group = group
        resize!(old_group.scenes, scene_idx)
        empty!(old_group.renderobjects)
        collect_renderobjects!(old_group.renderobjects, old_group.scenes)

        insert!(ctx.groups, group_idx+1, new_group)
        for (key, gi) in ctx.scene2group
            if gi == group_idx
                ctx.scene2group[key] = gi + any(x -> objectid(x.value) === key, new_group.scenes)
            elseif gi > group_idx
                ctx.scene2group[key] = gi + 1
            end
        end
    end

    screen.requires_update = true
    # TODO: Does this consume?
    onany(
        (args...) -> screen.requires_update = true,
        scene,
        scene.visible, scene.backgroundcolor, scene.clear,
        scene.ssao.bias, scene.ssao.blur, scene.ssao.radius, scene.camera.projectionview,
        scene.camera.resolution
    )

    # TODO: scene.clear should cause update of scene grouping

    return
end

function delete_scene!(ctx::RenderContext, scene::Scene)
    if haskey(ctx.scene2group, objectid(scene))
        idx = pop!(ctx.scene2group, objectid(scene))
        group = ctx.groups[idx]
        delete_scene!(group, scene)
        if isempty(group)
            delete_group!(ctx, idx)
        end
    end
    return
end

function delete_group!(ctx, idx::Integer)
    deleteat!(ctx.groups, idx)
    filter!(kv -> kv[2] != idx, ctx.scene2group)
    for (key, i) in ctx.scene2group
        if i > idx
            ctx.scene2group[key] = i - 1
        end
    end
    return
end

function delete_robj!(ctx::RenderContext, scene::Scene, robj::RenderObject)
    if haskey(ctx.scene2group, objectid(scene))
        idx = ctx.scene2group[objectid(scene)]
        group = ctx.groups[idx]
        delete_robj!(group, robj)
    end
    return
end