struct GLScene
    scene::WeakRef # TODO phase this out?

    # TODO: do these need to be reactive for render on demand?
    viewport::Observable{Rect2f}
    clear::Observable{Bool}
    backgroundcolor::Observable{RGBAf}
    visible::Observable{Bool}
    # clear_depth::Bool
    # stecil/scene_based_occlusion

    # TODO:
    # - move postprocessors here
    # - make them controllable by Makie
    # - move SSAO settings into postprocessor controls
    ssao::Makie.SSAO
    # postprocessors
    
    renderobjects::Vector{RenderObject}

    # TODO: WeakRef or not?
    plot2robj::Dict{UInt64, RenderObject}
    robj2plot::Dict{UInt32, Plot}
end

function GLScene(scene::Scene)
    return GLScene(
        WeakRef(scene), 
        
        scene.viewport,
        scene.clear,
        scene.backgroundcolor,
        scene.visible,
        scene.ssao,

        RenderObject[],
        Dict{UInt64, RenderObject}(),
        Dict{UInt32, Plot}()
    ) 
end

# A bit dodgy...
Base.haskey(glscene::GLScene, robj::RenderObject) = haskey(glscene, robj.id)
Base.haskey(glscene::GLScene, plot::AbstractPlot) = haskey(glscene, objectid(plot))
Base.haskey(glscene::GLScene, robj_id::UInt32) = haskey(glscene.robj2plot, robj_id)
Base.haskey(glscene::GLScene, plot_id::UInt64) = haskey(glscene.plot2robj, plot_id)

Base.getindex(glscene::GLScene, robj::RenderObject) = getindex(glscene, robj.id)
Base.getindex(glscene::GLScene, plot::AbstractPlot) = getindex(glscene, objectid(plot))
Base.getindex(glscene::GLScene, robj_id::UInt32) = getindex(glscene.robj2plot, robj_id)
Base.getindex(glscene::GLScene, plot_id::UInt64) = getindex(glscene.plot2robj, plot_id)


function Base.show(io::IO, glscene::GLScene)
    println(io, 
        "GLScene(", 
        glscene === nothing ? "nothing" : "scene", ", ", 
        "viewport = ", glscene.viewport[], ", ", 
        "clear = ", glscene.clear[], ", ", 
        "backgroundcolor = ", glscene.backgroundcolor[], ", ", 
        "visible = ", glscene.visible[], ", ", 
        "ssao = ..., ", 
        length(glscene.renderobjects), " RenderObjects",
        ")"
    )
end


# TODO: name? should we keep this separate from Screen?
struct GLSceneTree
    scene2index::Dict{WeakRef, Int}
    robj2plot::Dict{UInt32, AbstractPlot} # for picking
    
    # flattened scene tree
    # Order:
    # Scene        1
    #   Scene      2
    #     Scene    3
    #     Scene    4
    #       Scene  5
    #     Scene    6
    #   Scene      7
    #   Scene      8
    #     Scene    9
    scenes::Vector{GLScene}
    depth::Vector{Int}
end

GLSceneTree() = GLSceneTree(Dict{WeakRef, Int}(), Dict{UInt32, AbstractPlot}(), GLScene[], Int[])

function gc_cleanup(tree::GLSceneTree)
    @debug "WeakRef cleanup"
    # TODO: do we need this? Can this create orphaned child scenes?
    for k in copy(keys(tree.scene2index))
        if k === nothing
            # Remove scene from map
            index = pop!(tree.scene2index, WeakRef(scene))
        
            # Clean up RenderObjects (maps should get deleted with GLScene struct)
            foreach(destroy!, tree.scenes[index])

            # Remove GLScene (TODO: rendering parameters should not need cleanup? )
            deleteat!(tree.scenes, index)
            deleteat!(tree.depth, index)

            # Update mapping
            for (k, v) in tree.scene2index
                if v > index
                    tree.scene2index[k] -= 1
                end
            end
        end
    end
end

Base.haskey(tree::GLSceneTree, scene::Scene) = haskey(tree.scene2index, WeakRef(scene))
Base.getindex(tree::GLSceneTree, scene::Scene) = tree.scenes[tree.scene2index[WeakRef(scene)]]
Base.isempty(tree::GLSceneTree) = isempty(tree.scenes)

function Base.show(io::IO, tree::GLSceneTree)
    for i in eachindex(tree.scenes)
        println(io, "  " ^ tree.depth[i], "GLScene(", length(tree.scenes[i].renderobjects), ")")
    end
end

function insert_scene!(tree::GLSceneTree, scene::Scene, parent::Nothing, index::Integer)
    # a root scene can only be added if the screen does not already have a root scene
    @debug "Inserting root scene $(objectid(scene))"
    if isempty(tree.scenes)
        tree.scene2index[WeakRef(scene)] = 1
        push!(tree.scenes, GLScene(scene))
        push!(tree.depth, 1)
    else
        error("Cannot insert a root scene into a tree that already contains one.")
    end

    return
end

function insert_scene!(tree::GLSceneTree, scene::Scene, parent::Scene, index::Integer)
    @debug "Inserting scene $(objectid(scene))"
    if isempty(tree.scenes) # allow non-root scenes to act as root scenes
        tree.scene2index[WeakRef(scene)] = 1
        push!(tree.scenes, GLScene(scene))
        push!(tree.depth, 1)
        return
    elseif !haskey(tree.scene2index, WeakRef(parent))
        error("Cannot add a scene whose parent is not part of the displayed scene tree.")
    end

    @assert !isempty(tree.scenes) "An empty scene tree should not be reachable here."

    # Figure out where the scene should be inserted
    parent_index = tree.scene2index[WeakRef(parent)]
    insert_index = parent_index
    # @debug insert_index
    while (index > 0) && (insert_index < length(tree.scenes))
        # @debug "loop"
        insert_index += 1
        if tree.depth[insert_index] == tree.depth[parent_index] + 1
            # found a child of parent
            index -= 1
        elseif tree.depth[insert_index] == tree.depth[parent_index]
            # found a sibling of parent
            # we can insert here but no further down
            if index != 1
                error("Cannot insert scene because other children of its parent are missing.")
            end
            index -= 1
            break
        end
    end
    # @debug insert_index, tree.depth[insert_index], tree.depth[parent_index]
    if index == 1 && insert_index == length(tree.scenes)
        insert_index += 1
    elseif index != 0
        error("Failed to find scene insertion index.")
    end
    # @debug insert_index
    
    tree.scene2index[WeakRef(scene)] = insert_index
    insert!(tree.scenes, insert_index, GLScene(scene))
    insert!(tree.depth,  insert_index, tree.depth[parent_index] + 1)

    return
end

function delete_scene!(screen, tree::GLSceneTree, scene::Scene)
    @debug "Deleting scene $(objectid(scene))"
    if haskey(tree.scene2index, WeakRef(scene))
        # Delete all child scenes
        for child in scene.children
            delete_scene!(screen, tree, child)
        end

        # Remove scene from map
        index = pop!(tree.scene2index, WeakRef(scene))
        
        # Clean up RenderObjects (maps should get deleted with GLScene struct)
        glscene = tree.scenes[index]
        foreach(glscene.renderobjects) do robj
            delete!(tree.robj2plot, robj.id)
            destroy!(robj)
        end

        # Remove GLScene (TODO: rendering parameters should not need cleanup? )
        deleteat!(tree.scenes, index)
        deleteat!(tree.depth, index)

        # Update mapping
        for (k, v) in tree.scene2index
            if v > index
                tree.scene2index[k] -= 1
            end
        end

        # Remove screen from scene to avoid double-deletion
        filter!(x -> x !== screen, scene.current_screens)
    else
        @debug("Cannot delete scene from tree - does not exist in tree.")
    end
    return
end

function delete_plot!(tree::GLSceneTree, scene::Scene, plot::AbstractPlot)
    @debug("Deleting plot $(objectid(plot))")

    if haskey(tree, scene)
        glscene = tree[scene]
        for atomic in Makie.collect_atomic_plots(plot)
            if haskey(glscene.plot2robj, objectid(atomic))
                @debug "deleting atomic $(objectid(atomic))"
                robj = pop!(glscene.plot2robj, objectid(atomic))
                
                delete!(tree.robj2plot, robj.id)
                delete!(glscene.robj2plot, robj.id)
                
                filter!(x -> x !== robj, glscene.renderobjects)
                destroy!(robj)
            end
        end
    else
        @debug("Cannot delete plot if its parent scene is not being shown.")
    end
    return
end
