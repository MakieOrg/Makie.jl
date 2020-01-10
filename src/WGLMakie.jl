module WGLMakie

using Hyperscript
using JSServe, Observables, AbstractPlotting
using GeometryTypes, Colors
using ShaderAbstractions, LinearAlgebra
import GeometryBasics

using JSServe: Application, Session, evaljs, linkjs, div, active_sessions
using JSServe: @js_str, onjs, Button, TextField, Slider, JSString, Dependency, with_session
using JSServe: JSObject, onload, uuidstr
using JSServe.DOM
using ShaderAbstractions: VertexArray, Buffer, Sampler, AbstractSampler
using ShaderAbstractions: InstancedProgram
import AbstractPlotting.FileIO
using StaticArrays

import GeometryTypes: GLNormalMesh, GLPlainMesh
using ImageTransformations

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
        return getfield(Keyboard, Symbol("_" * button[6:end]))
    end
    if startswith(button, "key")
        return getfield(Keyboard, Symbol(button[4:end]))
    end
    button = replace(button, r"(.*)left" => s"left_\1")
    button = replace(button, r"(.*)right" => s"right_\1")
    sym = Symbol(button)
    if isdefined(Keyboard, sym)
        return getfield(Keyboard, sym)
    else
        return Keyboard.unknown
    end
end

function connect_scene_events!(session::Session, scene::Scene, comm::Observable)
    e = events(scene)
    on(comm) do msg
        JSServe.fuse(session) do
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
        end
        return
    end
end


function draw_js(jsctx, jsscene, mscene::Scene, plot)
    @warn "Plot of type $(typeof(plot)) not supported yet"
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

function add_scene!(three, scene::Scene)
    js_scene = to_jsscene(three, scene)
    renderer = three.renderer
    evaljs(three, js"""
        function render_camera(scene, camera){
            $(renderer).autoClear = scene.clearscene;
            var bg = scene.backgroundcolor;
            var area = scene.pixelarea;
            if(area){
                var x = area[0];
                var y = area[1];
                var w = area[2];
                var h = area[3];
                camera.aspect = w/h;
                camera.updateProjectionMatrix();
                $(renderer).setViewport(x, y, w, h);
                $(renderer).setScissor(x, y, w, h);
                $(renderer).setScissorTest(true);
                $(renderer).setClearColor(scene.backgroundcolor);
                $(renderer).render(scene, camera);
            }
        }
        function render_scene(scene){
            var camera = scene.getObjectByName("camera");
            if(camera){
                render_camera(scene, camera);
            }
            for(var i = 0; i < scene.children.length; i++){
                var child = scene.children[i];
                render_scene(child);
            }
        }
        function render_all(){
            render_scene($(js_scene));
            // Schedule the next frame.
            requestAnimationFrame(render_all);
        }
        requestAnimationFrame(render_all);
    """)
end

struct ThreeDisplay <: AbstractPlotting.AbstractScreen
    THREE::JSObject
    renderer::JSObject
    window::JSObject
    session_cache::Dict{UInt64, JSObject}
    scene2jsscene::Dict{Scene, JSObject}
    redraw::Observable{Bool}
    function ThreeDisplay(
            jsm::JSObject,
            renderer::JSObject,
            window::JSObject,
        )
        return new(
            jsm, renderer, window,
            Dict{UInt64, JSObject}(), Dict{Scene, JSObject}(),
            Observable(false)
        )
    end
end

function Base.insert!(td::ThreeDisplay, scene::Scene, plot::AbstractPlot)
    js_scene = to_jsscene(td, scene)
    add_plots!(td, js_scene, scene, plot)
end

JSServe.session(x::ThreeDisplay) = JSServe.session(x.THREE)

function to_jsscene(three::ThreeDisplay, scene::Scene)
    get!(getfield(three, :scene2jsscene), scene) do
        # return JSServe.fuse(three) do
            js_scene = three.new.Scene()
            add_camera!(three, js_scene, scene)
            lift(pixelarea(scene)) do area
                js_scene.pixelarea = [minimum(area)..., widths(area)...]
                return
            end
            lift(scene.backgroundcolor) do color
                js_scene.backgroundcolor = "#" * hex(Colors.color(to_color(color)))
                return
            end
            js_scene.clearscene = scene.clear
            for plot in scene.plots
                add_plots!(three, js_scene, scene, plot)
            end
            for sub in scene.children
                js_sub = to_jsscene(three, sub)
                js_scene.add(js_sub)
            end
            return js_scene
        # end
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

const THREE = JSServe.Dependency(:THREE, ["https://cdn.jsdelivr.net/gh/mrdoob/three.js/build/three.js"])

function three_display(session::Session, scene::Scene)
    update!(scene)
    width, height = size(scene)
    canvas = DOM.um("canvas", width = width, height = height)
    comm = Observable(Dict{String, Any}())
    threemod, renderer = JSObject(session, :THREE), JSObject(session, :renderer)
    window = JSObject(session, :window)
    onload(session, canvas, js"""
        function threejs_module(canvas){
            var context = canvas.getContext("webgl2", {preserveDrawingBuffer: true});
            if(!context){
                context = canvas.getContext("webgl", {preserveDrawingBuffer: true});
            }
            var renderer = new $THREE.WebGLRenderer({
                antialias: true, canvas: canvas, context: context,
                powerPreference: "high-performance"
            });
            var ratio = window.devicePixelRatio || 1;
            // var corrected_width = $width / ratio;
            // var corrected_height = $height / ratio;
            // canvas.style.width = corrected_width;
            // canvas.style.height = corrected_height;
            renderer.setSize($width, $height);
            renderer.setClearColor("#ff00ff");
            renderer.setPixelRatio(ratio);

            put_on_heap($(uuidstr(threemod)), $THREE);
            put_on_heap($(uuidstr(renderer)), renderer);
            put_on_heap($(uuidstr(window)), window);

            function mousemove(event){
                var rect = canvas.getBoundingClientRect();
                var x = event.clientX - rect.left;
                var y = event.clientY - rect.top;
                update_obs($comm, {
                    mouseposition: [x, y]
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
                    scroll: [event.deltaX, -event.deltaY]
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
    connect_scene_events!(session, scene, comm)
    mousedrag(scene, nothing)
    three = ThreeDisplay(threemod, renderer, window)
    add_scene!(three, scene)
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
                three, canvas = three_display(session, scene)
                canvas
            end
            Base.show(io, m, inline_display)

            return three
        end
    end
end

function scene2image(scene::Scene)
    three = nothing; session = nothing
    inline_display = JSServe.with_session() do s, request
        session = s
        three, canvas = three_display(s, scene)
        canvas
    end
    electron_display = display(inline_display)
    task = @async wait(session.js_fully_loaded)
    tstart = time()
    # Jeez... Base.Event was a nice idea for waiting on
    # js to be ready, but if anything fails, it becomes unkillable -.-
    while !istaskdone(task)
        sleep(0.01)
        (time() - tstart > 30) && error("JS Session not ready after 30s waiting")
    end
    # HMMMMPFH... This is annoying - we really need to find a way to have
    # devicePixelRatio work correctly
    img_device_scale = AbstractPlotting.colorbuffer(three)
    return ImageTransformations.imresize(img_device_scale, size(scene))
end

function AbstractPlotting.backend_show(::WGLBackend, io::IO, m::MIME"image/png", scene::Scene)
    img = scene2image(scene)
    FileIO.save(FileIO.Stream(FileIO.format"PNG", io), img)
end

function AbstractPlotting.backend_show(::WGLBackend, io::IO, m::MIME"image/jpeg", scene::Scene)
    img = scene2image(scene)
    FileIO.save(FileIO.Stream(FileIO.format"JPEG", io), img)
end

function AbstractPlotting.backend_showable(::WGLBackend, ::T, scene::Scene) where T <: MIME
    return T in WEB_MIMES
end

function session2image(sessionlike)
    s = JSServe.session(sessionlike)
    picture_base64 = JSServe.evaljs_value(s, js"document.querySelector('canvas').toDataURL()")
    picture_base64 = replace(picture_base64, "data:image/png;base64," => "")
    bytes = JSServe.Base64.base64decode(picture_base64)
    return AbstractPlotting.ImageMagick.load_(bytes)
end

function AbstractPlotting.colorbuffer(screen::ThreeDisplay)
    return session2image(screen)
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
