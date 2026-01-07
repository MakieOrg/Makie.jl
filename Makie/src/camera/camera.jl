function Base.copy(x::Camera)
    return Camera(
        ntuple(9) do i
            getfield(x, i)
        end...
    )
end

function Base.:(==)(a::Camera, b::Camera)
    return to_value(a.view) == to_value(b.view) &&
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
    return println(io, "  view direction: ", camera.view_direction[])
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
    return cl.f(map(to_value, cl.args)...)
end

"""
    on(f, c::Camera, observables::Observable...)

When mapping over observables for the camera, we store them in the `steering_node` vector,
to make it easier to disconnect the camera steering signals later!
"""
function Observables.on(f, camera::Camera, observables::AbstractObservable...; priority = 0)
    # PriorityObservables don't implement on_any, because that would replace
    # the method in Observables. CameraLift acts as a workaround for now.
    cl = CameraLift(f, observables)
    for n in observables
        obs = on(cl, n, priority = priority)
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
        lift(a -> Vec2f(widths(a)), viewport),
        Observable(Vec3f(0, 0, -1)),
        Observable(Vec3f(1)),
        Observable(Vec3f(0, 1, 0)),
        ObserverFunction[],
    )
end

function set_proj_view!(camera::Camera, projection, view)
    # hack, to not double update projectionview
    # TODO, this makes code doing on(view), not work correctly...
    # But nobody should do that, right?
    # GLMakie uses map on view
    camera.view[] = view
    return camera.projection[] = projection
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

    # Since (marker)space can change, the matrices a plot needs may change and
    # thus they need to react to all matrix updates. We add a trigger node here
    # to simplify this (i.e. avoid the need to listen to 25 matrices or some
    # subset of the inputs)
    # Note: The value needs to change so that the update doesn't get discarded
    map!((a, b, c) -> time(), graph, [:view, :projection, :viewport], :camera_trigger)

    map!(graph, :viewport, [:scene_origin, :resolution]) do viewport
        return (Vec2d(origin(viewport)), Vec2d(widths(viewport)))
    end

    # Camera matrices
    # TODO: consider aliasing view, projection
    map!(graph, [:projection, :view], [:world_to_clip, :world_to_eye, :eye_to_clip]) do projection, view
        return (projection * view, view, projection)
    end
    map!(graph, [:projection, :view], [:clip_to_world, :eye_to_world, :clip_to_eye]) do projection, view
        # are there accuracy issues with inv first?
        iview = inv(view)
        iprojection = inv(projection)
        return (iview * iprojection, iview, iprojection)
    end

    # constants
    identity_matrix = Mat4d(I)
    add_constants!(
        graph,
        world_to_world = identity_matrix,
        eye_to_eye = identity_matrix,
        pixel_to_pixel = identity_matrix,
        relative_to_relative = identity_matrix,
        clip_to_clip = identity_matrix,
        clip_to_relative = Mat4d(0.5, 0, 0, 0, 0, 0.5, 0, 0, 0, 0, 1, 0, 0.5, 0.5, 0, 1),
        relative_to_clip = Mat4d(2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 1, 0, -1, -1, 0, 1),
    )

    # pixel

    map!(graph, :resolution, [:pixel_to_clip, :clip_to_pixel, :pixel_to_relative, :relative_to_pixel]) do resolution
        nearclip = -10_000.0
        farclip = 10_000.0
        w, h = resolution

        d = -(farclip - nearclip)
        iw, ih, id = 1.0 ./ (w, h, d)
        co = (farclip + nearclip) * id
        # Same as orthographicprojection(w, h, nearclip, farclip) but inlined
        # so we don't need to recalculate 1 / w etc
        pixel_to_clip = Mat4d(2iw, 0, 0, 0, 0, 2ih, 0, 0, 0, 0, 2id, 0, -1, -1, co, 1)
        clip_to_pixel = Mat4d(0.5w, 0, 0, 0, 0, 0.5h, 0, 0, 0, 0, 0.5d, 0, 0.5w, 0.5h, 0, 1)
        pixel_to_relative = Mat4d(iw, 0, 0, 0, 0, ih, 0, 0, 0, 0, id, 0, 0, 0, co, 1)
        relative_to_pixel = Mat4d(w, 0, 0, 0, 0, h, 0, 0, 0, 0, d, 0, 0, 0, co, 1)
        return (pixel_to_clip, clip_to_pixel, pixel_to_relative, relative_to_pixel)
    end

    # Pretty common for scatter (space to markerspace = pixel, markerspace to clip)
    # So let's keep it separated
    map!(graph, [:world_to_clip, :clip_to_pixel], :world_to_pixel) do world_to_clip, clip_to_pixel
        world_to_pixel = clip_to_pixel * world_to_clip
        return world_to_pixel
    end

    # Uncommon cases
    map!(graph, [:world_to_clip, :eye_to_clip, :clip_to_pixel, :clip_to_relative], [:world_to_relative, :eye_to_relative, :eye_to_pixel]) do world_to_clip, eye_to_clip, clip_to_pixel, clip_to_relative
        world_to_relative = clip_to_relative * world_to_clip
        eye_to_relative = clip_to_relative * eye_to_clip
        eye_to_pixel = clip_to_pixel * eye_to_clip
        return (world_to_relative, eye_to_relative, eye_to_pixel)
    end

    map!(graph, [:clip_to_world, :clip_to_eye, :relative_to_clip, :pixel_to_clip], [:relative_to_world, :relative_to_eye, :pixel_to_world, :pixel_to_eye]) do clip_to_world, clip_to_eye, relative_to_clip, pixel_to_clip
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
#
const CAMERA_MATRIX_NAMES = let
    # dynamic Symbol(a, b) is fairly expensive...
    spaces = [:world, :eye, :clip, :relative, :pixel, :space, :markerspace]
    Dict{Tuple{Symbol, Symbol}, Symbol}(
        [(a, b) => Symbol(a, :_to_, b) for a in spaces for b in spaces]
    )
end

_data_to_world(x) = ifelse(x === :data, :world, x)
function get_camera_matrix_name(input_space::Symbol, output_space::Symbol)
    return CAMERA_MATRIX_NAMES[(_data_to_world(input_space), _data_to_world(output_space))]
end

function get_projectionview_name(space::Symbol)
    return Symbol(ifelse(is_data_space(space), :world, space), :_to_clip)
end
function get_projection_name(space::Symbol)
    return ifelse(is_data_space(space), :eye_to_clip, Symbol(space, :_to_clip))
end
function get_view_name(space::Symbol)
    return ifelse(is_data_space(space), :world_to_eye, :eye_to_eye)
end


get_pixelspace(graph::ComputeGraph) = graph[:pixel_to_clip][]::Mat4f

function get_projectionview(graph::ComputeGraph, space::Symbol)
    return Mat4f(graph[get_projectionview_name(space)][])::Mat4f
end

function get_projection(graph::ComputeGraph, space::Symbol)
    return Mat4f(graph[get_projection_name(space)][])::Mat4f
end

function get_view(graph::ComputeGraph, space::Symbol)
    return Mat4f(graph[get_view_name(space)][])::Mat4f
end

function get_space_to_space_matrix(graph::ComputeGraph, input_space::Symbol, output_space::Symbol)
    return Mat4f(graph[get_camera_matrix_name(input_space, output_space)][])::Mat4f
end
function get_preprojection(graph::ComputeGraph, space::Symbol, markerspace::Symbol)
    return get_space_to_space_matrix(graph, space, markerspace)
end

"""
    get_projectionview(scene, space)

Returns the matrix projecting from `space` to clip space.
"""
get_projectionview(scene, space::Symbol) = get_projectionview(get_scene(scene), space)

"""
    get_projection(scene, space)

If `is_data_space(space)`, returns the matrix projecting from eye (or view) space
to clip space. Otherwise returns the same matrix as `get_projectionview()`

Eye space excludes the orientation and placement of the camera.
"""
get_projection(scene, space::Symbol) = get_projection(get_scene(scene), space)

"""
    get_view(scene, space)

If `is_data_space(space)`, returns the matrix projecting from `space` to eye
space. Otherwise returns an identity matrix.

Eye space excludes the orientation and placement of the camera.
"""
get_view(scene, space::Symbol) = get_view(get_scene(scene), space)

"""
    get_preprojection(scene, space, markerspace)

Returns the matrix projecting from `space` to `markerspace`.
"""
function get_preprojection(scene, space::Symbol, markerspace::Symbol)
    return get_preprojection(get_scene(scene).compute, space, markerspace)
end

"""
    get_space_to_space_matrix(scene, input_space, output_space)

Return a camera matrix that transforms from `input_space` to `output_space`.
"""
function get_space_to_space_matrix(scene, input_space::Symbol, output_space::Symbol)
    return get_preprojection(get_scene(scene).compute, input_space, output_space)
end

struct CameraMatrixCallback <: Function
    graph::ComputeGraph
end
(cb::CameraMatrixCallback)(_, names) = map(name -> Mat4f(cb.graph[name][]::Mat4d), names)

function _register_common_camera_matrices!(plot_graph::ComputeGraph, scene_graph::ComputeGraph)
    output_keys = [:projectionview, :projection, :view]

    # merging Symbols is somewhat expensive so we shouldn't do it repetitively
    if haskey(plot_graph, :markerspace)
        map!(plot_graph, [:space, :markerspace], :camera_matrix_names) do space, markerspace
            return get_projectionview_name(markerspace), get_projection_name(markerspace),
                get_view_name(markerspace), get_camera_matrix_name(space, markerspace)
        end
        push!(output_keys, :preprojection)
    else
        map!(plot_graph, :space, :camera_matrix_names) do space
            return get_projectionview_name(space), get_projection_name(space), get_view_name(space)
        end
    end

    input_keys = Computed[scene_graph.camera_trigger, plot_graph.camera_matrix_names]

    # Update camera matrices in plot if space changed or a relevant camera update happened
    callback = CameraMatrixCallback(scene_graph)
    map!(callback, plot_graph, input_keys, output_keys)

    return
end

function register_camera!(plot_graph::ComputeGraph, scene_graph::ComputeGraph)
    _register_common_camera_matrices!(plot_graph, scene_graph)

    # Do we need those? Maybe also viewport?
    # type assert for safety
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

"""
    register_camera_matrix!(plot, input_space, output_space)

Adds the matrix projecting from `input_space` to `output_space` to the given
plot. For this the spaces can also be `:space` or `:markerspace`. The name of
the added projectionmatrix is returned

The registered matrix will usually be named `Symbol(input_space, :_to_, :output_space)`,
e.g. `:data_to_pixel` or `:space_to_pixel`. `:space_to_clip`, `:space_to_markerspace`
and `:markerspace_to_clip` will be renamed to `projectionview`, `preprojection` and
`projectionview` respectively, to avoid duplicating nodes.
"""
function register_camera_matrix!(plot, input::Union{Symbol, Computed}, output::Union{Symbol, Computed})
    scene = parent_scene(plot)

    getname(x::Computed) = x.name::Symbol
    getname(x::Symbol) = x

    return register_camera_matrix!(scene.compute, plot.attributes, getname(input), getname(output))
end
function register_camera_matrix!(
        scene_graph::ComputePipeline.ComputeGraph, plot_graph::ComputePipeline.ComputeGraph,
        input::Symbol, output::Symbol
    )

    # this can be :space_to_pixel, i.e. its not always a name for fetching from camera
    matrix_name = get_camera_matrix_name(input, output)

    haskey(plot_graph, matrix_name) && return matrix_name

    if input === output # catch space -> space here
        if !haskey(plot_graph, :identity_matrix)
            ComputePipeline.add_constant!(plot_graph, :identity_matrix, Mat4f(I))
        end
        return :identity_matrix
    end

    # These already exist
    if haskey(plot_graph, :markerspace) && matrix_name === :space_to_markerspace
        haskey(plot_graph, :preprojection) || _register_common_camera_matrices!(plot_graph, scene_graph)
        return :preprojection
    elseif haskey(plot_graph, :markerspace) && matrix_name === :markerspace_to_clip
        haskey(plot_graph, :projectionview) || _register_common_camera_matrices!(plot_graph, scene_graph)
        return :projectionview
    elseif !haskey(plot_graph, :markerspace) && matrix_name === :space_to_clip
        haskey(plot_graph, :projectionview) || _register_common_camera_matrices!(plot_graph, scene_graph)
        return :projectionview
    end

    _input = input in (:markerspace, :space) ? getindex(plot_graph, input) : input
    _output = output in (:markerspace, :space) ? getindex(plot_graph, output) : output

    isconst(x::Symbol) = true
    isconst(x::Computed) = false

    if isconst(_input) && isconst(_output)
        # both spaces are constant so we don't need to be able to switch to a
        # different camera.
        add_input!(plot_graph, matrix_name, scene_graph[matrix_name])
        return matrix_name
    end

    # dynamic case (space and/or markerspace used)
    # Need to build name of the matrix dynamically before fetching it
    name_name = Symbol(matrix_name, :_name)

    if !isconst(_input) && isconst(_output)
        map!(a -> get_camera_matrix_name(a, output), plot_graph, _input, name_name)
    elseif isconst(_input) && !isconst(_output)
        map!(b -> get_camera_matrix_name(input, b), plot_graph, _output, name_name)
    else
        map!(get_camera_matrix_name, plot_graph, [_input, _output], name_name)
    end

    inputs = Computed[scene_graph.camera_trigger, getindex(plot_graph, name_name)]
    map!((_, name) -> Mat4f(scene_graph[name][]::Mat4d), plot_graph, inputs, matrix_name)

    return matrix_name
end
