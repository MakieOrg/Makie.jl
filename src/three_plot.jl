struct ThreeDisplay <: AbstractPlotting.AbstractScreen
    session::JSServe.Session
end

JSServe.session(td::ThreeDisplay) = td.session

# We use objectid to find objects on the js side
js_uuid(object) = string(objectid(object))

function Base.insert!(td::ThreeDisplay, scene::Scene, plot::AbstractPlot)
    plot_data = serialize_three(scene, plot)
    WGL.insert_plot(td.session, js_uuid(scene), plot_data)
    return
end

function Base.delete!(td::WebDisplay, scene::Scene, plot::AbstractPlot)
    delete!(get_three(td), scene, plot)
end

function Base.delete!(td::ThreeDisplay, scene::Scene, plot::AbstractPlot)
    println("HELLOO")
    uuids = js_uuid.(AbstractPlotting.flatten_plots(plot))
    WGL.delete_plots(td.session, js_uuid(scene), uuids)
    return
end

"""
    find_plots(td::ThreeDisplay, plot::AbstractPlot)

Gets the ThreeJS object representing the plot object.
"""
function find_plots(td::ThreeDisplay, plot::AbstractPlot)
    uuids = js_uuid.(AbstractPlotting.flatten_plots(plot))
    return WGL.find_plots(td, uuids)
end

function three_display(session::Session, scene::Scene)
    empty_serialization_cache!()
    serialized = serialize_scene(scene)
    JSServe.register_resource!(session, serialized)
    window_open = scene.events.window_open
    on(session.on_close) do closed
        closed && (window_open[] = false)
    end

    width, height = size(scene)

    canvas = DOM.um("canvas", width=width, height=height)

    comm = Observable(Dict{String,Any}())
    scene_data = Observable(serialized)

    canvas_width = lift(x -> [round.(Int, widths(x))...], pixelarea(scene))

    scene_id = objectid(scene)

    setup = js"""
    function setup(scenes){
        const canvas = $(canvas)
        if ( $(WEBGL).isWebGLAvailable() ) {
            const renderer = $(WGL).threejs_module(canvas, $comm, $width, $height)
            const three_scenes = scenes.map($(WGL).deserialize_scene)

            on_update($(window_open), open=>{
                $(WGL).delete_scene($(scene_id))
            })

            const cam = new $(THREE).PerspectiveCamera(45, 1, 0, 100)
            $(WGL).start_renderloop(renderer, three_scenes, cam)
            on_update($canvas_width, canvas_width => {
                const w_h = deserialize_js(canvas_width);
                renderer.setSize(w_h[0], w_h[1]);
                canvas.style.width = w_h[0];
                canvas.style.height = w_h[1];
            })
        } else {
            const warning = $(WEBGL).getWebGLErrorMessage();
            canvas.appendChild(warning);
        }
    }
    """

    JSServe.onjs(session, scene_data, setup)
    WGLMakie.connect_scene_events!(session, scene, comm)
    WGLMakie.mousedrag(scene, nothing)
    scene_data[] = scene_data[]
    connect_scene_events!(session, scene, comm)
    mousedrag(scene, nothing)
    three = ThreeDisplay(session)
    return three, canvas
end
