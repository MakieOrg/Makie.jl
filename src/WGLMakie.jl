module WGLMakie

using WebSockets, JSCall, WebIO, JSExpr, Colors, GeometryTypes
using JSExpr: jsexpr
using AbstractPlotting, Observables
using ShaderAbstractions, LinearAlgebra
using ShaderAbstractions: VertexArray, Buffer, Sampler, AbstractSampler
import GeometryTypes: GLNormalMesh
using ShaderAbstractions: InstancedProgram, VertexArray
import GeometryTypes: GLNormalMesh, GLPlainMesh
using Tables: columns

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

ENV["WEBIO_BUNDLE_URL"] = "https://simondanisch.github.io/ReferenceImages/generic_http.js"

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
end

function draw_js(jsscene, mscene::Scene, plot::Lines)
    @get_attribute plot (color, linewidth, model, transformation)
    positions = plot[1][]
    jslines!(jsscene, positions, color, linewidth, model)
end
function draw_js(jsscene, mscene::Scene, plot::LineSegments)
    @get_attribute plot (color, linewidth, model)
    positions = plot[1][]
    jslines!(jsscene, positions, color, linewidth, model, :linesegments)
end
function draw_js(jsscene, mscene::Scene, plot::Mesh)
    normalmesh = plot[1][]
    @get_attribute plot (color, model)
    geometry = THREE.new.BufferGeometry()
    cmap = vec(reinterpret(UInt8, RGB{Colors.N0f8}.(color)))
    data = window.Uint8Array.from(cmap)
    tex = THREE.new.DataTexture(
        data, size(color, 1), size(color, 2),
        THREE.RGBFormat, THREE.UnsignedByteType
    );
    tex.needsUpdate = true
    material = THREE.new.MeshLambertMaterial(
        color = 0xdddddd, map = tex,
        transparent = true
    )
    set_positions!(geometry, vertices(normalmesh))
    set_normals!(geometry, normals(normalmesh))
    set_uvs!(geometry, texturecoordinates(normalmesh))
    indices = faces(normalmesh)
    indices = reinterpret(UInt32, indices)
    geometry.setIndex(indices);
    mesh = THREE.new.Mesh(geometry, material)
    mesh.matrixAutoUpdate = false;
    mesh.matrix.set(model...)
    jsscene.add(mesh)
    return mesh
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

function get_camera(renderer, js_scene, scene)
  get_camera(renderer, js_scene, AbstractPlotting.camera(scene), cameracontrols(scene))
end

function get_camera(renderer, js_scene, cam, cam_controls::Camera2D)
    area = cam_controls.area
    mini, maxi = minimum(area[]), maximum(area[])
    jscam = THREE.new.OrthographicCamera(mini[1], maxi[1], maxi[2], mini[2], -1, 1000)
    onany(area) do area
        mini, maxi = minimum(area), maximum(area)
        jscam.left = mini[1]
        jscam.right = maxi[1]
        jscam.top = maxi[2]
        jscam.bottom = mini[2]
        jscam.updateProjectionMatrix()
        renderer.render(js_scene, jscam)
    end
    return jscam
end

function get_camera(renderer, js_scene, cam, cam_controls::Camera3D)
    jscam = THREE.new.PerspectiveCamera(cam_controls.fov[], (/)(cam.resolution[]...), 1, 1000)
    update = Observable(false)
    args = (
        cam.projection, cam_controls.eyeposition, cam_controls.lookat, cam_controls.upvector,
        cam_controls.fov, cam_controls.near, cam_controls.far
    )
    onany(update, args...) do _, proj, pos, lookat, up, fov, near, far
        jscam.position.set(pos...)
        jscam.lookAt(lookat...)
        jscam.up.set(up...)
        jscam.fov = fov
        jscam.near = near
        jscam.far = far
        jscam.updateProjectionMatrix()
        renderer.render(js_scene, jscam);
    end
    update[] = true # run onany first time
    jscam
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

function js_display(scene)
    global THREE, window

    update!(scene)
    mousedrag(scene, nothing)
    width, height = size(scene) ./ 2
    THREE, document, window = JSModule(
        :THREE,
        "https://cdnjs.cloudflare.com/ajax/libs/three.js/103/three.js",
    )
    style = Dict(
        :width => string(width, "px"), :height => string(height, "px")
    )
    display(scope(THREE)(dom"canvas"(attributes = style)))
    connect_scene_events!(scene, document)
    canvas = document.querySelector("canvas")
    renderer = THREE.new.WebGLRenderer(
        antialias = false, canvas = canvas
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
    document, window, js_scene
end

function three_scene(scene)
    global THREE, window, document
    update!(scene)
    mousedrag(scene, nothing)
    width, height = size(scene)
    THREE, document, window = JSModule(
        :THREE,
        "https://cdnjs.cloudflare.com/ajax/libs/three.js/103/three.js",
    )

    display(scope(THREE)(dom"div#container"()))

    connect_scene_events!(scene, document)

    renderer = THREE.new.WebGLRenderer(antialias = true)
    renderer.setSize(width, height)
    renderer.setClearColor("#ffffff")
    document.body.appendChild(renderer.domElement)
    js_scene = THREE.new.Scene()
    THREE, document, window, js_scene, renderer
end

include("particles.jl")

export js_display

# document.addEventListener("mousedown", onDocumentMouseDown, false)
# document.addEventListener("mouseup", onDocumentMouseDown, false)
# document.addEventListener("wheel", onDocumentMouseDown, false)
#
# document.addEventListener("resize", onWindowResize, false)
#
# document.addEventListener("focus", onWindowResize, false)
#
# document.addEventListener("resize", onWindowResize, false)
# document.addEventListener("keydown", onWindowResize, false)
#
# document.addEventListener("keyup", onWindowResize, false)

end # module
