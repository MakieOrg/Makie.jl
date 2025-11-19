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
    code = js"""$(WGL).then(WGL=> {
        function try_find_scene(_retries) {
            let retries = _retries || 0;
            const max_retries = 100;
            const retry_delay = 100;
            const scene = WGL.find_scene($(js_uuid(scene)));
            if (scene) {
                return Promise.resolve(scene);
            } else if (retries < max_retries) {
                return new Promise(resolve => {
                    setTimeout(() => {
                        try_find_scene(retries + 1).then(resolve);
                    }, retry_delay);
                });
            } else {
                return Promise.reject(new Error("Scene not found after retries"));
            }
        }
        return try_find_scene();
    })"""
    return Bonito.print_js_code(io, code, context)
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
    window_open = scene.events.window_open
    initial_size = size(scene)
    canvas_width = lift(x -> [round.(Int, widths(x))...], scene, viewport(scene))
    is_offline = Bonito.root_session(session).connection isa Bonito.NoConnection
    # Observable to receive the actual canvas size from JS after resize_to calculation
    real_size = Observable{Any}(nothing)
    # Create observable for scene serialization that updates asynchronously
    scene_serialized = Observable{Any}(nothing)
    done_init = Observable{Any}(nothing)
    if is_offline
        # For offline connections, we have to serialize immediately
        # Since we cant do any round trip communication
        scene_serialized[] = serialize_scene(scene)
    else
        scene_serialized_task = @async serialize_scene(scene)
        # Wait for real size to be determined, then resize scene and serialize
        on(real_size) do size_arr
            @async try
                size_tuple = (round.(Int, (size_arr))...,)
                # Resize the scene to the actual canvas size before serialization
                serialized = fetch(scene_serialized_task)
                if size_tuple != initial_size
                    # resize before sending - since all changes should be captured in the serialized observables
                    # We dont need to serialize again!
                    resize!(scene, size_tuple...)
                end
                # Now serialize with the correct size
                scene_serialized[] = serialized
            catch e
                @warn "Error resizing/serializing scene" exception = (e, catch_backtrace())
                done_init[] = e
            end
        end
    end
    width, height = initial_size
    # Create canvas
    canvas = DOM.m(
        "canvas";
        tabindex="0",
        # Set with/height to have a good inital size - might not match the final size with scaling etc, but this
        # will be adjusted in JS - this helps with less re-layoting
        width="$(width)px",
        height="$(height)px",
        style = "display: block",
        # Pass JupyterLab specific attributes to prevent it from capturing keyboard shortcuts
        # and to suppress the JupyterLab context menu in Makie plots, see:
        # https://jupyterlab.readthedocs.io/en/4.2.x/extension/notebook.html#keyboard-interaction-model
        # https://jupyterlab.readthedocs.io/en/4.2.x/extension/extension_points.html#context-menu
        dataLmSuppressShortcuts = true, dataJpSuppressContextMenu = nothing,
    )

    # Get spinner from config (will be constructed from theming)
    spinner = config.spinner

    # Wrapper contains canvas and spinner as siblings, plus widgets will be added later
    # position: relative is needed for:
    # 1. absolute positioning of spinner on top of canvas
    # 2. absolute positioning of widgets (HTML widgets, etc.)
    wrapper = DOM.div(canvas, spinner; style = "width: 100%; height: 100%; position: relative; background-color: gray")
    comm = Observable(Dict{String, Any}())

    # Keep texture atlas in parent session, so we don't need to send it over and over again
    evaljs(
        session, js"""
        $(WGL).then(WGL => {
            WGL.execute_in_order($order, ()=> {
                WGL.setup_scene_init(
                    $wrapper,
                    $canvas,
                    $width,
                    $height,
                    $(config.resize_to),
                    $(config.px_per_unit),
                    $(config.scalefactor),
                    $(real_size),
                    $canvas_width,
                    $(scene_serialized),
                    $comm,
                    $(config.framerate),
                    $(done_init)
                )
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
