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
    # TODO: Should we move viewport to the graph entirely?
    add_input!(graph, :viewport, scene.viewport)

    for key in [:view, :projection, :eyeposition, :upvector, :view_direction]
        add_input!(graph, key, getproperty(scene.camera, key))
    end

    register_computation!(graph, [:viewport], [:scene_origin, :resolution]) do (viewport,), changed, cached
        return (Vec2d(origin(viewport)), Vec2d(widths(viewport)),)
    end

    # Camera matrices
    # TODO: consider aliasing view, projection
    register_computation!(
            graph, [:projection, :view], [:world_to_clip, :world_to_eye, :eye_to_clip]
        ) do (projection, view), changed, cached

        return (projection * view, view, projection)
    end
    register_computation!(
            graph, [:projection, :view],
            [:clip_to_world, :eye_to_world, :clip_to_eye]
        ) do (projection, view), changed, cached

        # are there accuracy issues with inv first?
        iview = inv(view)
        iprojection = inv(projection)
        return (iview * iprojection, iview, iprojection)
    end

    # constants
    # TODO: consider aliasing identities
    register_computation!(
            graph, Symbol[],
            [:world_to_world, :eye_to_eye, :pixel_to_pixel, :relative_to_relative, :clip_to_clip,
                :clip_to_relative, :relative_to_clip]
        ) do input, changed, cached
        id = Mat4d(I)
        clip_to_relative = Mat4d(0.5, 0, 0, 0, 0, 0.5, 0, 0, 0, 0, 1, 0, 0.5, 0.5, 0, 1)
        relative_to_clip = Mat4d(2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 1, 0, -1, -1, 0, 1)
        return (id, id, id, id, id, clip_to_relative, relative_to_clip)
    end

    # pixel

    register_computation!(
            graph, [:resolution],
            [:pixel_to_clip, :clip_to_pixel, :pixel_to_relative, :relative_to_pixel]
        ) do (resolution,), changed, cached
        nearclip = -10_000.0
        farclip = 10_000.0
        w, h = resolution

        d = farclip - nearclip
        iw, ih, id = 1.0 ./ (w, h, -d)
        co = (farclip + nearclip) * id
        # Same as orthographicprojection(w, h, nearclip, farclip) but inlined
        # so we don't need to recalculate 1 / w etc
        pixel_to_clip = Mat4d(2iw,0,0,0, 0,2ih,0,0, 0,0,2id,0, -1,-1,co,1)
        clip_to_pixel = Mat4d(0.5w,0,0,0, 0,0.5h,0,0, 0,0,0.5d,0, 0.5w,0.5h,0,1)
        pixel_to_relative = Mat4d(iw,0,0,0, 0,ih,0,0, 0,0,id,0, 0,0,co,1)
        relative_to_pixel = Mat4d(w,0,0,0, 0,h,0,0, 0,0,id,0, 0,0,co,1)
        return (pixel_to_clip, clip_to_pixel, pixel_to_relative, relative_to_pixel)
    end

    # Pretty common for scatter (space to markerspace = pixel, markerspace to clip)
    # So let's keep it separated
    register_computation!(
            graph, [:world_to_clip, :clip_to_pixel],
            [:world_to_pixel]
        ) do (world_to_clip, clip_to_pixel), changed, cached
        world_to_pixel = clip_to_pixel * world_to_clip
        return (world_to_pixel,)
    end

    # Uncommon cases
    register_computation!(
            graph, [:world_to_clip, :eye_to_clip, :clip_to_pixel, :clip_to_eye],
            [:world_to_relative, :eye_to_relative, :eye_to_pixel]
        ) do (world_to_clip, clip_to_pixel), changed, cached
        world_to_relative = clip_to_relative * world_to_clip
        eye_to_relative = clip_to_relative * eye_to_clip
        eye_to_pixel = clip_to_pixel * eye_to_clip
        return (world_to_relative, eye_to_relative, eye_to_pixel)
    end

    register_computation!(
            graph, [:clip_to_world, :clip_to_eye, :relative_to_clip, :pixel_to_clip],
            [:relative_to_world, :relative_to_eye, :pixel_to_world, :pixel_to_eye]
        ) do (clip_to_world, clip_to_eye, relative_to_clip, pixel_to_clip), changed, cached
        relative_to_world = clip_to_world * relative_to_clip
        relative_to_eye = clip_to_eye * relative_to_clip
        pixel_to_world = clip_to_world * pixel_to_clip
        pixel_to_eye = clip_to_eye * pixel_to_clip

        return (relative_to_world, relative_to_eye, pixel_to_world, pixel_to_eye)
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

get_pixelspace(graph::ComputeGraph) = Mat4f(graph[:pixel_to_clip][])

function get_projectionview(graph::ComputeGraph, space::Symbol)
    key = ifelse(space === :data, :world, space)
    return Mat4f(graph[Symbol(key, :_to_clip)][])
end

function get_projection(graph::ComputeGraph, space::Symbol)
    key = ifelse(space === :data, :eye_to_clip, Symbol(space, :_to_clip))
    return Mat4f(graph[key][])
end

function get_view(graph::ComputeGraph, space::Symbol)
    # or :eye_to_eye for the else case
    return Mat4f(space === :data ? graph[Symbol(:world_to_eye)][] : Mat4d(I))
end

function get_preprojection(graph::ComputeGraph, space::Symbol, markerspace::Symbol)
    key1 = ifelse(space === :data, :world, space)
    key2 = ifelse(markerspace === :data, :world, markerspace)
    return Mat4f(graph[Symbol(key1, :_to_, key2)][])
end



function _has_camera_changed(changed, space, markerspace = space)
    is_data = is_data_space(space) || is_data_space(markerspace)
    is_pixel = is_pixel_space(space) || is_pixel_space(markerspace)
    result = (is_data && (changed.view || changed.projection)) || (is_pixel && (changed.viewport))
    return result
end

function camera_trigger(inputs, changed, cached)
    isnothing(cached) && return (true,)
    view, projection, viewport, spaces... = inputs
    has_changed = _has_camera_changed(changed, spaces...)
    # Same values get ignored
    return has_changed ? (!cached[1],) : nothing
end

struct CameraMatrixCallback <: Function
    graph::ComputeGraph
end

function (cb::CameraMatrixCallback)(inputs, changed, cached)
    graph = cb.graph
    space = inputs.space
    # TODO: more fine grained updates?
    # e.g. log if space related matrices or markerspace related matrices need
    # update in camera_trigger and only update those?
    if haskey(inputs, :markerspace)
        markerspace = inputs.markerspace
        # TODO: breaks FastPixel?
        preprojection = get_preprojection(graph, space, markerspace)
        projectionview = get_projectionview(graph, markerspace)
        projection = get_projection(graph, markerspace)
        view = get_view(graph, markerspace)
        return (projectionview, projection, view, preprojection)
    else
        projectionview = get_projectionview(graph, space)
        projection = get_projection(graph, space)
        view = get_view(graph, space)
        return (projectionview, projection, view)
    end
end

function register_camera!(plot_graph::ComputeGraph, scene_graph::ComputeGraph)
    # This should connect Computed's from the parent graph to a new Computed in the child graph
    inputs = [scene_graph.view, scene_graph.projection, scene_graph.viewport, plot_graph.space]
    haskey(plot_graph, :markerspace) && push!(inputs, plot_graph.markerspace)
    @assert inputs isa Vector{ComputePipeline.Computed}

    # Only propagate update from camera matrices if its relevant to space
    ComputePipeline.unsafe_register!(camera_trigger, plot_graph, inputs, [:camera_trigger])

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
    # type assert for safety
    add_input!(plot_graph, :pixel_space, scene_graph[:pixel_to_clip]::Computed)
    add_input!(plot_graph, :viewport, scene_graph[:viewport]::Computed)
    for key in [:resolution, :scene_origin]
        add_input!((k, v) -> Vec2f(v), plot_graph, key, getindex(scene_graph, key)::Computed)
    end
    for key in [:eyeposition, :upvector, :view_direction]
        add_input!((k, v) -> Vec3f(v), plot_graph, key, getindex(scene_graph, key)::Computed)
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