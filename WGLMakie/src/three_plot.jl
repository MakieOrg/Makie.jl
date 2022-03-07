struct ThreeDisplay <: Makie.AbstractScreen
    session::JSServe.Session
end

JSServe.session(td::ThreeDisplay) = td.session

# We use objectid to find objects on the js side
js_uuid(object) = string(objectid(object))

function Base.insert!(td::ThreeDisplay, scene::Scene, plot::AbstractPlot)
    plot_data = serialize_plots(scene, [plot])
    WGL.insert_plot(td.session, js_uuid(scene), plot_data)
    return
end

function Base.delete!(td::ThreeDisplay, scene::Scene, plot::AbstractPlot)
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


function JSServe.print_js_code(io::IO, plot::AbstractPlot, context)
    uuids = js_uuid.(Makie.flatten_plots(plot))
    JSServe.print_js_code(io, js"$(WGL).find_plots($(uuids))", context)
end

function three_display(session::Session, scene::Scene)
    serialized = serialize_scene(scene)

    if TEXTURE_ATLAS_CHANGED[]
        JSServe.update_cached_value!(session, Makie.get_texture_atlas().data)
        TEXTURE_ATLAS_CHANGED[] = false
    end

    window_open = scene.events.window_open
    width, height = size(scene)
    canvas = DOM.um("canvas", tabindex="0")
    wrapper = DOM.div(canvas)
    comm = Observable(Dict{String,Any}())
    scene_data = Observable(serialized)
    canvas_width = lift(x -> [round.(Int, widths(x))...], pixelarea(scene))
    setup = js"""
    function onload(wrapper) {
        (async () => {
            const WGLMakie = await $(WGL)
            WGLMakie.create_scene(wrapper, $canvas, $canvas_width, $scene_data, $comm, $width, $height, $(CONFIG.fps[]))
        })()
    }
    """

    JSServe.onload(session, wrapper, setup)

    connect_scene_events!(scene, comm)
    three = ThreeDisplay(session)
    return three, wrapper
end
