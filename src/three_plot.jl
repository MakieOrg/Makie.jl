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

function Base.delete!(td::ThreeDisplay, scene::Scene, plot::AbstractPlot)
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
    serialized = serialize_scene(scene)
    JSServe.register_resource!(session, serialized)
    window_open = scene.events.window_open
    on(session.on_close) do closed
        closed && (window_open[] = false)
    end

    width, height = size(scene)

    canvas = DOM.um("canvas", width=width, height=height, tabindex="0")
    wrapper = DOM.div(canvas)
    comm = Observable(Dict{String,Any}())
    push!(session, comm)

    scene_data = Observable(serialized)

    canvas_width = lift(x -> [round.(Int, widths(x))...], pixelarea(scene))

    scene_id = objectid(scene)
    @show scene_id
    setup = js"""
    function setup(scenes){
        const canvas = $(canvas)

        const scene_id = $(scene_id)
        const renderer = $(WGL).threejs_module(canvas, $comm, $width, $height)
        if ( renderer ) {
            const three_scenes = scenes.map(x=> $(WGL).deserialize_scene(x, canvas))
            JSServe.on_update($(window_open), open=>{
                if (!open) {
                    $(WGL).delete_scene($(scene_id))
                }
            })

            const cam = new $(THREE).PerspectiveCamera(45, 1, 0, 100)
            $(WGL).start_renderloop(renderer, three_scenes, cam)
            JSServe.on_update($canvas_width, w_h => {
                console.log(scene_id, w_h)
                renderer.setSize(w_h[0], w_h[1]);
                canvas.style.width = w_h[0];
                canvas.style.height = w_h[1];
            })
        } else {
            const warning = $(WEBGL).getWebGLErrorMessage();
            $(wrapper).removeChild(canvas)
            $(wrapper).appendChild(warning)
        }
    }
    """

    onjs(session, scene_data, setup)
    mousedrag(scene, nothing)
    scene_data[] = scene_data[]
    connect_scene_events!(scene, comm)
    mousedrag(scene, nothing)
    three = ThreeDisplay(session)
    return three, wrapper
end
