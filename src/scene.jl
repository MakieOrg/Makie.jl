
mutable struct Camera
    view::Node{Mat4f0}
    projection::Node{Mat4f0}
    projectionview::Node{Mat4f0}
    resolution::Node{Vec2f0}
    eyeposition::Node{Vec3f0}
    steering_nodes::Vector{Node}
end

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

abstract type AbstractCamera end

# placeholder
struct EmptyCamera <: AbstractCamera end

Camera(px_area) = Camera(
    Node(eye(Mat4f0)),
    Node(eye(Mat4f0)),
    Node(eye(Mat4f0)),
    map(a-> Vec2f0(widths(a)), px_area),
    Node(Vec3f0(1)),
    Node[]
)



struct Transformation
    translation::Node{Vec3f0}
    scale::Node{Vec3f0}
    rotation::Node{Vec4f0}
    model::Node{Mat4f0}
    flip::Node{NTuple{3, Bool}}
    align::Node{Vec2f0}
    func::Node{Any}
end

function Transformation()
    flip = node(:flip, (false, false, false))
    scale = node(:scale, Vec3f0(1))
    scale = map(flip, scale) do f, s
        map((f, s)-> f ? -s : s, Vec(f), s)
    end
    translation, rotation, align = (
        node(:translation, Vec3f0(0)),
        node(:rotation, Vec4f0(0, 0, 0, 1)),
        node(:align, Vec2f0(0))
    )
    model = map_once(scale, translation, rotation, align) do s, o, r, a
        q = Quaternions.Quaternion(r[4], r[1], r[2], r[3])
        transformationmatrix(o, s, q)
    end
    Transformation(
        translation,
        scale,
        rotation,
        model,
        flip,
        align,
        signal_convert(Node{Any}, identity)
    )
end

if VERSION >= v"0.7-"
    const jl_finalizer = finalizer
else
    const jl_finalizer = (f, x) -> finalizer(x, f)
end

function close_all_nodes(any)
    for field in fieldnames(any)
        value = getfield(any, field)
        (value isa Node) && close(value, true)
    end
end

mutable struct Scene
    events::Events

    px_area::Node{IRect2D}
    camera::Camera
    camera_controls::RefValue
    limits::Node{FRect3D}

    transformation::Transformation

    plots::Vector{AbstractPlot}
    theme::Attributes
    children::Vector{Scene}
    current_screens::Vector{AbstractScreen}

    function Scene(
            events::Events,
            px_area::Node{IRect2D},
            camera::Camera,
            camera_controls::RefValue,
            limits::Node,
            transformation::Transformation,
            plots::Vector{AbstractPlot},
            theme::Attributes,
            children::Vector{Scene},
            current_screens::Vector{AbstractScreen},
        )
        obj = new(events, px_area, camera, camera_controls, limits, transformation, plots, theme, children, current_screens)
        jl_finalizer(obj) do obj
            # save_print("Freeing scene")
            close_all_nodes(obj.events)
            close_all_nodes(obj.transformation)
            for field in (:px_area, :limits)
                close(getfield(obj, field), true)
            end
            disconnect!(obj.camera)
            empty!(obj.theme)
            empty!(obj.children)
            empty!(obj.current_screens)
            return
        end
        obj
    end
end


const current_global_scene = Ref{Any}()

if is_windows()
    function _primary_resolution()
        # ccall((:GetSystemMetricsForDpi, :user32), Cint, (Cint, Cuint), 0, ccall((:GetDpiForSystem, :user32), Cuint, ()))
        # ccall((:GetSystemMetrics, :user32), Cint, (Cint,), 17)
        dc = ccall((:GetDC, :user32), Ptr{Void}, (Ptr{Void},), C_NULL)
        ntuple(2) do i
            Int(ccall((:GetDeviceCaps, :gdi32), Cint, (Ptr{Void}, Cint), dc, (2 - i) + 117))
        end
    end
else
    # TODO implement osx + linux
    _primary_resolution() = (1920, 1080) # everyone should have at least a hd monitor :D
end
function primary_resolution()
    # Since this is pretty low level and os specific + we can't test on all possible
    # computers, I assume we'll have bugs here. Let's not sweat about it too much,
    # we just use primary_resolution to have a good estimate for a default window resolution
    # if this fails, only thing happening will be a too small/big window when the user doesn't give any resolution.
    try
        _primary_resolution()
    catch e
        warn("Could not retrieve primary monitor resolution. A default resolution of (1920, 1080) is assumed!
        Error: $(sprint(io->showerror(io, e))).")
        (1920, 1080)
    end
end
reasonable_resolution() = primary_resolution() .÷ 2

current_scene() = current_global_scene[]

Scene(::Void) = Scene()

default_theme() = Theme(
    font = "DejaVuSans",
    backgroundcolor = RGBAf0(1,1,1,1),
    color = :black,
    colormap = :viridis
)

function Scene(;
        area = nothing,
        resolution = reasonable_resolution()
    )
    events = Events()
    if area == nothing
        px_area = foldp(IRect(0, 0, resolution), events.window_area) do v0, w_area
            wh = widths(w_area)
            wh = (wh == Vec(0, 0)) ? widths(v0) : wh
            IRect(0, 0, wh)
        end
    else
        px_area = signal_convert(Signal{IRect2D}, area)
    end
    scene = Scene(
        events,
        px_area,
        Camera(px_area),
        RefValue{Any}(EmptyCamera()),
        node(:scene_limits, FRect3D(Vec3f0(0), Vec3f0(1))),
        Transformation(),
        AbstractPlot[],
        default_theme(),
        Scene[],
        AbstractScreen[]
    )
    current_global_scene[] = scene
    scene
end
function Scene(
        scene::Scene;
        events = scene.events,
        px_area = scene.px_area,
        cam = scene.camera,
        camera_controls = scene.camera_controls,
        boundingbox = Node(AABB(Vec3f0(0), Vec3f0(1))),
        transformation = scene.transformation,
        theme = Theme(),
        current_screens = scene.current_screens
    )
    child = Scene(
        events,
        px_area,
        cam,
        camera_controls,
        boundingbox,
        transformation,
        AbstractPlot[],
        merge(theme, default_theme()),
        Scene[],
        current_screens
    )
    push!(scene.children, child)
    child
end

function Scene(scene::Scene, area)
    events = scene.events
    px_area = signal_convert(Signal{IRect2D}, area)
    child = Scene(
        events,
        px_area,
        Camera(px_area),
        RefValue{Any}(EmptyCamera()),
        node(:scene_limits, FRect3D(Vec3f0(0), Vec3f0(1))),
        Transformation(),
        AbstractPlot[],
        default_theme(),
        Scene[],
        scene.current_screens
    )
    push!(scene.children, child)
    child
end

"""
Fetches all plots sharing the same camera
"""
plots_from_camera(scene::Scene) = plots_from_camera(scene, scene.camera)
function plots_from_camera(scene::Scene, camera::Camera, list = AbstractPlot[])
    append!(list, scene.plots)
    for child in scene.children
        child.camera === camera && plots_from_camera(child, camera, list)
    end
    list
end

function flatten_combined(plots::Vector, flat = AbstractPlot[])
    for elem in plots
        if (elem isa Combined)
            flatten_combined(elem.plots, flat)
        else
            push!(flat, elem)
        end
    end
    flat
end
function real_boundingbox(scene::Scene)
    bb = AABB{Float32}()
    for screen in scene.current_screens
        for plot in flatten_combined(plots_from_camera(scene))
            id = object_id(plot)
            haskey(screen.cache, id) || continue
            robj = screen.cache[id]
            bb == AABB{Float32}() && (bb = value(robj.boundingbox))
            bb = union(bb, value(robj.boundingbox))
        end
    end
    bb
end
function merge_attributes!(input, theme, rest = Attributes(), merged = Attributes())
    for key in union(keys(input), keys(theme))
        if haskey(input, key) && haskey(theme, key)
            val = input[key]
            if isa(val, Attributes)
                merged[key] = Attributes()
                merge_attributes!(val, theme[key][], rest, merged[key])
            else
                merged[key] = to_node(val)
            end
        elseif haskey(input, key)
            rest[key] = input[key]
        else # haskey(theme) must be true!
            merged[key] = theme[key]
        end
    end
    return merged, rest
end

function merged_get!(defaults::Function, key, scene, input::Vector{Any})
    return merged_get!(defaults, key, scene, Attributes(input))
end


Theme(; kw_args...) = Attributes(map(kw-> kw[1] => node(kw[1], kw[2]), kw_args))

function insert_plots!(scene::Scene)
    for screen in scene.current_screens
        for elem in scene.plots
            insert!(screen, scene, elem)
        end
    end
    foreach(insert_plots!, scene.children)
end
update_cam!(scene::Scene, bb::AbstractCamera, rect) = nothing

function Base.show(io::IO, ::MIME"text/plain", scene::Scene)
    filter!(isopen, scene.current_screens)
    isempty(scene.current_screens) || return
    screen = Screen(scene)
    insert_plots!(scene)
    bb = Makie.real_boundingbox(scene)
    w = widths(bb)
    padd = w .* 0.01
    bb = FRect3D(minimum(bb) .- padd, w .+ 2padd)
    update_cam!(scene, bb)
    return
end

function Base.show(io::IO, m::MIME"text/plain", plot::AbstractPlot)
    show(io, m, parent(plot))
    display(TextDisplay(io), m, plot.attributes)
    nothing
end

Base.empty!(scene::Scene) = empty!(scene.plots)

"""
A plot type that combines multiple more primitive plots.
"""
struct Combined{Typ, T} <: AbstractPlot
    transformation::Transformation
    args::T
    attributes::Attributes
    parent
    plots::Vector{AbstractPlot}
end

Base.parent(x::Combined) = x.parent

# Since we can use Combined like a scene in some circumstances, we define this alias

# A combined plot can be used like a scene
function plot!(cplot::Combined, plot::AbstractPlot, attributes::Attributes)
    push!(cplot.plots, plot)
    plot
end

function Combined{Typ}(scene::Combined, attributes, args...) where Typ
    c = Combined{Typ, typeof(args)}(Transformation(scene), args, attributes, scene.parent, AbstractPlot[])
    push!(scene.plots, c)
    c
end

const Scenelike = Union{Scene, Combined}

function Transformation(scene::Scenelike)
    flip = node(:flip, (false, false, false))
    scale = node(:scale, Vec3f0(1))
    scale = map(flip, scale) do f, s
        map((f, s)-> f ? -s : s, Vec(f), s)
    end
    translation, rotation, align = (
        node(:translation, Vec3f0(0)),
        node(:rotation, Vec4f0(0, 0, 0, 1)),
        node(:align, Vec2f0(0))
    )
    pmodel = modelmatrix(scene)
    model = map_once(scale, translation, rotation, align, pmodel) do s, o, r, a, p
        q = Quaternions.Quaternion(r[4], r[1], r[2], r[3])
        p * transformationmatrix(o, s, q)
    end
    Transformation(
        translation,
        scale,
        rotation,
        model,
        flip,
        align,
        signal_convert(Node{Any}, identity)
    )
end
function Combined{Typ}(scene::Scenelike, attributes, args...) where Typ
    c = Combined{Typ, typeof(args)}(Transformation(scene), args, attributes, scene, AbstractPlot[])
    push!(scene, c)
    c
end
function translated(scene::Scene, translation...)
    tscene = Scene(scene, transformation = Transformation())
    transform!(tscene, translation...)
    tscene
end

function translated(
        scene::Scene;
        translation = Vec3f0(0),
        scale = Vec3f0(1),
        rotation = 0.0,
    )
    tscene = Scene(scene, transformation = Transformation())
    translate!(tscene, translation)
    scale!(tscene, scale)
    rotate!(tscene, rotation)
    tscene
end


const Transformable = Union{Scenelike, AbstractPlot}

transformation(scene::Scene) = scene.transformation
transformation(scene::Combined) = scene.transformation
transformation(scene::Scenelike) = transformation(scene.parent)
transformation(plot::AbstractPlot) = plot[:transformation]

scale(scene::Transformable) = transformation(scene).scale
scale!(scene::Transformable, s) = (scale(scene)[] = to_ndim(Vec3f0, Float32.(s), 1))
scale!(scene::Transformable, xyz...) = scale!(scene, xyz)

rotation(scene::Transformable) = transformation(scene).rotation
rotate!(scene::Transformable, q) = (rotation(scene)[] = attribute_convert(q, key"rotation"()))
rotate!(scene::Transformable, axis_rot...) = rotate!(scene, axis_rot)

translation(scene::Transformable) = transformation(scene).translation
translate!(scene::Transformable, t) = (translation(scene)[] = to_ndim(Vec3f0, Float32.(t), 0))
translate!(scene::Transformable, xyz...) = translate!(scene, xyz)


function transform!(scene::Transformable, x::Tuple{Symbol, <: Number})
    plane, dimval = string(x[1]), Float32(x[2])
    if length(plane) != 2 || (!all(x-> x in ('x', 'y', 'z'), plane))
        error("plane needs to define a 2D plane in xyz. It should only contain 2 symbols out of (:x, :y, :z). Found: $plane")
    end
    if all(x-> x in ('x', 'y'), plane) # xy plane
        translate!(scene, 0, 0, dimval)
    elseif all(x-> x in ('x', 'z'), plane) # xz plane
        rotate!(scene, Vec3f0(1, 0, 0), 0.5pi)
        translate!(scene, 0, dimval, 0)
    else #yz plane
        q1 = Makie.qrotation(Vec3f0(1, 0, 0), -0.5pi)
        q2 = Makie.qrotation(Vec3f0(0, 0, 1), 0.5pi)
        Makie.rotate!(scene, Makie.qmul(q2, q1))
        translate!(scene, dimval, 0, 0)
    end
    scene
end
modelmatrix(x::Scenelike) = transformation(x).model

limits(scene::Scene) = scene.limits
limits(scene::Scenelike) = scene.parent.limits


# Since we can use Combined like a scene in some circumstances, we define this alias
theme(x::Scenelike, args...) = theme(x.parent, args...)
theme(x::Scene) = x.theme
theme(x::Scene, key) = x.theme[key]


Base.push!(scene::Combined, subscene) = nothing # Combined plots add themselves uppon creation
function Base.push!(scene::Scene, plot::AbstractPlot)
    push!(scene.plots, plot)
    plot.parent[] = scene
    for screen in scene.current_screens
        insert!(screen, scene, plot)
    end
end
function Base.push!(scene::Scene, plot::Combined)
    push!(scene.plots, plot)
    for screen in scene.current_screens
        insert!(screen, scene, plot)
    end
end

events(scene::Scene) = scene.events
events(scene::Scenelike) = events(scene.parent)

camera(scene::Scene) = scene.camera
camera(scene::Scenelike) = camera(scene.parent)

cameracontrols(scene::Scene) = scene.camera_controls[]
cameracontrols(scene::Scenelike) = cameracontrols(scene.parent)

cameracontrols!(scene::Scene, cam) = (scene.camera_controls[] = cam)
cameracontrols!(scene::Scenelike, cam) = cameracontrols(scene.parent, cam)

pixelarea(scene::Scene) = scene.px_area
pixelarea(scene::Scenelike) = pixelarea(scene.parent)

plots(scene::Scenelike) = scene.plots


function merged_get!(defaults::Function, key, scene::Scenelike, input::Attributes)
    return merge_attributes!(input, get!(defaults, theme(scene), key))
end
