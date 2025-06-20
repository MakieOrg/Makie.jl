# We use objectid to find objects on the js side
js_uuid(object) = string(objectid(object))

function Bonito.print_js_code(io::IO, plot::AbstractPlot, context::Bonito.JSSourceContext)
    uuids = js_uuid.(Makie.collect_atomic_plots(plot))
    # This is a bit more complicated then it has to be, since evaljs / on_document_load
    # isn't guaranteed to run after plot initialization in an App... So, if we don't find any plots,
    # we have to check again after inserting new plots
    return Bonito.print_js_code(
        io, js"""(new Promise(resolve => {
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
        }))""", context
    )
end

function Bonito.print_js_code(io::IO, scene::Scene, context::Bonito.JSSourceContext)
    return Bonito.print_js_code(io, js"""$(WGL).then(WGL=> WGL.find_scene($(js_uuid(scene))))""", context)
end


const SCENE_ORDER_PER_SESSION = Dict{String, Int}()
const ORDER_LOCK = Base.ReentrantLock()

function get_order!(session::Session)
    roots = Bonito.root_session(session)
    return lock(ORDER_LOCK) do
        order = get!(SCENE_ORDER_PER_SESSION, roots.id, 1)
        SCENE_ORDER_PER_SESSION[roots.id] = order + 1
        return order
    end
end

function three_display(screen::Screen, session::Session, scene::Scene)
    config = screen.config
    order = get_order!(session)
    scene_serialized = serialize_scene(scene)
    window_open = scene.events.window_open
    width, height = size(scene)
    canvas_width = lift(x -> [round.(Int, widths(x))...], scene, viewport(scene))
    canvas = DOM.m(
        "canvas";
        tabindex = "0", style = "display: block",
        # Pass JupyterLab specific attributes to prevent it from capturing keyboard shortcuts
        # and to suppress the JupyterLab context menu in Makie plots, see:
        # https://jupyterlab.readthedocs.io/en/4.2.x/extension/notebook.html#keyboard-interaction-model
        # https://jupyterlab.readthedocs.io/en/4.2.x/extension/extension_points.html#context-menu
        dataLmSuppressShortcuts = true, dataJpSuppressContextMenu = nothing,
    )
    wrapper = DOM.div(canvas; style = "width: 100%; height: 100%")
    comm = Observable(Dict{String, Any}())
    done_init = Observable{Any}(nothing)
    # Keep texture atlas in parent session, so we don't need to send it over and over again
    evaljs(
        session, js"""
        $(WGL).then(WGL => {
            WGL.execute_in_order($order, ()=> {
                console.log("RUNNING IN ORDER: ", $order)
                try {
                    const wrapper = $wrapper
                    const canvas = $canvas
                    if (wrapper == null || canvas == null) {
                        return
                    }
                    const renderer = WGL.create_scene(
                        wrapper, canvas, $canvas_width, $scene_serialized, $comm, $width, $height,
                        $(config.framerate), $(config.resize_to), $(config.px_per_unit), $(config.scalefactor)
                    )
                    const gl = renderer.getContext()
                    const err = gl.getError()
                    if (err != gl.NO_ERROR) {
                        throw new Error("WebGL error: " + WGL.wglerror(gl, err))
                    }
                    $(done_init).notify(true)
                } catch (e) {
                    Bonito.Connection.send_error("error initializing scene", e)
                    $(done_init).notify(e)
                    return
                }
            })
        })
        """
    )
    on(session, done_init) do val
        window_open[] = true
    end
    connect_scene_events!(screen, scene, comm)
    return wrapper, done_init
end

#=
Makie.supports_move_to(::Screen) = false

function Makie.move_to!(screen::Screen, plot::Plot, scene::Scene)
    session = get_screen_session(screen)
    # Make sure target scene is serialized
    insert_scene!(session, screen, scene)
    return evaljs(
        session, js"""
        $(scene).then(scene=> {
            $(plot).then(meshes=> {
                meshes.forEach(m => {
                    m.plot_object.move_to(scene)
                })
            })
        })
        """
    )
end
=#
