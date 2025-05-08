function Base.copy(x::Camera)
    Camera(ntuple(11) do i
        getfield(x, i)
    end...)
end

function Base.:(==)(a::Camera, b::Camera)
    to_value(a.view) == to_value(b.view) &&
    to_value(a.projection) == to_value(b.projection) &&
    to_value(a.resolution) == to_value(b.resolution)
end

function Base.show(io::IO, camera::Camera)
    println(io, "Camera:")
    println(io, "  $(length(camera.steering_nodes)) steering observables connected")
    println(io, "  pixel_space: ", camera.pixel_space[])
    println(io, "  view: ", camera.view[])
    println(io, "  projection: ", camera.projection[])
    println(io, "  projectionview: ", camera.projectionview[])
    println(io, "  resolution: ", camera.resolution[])
    println(io, "  eyeposition: ", camera.eyeposition[])
    println(io, "  view direction: ", camera.view_direction[])
end

function disconnect!(c::Camera)
    for obsfunc in c.steering_nodes
        off(obsfunc)
    end
    empty!(c.steering_nodes)
    return
end

function disconnect!(c::EmptyCamera)
    return
end

function disconnect!(observables::Vector)
    for obs in observables
        disconnect!(obs)
    end
    empty!(observables)
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
    on(f, c::Camera, observables::Observable...)

When mapping over observables for the camera, we store them in the `steering_node` vector,
to make it easier to disconnect the camera steering signals later!
"""
function Observables.on(f, camera::Camera, observables::AbstractObservable...; priority=0)
    # PriorityObservables don't implement on_any, because that would replace
    # the method in Observables. CameraLift acts as a workaround for now.
    cl = CameraLift(f, observables)
    for n in observables
        obs = on(cl, n, priority=priority)
        push!(camera.steering_nodes, obs)
    end
    return f
end

function Camera(viewport)
    pixel_space = lift(viewport) do window_size
        nearclip = -10_000.0
        farclip = 10_000.0
        w, h = Float64.(widths(window_size))
        return orthographicprojection(0.0, w, 0.0, h, nearclip, farclip)
    end
    view = Observable(Mat4d(I))
    proj = Observable(Mat4d(I))
    proj_view = map(*, proj, view)
    return Camera(
        pixel_space,
        view,
        proj,
        proj_view,
        lift(a-> Vec2f(widths(a)), viewport),
        Observable(Vec3f(0, 0, -1)),
        Observable(Vec3f(1)),
        Observable(Vec3f(0, 1, 0)),
        ObserverFunction[],
        Dict{Symbol, Observable{Mat4f}}(),
        Dict{Float64,Observable{Vec2f}}()
    )
end

function set_proj_view!(camera::Camera, projection, view)
    # hack, to not double update projectionview
    # TODO, this makes code doing on(view), not work correctly...
    # But nobody should do that, right?
    # GLMakie uses map on view
    camera.view[] = view
    camera.projection[] = projection
end

is_mouseinside(x, target) = is_mouseinside(get_scene(x), target)
function is_mouseinside(scene::Scene, target)
    scene === target && return false
    Vec(scene.events.mouseposition[]) in viewport(scene)[] || return false
    for child in r.children
        is_mouseinside(child, target) && return true
    end
    return false
end

"""
    is_mouseinside(scene)

Returns true if the current mouseposition is inside the given scene.
"""
is_mouseinside(x) = is_mouseinside(get_scene(x))
function is_mouseinside(scene::Scene)
    return scene.visible[] && in(Vec(scene.events.mouseposition[]), viewport(scene)[])
    # Check that mouse is not inside any other screen
    # for child in scene.children
    #     is_mouseinside(child) && return false
    # end
end


function add_camera_computation!(graph::ComputeGraph, scene)
    # This includes all combinations of:
    # [world, eye, pixel, relative, clip] to [world, eye, pixel, relative, clip]

    # Inputs to be set by camera controller/scene
    add_input!(graph, :view, Mat4d(I))
    add_input!(graph, :projection, Mat4d(I))
    add_input!(graph, :viewport, Rect2d(0,0,0,0))


    # TODO: Should we move viewport to the graph entirely?
    on(viewport -> update!(graph, :viewport = viewport), scene, scene.viewport)

    # TODO: Should we have px_per_unit + ppu_resolution in here? A float * Vec2d
    # isn't much to calculate so maybe not?
    # Note that this needs to exist without ppu too
    register_computation!(graph, [:viewport], [:resolution]) do (viewport,), changed, cached
        return (Vec2d(widths(viewport)),)
    end

    # space to clip
    alias!(graph, :projectionview, :world_to_clip)
    alias!(graph, :projection, :eye_to_clip)
    register_computation!(graph, [:resolution], [:pixel_to_clip]) do (resolution,), changed, cached
        nearclip = -10_000.0
        farclip = 10_000.0
        w, h = resolution
        return (orthographicprojection(0.0, w, 0.0, h, nearclip, farclip),)
    end
    register_computation!(graph, Symbol[], [:relative_to_clip]) do input, changed, cached
        return (Mat4d(2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 1, 0, -1, -1, 0, 1),)
    end

    # space to space (identities)
    for key in [:world, :eye, :pixel, :relative, :clip]
        register_computation!(graph, Symbol[], [Symbol(key, :_to_, key)]) do input, changed, cached
            return (Mat4d(I),)
        end
    end

    # clip to space
    for key in [:world, :eye]
        register_computation!(graph, [:projectionview], [Symbol(:clip_to_, key)]) do input, changed, cached
            return (inv(input[1]),)
        end
    end
    register_computation!(graph, [:resolution], [:clip_to_pixel]) do (resolution,), changed, cached
        w, h = resolution
        return (Mat4d(0.5w, 0, 0, 0, 0, 0.5h, 0, 0, 0, 0, -10_000, 0, 0.5w, 0.5h, 0, 1),)
    end
    register_computation!(graph, Symbol[], [:clip_to_relative]) do input, changed, cached
        return (Mat4d(0.5, 0, 0, 0, 0, 0.5, 0, 0, 0, 0, 1, 0, 0.5, 0.5, 0, 1),)
    end

    # remaining off-diagonal elements
    for input in [:eye, :pixel, :relative]
        for output in [:eye, :pixel, :relative]
            if input != output
                register_computation!(
                    graph,
                    [Symbol(input, :_to_clip), Symbol(:clip_to, :output)],
                    [Symbol(input, :_to_, output)]
                ) do (input_to_clip, clip_to_output), changed, cached
                    # Reminder: This applies right to left `clip_to_output * (input_to_clip * input)`
                    return (clip_to_output * input_to_clip)
                end
            end
        end
    end

    return graph
end

#=
projection pipelines:
       view            projection
world ------>   eye   -----------> clip
               pixel  -----------> clip
             relative -----------> clip
=#


get_projectionview(graph::ComputeGraph, space::Symbol) = graph[Symbol(space, :_to_clip)][]
get_pixelspace(graph::ComputeGraph) = graph[:pixel_to_clip][]

function get_projection(graph::ComputeGraph, space::Symbol)
    key = ifelse(space === :data, :eye_to_clip, Symbol(space, :_to_clip))
    return graph[key][]
end

function get_view(graph::ComputeGraph, space::Symbol)
    # or :eye_to_eye for the else case
    return space === :data ? graph[Symbol(:data_to_eye)][] : Mat4d(I)
end

function get_preprojection(graph::ComputeGraph, space::Symbol, markerspace::Symbol)
    return graph[Symbol(space, :_to_, markerspace)][]
end

#=
Idea: Do something like:
register_computation!(graph, [:camera, ...], ...) do ...
    has_camera_changed(graph, space[, markerspace]) || return nothing
end

Problem:
The inputs may get resolved between the :camera becoming dirty and the runtime
of the function, so has_camera_changed() may be incorrect
=#
function has_camera_changed(graph, space::Symbol, markerspace::Symbol = space)
    has_changed = false

    is_data = is_data_space(space) || is_data_space(markerspace)
    has_changed = has_changed || (is_data && ComputePipeline.isdirty(graph[:view]))
    has_changed = has_changed || (is_data && ComputePipeline.isdirty(graph[:projection]))

    is_pixel = is_pixel_space(space) || is_pixel_space(markerspace)
    has_changed = has_changed || (is_pixel && ComputePipeline.isdirty(graph[:viewport]))

    return has_changed
end