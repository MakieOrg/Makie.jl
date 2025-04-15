# Node struct
struct DNode
    idx::Int
    position::Point2d
    children::Union{Tuple{Int,Int}, Nothing}
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
    "TODO: document"
    groups = nothing
    "Sets the position of the tree root."
    origin = Point2d(0)
    "Sets the color of branches with mixed groups if groups are defined."
    ungrouped_color = :gray

    MakieCore.documented_attributes(Lines)...
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

function plot!(plot::Dendrogram)
    branch_colors = map(plot, plot[1], plot.color, plot.groups) do nodes, color, groups
        if isnothing(groups)
            return to_color(color)
        else
            # Get a value per node, where each value matches the group values of
            # both children if they are the same or NaN if they differ
            return recursive_leaf_groups(nodes[end], nodes, groups)
        end
    end

    points_vec = Observable(Point2d[])
    colors_vec = map(plot,
            plot[1], plot.origin, plot.rotation, plot.branch_shape, branch_colors,
            transform_func_obs(plot)
        ) do nodes, origin, rotation, branch_shape, branch_colors, tf

        ps = empty!(points_vec[])

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
        if rotation isa Real;
            rot_angle = rotation
        elseif rotation === :down
            rot_angle = 0.0
        elseif rotation === :right
            rot_angle = pi/2
        elseif rotation === :up
            rot_angle = pi
        elseif rotation === :left
            rot_angle = 3pi/2
        else
            error("Rotation $rotation is not valid. Must be a <: Real or :down, :right, :up or :left.")
        end
        R = rotmatrix2d(rot_angle)

        # move root to (0, 0), rotate, then to origin
        root_pos = nodes[end].position
        for (i, p) in enumerate(ps)
            ps[i] = R * (p - root_pos) + origin
        end

        if tf isa Polar
            dim = ifelse(tf.theta_as_x, 1, 2)
            step = 2pi/180

            # downscale angles so that leaves spread across 0..2pi without overlap at 0/2pi
            # Nleaves = count(node -> isnothing(node.children), nodes)
            # mini, maxi = extrema(node -> node.position[dim], nodes)
            # angle_scale = 2pi * Nleaves / ((Nleaves + 1) * (maxi - mini))
            # scale = ifelse(tf.theta_as_x, Vec2d(angle_scale, 1), Vec2f(1, angle_scale))

            interpolated_points = similar(ps, 0)
            push!(interpolated_points, ps[1])
            interpolated_colors = similar(colors, 0)
            push!(interpolated_colors, colors[1])

            for i in 2:length(ps)
                # p0 = scale .* ps[i-1]
                # p1 = scale .* ps[i]
                p0 = ps[i-1]
                p1 = ps[i]

                if isnan(p0) || isnan(p1)
                    push!(interpolated_points, p1)
                    push!(interpolated_colors, colors[i])
                    continue
                end

                N = 1 + max(1, round(Int, abs(p1[dim] - p0[dim]) / step))
                if N == 2
                    push!(interpolated_points, p1)
                    push!(interpolated_colors, colors[i])
                else
                    append!(interpolated_points, range(p0, p1, length = N)[2:N])
                    if isnan(colors[i-1]) || isnan(colors[i])
                        append!(interpolated_colors, (colors[i-1] for _ in 2:N))
                    else
                        append!(interpolated_colors, range(colors[i-1], colors[i], length = N)[2:N])
                    end
                end
            end
            points_vec[] = interpolated_points
            colors = interpolated_colors
        else
            notify(points_vec)
        end

        return colors
    end

    attr = shared_attributes(plot, Lines)
    # Not sure if Attributes() replaces an entry with setindex!(attr, key, ::Observable)
    # or if it tries to be smart and updates, so pop!() to be safe
    pop!(attr, :color)
    attr[:color] = colors_vec

    # Set the default for nan_color. If groups are used, nan_color represents the
    # ungrouped case, :black. Otherwise it should follow the usual default :transparent
    if plot.groups[] !== nothing
        pop!(attr, :nan_color)
        attr[:nan_color] = plot.ungrouped_color
    end

    lines!(plot, attr, points_vec)
end


# branching styles

function dendrogram_connectors!(::Val{:tree}, points, parent, child1, child2)
    push!(points, child1.position, parent.position, child2.position)
end

function dendrogram_connectors!(::Val{:box}, points, parent::DNode, child1::DNode, child2::DNode)
    yp = parent.position[2]
    x1 = child1.position[1]
    x2 = child2.position[1]
    push!(points, child1.position, Point2d(x1, yp), Point2d(x2, yp), child2.position)
end

# Note: If wanted curved connections might be fairly easy to implemented with
#       convert_arguments(Lines, BezierPath(...))[1]

# convert utils

function find_merge(n1, n2; height=1)
    newx = min(n1[1], n2[1]) + abs((n1[1] - n2[1])) / 2
    newy = max(n1[2], n2[2]) + height
    return Point2d(newx, newy)
end

function find_merge(n1::DNode, n2::DNode; height=1, index=max(n1.idx, n2.idx)+1)
    newx = min(n1.position[1], n2.position[1]) + 0.5 * abs((n1.position[1] - n2.position[1]))
    newy = max(n1.position[2], n2.position[2]) + height

    return DNode(index, Point2d(newx, newy), (n1.idx, n2.idx))
end

function convert_arguments(::Type{<: Dendrogram}, leaves::Vector{<: VecTypes{2}}, merges::Vector{<: Tuple{<: Integer, <: Integer}})
    nodes = [DNode(i, n, nothing) for (i,n) in enumerate(leaves)]
    for m in merges
        push!(nodes, find_merge(nodes[m[1]], nodes[m[2]]; index = length(nodes)+1))
    end
    return (nodes,)
end

# TODO: PackageExtension?
function hcl_nodes(hcl; useheight=false)
    nleaves = length(hcl.order)
    nodes = [DNode(i, Point2d(x, 0), nothing) for (i,x) in enumerate(invperm(hcl.order))]

    for (m1, m2) in eachrow(hcl.merges)
        m1 = ifelse(m1 < 0, -m1, m1 + nleaves)
        m2 = ifelse(m2 < 0, -m2, m2 + nleaves)
        push!(nodes, find_merge(nodes[m1], nodes[m2]; index = length(nodes)+1))
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
