"""
    dendrogram(x, y; kwargs...)

Draw a [dendrogram](https://en.wikipedia.org/wiki/Dendrogram),
with leaf nodes specified by `x` and `y` coordinates,
and parent nodes identified by `merges`.

# Arguments
- `x`: x positions of leaf nodes
- `y`: y positions of leaf nodes (default = 0)
# Keywords
- `merges`: specifies connections between nodes (see below)
- `treestyle`: one of `:??`, `:??` 

# Extended help

$(ATTRIBUTES)
"""
@recipe(Dendrogram, x, y) do scene
    Theme(
        weights = automatic,
        color = Makie.inherit(scene, :color, :black),
        colormap = Makie.inherit(scene, :colormap, :viridis),
        colorrange = automatic,
        orientation = :vertical,
        strokecolor = Makie.inherit(scene, :strokecolor, :black),
        strokewidth = Makie.inherit(scene, :strokewidth, 1.0),
        cycle = [:color => :patchcolor],
        inspectable = Makie.inherit(scene, :inspectable)
    )
end

conversion_trait(x::Type{<:Dendrogram}) = SampleBased() #??

function Makie.plot!(plot::Dendrogram)
    args = @extract plot (weights, width, range, show_outliers, whiskerwidth, show_notch, orientation, gap, dodge, n_dodge, dodge_gap)

end

##############
# Playground #
##############

struct DNode
    idx::Int
    x::Float32
    y::Float32
    children::Union{Tuple{Int,Int}, Nothing}
end

function find_merge(n1, n2; height=1)
    newx = min(n1[1], n2[1]) + abs((n1[1] - n2[1])) / 2
    newy = max(n1[2], n2[2]) + height
    return Point2f(newx, newy)
end

function find_merge(n1::DNode, n2::DNode; height=1, index=max(n1.idx, n2.idx)+1)
    newx = min(n1.x, n2.x) + abs((n1.x - n2.x)) / 2
    newy = max(n1.y, n2.y) + height

    return DNode(index, Point2f(newx, newy)..., (n1.idx, n2.idx))
end


function get_tree_connectors(parent, child1, child2)
    return [(child1.x, child1.y), (parent.x, parent.y), (child2.x, child2.y)]
end

function get_box_connectors(parent, child1, child2)
    yp = parent.y
    x1 = child1.x
    x2 = child2.x

    return [(x1, child1.y), (x1, yp), (x2, yp), (x2, child2.y)]
end

function recursive_draw_dendrogram!(ax, node, nodes; branch_shape=:tree)
    isnothing(node.children) && return nothing
    child1 = nodes[node.children[1]]
    child2 = nodes[node.children[2]]
   
    l = branch_shape == :tree ? get_tree_connectors(node, child1, child2) :
        branch_shape == :box  ? get_box_connectors(node, child1, child2) : error()
    
    lines!(ax, l)

    recursive_draw_dendrogram!(ax, child1, nodes; branch_shape)
    recursive_draw_dendrogram!(ax, child2, nodes; branch_shape)
    return nothing
end


function dendrogram(leaves, merges; branch_shape=:tree)
    nodes = Dict(i => DNode(i, n[1], n[2], nothing) for (i,n) in enumerate(leaves))
    nm = maximum(keys(nodes))

    for m in merges
        nm += 1
        nodes[nm] = find_merge(nodes[m[1]], nodes[m[2]]; index = nm)
    end

    dendrogram(nodes; branch_shape)
end


function dendrogram(nodes::Dict{Int, DNode}; branch_shape=:tree)
    ax = Axis(Figure()[1,1])    
    recursive_draw_dendrogram!(ax, nodes[maximum(keys(nodes))], nodes; branch_shape)
    current_figure()
end


function hcl_nodes(hcl; useheight=false)
    nleaves = length(hcl.order)
    nodes = Dict(i => DNode(i, x, 0, nothing) for (i,x) in enumerate(invperm(hcl.order)))
    nm = maximum(keys(nodes))

    for (m1, m2) in eachrow(hcl.merges)
        nm += 1
        
        m1 = m1 < 0 ? -m1 : m1 + nleaves
        m2 = m2 < 0 ? -m2 : m2 + nleaves
        nodes[nm] = find_merge(nodes[m1], nodes[m2]; index=nm)            
    end

    return nodes
end
