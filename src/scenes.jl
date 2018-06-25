
mutable struct Scene <: AbstractScene
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

# Just indexing into a scene gets you plot 1, plot 2 etc
Base.start(scene::Scene) = 1
Base.done(scene::Scene, idx) = idx > length(scene)
Base.next(scene::Scene, idx) = (scene[idx], idx + 1)
Base.length(scene::Scene) = length(scene.plots)
Base.endof(scene::Scene) = length(scene.plots)
getindex(scene::Scene, idx::Integer) = scene.plots[idx]
GeometryTypes.widths(scene::Scene) = widths(to_value(pixelarea(scene)))
struct Axis end

child(scene::Scene) = Scene(scene, pixelarea(scene))

"""
Creates a subscene with a pixel camera
"""
function cam2d(scene::Scene)
    sub = child(scene)
    cam2d!(sub)
    sub
end
function campixel(scene::Scene)
    sub = child(scene)
    campixel!(sub)
    sub
end

function getindex(scene::Scene, ::Type{Axis})
    for plot in scene
        isaxis(plot) && return plot
    end
    nothing
end


"""
Each argument can be named for a certain plot type `P`. Falls back to `arg1`, `arg2`, etc.
"""
function argument_names(plot::P) where P <: AbstractPlot
    argument_names(P, length(plot.converted))
end


function argument_names(::Type{<: AbstractPlot}, num_args::Integer)
    # this is called in the indexing function, so let's be a bit efficient
    ntuple(i-> Symbol("arg$i"), num_args)
end


Base.empty!(scene::Scene) = empty!(scene.plots)

limits(scene::Scene) = scene.limits
limits(scene::SceneLike) = scene.parent.limits


# Since we can use Combined like a scene in some circumstances, we define this alias
theme(x::SceneLike, args...) = theme(x.parent, args...)
theme(x::Scene) = x.theme
theme(x::Scene, key) = x.theme[key]
theme(x::AbstractPlot, key) = x.attributes[key]
theme(::Void, key::Symbol) = current_default_theme()[key]

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

function connect!(scene::Scene, child::Scene)

end

function Base.push!(scene::Scene, child::Scene)
    push!(scene.children, child)
    disconnect!(child.camera)
    nodes = map([:view, :projection, :projectionview, :resolution, :eyeposition]) do field
        lift(getfield(scene.camera, field)) do val
            push!(getfield(child.camera, field), val)
        end
    end
    cameracontrols!(child, nodes)
end

events(scene::Scene) = scene.events
events(scene::SceneLike) = events(scene.parent)

camera(scene::Scene) = scene.camera
camera(scene::SceneLike) = camera(scene.parent)

cameracontrols(scene::Scene) = scene.camera_controls[]
cameracontrols(scene::SceneLike) = cameracontrols(scene.parent)

cameracontrols!(scene::Scene, cam) = (scene.camera_controls[] = cam)
cameracontrols!(scene::SceneLike, cam) = cameracontrols!(parent(scene), cam)

pixelarea(scene::Scene) = scene.px_area
pixelarea(scene::SceneLike) = pixelarea(scene.parent)

plots(scene::SceneLike) = scene.plots

const _forced_update_scheduled = Ref(false)
function must_update()
    val = _forced_update_scheduled[]
    _forced_update_scheduled[] = false
    val
end
function force_update!()
    _forced_update_scheduled[] = true
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

function current_scene()
    if isassigned(current_global_scene)
        current_global_scene[]
    else
        Scene()
    end
end

Scene(::Void) = Scene()

const minimal_default = Attributes(
    font = "Dejavu Sans",
    backgroundcolor = RGBAf0(1,1,1,1),
    color = :black,
    colormap = :viridis,
    resolution = reasonable_resolution()
)

const _current_default_theme = copy(minimal_default)

current_default_theme(; kw_args...) = merge(_current_default_theme, Attributes(;kw_args...))

function set_theme!(new_theme::Attributes = minimal_default)
    empty!(_current_default_theme)
    merge!(_current_default_theme, minimal_default, new_theme)
    return
end



function Scene(;
        area = nothing,
        resolution = reasonable_resolution(),
        kw_args...
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
        current_default_theme(; kw_args...),
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
        merge(theme, current_default_theme()),
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
        current_default_theme(),
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
        child.camera == camera && plots_from_camera(child, camera, list)
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





function insertplots!(screen::Display, scene::Scene)
    for elem in scene.plots
        insert!(screen, scene, elem)
    end
    foreach(s-> insertplots!(screen, s), scene.children)
end
update_cam!(scene::Scene, bb::AbstractCamera, rect) = nothing


function center!(scene::Scene, padding = 0.01)
    bb = boundingbox(scene)
    w = widths(bb)
    padd = w .* padding
    bb = FRect3D(minimum(bb) .- padd, w .+ 2padd)
    update_cam!(scene, bb)
    force_update!()
    scene
end
parent_scene(x::Combined) = parent_scene(parent(x))
parent_scene(x::Scene) = x
