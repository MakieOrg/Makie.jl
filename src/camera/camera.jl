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
    for key in [:eyeposition, :upvector, :view_direction]
        add_input!(graph, key, Vec3d(0))
    end

    # TODO: Should we move viewport to the graph entirely?
    on(viewport -> update!(graph, viewport = viewport), scene, scene.viewport, update = true)
    for key in [:view, :projection, :eyeposition, :upvector, :view_direction]
        on(x -> update!(graph, key => x), scene, getproperty(scene.camera, key), update = true)
    end

    # TODO: Should we have px_per_unit + ppu_resolution in here? A float * Vec2d
    # isn't much to calculate so maybe not?
    # Note that this needs to exist without ppu too
    register_computation!(graph, [:viewport], [:scene_origin, :resolution]) do (viewport,), changed, cached
        return (Vec2d(origin(viewport)), Vec2d(widths(viewport)),)
    end

    # space to clip
    register_computation!(graph, [:projection, :view], [:world_to_clip]) do (viewport,), changed, cached
        return (projection * view,)
    end
    ComputePipeline.alias!(graph, :projection, :eye_to_clip)
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
        register_computation!(graph, [Symbol(key, :_to_clip)], [Symbol(:clip_to_, key)]) do input, changed, cached
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

    register_computation!(graph, [:view], [:world_to_eye]) do (view,), changed, cached
        return (view,)
    end
    register_computation!(graph, [:view], [:eye_to_world]) do (view,), changed, cached
        return (inv(view),)
    end

    # remaining off-diagonal elements
    for input in [:world, :eye, :pixel, :relative]
        for output in [:world, :eye, :pixel, :relative]
            if input != output && (input, output) != (:world, :eye) && (input, output) != (:eye, :world)
                register_computation!(
                    graph,
                    [Symbol(input, :_to_clip), Symbol(:clip_to_, output)],
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



function _has_camera_changed(changed, space, markerspace = space)
    is_data = is_data_space(space) || is_data_space(markerspace)
    is_pixel = is_pixel_space(space) || is_pixel_space(markerspace)
    return (is_data && (changed.view || changed.projection)) || (is_pixel && (changed.viewport))
end

function camera_trigger(inputs, changed, cached)
    view, projection, viewport, spaces... = inputs
    return _has_camera_changed(changed, spaces...) ? nothing : true
end

struct CameraMatrixCallback
    graph::ComputeGraph
end

function (cb::CameraMatrixCallback)((_, space), changed, cached)
    graph = cb.graph
    projectionview = get_projectionview(graph, space)
    projection = get_project(graph, space)
    view = get_view(graph, space)
    return (projectionview, projection, view)
end

function (cb::CameraMatrixCallback)((_, space, markerspace), changed, cached)
    graph = cb.graph
    # TODO: breaks FastPixel?
    preprojection = get_preprojection(graph, space, markerspace)
    projectionview = get_projectionview(graph, markerspace)
    projection = get_project(graph, markerspace)
    view = get_view(graph, markerspace)
    return (projectionview, projection, view, preprojection)
end

function register_camera!(plot_graph::ComputeGraph, scene_graph::ComputeGraph)
    # This should connect Computed's from the parent graph to a new Computed in the child graph
    inputs = [scene_graph.view, scene_graph.projection, scene_graph.viewport, plot_graph.space]
    haskey(plot_graph, :markerspace) && push!(inputs, plot_graph.markerspace)
    @assert inputs isa Vector{ComputeGraph.Computed}

    # Only propagate update from camera matrices if its relevant to space
    unsafe_register!(camera_trigger, plot_graph, inputs, [:camera_trigger])

    # Update camera matrices in plot if space changed or a relevant camera update happened
    input_keys = [:camera_trigger, :space]
    output_keys = [:projectionview, :projection, :view]
    if haskey(plot_graph, :markerspace)
        push!(input_keys, :markerspace)
        push!(output_keys, :preprojection)
    end
    callback = CameraMatrixCallback(scene_graph)
    register_computation!(callback, plot_graph, input_keys, output_keys)

    # Do we need those? Maybe also viewport?
    add_input!(plot_graph, :pixel_space, scene_graph.pixel_to_clip)
    for key in [:resolution, :scene_origin, :eyeposition, :upvector, :view_direction]
        # type assert for safety
        add_input!(plot_graph, key, getproperty(scene_graph, key)::Computed)
    end

    return
end

#=
Design Notes:

add_camera_computation!(scene.graph, scene)
- creates inputs for camera controller, scene.viewport
- calculates all space-to-space matrices
- calculates some utilities, e.g. resolution, scene_origin (no ppu)

register_camera!(plot_graph, scene_graph)
- creates a trigger which filters space-relevant camera updates from scene_graph in plot_graph
- pull view etc appropriate for the plots (marker)space via get_view(scene_graph, space)
- connects some more utilities, e.g. resolution
=#