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
    # Some large scenes can initialize slowly in app mode; allow configurable retry window.
    retry_delay_ms = max(1, something(tryparse(Int, get(ENV, "WGLMAKIE_SCENE_RETRY_DELAY_MS", "100")), 100))
    total_wait_ms = max(retry_delay_ms, something(tryparse(Int, get(ENV, "WGLMAKIE_SCENE_RETRY_TOTAL_MS", "60000")), 60000))
    max_retries = max(100, cld(total_wait_ms, retry_delay_ms))

    code = js"""$(WGL).then(WGL=> {
        function try_find_scene(_retries) {
            let retries = _retries || 0;
            const max_retries = $(max_retries);
            const retry_delay = $(retry_delay_ms);
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


"""
    AwaitedNode(node)

Wraps a `Hyperscript.Node` (e.g. anything created via `DOM.div`, `DOM.m`, ...) so that
interpolating it into a `js"..."` string waits for the node to actually be mounted in the
DOM before resolving, instead of Bonito's default `Node` interpolation, which compiles to
a plain, one-shot `document.querySelector(...)` with no retry. That default is only safe
if the node is *guaranteed* to already be in the DOM by the time the interpolated code
runs — which the JS module (`\$(WGL)`) finishing its own async load does not guarantee: on
a slow/cold page load, the module can finish loading before Bonito has actually spliced
this particular node into `document.body`, silently querying `null`. Mirrors the retry
loop used for `Scene` lookups above, and shares its env var configuration.
"""
struct AwaitedNode
    node::Hyperscript.Node
end

function Bonito.print_js_code(io::IO, awaited::AwaitedNode, context::Bonito.JSSourceContext)
    id = Bonito.uuid(context.session, awaited.node)
    retry_delay_ms = max(1, something(tryparse(Int, get(ENV, "WGLMAKIE_SCENE_RETRY_DELAY_MS", "100")), 100))
    total_wait_ms = max(retry_delay_ms, something(tryparse(Int, get(ENV, "WGLMAKIE_SCENE_RETRY_TOTAL_MS", "60000")), 60000))
    max_retries = max(100, cld(total_wait_ms, retry_delay_ms))

    code = js"""(function() {
        function try_find_node(_retries) {
            let retries = _retries || 0;
            const max_retries = $(max_retries);
            const retry_delay = $(retry_delay_ms);
            const node = document.querySelector('[data-jscall-id="' + $(id) + '"]');
            if (node) {
                return Promise.resolve(node);
            } else if (retries < max_retries) {
                return new Promise(resolve => {
                    setTimeout(() => {
                        try_find_node(retries + 1).then(resolve);
                    }, retry_delay);
                });
            } else {
                return Promise.reject(new Error("DOM node not found after retries: " + $(id)));
            }
        }
        return try_find_node();
    })()"""
    return Bonito.print_js_code(io, code, context)
end

function get_order!(session::Session)
    order = Bonito.get_metadata(session, :wglmakie_scene_order, 1)
    Bonito.set_metadata!(session, :wglmakie_scene_order, order + 1)
    return order
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
    scene_serialized = Observable{Union{Nothing, Dict{Symbol, Any}}}(nothing)
    done_init = Observable{Any}(nothing)
    if is_offline
        # For offline connections, we have to serialize immediately
        # Since we cant do any round trip communication
        scene_serialized[] = serialize_scene(scene)
    else
        # Query the real canvas size (resize_to) from JS first, resize the scene to
        # it, THEN serialize — so the browser renders at the final size directly
        # instead of rendering at `initial_size` and re-laying-out via observable
        # updates afterwards (which caused a visible resize + a race on capture).
        on(session, real_size) do size_arr
            Makie.async_tracked() do should_close
                try
                    size_tuple = (round.(Int, (size_arr))...,)
                    if size_tuple != initial_size
                        resize!(scene, size_tuple...)
                    end
                    scene_serialized[] = serialize_scene(scene)
                catch e
                    @warn "Error resizing/serializing scene" exception = (e, catch_backtrace())
                    done_init[] = e
                end
            end
            return
        end
    end
    width, height = initial_size
    # Create canvas
    canvas = DOM.m(
        "canvas";
        tabindex = "0",
        # Set with/height to have a good inital size - might not match the final size with scaling etc, but this
        # will be adjusted in JS - this helps with less re-layoting
        width = "$(width)px",
        height = "$(height)px",
        style = "display: block",
        # Pass JupyterLab specific attributes to prevent it from capturing keyboard shortcuts
        # and to suppress the JupyterLab context menu in Makie plots, see:
        # https://jupyterlab.readthedocs.io/en/4.2.x/extension/notebook.html#keyboard-interaction-model
        # https://jupyterlab.readthedocs.io/en/4.2.x/extension/extension_points.html#context-menu
        dataLmSuppressShortcuts = true, dataJpSuppressContextMenu = nothing,
    )

    # Get spinner from config (will be constructed from theming)
    # Wrapper contains canvas and spinner as siblings, plus widgets will be added later
    # position: relative is needed for:
    # 1. absolute positioning of spinner on top of canvas
    # 2. absolute positioning of widgets (HTML widgets, etc.)
    wrapper = DOM.div(canvas, config.spinner; style = "width: 100%; height: 100%; position: relative;")
    comm = Observable(Dict{String, Any}())

    # Keep texture atlas in parent session, so we don't need to send it over and over again
    # `wrapper`/`canvas` are awaited (not interpolated directly) since the JS module
    # loading (`$(WGL)`) does not guarantee they've already been mounted in the DOM —
    # see `AwaitedNode`.
    evaljs(
        session, js"""
        Promise.all([$(WGL), $(AwaitedNode(wrapper)), $(AwaitedNode(canvas))]).then(([WGL, wrapper, canvas]) => {
            WGL.execute_in_order($order, ()=> {
                WGL.setup_scene_init(
                    wrapper,
                    canvas,
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
    # push!(Bonito.children(wrapper), jss)
    on(session, done_init) do val
        window_open[] = true
    end
    connect_scene_events!(screen, scene, comm)
    return wrapper, done_init
end
