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
    return RenderGroup(pipeline, Scene[], RenderObject[])
end

function RenderGroup(pipeline, scenes)
    return RenderGroup(pipeline, scenes, collect_renderobjects!(RenderObject[], scenes))
end

# function collect_renderobjects!(buffer, scenes::Vector)
#     for scene in scenes
#         collect_renderobjects!(buffer, scene)
#     end
#     return buffer
# end

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
end
function Base.show(io::IO, ::MIME"text/plain", ctx::RenderContext)
    print(io, "RenderContext")
    for group in ctx.groups
        print(io, "\n  ", group)
    end
end

function RenderContext()
    return RenderContext(Dict{UInt32, Plot}(), Dict{Scene, Int}(), RenderGroup[])
end

function recreate!(ctx::RenderContext, screen, root::Scene)
    empty!(ctx.robj2plot)
    empty!(ctx.scene2group)
    empty!(ctx.groups)
    build_groups!(ctx, screen, root)
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
    # TODO: robj -> group
    return
end

function insert_plot!(ctx::RenderContext, screen, scene, plot)
    @assert haskey(ctx.scene2group, scene)
    idx = ctx.scene2group[scene]
    # just needs some management updates in insert!(screen, scene, plot)?
    insert_plot!(ctx.groups[idx], screen, plot)
end

function insert_scene!(ctx::RenderContext, screen, scene)
    parent = parentscene(scene)
    idx = findfirst(===(scene), parent.children)
    previous = idx === 1 ? parent : parent.children[idx - 1]
    group_idx = ctx.scene2group[previous]
    ctx.scene2group[scene] = group_idx

    group = ctx.groups[group_idx]
    scene_idx = firstfirst(===(scene), group.scenes)
    insert!(group.scenes, scene_idx + 1, scene)

    # If we do overlap checking we would need to recheck it here
    if scene.clear[]
        # Need to split group
        # 1 .. group_idx+1 | group_idx+2 .. end
        new_group = RenderGroup(group.gl_pipeline, group.scenes[scene_idx+2 : end])
        old_group = group
        resize!(old_group.scenes, scene_idx+1)
        empty!(old_group.renderobjects)
        collect_renderobjects!(old_group.renderobjects, old_group.scenes)

        insert!(ctx.groups, group_idx+1, new_group)
        for (key, gi) in ctx.scene2group
            if gi == group_idx
                ctx.scene2group[key] = gi + any(===(key), new_group.scenes)
            elseif gi > group_idx
                ctx.scene2group[key] = gi + 1
            end
        end
    end

end
