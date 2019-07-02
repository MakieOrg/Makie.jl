module WGLMakie

using WebSockets, JSCall, WebIO, JSExpr, GeometryTypes, Colors
using JSExpr: jsexpr
using AbstractPlotting, Observables
using ShaderAbstractions, LinearAlgebra
using ShaderAbstractions: VertexArray, Buffer, Sampler, AbstractSampler
using ShaderAbstractions: InstancedProgram
import GeometryBasics
import GeometryTypes: GLNormalMesh, GLPlainMesh

struct WebGL <: ShaderAbstractions.AbstractContext end

function register_js_events!(comm)
    @js begin
        # TODO, the below doesn't actually work to disable right-click menu
        function no_context(event)
            event.preventDefault()
            return false
        end
        # document.addEventListener("contextmenu", no_context, false)

        function mousemove(event)
            $(comm)[] = Dict(
                :mouseposition => [event.pageX, event.pageY]
            )
            # event.preventDefault()
            return false
        end
        document.addEventListener("mousemove", mousemove, false)

        function mousedown(event)
            $(comm)[] = Dict(
                :mousedown => event.buttons
            )
            # event.preventDefault()
            return false
        end
        document.addEventListener("mousedown", mousedown, false)

        function mouseup(event)
            $(comm)[] = Dict(
                :mouseup => event.buttons
            )
            # event.preventDefault()
            return false
        end
        document.addEventListener("mouseup", mouseup, false)

        function wheel(event)
            $(comm)[] = Dict(
                :scroll => [event.deltaX, event.deltaY]
            )
            event.preventDefault()
            return false
        end
        document.addEventListener("wheel", wheel, false)
    end
end

macro handle(accessor, body)
    obj, field = accessor.args
    key = string(field.value)
    efield = esc(field.value); obj = esc(obj)
    quote
        if haskey($(obj), $(key))
            $(efield) = $(obj)[$(key)]
            $(esc(body))
            return nothing
        end
    end
end

function connect_scene_events!(scene, js_doc)
    comm = get_comm(js_doc)
    evaljs(js_doc, register_js_events!(comm))
    e = events(scene)
    on(comm) do msg
        msg isa Dict || return
        @handle msg.mouseposition begin
            x, y = Float64.((mouseposition...,))
            e.mouseposition[] = (x, size(scene)[2] - y)
        end
        @handle msg.mousedown begin
            set = e.mousebuttons[]; empty!(set)
            mousedown & 1 != 0 && push!(set, Mouse.left)
            mousedown & 2 != 0 && push!(set, Mouse.right)
            mousedown & 4 != 0 && push!(set, Mouse.middle)
            e.mousebuttons[] = set
        end
        @handle msg.mouseup begin
            set = e.mousebuttons[]; empty!(set)
            mouseup & 1 != 0 && push!(set, Mouse.left)
            mouseup & 2 != 0 && push!(set, Mouse.right)
            mouseup & 4 != 0 && push!(set, Mouse.middle)
            e.mousebuttons[] = set
        end
        @handle msg.scroll begin
            e.scroll[] = Float64.((sign.(scroll)...,))
        end
        return
    end
end


function draw_js(jsctx, jsscene, mscene::Scene, plot)
    @warn "Plot of type $(typeof(plot)) not supported yet"
end


function on_any_event(f, scene::Scene)
    key_events = (
        :window_area, :mousebuttons, :mouseposition, :scroll,
        :keyboardbuttons, :hasfocus, :entered_window
    )
    scene_events = getfield.((events(scene),), key_events)
    f(getindex.(scene_events)) # call on first event
    onany(f, scene_events...)
end

function add_plots!(jsctx, jsscene, scene::Scene, x::Combined)
    if isempty(x.plots) # if no plots inserted, this truely is an atomic
        draw_js(jsctx, jsscene, scene, x)
    else
        foreach(x.plots) do x
            add_plots!(jsctx, jsscene, scene, x)
        end
    end
end

function _add_scene!(jsctx, scene::Scene, scene_graph = [])
    js_scene = jsctx.THREE.new.Scene()
    cam, func = add_camera!(jsctx, js_scene, scene)

    getfield(jsctx, :scene2jsscene)[scene] = (js_scene, cam)

    push!(scene_graph, (js_scene, (cam, func)))
    for plot in scene.plots
        add_plots!(jsctx, js_scene, scene, plot)
    end
    for sub in scene.children
        _add_scene!(jsctx, sub, scene_graph)
    end
    scene_graph
end

function add_scene!(jsctx, scene::Scene)
    scene_graph = _add_scene!(jsctx, scene)
    on_any_event(scene) do events...
        # Fuse all calls in the event loop together!
        JSCall.fused(jsctx.THREE) do
            for (js_scene, (cam, update_func)) in scene_graph
                update_func()
            end
        end
    end
end

struct ThreeDisplay <: AbstractPlotting.AbstractScreen
    jsm::JSModule
    renderer::JSObject
    session_cache::Dict{UInt64, JSObject}
    scene2jsscene::Dict{Scene, Tuple{JSObject, JSObject}}
end

function to_jsscene(three::ThreeDisplay, scene::Scene)
    return getfield(three, :scene2jsscene)[scene]
end

function Base.getproperty(x::ThreeDisplay, field::Symbol)
    field === :renderer && return getfield(x, :renderer)
    field === :THREE && return getfield(x, :jsm).mod
    field === :session_cache && return getfield(x, :session_cache)
    if Base.sym_in(field, (:window, :document))
        return getfield(getfield(x, :jsm), field)
    else
        # forward getproperty to THREE, to make js work
        return getproperty(x.THREE, field)
    end
end

function ThreeDisplay(width::Integer, height::Integer)
    jsm = JSModule(
            :THREE,
            "https://cdnjs.cloudflare.com/ajax/libs/three.js/104/three.js",
        ) do scope
        # Render callback
        style = Dict(
            :width => string(width, "px"), :height => string(height, "px")
        )
        WebIO.node(
            :div,
            scope(dom"canvas"(attributes = style)),
            style = style
        )
    end
    THREE = jsm.mod
    canvas = jsm.document.querySelector("canvas")
    context = canvas.getContext("webgl2");
    renderer = THREE.new.WebGLRenderer(
        antialias = true, canvas = canvas, context = context,
        powerPreference = "high-performance"
    )
    renderer.setSize(width, height)
    renderer.setClearColor("#ffffff")
    renderer.setPixelRatio(jsm.window.devicePixelRatio);
    return ThreeDisplay(
        jsm, renderer,
        Dict{Symbol, JSObject}(),
        Dict{Scene, JSObject}()
    )
end

function get_comm(jso)
    # LOL TODO git gud
    obs, sync = scope(jso).observs["_jscall_value_comm"]
    return obs
end

function three_scene(scene::Scene)
    jsctx = ThreeDisplay(size(scene)...)
    connect_scene_events!(scene, jsctx.document)
    mousedrag(scene, nothing)
    add_scene!(jsctx, scene)
    return jsctx
end

function Base.show(io::IO, m::MIME"text/html", jsm::ThreeDisplay)
    Base.show(io, m, getfield(jsm, :jsm))
end
function Base.show(io::IO, m::WebIO.WEBIO_APPLICATION_MIME, jsm::ThreeDisplay)
    Base.show(io, m, getfield(jsm, :jsm))
end
function Base.show(io::IO, m::MIME"application/prs.juno.plotpane+html", jsm::ThreeDisplay)
    Base.show(io, m, getfield(jsm, :jsm))
end


include("camera.jl")
include("webgl.jl")
include("particles.jl")
include("lines.jl")
include("meshes.jl")
include("imagelike.jl")
include("picking.jl")


struct WGLBackend <: AbstractPlotting.AbstractBackend
end


for M in (MIME"text/html", WebIO.WEBIO_APPLICATION_MIME, MIME"application/prs.juno.plotpane+html")
    @eval function AbstractPlotting.backend_show(::WGLBackend, io::IO, m::$M, scene::Scene)
        screen = three_scene(scene)
        Base.show(io, m, screen)
        return screen
    end
end

function __init__()
    # Make webio stay even after server is down
    ENV["WEBIO_BUNDLE_URL"] = "https://simondanisch.github.io/ReferenceImages/generic_http.js"
    AbstractPlotting.register_backend!(WGLBackend())
end

end # module
