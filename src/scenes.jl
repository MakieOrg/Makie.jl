
mutable struct Scene <: AbstractScene
    parent
    events::Events

    px_area::Node{IRect2D}
    camera::Camera
    camera_controls::RefValue
    limits::Node{FRect3D}

    transformation::Transformation

    plots::Vector{AbstractPlot}
    theme::Attributes
    attributes::Attributes
    children::Vector{Scene}
    current_screens::Vector{AbstractScreen}
    updated::Node{Bool}
end

update_callback2 = Ref{Function}() do update, scene
    if update
        center!(scene)
    end
    nothing
end

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
        parent = nothing,
    )
    updated = Node(false)

    scene = Scene(
        parent, events, px_area, camera, camera_controls, limits,
        transformation, plots, theme, Attributes(),
        children, current_screens, updated
    )
    finalizer(scene) do scene
        # save_print("Freeing scene")
        close_all_nodes(scene.events)
        close_all_nodes(scene.transformation)
        for field in (:px_area, :limits)
            close(getfield(scene, field))
        end
        disconnect!(scene.camera)
        empty!(scene.theme)
        empty!(scene.attributes)
        empty!(scene.children)
        empty!(scene.current_screens)
        return
    end
    onany(updated, px_area) do update, px_area
        if update
            scale_scene!(scene);
            yield(); yield();
            center!(scene);
        end
        nothing
    end
    scene
end

Base.parent(scene::Scene) = scene.parent
isroot(scene::Scene) = parent(scene) === nothing
function root(scene::Scene)
    while !isroot(scene)
        scene = parent(scene)
    end
    scene
end
parent_or_self(scene::Scene) = isroot(scene) ? scene : parent(scene)


Base.size(x::Scene) = pixelarea(x) |> to_value |> widths |> Tuple
Base.size(x::Scene, i) = size(x)[i]


# Just indexing into a scene gets you plot 1, plot 2 etc
Base.iterate(scene::Scene, idx = 1) = idx <= length(scene) ? (scene[idx], idx + 1) : nothing
Base.length(scene::Scene) = length(scene.plots)
Base.lastindex(scene::Scene) = length(scene.plots)
getindex(scene::Scene, idx::Integer) = scene.plots[idx]
GeometryTypes.widths(scene::Scene) = widths(to_value(pixelarea(scene)))
struct Axis end

child(scene::Scene) = Scene(scene, pixelarea(scene)[])

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


function Base.empty!(scene::Scene)
    empty!(scene.plots)
    disconnect!(scene.camera)
    scene.limits[] = FRect3D()
    scene.camera_controls[] = EmptyCamera()
    empty!(scene.theme)
    merge!(scene.theme, _current_default_theme)
    empty!(scene.children)
    empty!(scene.current_screens)
end

limits(scene::Scene) = scene.limits
limits(scene::SceneLike) = scene.parent.limits


# Since we can use Combined like a scene in some circumstances, we define this alias
theme(x::SceneLike, args...) = theme(x.parent, args...)
theme(x::Scene) = x.theme
theme(x::Scene, key) = x.theme[key]
theme(x::AbstractPlot, key) = x.attributes[key]
theme(::Nothing, key::Symbol) = current_default_theme()[key]

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

function Observables.connect!(scene::Scene, child::Scene)

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

"""
Returns wether a scene needs updating
"""
function must_update()
    val = _forced_update_scheduled[]
    _forced_update_scheduled[] = false
    val
end

"""
Forces to rerender the scnee
"""
function force_update!()
    _forced_update_scheduled[] = true
end


const current_global_scene = Ref{Any}()

if Sys.iswindows()
    function _primary_resolution()
        # ccall((:GetSystemMetricsForDpi, :user32), Cint, (Cint, Cuint), 0, ccall((:GetDpiForSystem, :user32), Cuint, ()))
        # ccall((:GetSystemMetrics, :user32), Cint, (Cint,), 17)
        dc = ccall((:GetDC, :user32), Ptr{Cvoid}, (Ptr{Cvoid},), C_NULL)
        ntuple(2) do i
            Int(ccall((:GetDeviceCaps, :gdi32), Cint, (Ptr{Cvoid}, Cint), dc, (2 - i) + 117))
        end
    end
else
    # TODO implement osx + linux
    _primary_resolution() = (1920, 1080) # everyone should have at least a hd monitor :D
end

"""
Returns the resolution of the primary monitor.
If the primary monitor can't be accessed, returns (1920, 1080) (full hd)
"""
function primary_resolution()
    # Since this is pretty low level and os specific + we can't test on all possible
    # computers, I assume we'll have bugs here. Let's not sweat about it too much,
    # we just use primary_resolution to have a good estimate for a default window resolution
    # if this fails, only thing happening will be a too small/big window when the user doesn't give any resolution.
    try
        _primary_resolution()
    catch e
        @warn("Could not retrieve primary monitor resolution. A default resolution of (1920, 1080) is assumed!
        Error: $(sprint(io->showerror(io, e))).")
        (1920, 1080)
    end
end

"""
Returns a reasonable resolution for the main monitor.
(right now just half the resolution of the main monitor)
"""
reasonable_resolution() = primary_resolution() .÷ 2


"""
Returns the current active scene (the last scene that got created)
"""
function current_scene()
    if isassigned(current_global_scene)
        current_global_scene[]
    else
        Scene()
    end
end

Scene(::Nothing) = Scene()


function Scene(;
        kw_args...
    )
    events = Events()
    theme = current_default_theme(; kw_args...)
    resolution = theme[:resolution][]
    v0 = IRect(0, 0, resolution)
    px_area = lift(events.window_area) do w_area
       wh = widths(w_area)
       wh = any(x-> x ≈ 0.0, wh) ? widths(v0) : wh
       v0 = IRect(0, 0, wh)
       v0
    end
    scene = Scene(
        events,
        px_area,
        Camera(px_area),
        RefValue{Any}(EmptyCamera()),
        node(:scene_limits, FRect3D(Vec3f0(0), Vec3f0(1))),
        Transformation(),
        AbstractPlot[],
        theme,
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
        transformation = Transformation(scene),
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
        merge(current_default_theme(), theme),
        Scene[],
        current_screens,
        scene
    )
    push!(scene.children, child)
    child
end

function Scene(parent::Scene, area; theme...)
    events = parent.events
    px_area = lift(pixelarea(parent), to_node(area)) do p, a
        # make coordinates relative to parent
        IRect2D(minimum(p) .+ minimum(a), widths(a))
    end
    child = Scene(
        events,
        px_area,
        Camera(px_area),
        RefValue{Any}(EmptyCamera()),
        node(:scene_limits, FRect3D(Vec3f0(0), Vec3f0(1))),
        Transformation(),
        AbstractPlot[],
        merge(Attributes(theme), current_default_theme()),
        Scene[],
        parent.current_screens,
        parent
    )
    push!(parent.children, child)
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

"""
Flattens all the combined plots and returns a Vector of Atomic plots
"""
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


function insertplots!(screen::AbstractDisplay, scene::Scene)
    for elem in scene.plots
        insert!(screen, scene, elem)
    end
    foreach(s-> insertplots!(screen, s), scene.children)
end
update_cam!(scene::Scene, bb::AbstractCamera, rect) = nothing


function center!(scene::Scene, padding = 0.01)
    bb = boundingbox(scene)
    bb = transformationmatrix(scene)[] * bb
    w = widths(bb)
    padd = w .* padding
    bb = FRect3D(minimum(bb) .- padd, w .+ 2padd)
    update_cam!(scene, bb)
    force_update!()
    scene
end
parent_scene(x::Combined) = parent_scene(parent(x))
parent_scene(x::Scene) = x

Base.isopen(x::SceneLike) = events(x).window_open[]
