# GLMakie representation of Makie scenes
struct GLScene
    scene::Scene
    obsfuncs::Vector{ObserverFunction} # for cleanup
    renderobjects::Vector{RenderObject} # lowered plots
end

GLScene(scene, obsfuncs) = GLScene(scene, obsfuncs, Vector{RenderObject}())
GLScene(scene) = GLScene(scene, Vector{ObserverFunction}(), Vector{RenderObject}())

"""
    unsafe_empty!(glscene::GLScene)

Just deletes tracking. OpenGL destruction happens up the call stack.
"""
function unsafe_empty!(glscene::GLScene)
    foreach(off, glscene.obsfuncs)
    empty!(glscene.obsfuncs)
    empty!(glscene.renderobjects)
    return
end

"""
    RenderContext(scene_to_gl_scene, scenes)

The RenderContext holds references to all GLScenes and tracks which scene maps
to which GLScene index.
"""
struct RenderContext
    # Maps objectid of a Scene to its 1-based index in `scenes`.
    scene_to_gl_scene::Dict{UInt64, Int}

    # Array of GLScene objects
    scenes::Vector{GLScene}
end

function Base.show(io::IO, ctx::RenderContext)
    print(io, "RenderContext($(length(ctx.scenes)) Scene(s))")
    return io
end

function Base.show(io::IO, ::MIME"text/plain", ctx::RenderContext)
    print(io, "RenderContext")
    for gl_scene in ctx.scenes
        print(io, "\n  ", gl_scene.scene)
    end
    return io
end

# Create an empty render context.
RenderContext() = RenderContext(Dict{UInt64, Int}(), Vector{GLScene}())

# We don't take care of cleaning up render objects here!
function unsafe_empty!(ctx::RenderContext)
    empty!(ctx.scene_to_gl_scene)
    foreach(unsafe_empty!, ctx.scenes)
    empty!(ctx.scenes)
    return
end

Base.isempty(ctx::RenderContext) = isempty(ctx.scenes)

"""
    recreate!(render_context, root_scene)

Empties the render context and refills it according to the given scene tree.
"""
function recreate!(ctx::RenderContext, screen, root::Scene)
    unsafe_empty!(ctx)

    Makie.collect_scenes!(ctx, root) do ctx, scene
        # Map scene to its index in the scenes array (1-based)
        idx = length(ctx.scenes) + 1
        ctx.scene_to_gl_scene[objectid(scene)] = idx

        obsfuncs = onany(
            (args...) -> screen.requires_update = true,
            scene,
            scene.visible, scene.backgroundcolor, scene.clear,
            scene.ssao.bias, scene.ssao.blur, scene.ssao.radius,
        )

        gl_scene = GLScene(scene, obsfuncs)
        push!(ctx.scenes, gl_scene)
    end

    screen.requires_update = true
    return
end

function Makie.insert_scene!(ctx::RenderContext, screen, scene)
    # verify that scenes don't get added multiple times
    if haskey(ctx.scene_to_gl_scene, objectid(scene))
        error("Duplicate scene insertion is not allowed")
    end

    # The given scene renders after "previous" in back to front render order.
    previous = Makie.find_previous_scene(scene)
    if !haskey(ctx.scene_to_gl_scene, objectid(previous))
        error("Cannot insert scene that is not part of the tracked scene tree")
    end

    # Find index of previous GLScene
    prev_idx = ctx.scene_to_gl_scene[objectid(previous)]

    # Update all scene-to-GLScene indices that are after the insertion point
    map!(v -> ifelse(v > prev_idx, v + 1, v), values(ctx.scene_to_gl_scene))

    screen.requires_update = true

    obsfuncs = onany(
        (args...) -> screen.requires_update = true,
        scene,
        scene.visible, scene.backgroundcolor, scene.clear,
        scene.ssao.bias, scene.ssao.blur, scene.ssao.radius,
    )

    # Create new GLScene and insert after previous
    new_gl_scene = GLScene(scene, obsfuncs)
    insert!(ctx.scenes, prev_idx + 1, new_gl_scene)
    ctx.scene_to_gl_scene[objectid(scene)] = prev_idx + 1

    return
end

function delete_scene!(ctx::RenderContext, scene::Scene)
    if !haskey(ctx.scene_to_gl_scene, objectid(scene))
        # @warn "delete_scene! called on untracked scene"
        return
    end

    scene_idx = ctx.scene_to_gl_scene[objectid(scene)]

    # Disconnect scene
    foreach(off, ctx.scenes[scene_idx].obsfuncs)

    # Remove the GLScene from the scenes array
    deleteat!(ctx.scenes, scene_idx)
    delete!(ctx.scene_to_gl_scene, objectid(scene))

    # Update all scene-to-GLScene indices that were after this one
    map!(v -> ifelse(v > scene_idx, v - 1, v), values(ctx.scene_to_gl_scene))

    return
end

function insert_robj!(ctx::RenderContext, scene::Scene, robj::RenderObject)
    if !haskey(ctx.scene_to_gl_scene, objectid(scene))
        @error "Failed to insert robj because parent scene is missing"
    end

    scene_idx = ctx.scene_to_gl_scene[objectid(scene)]
    push!(ctx.scenes[scene_idx].renderobjects, robj)
    return
end

function delete_robj!(ctx::RenderContext, scene::Scene, robj::RenderObject)
    if !haskey(ctx.scene_to_gl_scene, objectid(scene))
        return
    end

    scene_idx = ctx.scene_to_gl_scene[objectid(scene)]
    filter!(x -> x !== robj, ctx.scenes[scene_idx].renderobjects)
    return
end