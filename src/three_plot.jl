struct ThreeDisplay <: AbstractPlotting.AbstractScreen
    context
end

JSServe.session(td::ThreeDisplay) = JSServe.session(td.context)

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
    serialized = serialize_scene(scene)
    smaller_serialized = replace_dublicates(serialized)
    JSServe.register_resource!(session, smaller_serialized[1])

    session.on_close() do closed
        closed && (scene.window_open[] = false)
    end

    width, height = size(scene)

    canvas = DOM.um("canvas", width=width, height=height)

    comm = Observable(Dict{String,Any}())
    scene_data = Observable(smaller_serialized)

    canvas_width = lift(x -> [round.(Int, widths(x))...], pixelarea(scene))

    setup = js"""
    function setup([scenes, duplicates]){
        const canvas = $(canvas)
        const renderer = $(WGL).threejs_module(canvas, $comm, $width, $height)
        $(WGL).set_duplicate_references(duplicates)
        const three_scenes = scenes.map($(WGL).deserialize_scene)
        const cam = new $(THREE).PerspectiveCamera(45, 1, 0, 100)
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

        function add_plot(plot) {
            const mesh = $(WGL).deserialize_plot(plot);
        }

        on_update($canvas_width, canvas_width => {
            const w_h = deserialize_js(canvas_width);
            renderer.setSize(w_h[0], w_h[1]);
            canvas.style.width = w_h[0];
            canvas.style.height = w_h[1];
        })
    }
    """

    JSServe.onjs(session, scene_data, setup)

    WGLMakie.connect_scene_events!(session, scene, comm)
    WGLMakie.mousedrag(scene, nothing)
    scene_data[] = scene_data[]

    connect_scene_events!(session, scene, comm)
    mousedrag(scene, nothing)
    get_plot(scene, plot) = js_call(session, :get_plot, plot_uuid)
    three = ThreeDisplay((; get_plot))
    return three, canvas
end
