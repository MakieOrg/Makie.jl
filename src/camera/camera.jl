function Base.copy(x::Camera)
    Camera(ntuple(7) do i
        getfield(x, i)
    end...)
end

function Base.:(==)(a::Camera, b::Camera)
    to_value(a.view) == to_value(b.view) &&
    to_value(a.projection) == to_value(b.projection) &&
    to_value(a.resolution) == to_value(b.resolution)
end

function disconnect!(c::Camera)
    for node in c.steering_nodes
        filter!(listeners(node)) do x
            !(x isa CameraLift) # remove all camera lifts
        end
    end
    return
end

function disconnect!(nodes::Vector)
    for node in nodes
        disconnect!(node)
    end
    empty!(nodes)
    return
end

struct CameraLift{F, Args}
    f::F
    args::Args
end

function (cl::CameraLift{F, Args})(val) where {F, Args}
    cl.f(map(to_value, cl.args)...)
end

"""
    on(f, c::Camera, nodes::Node...)
When mapping over nodes for the camera, we store them in the `steering_node` vector,
to make it easier to disconnect the camera steering signals later!
"""
function Observables.on(f, c::Camera, nodes::Node...)
    # this basically reimplements onany, which is a bit annoying, but like
    # this we don't have such a closure hell and CameraLift will be nicely
    # identifiable when we disconnect the nodes!
    cl = CameraLift(f, nodes)
    for n in nodes
        on(cl, n)
    end
    push!(c.steering_nodes, nodes...)
    return f
end

function Camera(px_area)
    pixel_space = lift(px_area) do window_size
        nearclip = -10_000f0
        farclip = 10_000f0
        w, h = Float32.(widths(window_size))
        return orthographicprojection(0f0, w, 0f0, h, nearclip, farclip)
    end
    Camera(
        pixel_space,
        Node(Mat4f0(I)),
        Node(Mat4f0(I)),
        Node(Mat4f0(I)),
        lift(a-> Vec2f0(widths(a)), px_area),
        Node(Vec3f0(1)),
        []
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
