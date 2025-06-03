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


"""
    add_camera_computation!(graph::ComputeGraph, scene)

Adds `scene.viewport` and the `scene.camera` Observables as inputs to the compute
graph along with computations for all possible spatial conversion matrices.

More specifically this adds conversion matrices between any two spaces of :world,
:eye, :pixel, :relative and :clip. These matrices are then used by plots to
project their data.

Also calculates some utilities like `scene_origin` and `resolution`, and tracks
`eyeposition`, `upvector` and `view_direction`. (Pixel per unit is not included
here)
"""
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

        d = -(farclip - nearclip)
        iw, ih, id = 1.0 ./ (w, h, d)
        co = (farclip + nearclip) * id
        # Same as orthographicprojection(w, h, nearclip, farclip) but inlined
        # so we don't need to recalculate 1 / w etc
        pixel_to_clip     = Mat4d(2iw,0,0,0,  0,2ih,0,0,  0,0,2id,0,  -1,-1,co,1)
        clip_to_pixel     = Mat4d(0.5w,0,0,0, 0,0.5h,0,0, 0,0,0.5d,0, 0.5w,0.5h,0,1)
        pixel_to_relative = Mat4d(iw,0,0,0,   0,ih,0,0,   0,0,id,0,   0,0,co,1)
        relative_to_pixel = Mat4d(w,0,0,0,    0,h,0,0,    0,0,d,0,   0,0,co,1)
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
            graph, [:world_to_clip, :eye_to_clip, :clip_to_pixel, :clip_to_relative],
            [:world_to_relative, :eye_to_relative, :eye_to_pixel]
        ) do (world_to_clip, eye_to_clip, clip_to_pixel, clip_to_relative), changed, cached
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
    return Mat4f(graph[Symbol(key, :_to_clip)][])::Mat4f
end

function get_projection(graph::ComputeGraph, space::Symbol)
    key = ifelse(space === :data, :eye_to_clip, Symbol(space, :_to_clip))
    return Mat4f(graph[key][])::Mat4f
end

function get_view(graph::ComputeGraph, space::Symbol)
    # or :eye_to_eye for the else case
    return Mat4f(space === :data ? graph[Symbol(:world_to_eye)][] : Mat4d(I))::Mat4f
end

function get_preprojection(graph::ComputeGraph, space::Symbol, markerspace::Symbol)
    key1 = ifelse(space === :data, :world, space)
    key2 = ifelse(markerspace === :data, :world, markerspace)
    return Mat4f(graph[Symbol(key1, :_to_, key2)][])::Mat4f
end


function get_camera_matrices(inputs, changed, cached)
    space = inputs.space
    is_data = is_data_space(space)
    projectionview = Symbol(ifelse(is_data, :world, space), :_to_clip)
    projection = ifelse(is_data, :eye_to_clip, Symbol(space, :_to_clip))
    view = ifelse(is_data, :world_to_eye, :eye_to_eye)

    if changed.space || changed[projectionview] || changed[projection] || changed[view] || isnothing(cached)
        return (Mat4f(inputs[projectionview]), Mat4f(inputs[projection]), Mat4f(inputs[view]))
    else
        return nothing
    end
end

function get_camera_matrices_with_markerspace(inputs, changed, cached)
    space = ifelse(is_data_space(inputs.space), :world, inputs.space)
    markerspace = inputs.markerspace
    is_data = is_data_space(markerspace)
    preprojection = Symbol(space, :_to_, ifelse(is_data, :world, markerspace))
    projectionview = Symbol(ifelse(is_data, :world, markerspace), :_to_clip)
    projection = ifelse(is_data, :eye_to_clip, Symbol(markerspace, :_to_clip))
    view = ifelse(is_data, :world_to_eye, :eye_to_eye)

    if changed.markerspace || changed.space || changed[preprojection] || changed[projectionview] ||
            changed[projection] || changed[view] || isnothing(cached)

        return (Mat4f(inputs[preprojection]), Mat4f(inputs[projectionview]),
            Mat4f(inputs[projection]), Mat4f(inputs[view]))
    else
        return nothing
    end
end

function register_camera_matrices!(plot_graph, scene_graph)
    space_names = [:world, :eye, :pixel, :relative, :clip]
    all_names = [Symbol(input, :_to_, output) for input in space_names for output in space_names]

    inputs = map(name -> getproperty(scene_graph, name), all_names)
    if haskey(plot_graph, :markerspace)
        pushfirst!(inputs, plot_graph.markerspace, plot_graph.space)
        register_computation!(get_camera_matrices_with_markerspace, plot_graph, inputs,
            [:preprojection, :projectionview, :projection, :view])
    else
        pushfirst!(inputs, plot_graph.space)
        register_computation!(get_camera_matrices, plot_graph, inputs,
            [:projectionview, :projection, :view])
    end
    return
end

"""
    register_camera!(plot)
    register_camera!(plot_graph, scene_graph)

Connects camera related outputs from the scene to the given `plot`. These always
include:
- `pixel_space`: A matrix transforming from pixel space to clip space
- `viewport`: The viewport of the scene
- `scene_origin`: The `origin(viewport)`
- `resolution`: The `widths(viewport)`
- `eyeposition`: The eyeposition of the camera
- `upvector`: The upvector of the camera
- `view_direction`: The `lookat - eyeposition` of the camera

The camera matrices depend on whether `markerspace` is present. If it is:
- `preprojection` projects from `space` to `markerspace`
- `projectionview` projects from `markerspace` to :clip space
- `view` projects from :data/:world space to :eye space, if `is_dataspace(markerspace)`
- `projection` projects from :eye or markerspace to :clip space, so that `projectionview = projection * view`

Otherwise:
- `projectionview` projects from `space` to :clip space
- `view` projects from :data/:world space to :eye space, if `is_dataspace(space)`
- `projection` projects from :eye or space to :clip space, so that `projectionview = projection * view`
"""
register_camera!(plot::Plot) = register_camera!(plot.attributes, parent_scene(plot).compute)

function register_camera!(plot_graph::ComputeGraph, scene_graph::ComputeGraph)
    # fetch camera matrices based on space (and optionally markerspace)
    register_camera_matrices!(plot_graph, scene_graph)

    # Do we need those? Maybe also viewport?
    # type assert for safety
    add_input!(plot_graph, :pixel_space, scene_graph[:pixel_to_clip]::Computed)
    add_input!(plot_graph, :viewport, scene_graph[:viewport]::Computed)
    for key in [:resolution, :scene_origin]
        haskey(plot_graph.inputs, key) && continue
        add_input!((k, v) -> Vec2f(v), plot_graph, key, getindex(scene_graph, key)::Computed)
    end
    for key in [:eyeposition, :upvector, :view_direction]
        add_input!((k, v) -> Vec3f(v), plot_graph, key, getindex(scene_graph, key)::Computed)
    end

    return
end