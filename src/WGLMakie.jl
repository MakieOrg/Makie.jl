module WGLMakie

using Hyperscript
using JSServe, Observables, AbstractPlotting
using Colors, GeometryBasics
using ShaderAbstractions, LinearAlgebra
import GeometryBasics

using JSServe: Application, Session, evaljs, linkjs
using JSServe: @js_str, onjs, Button, TextField, Slider, JSString, Dependency, with_session
using JSServe: JSObject, onload, uuidstr
using JSServe.DOM
using ShaderAbstractions: VertexArray, Buffer, Sampler, AbstractSampler
using ShaderAbstractions: InstancedProgram
import AbstractPlotting.FileIO
using StaticArrays
using GeometryBasics: decompose_uv
import ImageMagick

using FreeTypeAbstraction
using AbstractPlotting: get_texture_atlas, glyph_uv_width!, SceneSpace, Pixel
using AbstractPlotting: attribute_per_char, glyph_uv_width!, layout_text

using ImageTransformations

struct WebGL <: ShaderAbstractions.AbstractContext end
struct WGLBackend <: AbstractPlotting.AbstractBackend end


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
    elseif sym == :backquote
        return Keyboard.grave_accent
    elseif sym == :pageup
        return Keyboard.page_up
    elseif sym == :pagedown
        return Keyboard.page_down
    elseif sym == :end
        return Keyboard._end
    elseif sym == :capslock
        return Keyboard.caps_lock
    elseif sym == :contextmenu
        return Keyboard.menu
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
                button = code_to_keyboard(keydown)
                # don't add unknown buttons...we can't work with them
                # and they won't get removed
                if button != Keyboard.unknown
                    push!(set, button)
                    e.keyboardbuttons[] = set
                end
            end
            @handle msg.keyup begin
                set = e.keyboardbuttons[]
                if keyup == "delete_keys"
                    empty!(set)
                else
                    delete!(set, code_to_keyboard(keyup))
                end
                e.keyboardbuttons[] = set
            end
        end
        return
    end
end

const THREE = JSServe.Dependency(:THREE, ["https://cdn.jsdelivr.net/gh/mrdoob/three.js/build/three.js"])
const WGL = JSServe.Dependency(:WGLMakie, [joinpath(@__DIR__, "wglmakie.js")])

struct ThreeDisplay <: AbstractPlotting.AbstractScreen
    context::JSObject
end

function Base.insert!(td::ThreeDisplay, scene::Scene, plot::AbstractPlot)
    js_scene = serialize_three(scene, plot)
    td.context.add_plot(js_scene)
    return
end

"""
    get_plot(td::ThreeDisplay, plot::AbstractPlot)

Gets the ThreeJS object representing the plot object.
"""
function get_plot(td::ThreeDisplay, plot::AbstractPlot)
    return td.context.get_plot(string(objectid(plot)))
end

function three_display(session::Session, scene::Scene)
    update!(scene)

    serialized = serialize_scene(scene)
    JSServe.register_resource!(session, serialized)
    width, height = size(scene)
    canvas = DOM.um("canvas", width = width, height = height)
    comm = Observable(Dict{String, Any}())
    scene_data = Observable(serialized)
    context = JSObject(session, :context)

    setup = js"""
    function setup(scenes){
        const canvas = $(canvas)
        const renderer = $(WGL).threejs_module(canvas, $comm, $width, $height)
        const three_scenes = scenes.map($(WGL).deserialize_scene)
        const cam = new $(WGLMakie.THREE).PerspectiveCamera(45, 1, 0, 100)
        console.log(three_scenes[0])
        $(WGL).start_renderloop(renderer, three_scenes, cam)

        function get_plot(plot_uuid) {
            for (const idx in three_scenes) {
                const plot = three_scenes[idx].getObjectByName(plot_uuid)
                if (plot) {
                    return plot
                }
            }
            return undefined;
        }

        function add_plot(scene, plot) {
            const mesh = $(WGL).deserialize_plot(plot);
        }
        const context = {
            three_scenes,
            add_plot,
            get_plot,
            renderer
        }
        put_on_heap($(uuidstr(context)), context);
    }
    """

    JSServe.onjs(session, scene_data, setup)
    WGLMakie.connect_scene_events!(session, scene, comm)
    WGLMakie.mousedrag(scene, nothing)
    scene_data[] = serialized

    canvas_width = lift(x-> [round.(Int, widths(x))...], pixelarea(scene))
    onjs(session, canvas_width, js"""function update_size(canvas_width){
        const context = $(context);
        const w_h = deserialize_js(canvas_width);
        context.renderer.setSize(w_h[0], w_h[1]);
        var canvas = $(canvas)
        canvas.style.width = w_h[0];
        canvas.style.height = w_h[1];
    }""")
    connect_scene_events!(session, scene, comm)
    mousedrag(scene, nothing)
    three = ThreeDisplay(context)
    return three, canvas
end

include("webgl.jl")
include("particles.jl")
include("lines.jl")
include("meshes.jl")
include("imagelike.jl")
include("picking.jl")
include("display.jl")


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
