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
            const max_retries = 5;
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
    width, height = size(scene)
    canvas_width = lift(x -> [round.(Int, widths(x))...], scene, viewport(scene))
    # Create canvas
    canvas = DOM.m(
        "canvas";
        tabindex="0",
        width="$(width)px",
        height="$(height)px",
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
    wrapper = DOM.div(canvas, spinner; style = "width: 100%; height: 100%; position: relative")
    comm = Observable(Dict{String, Any}())
    done_init = Observable{Any}(nothing)

    # Observable to receive the actual canvas size from JS after resize_to calculation
    real_size = Observable{Any}(nothing)

    # Create observable for scene serialization that updates asynchronously
    scene_serialized = Observable{Any}(nothing)

    # Wait for real size to be determined, then resize scene and serialize
    on(real_size) do size_tuple
        if size_tuple === nothing
            return
        end
        @async begin
            try
                # Resize the scene to the actual canvas size before serialization
                resize!(scene, size_tuple...)
                # Now serialize with the correct size
                serialized = serialize_scene(scene)
                scene_serialized[] = serialized
            catch e
                @warn "Error resizing/serializing scene" exception=(e, catch_backtrace())
                scene_serialized[] = e
            end
        end
    end

    # Keep texture atlas in parent session, so we don't need to send it over and over again
    evaljs(
        session, js"""
        $(WGL).then(WGL => {
            WGL.execute_in_order($order, ()=> {
                const wrapper = $wrapper
                const canvas = $canvas
                const spinner = wrapper.querySelector('.wglmakie-spinner')
                try {
                    if (wrapper == null || canvas == null) {
                        return
                    }

                    // Calculate and apply the correct canvas size based on resize_to setting
                    // This ensures the canvas has correct dimensions and layout is fixed
                    // before serialization starts, preventing reflow
                    let final_width = $width
                    let final_height = $height
                    const resize_to = $(config.resize_to)

                    if (resize_to) {
                        const sizes = WGL.initialize_canvas_size(
                            canvas,
                            resize_to,
                            $width,
                            $height,
                            $(config.px_per_unit),
                            $(config.scalefactor)
                        )
                        final_width = sizes[0]
                        final_height = sizes[1]
                    }

                    // Send the real size to Julia to trigger scene resize and serialization
                    $(real_size).notify([final_width, final_height])

                    // Wait for scene serialization to complete
                    $scene_serialized.on((scene_data) => {
                        if (!scene_data) return; // Initial null value

                        try {
                            const renderer = WGL.create_scene(
                                wrapper, canvas, $canvas_width, scene_data, $comm, final_width, final_height,
                                $(config.framerate), $(config.resize_to), $(config.px_per_unit), $(config.scalefactor)
                            )
                            const gl = renderer.getContext()
                            const err = gl.getError()
                            if (err != gl.NO_ERROR) {
                                throw new Error("WebGL error: " + WGL.wglerror(gl, err))
                            }

                            // Remove spinner after successful initialization
                            if (spinner) spinner.remove()
                            $(done_init).notify(true)
                        } catch (e) {
                            if (spinner) spinner.remove()
                            Bonito.Connection.send_error("error initializing scene", e)
                            $(done_init).notify(e)
                            return
                        }

                        return false; // Deregister callback after first successful run
                    })
                } catch (e) {
                    if (spinner) {
                        spinner.remove()
                    }
                    Bonito.Connection.send_error("error setting up scene", e)
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
