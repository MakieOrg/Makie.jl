module WGLMakie

using Hyperscript
using JSServe, Observables, AbstractPlotting
using GeometryTypes, Colors
using ShaderAbstractions, LinearAlgebra
import GeometryBasics

using JSServe: Application, Session, evaljs, linkjs, update_dom!, div, active_sessions
using JSServe: @js_str, onjs, Button, TextField, Slider, JSString, Dependency, with_session
using JSServe: JSObject, onload, uuidstr
using JSServe.DOM
using ShaderAbstractions: VertexArray, Buffer, Sampler, AbstractSampler
using ShaderAbstractions: InstancedProgram

import GeometryTypes: GLNormalMesh, GLPlainMesh

struct WebGL <: ShaderAbstractions.AbstractContext end

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

function code_to_keyboard(code::String)
    if length(code) == 1 && isnumeric(code[1])
        return getfield(Keyboard, Symbol("_" * code))
    end
    button = lowercase(code)
    if startswith(button, "arrow")
        return getfield(Keyboard, Symbol(button[6:end]))
    end
    if startswith(button, "digit")
        return getfield(Keyboard, Symbol(button[6:end]))
    end
    if startswith(button, "key")
        return getfield(Keyboard, Symbol(button[4:end]))
    end
    button = replace(button, r"(.*)left" => s"left_\1")
    button = replace(button, r"(.*)right" => s"right_\1")
    return getfield(Keyboard, Symbol(button))
end

function connect_scene_events!(scene, comm)
    e = events(scene)
    on(comm) do msg
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
        @handle msg.keydown begin
            set = e.keyboardbuttons[]
            push!(set, code_to_keyboard(keydown))
            e.keyboardbuttons[] = set
        end
        @handle msg.keyup begin
            set = e.keyboardbuttons[]
            delete!(set, code_to_keyboard(keyup))
            e.keyboardbuttons[] = set
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
    on_redraw(jsctx) do _
        # Fuse all calls in the event loop together!
        JSServe.fuse(jsctx.THREE) do
            for (js_scene, (cam, update_func)) in scene_graph
                update_func()
            end
        end
    end
end

struct ThreeDisplay <: AbstractPlotting.AbstractScreen
    THREE::JSObject
    renderer::JSObject
    window::JSObject
    session_cache::Dict{UInt64, JSObject}
    scene2jsscene::Dict{Scene, Tuple{JSObject, Any}}
    redraw::Observable{Bool}
    function ThreeDisplay(
            jsm::JSObject,
            renderer::JSObject,
            window::JSObject,
        )
        return new(
            jsm, renderer, window,
            Dict{UInt64, JSObject}(), Dict{Scene, Tuple{JSObject, JSObject}}(),
            Observable(false)
        )
    end
end
function Base.insert!(x::ThreeDisplay, scene::Scene, plot::AbstractPlot)
    #TODO implement
    # js = to_jsscene(x, scene)
end
function redraw!(three::ThreeDisplay)
    getfield(three, :redraw)[] = true
end

function on_redraw(f, three::ThreeDisplay)
    on(f, getfield(three, :redraw))
end

function to_jsscene(three::ThreeDisplay, scene::Scene)
    get!(getfield(three, :scene2jsscene)) do
        three.Scene(), nothing
    end
end

function Base.getproperty(x::ThreeDisplay, field::Symbol)
    if Base.sym_in(field, fieldnames(ThreeDisplay))
        return getfield(x, field)
    else
        # forward getproperty to THREE, to make js work
        return getproperty(x.THREE, field)
    end
end

const THREE = JSServe.Dependency(
    :THREE,
    [
        "https://cdn.jsdelivr.net/gh/mrdoob/three.js/build/three.js",
    ]
)

function three_display(session::Session, scene::Scene)
    update!(scene)
    width, height = size(scene)
    canvas = DOM.um("canvas", width = width, height = height)
    comm = Observable(Dict{Symbol, Any}())
    threemod, renderer = JSObject(session, :THREE), JSObject(session, :renderer)
    window = JSObject(session, :window)
    onload(session, canvas, js"""
        function threejs_module(canvas){
            var context = canvas.getContext("webgl2");
            if(!context){
                context = canvas.getContext("webgl");
            }
            var renderer = new $THREE.WebGLRenderer({
                antialias: true, canvas: canvas, context: context,
                powerPreference: "high-performance"
            });
            renderer.setSize($width, $height);
            renderer.setClearColor("#ff00ff");
            renderer.setPixelRatio(window.devicePixelRatio);
            put_on_heap($(uuidstr(threemod)), $THREE);
            put_on_heap($(uuidstr(renderer)), renderer);
            put_on_heap($(uuidstr(window)), window);

            function mousemove(event){
                update_obs($comm, {
                    mouseposition: [event.pageX, event.pageY]
                })
                return false
            }
            canvas.addEventListener("mousemove", mousemove, false);

            function mousedown(event){
                update_obs($comm, {
                    mousedown: event.buttons
                })
                return false;
            }
            canvas.addEventListener("mousedown", mousedown, false);

            function mouseup(event){
                update_obs($comm, {
                    mouseup: event.buttons
                })
                return false;
            }
            canvas.addEventListener("mouseup", mouseup, false);

            function wheel(event){
                update_obs($comm, {
                    scroll: [event.deltaX, event.deltaY]
                })
                event.preventDefault()
                return false;
            }
            canvas.addEventListener("wheel", wheel, false);

            function keydown(event){
                update_obs($comm, {
                    keydown: event.code
                })
                return false;
            }
            document.addEventListener("keydown", keydown, false);

            function keyup(event){
                update_obs($comm, {
                    keyup: event.code
                })
                return false;
            }
            document.addEventListener("keyup", keyup, false);
        }"""
    )
    connect_scene_events!(scene, comm)
    mousedrag(scene, nothing)
    three = ThreeDisplay(threemod, renderer, window)
    add_scene!(three, scene)
    on_any_event(scene) do args...
        redraw!(three)
    end
    return three, canvas
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

function JSServe.jsrender(session::Session, scene::Scene)
    three, canvas = WGLMakie.three_display(session, scene)
    return canvas
end

const WEB_MIMES = (MIME"text/html", MIME"application/vnd.webio.application+html", MIME"application/prs.juno.plotpane+html")
for M in WEB_MIMES
    @eval begin
        function AbstractPlotting.backend_show(::WGLBackend, io::IO, m::$M, scene::Scene)
            three = nothing
            inline_display = JSServe.with_session() do session, request
                three, canvas = WGLMakie.three_display(session, scene)
                canvas
            end
            Base.show(io, m, inline_display)

            return three
        end
        # function Base.show(
        #         io::IO, m::$M, x::ThreeDisplay
        #     )
        #     show(io, m, WebIO.render(x))
        #     return x
        # end
    end
end
#
#
# function WebIO.render(three::ThreeDisplay)
#     WebIO.render(getfield(three, :jsm))
# end
#
function AbstractPlotting.backend_showable(::WGLBackend, ::T, scene::Scene) where T <: MIME
    return T in WEB_MIMES
end


function activate!()
    b = WGLBackend()
    AbstractPlotting.register_backend!(b)
    AbstractPlotting.set_glyph_resolution!(AbstractPlotting.Low)
    AbstractPlotting.current_backend[] = b
    AbstractPlotting.inline!(true) # can't display any different atm
end

function __init__()
    # Activate WGLMakie as backend!
    activate!()
end

end # module
