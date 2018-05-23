function Base.copy(x::Camera)
    Camera(ntuple(6) do i
        getfield(x, i)
    end...)
end

function disconnect!(c::Camera)
    for node in c.steering_nodes
        disconnect!(node)
    end
    empty!(c.steering_nodes)
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
        Node(eye(Mat4f0)),
        Node(eye(Mat4f0)),
        Node(eye(Mat4f0)),
        map(a-> Vec2f0(widths(a)), px_area),
        Node(Vec3f0(1)),
        Node[]
    )
end
