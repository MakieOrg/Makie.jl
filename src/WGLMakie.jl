module WGLMakie

using WebSockets, JSCall, WebIO, JSExpr, Colors, GeometryTypes
using JSExpr: jsexpr
using AbstractPlotting, Observables
using ShaderAbstractions, LinearAlgebra
using ShaderAbstractions: VertexArray, Buffer, Sampler, AbstractSampler
using ShaderAbstractions: InstancedProgram
import GeometryTypes: GLNormalMesh, GLPlainMesh

struct WebGL <: ShaderAbstractions.AbstractContext end
using Colors

import GeometryTypes, AbstractPlotting, GeometryBasics

function register_js_events!(comm)
    @js begin
        # TODO, the below doesn't actually work to disable right-click menu
        function no_context(event)
            event.preventDefault()
            return false
        end
        document.addEventListener("contextmenu", no_context, false)

        function mousemove(event)
            $(comm)[] = Dict(
                :mouseposition => [event.pageX, event.pageY]
            )
            event.preventDefault()
            return false
        end
        document.addEventListener("mousemove", mousemove, false)

        function mousedown(event)
            $(comm)[] = Dict(
                :mousedown => event.buttons
            )
            event.preventDefault()
            return false
        end
        document.addEventListener("mousedown", mousedown, false)

        function mouseup(event)
            $(comm)[] = Dict(
                :mouseup => event.buttons
            )
            event.preventDefault()
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


function set_positions!(geometry, positions::AbstractVector{<: Point{N, T}}) where {N, T}
    flat = reinterpret(T, positions)
    geometry.addAttribute(
        "position", THREE.new.Float32BufferAttribute(flat, N)
    )
end

function set_colors!(geometry, colors::AbstractVector{T}) where T <: Colorant
    flat = reinterpret(eltype(T), colors)
    geometry.addAttribute(
        "color", THREE.new.Float32BufferAttribute(flat, length(T))
    )
end
function set_normals!(geometry, colors::AbstractVector{T}) where T <: Normal
    flat = reinterpret(eltype(T), colors)
    geometry.addAttribute(
        "normal", THREE.new.Float32BufferAttribute(flat, 3)
    )
end
function set_uvs!(geometry, uvs::AbstractVector{T}) where T <: UV
    uvs = map(uvs) do uv
        (1f0 - uv[2], 1f0 - uv[1])
    end
    flat = reinterpret(Float32, uvs)
    geometry.addAttribute(
        "uv", THREE.new.Float32BufferAttribute(flat, 2)
    )
end

function material!(geometry, colors::AbstractVector)
    material = THREE.new.LineBasicMaterial(
        vertexColors = THREE.VertexColors, transparent = true, opacity = 0.1)
    set_colors!(geometry, colors)
    return material
end

function material!(geometry, color::Colorant)
    material = THREE.new.LineBasicMaterial(color = "#"*hex(RGB(color)), transparent = true)
    return material
end

function jslines!(scene, positions, colors, linewidth, model, typ = :lines)
    geometry = THREE.new.BufferGeometry()
    material = material!(geometry, colors)
    set_positions!(geometry, positions)
    Typ = typ === :lines ? THREE.new.Line : THREE.new.LineSegments
    mesh = Typ(geometry, material)
    mesh.matrixAutoUpdate = false;
    mesh.matrix.set(model...)
    scene.add(mesh)
    return mesh
end

function draw_js(jsscene, mscene::Scene, plot)
    @warn "Plot of type $(typeof(plot)) not supported yet"
end

function draw_js(jsscene, mscene::Scene, plot::Lines)
    @get_attribute plot (color, linewidth, model, transformation)
    positions = plot[1][]
    jslines!(jsscene, positions, color, linewidth, model)
end


function add_scene!(jsscene, scene::Scene)
    for plot in scene.plots
        add_scene!(jsscene, scene, plot)
    end
    for sub in scene.children
        add_scene!(jsscene, sub)
    end
end

function add_scene!(jsscene, scene::Scene, x::Combined)
    if isempty(x.plots) # if no plots inserted, this truely is an atomic
        draw_js(jsscene, scene, x)
    else
        foreach(x.plots) do x
            add_scene!(jsscene, scene, x)
        end
    end
end

# TODO make a scene struct that encapsulates these
global THREE = nothing
global window = nothing
global document = nothing

function get_comm(jso)
    # LOL TODO git gud
    obs, sync = scope(jso).observs["_jscall_value_comm"]
    return obs
end

function js_display(scene::Scene)
    three_scene(scene)
end

function three_scene(scene::Scene)
    global THREE, window, document
    mousedrag(scene, nothing)
    width, height = size(scene) ./ 2
    jsm = JSModule(
            :THREE,
            "https://cdnjs.cloudflare.com/ajax/libs/three.js/103/three.js",
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
    THREE = jsm.mod; window = jsm.window; document = jsm.document;

    connect_scene_events!(scene, jsm.document)
    canvas = document.querySelector("canvas")
    renderer = THREE.new.WebGLRenderer(
        antialias = true, canvas = canvas
    )
    renderer.setSize(width, height)
    renderer.setClearColor("#ffffff")
    renderer.setPixelRatio(window.devicePixelRatio);
    js_scene = THREE.new.Scene()
    add_scene!(js_scene, scene)
    ambient = THREE.new.AmbientLight(0x666666)
    directionalLight = THREE.new.DirectionalLight(0xffffff, 1.5)
    directionalLight.position.set((rand(Vec3f0) .- 0.5)...)
    directionalLight.position.normalize()
    js_scene.add(directionalLight)
    js_scene.add(ambient)
    cam = get_camera(renderer, js_scene, scene)
    renderer.render(js_scene, cam);
    jsm
end

include("camera.jl")
include("webgl.jl")
include("particles.jl")
include("lines.jl")
include("meshes.jl")
include("imagelike.jl")


struct WGLBackend <: AbstractPlotting.AbstractBackend
end

function AbstractPlotting.backend_show(::WGLBackend, io::IO, m::MIME"text/html", scene::Scene)
    Base.show(io, m, three_scene(scene))
end
function AbstractPlotting.backend_show(::WGLBackend, io::IO, m::WebIO.WEBIO_APPLICATION_MIME, scene::Scene)
    Base.show(io, m, three_scene(scene))
end
function AbstractPlotting.backend_show(::WGLBackend, io::IO, m::MIME"application/prs.juno.plotpane+html", scene::Scene)
    Base.show(io, m, three_scene(scene))
end

function __init__()
    # Make webio stay even after server is down
    ENV["WEBIO_BUNDLE_URL"] = "https://simondanisch.github.io/ReferenceImages/generic_http.js"
    AbstractPlotting.register_backend!(WGLBackend())
end

end # module
