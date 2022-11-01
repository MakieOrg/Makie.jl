struct ThreeDisplay <: Makie.MakieScreen
    session::JSServe.Session
end

JSServe.session(td::ThreeDisplay) = td.session
Base.empty!(::ThreeDisplay) = nothing # TODO implement


function Base.size(screen::ThreeDisplay)
    # look at d.qs().clientWidth for displayed width
    width, height = round.(Int, WGLMakie.JSServe.evaljs_value(screen.session, WGLMakie.JSServe.js"[document.querySelector('canvas').width, document.querySelector('canvas').height]"; time_out=100))
    return (width, height)
end

# We use objectid to find objects on the js side
js_uuid(object) = string(objectid(object))

function Base.insert!(td::ThreeDisplay, scene::Scene, plot::Combined)
    plot_data = serialize_plots(scene, [plot])
    JSServe.evaljs_value(td.session, js"""
        $(WGL).insert_plot($(js_uuid(scene)), $plot_data)
    """)
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

function JSServe.print_js_code(io::IO, plot::AbstractPlot, context)
    uuids = js_uuid.(Makie.flatten_plots(plot))
    JSServe.print_js_code(io, js"$(WGL).find_plots($(uuids))", context)
end

function JSServe.print_js_code(io::IO, scene::Scene, context)
    JSServe.print_js_code(io, js"$(WGL).find_scene($(js_uuid(scene)))", context)
end

function three_display(session::Session, scene::Scene; screen_config...)

    config = Makie.merge_screen_config(ScreenConfig, screen_config)::ScreenConfig

    serialized = serialize_scene(scene)

    if TEXTURE_ATLAS_CHANGED[]
        JSServe.update_cached_value!(session, Makie.get_texture_atlas().data)
        TEXTURE_ATLAS_CHANGED[] = false
    end

    JSServe.register_resource!(session, serialized)
    window_open = scene.events.window_open

    width, height = size(scene)

    canvas = DOM.um("canvas", tabindex="0")
    wrapper = DOM.div(canvas)
    comm = Observable(Dict{String,Any}())
    push!(session, comm)

    scene_data = Observable(serialized)

    canvas_width = lift(x -> [round.(Int, widths(x))...], pixelarea(scene))

    setup = js"""
    function setup(scenes){
        const canvas = $(canvas)

        const renderer = $(WGL).threejs_module(canvas, $comm, $width, $height)
        window.renderer = renderer
        if ( renderer ) {
            const camera = new $(THREE).PerspectiveCamera(45, 1, 0, 100)
            const size = new THREE.Vector2()
            renderer.getDrawingBufferSize(size)
            const picking_target = new THREE.WebGLRenderTarget(size.x, size.y);
            const screen = {renderer, picking_target, camera}

            const three_scenes = scenes.map(x=> {
                const three_scene = $(WGL).deserialize_scene(x)
                console.log(screen)
                three_scene.screen = screen
                return three_scene
            })

            $(WGL).start_renderloop(renderer, three_scenes, camera, $(config.framerate))
            JSServe.on_update($canvas_width, w_h => {
                // `renderer.setSize` correctly updates `canvas` dimensions
                const pixelRatio = renderer.getPixelRatio();
                renderer.setSize(w_h[0] / pixelRatio, w_h[1] / pixelRatio);
            })
        } else {
            const warning = $(WEBGL).getWebGLErrorMessage();
            $(wrapper).removeChild(canvas)
            $(wrapper).appendChild(warning)
        }
    }
    """

    onjs(session, scene_data, setup)
    scene_data[] = scene_data[]
    connect_scene_events!(scene, comm)
    three = ThreeDisplay(session)

    on(session.on_close) do closed
        if closed
            scene_uuids, plot_uuids = all_plots_scenes(scene)
            WGL.delete_scenes(session, scene_uuids, plot_uuids)
            window_open[] = false
        end
    end

    return three, wrapper
end

function wgl_pick(scene::Scene, screen::ThreeDisplay, rect::Rect2i)
    task = @async begin
        (x, y) = minimum(rect)
        (w, h) = widths(rect)
        plot_ids = JSServe.evaljs_value(screen.session, js"""
            $(WGL).pick_native_uuid([$(scene)], $x, $y, $w, $h)
        """)
        if isempty(plot_ids)
            return Tuple{AbstractPlot, Int}[]
        else
            all_children = Makie.flatten_plots(scene.plots)
            lookup = Dict(Pair.(js_uuid.(all_children), all_children))
            return map(plot_ids) do (uuid, index)
                !haskey(lookup, uuid) && error("Internal error, should always be able to lookup found plots")
                return (lookup[uuid], Int(index) + 1)
            end
        end
    end
    return fetch(task)
end
