# Node struct
struct DNode
    idx::Int
    position::Point2d
    children::Union{Tuple{Int, Int}, Nothing}
end

"""
    dendrogram(positions, merges)
    dendrogram(x, y, merges)

Draw a [dendrogram](https://en.wikipedia.org/wiki/Dendrogram) with leaf nodes
specified by `positions` and parent nodes identified by `merges`.

`merges` contain pairs of indices `(i, j)` which connect to a new parent node.
That node is then added to the list and can be merged with another.

Note that this recipe is still experimental and subject to change in the future.
"""
@recipe Dendrogram (nodes,) begin
    """
    Specifies how node connections are drawn. Can be `:tree` for direct lines or `:box` for
    rectangular lines. Other styles can be defined by overloading
    `dendrogram_connectors!(::Val{:mystyle}, points, parent, child1, child2)` which should
    add the points connecting the parent node to its children to `points`.
    """
    branch_shape = :box
    """
    Sets the rotation of the dendrogram, i.e. where the leaves are relative to the root.
    Can be `:down`, `:right`, `:up`, `:left` or a float.
    """
    rotation = :down
    "Sets the position of the tree root."
    origin = Point2d(0)
    """
    Scales the dendrogram so that the maximum distance between leaf nodes is `width`.
    By default no scaling is applied, i.e. the width of the dendrogram is defined
    by its arguments.
    """
    width = automatic
    """
    Scales the dendrogram so that the maximum distance between the root node and
    leaf nodes is `depth`. By default no scaling is applied, i.e. the depth or
    height of the dendrogram is derived from the given nodes and connections.
    (For this each parent node is at least 1 unit above its children.)
    """
    depth = automatic
    """
    Sets a group id for each leaf node. Branches that merge nodes of the same
    group will use their group to look up a color in the given colormap. Branches
    that merge different groups will use `ungrouped_color`.
    """
    groups = nothing
    "Sets the color of branches with mixed groups if groups are defined."
    ungrouped_color = :gray

    documented_attributes(Lines)...
end

function dendrogram_points!(ret_points, nodes, branch_shape, branch_color_groups)
    # If an explicit color is given we don't need to repeat anything, i.e. we
    # don't need to construct a new array.
    # This can be a <: Colorant, Vector{<: Colorant} or Vector{<: Real}
    colors = branch_color_groups isa Colorant ? branch_color_groups : similar(branch_color_groups, 0)
    recursive_dendrogram_points!(
        ret_points, colors, nodes[end],
        nodes, branch_shape, branch_color_groups
    )
    return colors
end

function recursive_dendrogram_points!(ret_points, ret_colors, node, nodes, branch_shape, branch_groups)
    isnothing(node.children) && return
    child1 = nodes[node.children[1]]
    child2 = nodes[node.children[2]]

    # Add branch connection points
    N = length(ret_points)
    dendrogram_connectors!(Val(branch_shape), ret_points, node, child1, child2)
    push!(ret_points, Point2d(NaN)) # separate segments
    N = length(ret_points) - N

    # If colors are defined per node, repeat them to be per point
    if ret_colors isa Vector
        append!(ret_colors, (branch_groups[node.idx] for _ in 1:N))
    end

    recursive_dendrogram_points!(ret_points, ret_colors, child1, nodes, branch_shape, branch_groups)
    recursive_dendrogram_points!(ret_points, ret_colors, child2, nodes, branch_shape, branch_groups)
    return
end

resample_for_transform(tf, args...; step = nothing) = args
function resample_for_transform(tf::Polar, ps, args...; step = 2pi / 180)
    isempty(ps) && return (ps, args...)

    interpolated_points = similar(ps, 0)
    push!(interpolated_points, ps[1])
    interpolated_args = map(x -> similar(x, 0), args)
    for (old, new) in zip(args, interpolated_args)
        push!(new, old[1])
    end

    dim = ifelse(tf.theta_as_x, 1, 2)
    for i in 2:length(ps)
        p0 = ps[i - 1]
        p1 = ps[i]

        if isnan(p0) || isnan(p1)
            push!(interpolated_points, p1)
            for (old, new) in zip(args, interpolated_args)
                push!(new, old[i])
            end
            continue
        end

        N = 1 + max(1, round(Int, abs(p1[dim] - p0[dim]) / step))
        if N == 2
            push!(interpolated_points, p1)
            for (old, new) in zip(args, interpolated_args)
                push!(new, old[i])
            end
        else
            append!(interpolated_points, range(p0, p1, length = N)[2:N])
            for (old, new) in zip(args, interpolated_args)
                if isnan(old[i - 1]) || isnan(old[i])
                    append!(new, (old[i - 1] for _ in 2:N))
                else
                    append!(new, range(old[i - 1], old[i], length = N)[2:N])
                end
            end
        end
    end

    return (interpolated_points, interpolated_args...)
end

_parse_dendrogram_scale(nodes, width::Automatic) = 1.0
_parse_dendrogram_scale(nodes, width) = error("Incorrect type for Dendrogram width or depth. Must be automatic or Real, but is $(typeof(width)).")
function _parse_dendrogram_scale(nodes, width::Real)
    # TODO: Should we consider connections? (check positions instead of nodes)
    mini, maxi = extrema(node -> node.position[1], nodes)
    return width / (maxi - mini)
end

function Makie.plot!(plot::Dendrogram)

    map!(plot.attributes, [:nodes, :color, :groups], :branch_colors) do nodes, color, groups
        if isnothing(groups)
            return to_color(color)
        else
            # Get a value per node, where each value matches the group values of
            # both children if they are the same or NaN if they differ
            return recursive_leaf_groups(nodes[end], nodes, groups)
        end
    end

    inputs = [:nodes, :origin, :rotation, :branch_shape, :branch_colors, :transform_func, :width, :depth]

    map!(plot.attributes, inputs, [:node_points, :line_points, :line_colors]) do nodes, _origin, rotation, branch_shape, branch_colors, tf, width, depth

        ps = Point2d[]
        origin = to_ndim(Vec2f, _origin, 0)

        # Generate positional data that connect branches of the tree. If colors are
        # given per node (either directly or through grouping) repeat their values
        # to match up with the branches
        colors = dendrogram_points!(ps, nodes, branch_shape, branch_colors)

        # force rotation to work with Polar transform
        if tf isa Polar
            rotation = ifelse(tf.theta_as_x, :up, :right)
            r_dim = ifelse(tf.theta_as_x, 2, 1)
            origin[r_dim] >= 0.0 || error("The origin of a dendrogram must not be at a negative radius in polar coordinates.")
        end

        # parse rotation, construct rotation matrix
        if rotation isa Real
            rot_angle = rotation
        elseif rotation === :down
            rot_angle = 0.0
        elseif rotation === :right
            rot_angle = pi / 2
        elseif rotation === :up
            rot_angle = pi
        elseif rotation === :left
            rot_angle = 3pi / 2
        else
            error("Rotation $rotation is not valid. Must be a <: Real or :down, :right, :up or :left.")
        end
        R = rotmatrix2d(rot_angle)

        # parse scaling
        scale = Vec2d(_parse_dendrogram_scale(nodes, width), _parse_dendrogram_scale(nodes, depth))

        # move root to (0, 0), scale, then rotate, then move to origin
        root_pos = nodes[end].position
        for (i, p) in enumerate(ps)
            ps[i] = R * (scale .* (p - root_pos)) + origin
        end

        if colors isa Vector
            points, colors = resample_for_transform(tf, ps, colors)
        else
            points = resample_for_transform(tf, ps)[1]
        end

        # TODO: or keep track of which points are node points in ps/points
        node_points = [R * (scale .* (node.position - root_pos)) + origin for node in nodes]

        return (node_points, points, colors)
    end

    attr = shared_attributes(plot, Lines)

    return lines!(plot, attr, plot.line_points, color = plot.line_colors, nan_color = plot.ungrouped_color)
end


# branching styles

function dendrogram_connectors!(::Val{:tree}, points, parent, child1, child2)
    return push!(points, child1.position, parent.position, child2.position)
end

function dendrogram_connectors!(::Val{:box}, points, parent::DNode, child1::DNode, child2::DNode)
    yp = parent.position[2]
    x1 = child1.position[1]
    x2 = child2.position[1]
    return push!(points, child1.position, Point2d(x1, yp), Point2d(x2, yp), child2.position)
end

# Note: If wanted curved connections might be fairly easy to implemented with
#       convert_arguments(Lines, BezierPath(...))[1]

# convert utils

function find_merge(n1, n2; height = 1)
    newx = min(n1[1], n2[1]) + abs((n1[1] - n2[1])) / 2
    newy = max(n1[2], n2[2]) + height
    return Point2d(newx, newy)
end

function find_merge(n1::DNode, n2::DNode; height = 1, index = max(n1.idx, n2.idx) + 1)
    newx = min(n1.position[1], n2.position[1]) + 0.5 * abs((n1.position[1] - n2.position[1]))
    newy = max(n1.position[2], n2.position[2]) + height

    return DNode(index, Point2d(newx, newy), (n1.idx, n2.idx))
end

function convert_arguments(::Type{<:Dendrogram}, x::RealVector, y::RealVector, merges::Vector{<:Tuple{<:Integer, <:Integer}})
    return convert_arguments(Dendrogram, convert_arguments(PointBased(), x, y)[1], merges)
end

function convert_arguments(::Type{<:Dendrogram}, leaves::Vector{<:VecTypes{2}}, merges::Vector{<:Tuple{<:Integer, <:Integer}})
    nodes = [DNode(i, n, nothing) for (i, n) in enumerate(leaves)]
    for m in merges
        push!(nodes, find_merge(nodes[m[1]], nodes[m[2]]; index = length(nodes) + 1))
    end
    return (nodes,)
end

# TODO: PackageExtension?
function hcl_nodes(hcl; useheight = false)
    nleaves = length(hcl.order)
    nodes = [DNode(i, Point2d(x, 0), nothing) for (i, x) in enumerate(invperm(hcl.order))]
    # Not the cleanest implementation. It may be better to instead change
    # find_merge(n1::DNode, n2::DNode; height = 1, index = max(n1.idx, n2.idx) + 1)
    # I leave it up to the council.
    for ((m1, m2), height) in zip(eachrow(hcl.merges), hcl.heights)
        m1 = ifelse(m1 < 0, -m1, m1 + nleaves)
        m2 = ifelse(m2 < 0, -m2, m2 + nleaves)
        max_height = height - max(nodes[m1].position[2], nodes[m2].position[2])
        merge = find_merge(
            nodes[m1], nodes[m2];
            height = ifelse(useheight, max_height, 1),
            index = length(nodes) + 1
        )
        push!(nodes, merge)
    end

    return nodes
end

function recursive_leaf_groups(node, nodes, groups::AbstractArray{T}) where {T}
    output = Vector{Float32}(undef, length(nodes))
    recursive_leaf_groups!(output, node, nodes, groups)
    return output
end

function recursive_leaf_groups!(output, node, nodes, groups)
    # group of a branch is based on its children. If all have the same group,
    # that group is used, otherwise it is marked as invalid/ungrouped (NaN)
    if isnothing(node.children)
        value = groups[node.idx]
        output[node.idx] = value
        return value
    else
        right = recursive_leaf_groups!(output, nodes[node.children[2]], nodes, groups)
        left = recursive_leaf_groups!(output, nodes[node.children[1]], nodes, groups)
        value = ifelse(left == right, left, NaN)
        output[node.idx] = value
        return value
    end
end

"""
    dendrogram_node_positions(dendrogram)

Returns an Observable that tracks the positions of all dendrogram nodes. This
includes translations from `origin`, `rotation` and scaling from `width` and
`depth`. The N nodes given as arguments are the first N positions returned.
"""
dendrogram_node_positions(plot::Dendrogram) = plot.node_points
