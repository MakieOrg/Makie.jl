function Base.copy(x::Camera)
    Camera(ntuple(6) do i
        getfield(x, i)
    end...)
end
function Base.:(==)(a::Camera, b::Camera)
    value(a.view) == value(b.view) &&
    value(a.projection) == value(b.projection) &&
    value(a.resolution) == value(b.resolution)
end
function disconnect!(c::Camera)
    disconnect!(c.steering_nodes)
    return
end
function disconnect!(nodes::Vector)
    for node in nodes
        disconnect!(node)
    end
    empty!(nodes)
    return
end

"""
When mapping over nodes for the camera, we store them in the steering_node vector,
to make it easier to disconnect the camera steering signals later!
"""
function Base.map(f, c::Camera, nodes::Node...)
    node = map(f, nodes...)
    push!(c.steering_nodes, node)
    node
end

function Camera(px_area)
    Camera(
        Node(Mat4f0(I)),
        Node(Mat4f0(I)),
        Node(Mat4f0(I)),
        map(a-> Vec2f0(widths(a)), px_area),
        Node(Vec3f0(1)),
        Node[]
    )
end
