# Represents multiple Makie Scenes that render with the same RenderPipeline and
# without clearing parts of itself. This should:
# - avoid resetting the render pipeline
# - allow shared depth buffers
# - allow accumulation of negative stencils (draw this, then exclude it from the next group)
# - allow merging of scenes w.r.t depth buffers
struct RenderGroup
    # And whatever is needed for identification?
    gl_pipeline::GLRenderPipeline
    scenes::Vector{Scene} # TODO: probably WeakRef? Or IdDict?
    renderobjects::Vector{Tuple{Int, RenderObject}}
end

function Base.show(io::IO, group::RenderGroup)
    print(io, "RenderGroup($(length(group.scenes)) Scenes, $(length(group.renderobjects)) render objects)")
end
# Base.show(io::IO, ::MIME"text/plain", group::RenderGroup)

function RenderGroup(pipeline)
    return RenderGroup(pipeline, Scene[], Tuple{Int, RenderObject}[])
end

function RenderGroup(pipeline, scenes)
    return RenderGroup(pipeline, scenes, collect_renderobjects!(Tuple{Int, RenderObject}[], scenes))
end

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

isfinished(group::RenderGroup) = last(group.scenes).clear[]

function push_scene!(group::RenderGroup, screen, scene::Scene)
    push!(group.scenes, scene)
    # for plot in scene.plots
    #     insert!(screen, group.renderobjects, plot)
    # end
    collect_renderobjects!(group.renderobjects, length(group.scenes), scene)
    return
end

Base.isempty(group::RenderGroup) = isempty(group.scenes)


# Manages all the rendering stuff
struct RenderContext
    # TODO: maybe keep old?
    # plot2robj - useless since we can just do plot.gl_renderobject[]
    # Needed for picking at least
    robj2plot::Dict{UInt32, Plot}
    # Needed for plot (and scene?) insertion?
    # Needed for scene insertion?
    scene2group::Dict{Scene, Int}

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
    return RenderContext(Dict{UInt32, Plot}(), Dict{Scene, Int}(), RenderGroup[])
end

function recreate!(ctx::RenderContext, screen, root::Scene)
    empty!(ctx.robj2plot)
    empty!(ctx.scene2group)
    empty!(ctx.groups)
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
    ctx.scene2group[scene] = length(ctx.groups)
    return
end

function insert_plot!(ctx::RenderContext, screen, scene, plot)
    @assert haskey(ctx.scene2group, scene)
    idx = ctx.scene2group[scene]
    # just needs some management updates in insert!(screen, scene, plot)?
    # insert_plot!(ctx.groups[idx], screen, plot)
end

function insert_robj!(ctx::RenderContext, scene, robj)
    @assert haskey(ctx.scene2group, scene)
    idx = ctx.scene2group[scene]
    group = ctx.groups[idx]
    scene_idx = findfirst(x -> x === scene, group.scenes)
    push!(group.renderobjects, (scene_idx, robj))
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
    # The given scene renders before "previous" in front to back rendering order.
    # Therefore it takes its spot in `group.scenes`
    previous = find_previous_scene(scene)
    group_idx = ctx.scene2group[previous]
    group = ctx.groups[group_idx]
    scene_idx = findfirst(x -> x === previous, group.scenes)
    insert!(group.scenes, scene_idx, scene)
    ctx.scene2group[scene] = group_idx

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
                ctx.scene2group[key] = gi + any(x -> x === key, new_group.scenes)
            elseif gi > group_idx
                ctx.scene2group[key] = gi + 1
            end
        end
    end

    # TODO: Do we need this?
    add_scene!(screen, scene)

    return
end
