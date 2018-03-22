
struct Camera
    view::Node{Mat4f0}
    projection::Node{Mat4f0}
    projectionview::Node{Mat4f0}
    resolution::Node{Vec2f0}
    eyeposition::Node{Vec3f0}
    steering_nodes::Vector{Node}
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
    flip::Node{NTuple{3, Bool}}
    align::Node{Vec2f0}
    func::Node{Any}
end
Transformation() = Transformation(
    Node(Vec3f0(0)),
    Node(Vec3f0(1)),
    Node(Vec4f0(0, 0, 0, 1)),
    Node((false, false, false)),
    Node(Vec2f0(0)),
    signal_convert(Node{Any}, identity)
)

struct Scene
    events::Events

    px_area::Node{IRect2D}
    camera::Camera
    camera_controls::RefValue

    limits::Node{HyperRectangle{3, Float32}}

    transformation::Transformation

    plots::Vector{AbstractPlot}
    theme::Attributes
    children::Vector{Scene}
    current_screens::Vector{AbstractScreen}
end

function Base.push!(scene::Scene, plot::AbstractPlot)
    push!(scene.plots, plot)
    parent(plot)[] = scene
    for screen in scene.current_screens
        insert!(screen, scene, plot)
    end
end

const current_global_scene = Ref{Scene}()
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


function Scene(; area = nothing, resolution = reasonable_resolution())
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
        Node(AABB(Vec3f0(0), Vec3f0(1))),
        Transformation(),
        AbstractPlot[],
        Theme(
            backgroundcolor = RGBAf0(1,1,1,1),
            color = :black,
            colormap = :YlOrRd
        ),
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
        theme = scene.theme,
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
        theme,
        Scene[],
        current_screens
    )
    push!(scene.children, child)
    child
end

function real_boundingbox(scene::Scene)
    bb = AABB{Float32}()
    for screen in scene.current_screens
        if !isempty(screen.renderlist)
            if bb == AABB{Float32}()
                bb = value(first(screen.renderlist)[end].boundingbox)
            end
            for (a,b,robj) in screen.renderlist
                bb = union(bb, value(robj.boundingbox))
            end
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

function merged_get!(defaults::Function, key, scene, input::Attributes)
    return merge_attributes!(input, get!(defaults, scene.theme, key))
end

Theme(; kw_args...) = Attributes(map(kw-> kw[1] => to_node(kw[2]), kw_args))

function insert_plots!(scene::Scene)
    for screen in scene.current_screens
        for elem in scene.plots
            insert!(screen, scene, elem)
        end
    end
    foreach(insert_plots!, scene.children)
end

function Base.show(io::IO, ::MIME"text/plain", scene::Scene)
    isempty(scene.current_screens) || return
    screen = Screen(scene)
    insert_plots!(scene)
    bb = Makie.FRect2D(Makie.real_boundingbox(scene))
    w = widths(bb)
    padd = w .* 0.01
    bb = FRect(minimum(bb) .- padd, widths(bb) .+ 2padd)
    update_cam!(scene, bb)
    return
end

function Base.show(io::IO, m::MIME"text/plain", plot::AbstractPlot)
    show(io, m, Makie.parent(plot)[])
    display(TextDisplay(io), m, plot.attributes)
    nothing
end
