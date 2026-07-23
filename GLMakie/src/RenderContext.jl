struct GLScene
    scene::WeakRef
    renderobjects::Vector{RenderObject}
end

function Base.show(io::IO, group::GLScene)
    print(io, "GLScene($(group.scene), $(length(group.renderobjects)) render objects)")
end
# Base.show(io::IO, ::MIME"text/plain", group::GLScene)

GLScene() = GLScene(WeakRef(nothing), RenderObject[])
GLScene(scene::Scene) = GLScene(WeakRef(scene))
GLScene(scene::WeakRef) = GLScene(scene, collect_renderobjects!(RenderObject[], scene))

collect_renderobjects!(buffer, scene::WeakRef) = collect_renderobjects!(buffer, scene.value)
collect_renderobjects!(buffer, ::Nothing) = nothing

function collect_renderobjects!(buffer, scene::Scene)
    for plot in scene.plots
        collect_renderobjects!(buffer, plot)
    end
    return buffer
end

function collect_renderobjects!(buffer, plot::AbstractPlot)
    if haskey(plot, :gl_renderobject)
        push!(buffer, plot.gl_renderobject[])
    end
    for child in plot.plots
        collect_renderobjects!(buffer, child)
    end
    return buffer
end

# Just deletes tracking. OpenGL destruction happens up the call stack
function delete_robj!(group::GLScene, robj::RenderObject)
    filter!(x -> x !== robj, group.renderobjects)
    return
end

struct RenderContext
    # Needed for plot (and scene?) insertion?
    # Needed for scene insertion?
    # Is objectid ok?
    # GC'd scenes call delete!(screen, scene), which cleans up entries here.
    # Even if an entry remains past GC, it should only be addressed with scenes
    # that have been added before, which overwrites/updates id collisions.
    # And even if that doesn't work, we check scene equality in scenes
    scene2glscene::Dict{UInt64, Int}

    # sorted back (first) to front (last)
    # iterate normally to get the background (root scene) first
    # iterate in reverse to get the front most scene first
    scenes::Vector{GLScene}
    # Note for future:
    # If we want multiple render pipelines in the future we should probably
    # group GLScenes by pipeline (continuous groups)
end

RenderContext() = RenderContext(Dict{UInt64, Int}(), GLScene[])

function Base.show(io::IO, ctx::RenderContext)
    print(io, "RenderContext($(length(ctx.scenes)) scenes)")
    return io
end

function Base.show(io::IO, ::MIME"text/plain", ctx::RenderContext)
    print(io, "RenderContext")
    for group in ctx.scenes
        print(io, "\n  ", group)
    end
    return io
end

function Base.empty!(ctx::RenderContext)
    empty!(ctx.scene2glscene)
    empty!(ctx.scenes)
    return
end

Base.isempty(ctx::RenderContext) = isempty(ctx.scenes)

function recreate!(ctx::RenderContext, screen, root::Scene)
    empty!(ctx)
    collect_scenes!(ctx, screen, root)
    return
end

function collect_scenes!(ctx::RenderContext, screen, scene)
    push!(ctx.scenes, GLScene(scene))
    ctx.scene2glscene[objectid(scene)] = length(ctx.scenes)
    for child in scene.children
        collect_scenes!(ctx, screen, child)
    end
    return
end

function insert_robj!(ctx::RenderContext, scene, robj)
    if haskey(ctx.scene2glscene, objectid(scene))
        idx = ctx.scene2glscene[objectid(scene)]
        @assert idx isa Integer
        glscene = ctx.scenes[idx]
        push!(glscene.renderobjects, robj)
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
    # verify that scenes don't get added multiple times
    @assert !haskey(ctx.scene2glscene, objectid(scene))

    # The given scene renders before "previous" in front to back rendering order.
    # Therefore it takes its spot in `group.scenes`
    previous = find_previous_scene(scene)
    scene_idx = ctx.scene2glscene[objectid(previous)]
    insert!(ctx.scenes, scene_idx + 1, GLScene(scene))

    for (k, idx) in ctx.scene2glscene
        ctx.scene2glscene[k] = idx + Int(idx > scene_idx)
    end
    ctx.scene2glscene[objectid(scene)] = scene_idx + 1

    screen.requires_update = true
    # TODO: Does this consume?
    onany(
        (args...) -> screen.requires_update = true,
        scene,
        scene.visible, scene.backgroundcolor, scene.clear,
        scene.ssao.bias, scene.ssao.blur, scene.ssao.radius, scene.camera.projectionview,
        scene.camera.resolution
    )

    return
end

function delete_scene!(ctx::RenderContext, scene::Scene)
    if haskey(ctx.scene2glscene, objectid(scene))
        idx = pop!(ctx.scene2glscene, objectid(scene))
        popat!(ctx.scenes, idx)
        for (key, i) in ctx.scene2glscene
            ctx.scene2glscene[key] = i - Int(i > idx)
        end
    end
    return
end

function delete_robj!(ctx::RenderContext, scene::Scene, robj::RenderObject)
    if haskey(ctx.scene2glscene, objectid(scene))
        idx = ctx.scene2glscene[objectid(scene)]
        glscene = ctx.scenes[idx]
        delete_robj!(glscene, robj)
    end
    return
end