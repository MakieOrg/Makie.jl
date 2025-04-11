# Node struct
struct DNode{N}
    idx::Int
    position::Point{N, Float64}
    children::Union{Tuple{Int,Int}, Nothing}
end

function DNode(idx::Int, point::Point{N}, children::Union{Tuple{Int,Int}, Nothing}) where N
    return DNode{N}(idx, point, children)
end

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
"""
@recipe Dendrogram begin
    "TODO: document"
    weights = Makie.automatic
    """
    Specifies how node connections are drawn. Can be `:tree` for direct lines or `:box` for
    rectangular lines. Other styles can be defined by overloading
    `dendrogram_connectors(::Val{:mystyle}, parent, child1, child2)` which should return a
    Vector of points connecting the parent to its children.
    """
    branch_shape = :box
    "TODO: document"
    orientation = :vertical
    "TODO: document"
    groups = nothing

    MakieCore.documented_attributes(Lines)...
end

function recursive_dendrogram_points(
        node::DNode{D}, nodes, ret_points::Vector{<: VecTypes{D}}, ret_colors;
        color=:black, branch_shape=:tree, groups=nothing
    ) where {D}

    isnothing(node.children) && return
    child1 = nodes[node.children[1]]
    child2 = nodes[node.children[2]]

    l = dendrogram_connectors(Val(branch_shape), node, child1, child2)

    # even if the inputs are 2d, the outputs should be 3d - this is what `to_ndim` does.
    append!(ret_points, to_ndim.(Point{D, Float64}, l, 0))
    push!(ret_points, Point{D, Float64}(NaN)) # separate segments

    if isnothing(groups)
        cgroup = 0
    else
        gs = recursive_leaf_groups(node, nodes, groups)
        @debug gs
        cgroup = length(unique(gs)) == 1 ? first(gs) : 0
    end

    @debug cgroup maxlog=2

    append!(ret_colors, [cgroup for _ in 1:length(l)])
    push!(ret_colors, NaN32) # separate segments

    recursive_dendrogram_points(child1, nodes, ret_points, ret_colors; branch_shape, groups)
    recursive_dendrogram_points(child2, nodes, ret_points, ret_colors; branch_shape, groups)
end


function Makie.plot!(plot::Dendrogram{<: Tuple{<: Vector{<: DNode{D}}}}) where {D}
    args = @extract plot (color, groups)

    points_vec = Observable(Point{D, Float64}[])
    colors_vec = Observable(Float32[])

    onany(plot[1], plot.branch_shape, plot[:color], update = true) do nodes, branch_shape, color
        empty!(points_vec[])
        empty!(colors_vec[])

        # this pattern is basically first updating the values of the observables,
        recursive_dendrogram_points(
            nodes[end], nodes, points_vec[], colors_vec[];
            color, branch_shape, groups=groups[]
        )

        # then propagating the signal, so that there is no error with differing lengths.
        notify(points_vec); notify(colors_vec)
    end


    lines!(plot, points_vec;
        color = colors_vec, colormap = plot.colormap, colorrange = plot.colorrange,
        linewidth = plot.linewidth, inspectable = plot.inspectable
    )
end


# branching styles

function dendrogram_connectors(::Val{:tree}, parent, child1, child2)
    return [child1.position, parent.position, child2.position]
end

function dendrogram_connectors(::Val{:box}, parent::DNode{2}, child1::DNode{2}, child2::DNode{2})
    yp = parent.position[2]
    x1 = child1.position[1]
    x2 = child2.position[1]

    return Point2d[child1.position, (x1, yp), (x2, yp), child2.position]
end

function dendrogram_connectors(::Val{:box}, parent::DNode{3}, child1::DNode{3}, child2::DNode{3})
    yp = parent.position[2]
    x1 = child1.position[1]
    x2 = child2.position[1]

    return Point3d[
        child1.position,
        (x1, yp, 0.5 * (parent.position[3] + child1.position[3])),
        (x2, yp, 0.5 * (parent.position[3] + child2.position[3])),
        child2.position
    ]
end


# convert utils

function find_merge(n1, n2; height=1)
    newx = min(n1[1], n2[1]) + abs((n1[1] - n2[1])) / 2
    newy = max(n1[2], n2[2]) + height
    return Point2d(newx, newy)
end

function find_merge(n1::DNode{2}, n2::DNode{2}; height=1, index=max(n1.idx, n2.idx)+1)
    newx = min(n1.position[1], n2.position[1]) + 0.5 * abs((n1.position[1] - n2.position[1]))
    newy = max(n1.position[2], n2.position[2]) + height

    return DNode{2}(index, Point2d(newx, newy), (n1.idx, n2.idx))
end

function find_merge(n1::DNode{3}, n2::DNode{3}; height=1, index=max(n1.idx, n2.idx)+1)
    newx = min(n1.position[1], n2.position[1]) + 0.5 * abs((n1.position[1] - n2.position[1]))
    newy = max(n1.position[2], n2.position[2]) + height
    newz = min(n1.position[3], n2.position[3]) + 0.5 * abs((n1.position[3] - n2.position[3]))

    return DNode{3}(index, Point3d(newx, newy, newz), (n1.idx, n2.idx))
end

function convert_arguments(::Type{<: Dendrogram}, leaves::Vector{<: Point}, merges::Vector{<: Tuple{<: Integer, <: Integer}})
    nodes = [DNode(i, n, nothing) for (i,n) in enumerate(leaves)]
    for m in merges
        push!(nodes, find_merge(nodes[m[1]], nodes[m[2]]; index = length(nodes)+1))
    end
    return (nodes,)
end


# function hcl_nodes(hcl; useheight=false)
#     nleaves = length(hcl.order)
#     nodes = Dict(i => DNode(i, Point2d(x, 0), nothing) for (i,x) in enumerate(invperm(hcl.order)))
#     nm = maximum(keys(nodes))

#     for (m1, m2) in eachrow(hcl.merges)
#         nm += 1

#         m1 = ifelse(m1 < 0, -m1, m1 + nleaves)
#         m2 = ifelse(m2 < 0, -m2, m2 + nleaves)
#         nodes[nm] = find_merge(nodes[m1], nodes[m2]; index=nm)
#     end

#     return nodes
# end

recursive_leaf_groups(node, nodes, groups::Nothing) = 0
function recursive_leaf_groups(node, nodes, groups::AbstractArray{T}) where {T}
    output = recursive_leaf_groups!(T[], node, nodes, groups)
    return output
end

function recursive_leaf_groups!(output, node, nodes, groups)
    if isnothing(node.children)
        push!(output, groups[node.idx])
    else
        recursive_leaf_groups!(output, nodes[node.children[1]], nodes, groups)
        recursive_leaf_groups!(output, nodes[node.children[2]], nodes, groups)
    end
    return output
end
