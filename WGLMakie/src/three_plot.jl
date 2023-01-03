

# We use objectid to find objects on the js side
js_uuid(object) = string(objectid(object))

function Base.insert!(td::ThreeDisplay, scene::Scene, plot::Combined)
    JSServe.wait_for_ready(td.session)
    plot_data = serialize_plots(scene, [plot])
    JSServe.evaljs_value(td.session, js"""
    $(WGL).then(WGL=> {
        WGL.insert_plot($(js_uuid(scene)), $plot_data);
    })""")
    return
end

function Base.delete!(td::ThreeDisplay, scene::Scene, plot::Combined)
    uuids = js_uuid.(Makie.flatten_plots(plot))
    WGL.delete_plots(td.session, js_uuid(scene), uuids)
    return
end

function all_plots_scenes(scene::Scene; scene_uuids=String[], plot_uuids=String[])
    push!(scene_uuids, js_uuid(scene))
    for plot in scene.plots
        append!(plot_uuids, (js_uuid(p) for p in Makie.flatten_plots(plot)))
    end
    for child in scene.children
        all_plots_scenes(child, plot_uuids=plot_uuids, scene_uuids=scene_uuids)
    end
    return scene_uuids, plot_uuids
end

"""
    find_plots(td::ThreeDisplay, plot::AbstractPlot)

Gets the ThreeJS object representing the plot object.
"""
function find_plots(td::ThreeDisplay, plot::AbstractPlot)
    return find_plots(JSServe.session(td), plot)
end

function find_plots(session::Session, plot::AbstractPlot)
    uuids = js_uuid.(Makie.flatten_plots(plot))
    return WGL.find_plots(session, uuids)
end

function JSServe.print_js_code(io::IO, plot::AbstractPlot, context::IdDict)
    uuids = js_uuid.(Makie.flatten_plots(plot))
    # This is a bit more complicated then it has to be, since evaljs / on_document_load
    # isn't guaranteed to run after plot initialization in an App... So, if we don't find any plots,
    # we have to check again after inserting new plots
    JSServe.print_js_code(io, js"""(new Promise(resolve => {
        $(WGL).then(WGL=> {
            const find = ()=> {
                const plots = WGL.find_plots($(uuids))
                if (plots.length > 0) {
                    resolve(plots)
                } else {
                    WGL.on_next_insert(find)
                }
            };
            find()
        })
    }))""", context)
end

function JSServe.print_js_code(io::IO, scene::Scene, context::IdDict)
    JSServe.print_js_code(io, js"""$(WGL).then(WGL=> WGL.find_scene($(js_uuid(scene))))""", context)
end

function three_display(session::Session, scene::Scene; screen_config...)
    config = Makie.merge_screen_config(ScreenConfig, screen_config)::ScreenConfig
    scene_serialized = serialize_scene(scene)

    window_open = scene.events.window_open
    width, height = size(scene)
    canvas_width = lift(x -> [round.(Int, widths(x))...], pixelarea(scene))
    canvas = DOM.um("canvas"; tabindex="0")
    wrapper = DOM.div(canvas)
    comm = Observable(Dict{String,Any}())
    done_init = Observable(false)
    # Keep texture atlas in parent session, so we don't need to send it over and over again
    ta = JSServe.Retain(TEXTURE_ATLAS)
    setup = js"""
    (wrapper)=>{
        const canvas = $canvas;
        $(WGL).then(WGL => {
            // well.... not nice, but can't deal with the `Promise` in all the other functions
            window.WGLMakie = WGL
            WGL.create_scene($wrapper, canvas, $canvas_width, $scene_serialized, $comm, $width, $height, $(config.framerate), $(ta))
        })
        $(done_init).notify(true)
    }
    """

    JSServe.onload(session, wrapper, setup)
    connect_scene_events!(scene, comm)
    three = ThreeDisplay(session)
    return three, wrapper, done_init
end
