function Base.copy(x::Camera)
    Camera(ntuple(6) do i
        getfield(x, i)
    end...)
end
function Base.:(==)(a::Camera, b::Camera)
    to_value(a.view) == to_value(b.view) &&
    to_value(a.projection) == to_value(b.projection) &&
    to_value(a.resolution) == to_value(b.resolution)
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
function lift(f, c::Camera, nodes::Node...)
    node = lift(f, nodes...)
    push!(c.steering_nodes, node)
    node
end

function Camera(px_area)
    Camera(
        Node(Mat4f0(I)),
        Node(Mat4f0(I)),
        Node(Mat4f0(I)),
        lift(a-> Vec2f0(widths(a)), px_area),
        Node(Vec3f0(1)),
        Node[]
    )
end





function is_mouseinside(scene, target)
    scene === target && return false
    Vec(scene.events.mouseposition[]) in pixelarea(scene)[] || return false
    for child in r.children
        is_mouseinside(child, target) && return true
    end
    return false
end
function is_mouseinside(scene)
    return Vec(scene.events.mouseposition[]) in pixelarea(scene)[]
    # Check that mouse is not inside any other screen
    # for child in scene.children
    #     is_mouseinside(child) && return false
    # end
end
