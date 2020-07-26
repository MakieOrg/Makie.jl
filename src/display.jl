
function JSServe.jsrender(session::Session, scene::Scene)
    three, canvas = WGLMakie.three_display(session, scene)
    return canvas
end

const WEB_MIMES = (MIME"text/html", MIME"application/vnd.webio.application+html",
                   MIME"application/prs.juno.plotpane+html")
for M in WEB_MIMES
    @eval begin
        function AbstractPlotting.backend_show(::WGLBackend, io::IO, m::$M, scene::Scene)
            three = nothing
            inline_display = JSServe.with_session() do session, request
                three, canvas = three_display(session, scene)
                return canvas
            end
            Base.show(io, m, inline_display)
            return three
        end
    end
end

function scene2image(scene::Scene)
    three = nothing
    session = nothing
    inline_display = JSServe.with_session() do s, request
        session = s
        three, canvas = three_display(s, scene)
        return canvas
    end
    electron_display = display(inline_display)
    task = @async wait(session.js_fully_loaded)
    tstart = time()
    # Jeez... Base.Event was a nice idea for waiting on
    # js to be ready, but if anything fails, it becomes unkillable -.-
    while !istaskdone(task)
        sleep(0.01)
        (time() - tstart > 30) && error("JS Session not ready after 30s waiting")
    end
    # HMMMMPFH... This is annoying - we really need to find a way to have
    # devicePixelRatio work correctly
    img_device_scale = AbstractPlotting.colorbuffer(three)
    return ImageTransformations.imresize(img_device_scale, reverse(size(scene)))
end

function AbstractPlotting.backend_show(::WGLBackend, io::IO, m::MIME"image/png",
                                       scene::Scene)
    img = scene2image(scene)
    return FileIO.save(FileIO.Stream(FileIO.format"PNG", io), img)
end

function AbstractPlotting.backend_show(::WGLBackend, io::IO, m::MIME"image/jpeg",
                                       scene::Scene)
    img = scene2image(scene)
    return FileIO.save(FileIO.Stream(FileIO.format"JPEG", io), img)
end

function AbstractPlotting.backend_showable(::WGLBackend, ::T, scene::Scene) where {T<:MIME}
    return T in WEB_MIMES
end

function session2image(sessionlike)
    s = JSServe.session(sessionlike)
    to_data = js"document.querySelector('canvas').toDataURL()"
    picture_base64 = JSServe.evaljs_value(s, to_data)
    picture_base64 = replace(picture_base64, "data:image/png;base64," => "")
    bytes = JSServe.Base64.base64decode(picture_base64)
    return ImageMagick.load_(bytes)
end

function AbstractPlotting.colorbuffer(screen::ThreeDisplay)
    return session2image(screen)
end

function three_display(session::Session, scene::Scene)
    update!(scene)

    serialized = serialize_scene(scene)
    smaller_serialized = replace_dublicates(serialized)
    # smaller_serialized = [serialized, []]
    JSServe.register_resource!(session, smaller_serialized[1])
    width, height = size(scene)
    canvas = DOM.um("canvas", width=width, height=height)
    comm = Observable(Dict{String,Any}())
    scene_data = Observable(smaller_serialized)
    context = JSObject(session, :context)

    setup = js"""
    function setup([scenes, duplicates]){
        const canvas = $(canvas)
        const renderer = $(WGL).threejs_module(canvas, $comm, $width, $height)
        $(WGL).set_duplicate_references(duplicates)
        const three_scenes = scenes.map($(WGL).deserialize_scene)
        const cam = new $(WGLMakie.THREE).PerspectiveCamera(45, 1, 0, 100)
        console.log(three_scenes)
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

        function add_plot(scene, plot) {
            const mesh = $(WGL).deserialize_plot(plot);
        }
        const context = {
            three_scenes,
            add_plot,
            get_plot,
            renderer
        }
        put_on_heap($(uuidstr(context)), context);
    }
    """

    JSServe.onjs(session, scene_data, setup)
    WGLMakie.connect_scene_events!(session, scene, comm)
    WGLMakie.mousedrag(scene, nothing)
    scene_data[] = scene_data[]

    canvas_width = lift(x -> [round.(Int, widths(x))...], pixelarea(scene))
    onjs(session, canvas_width, js"""function update_size(canvas_width){
        const context = $(context);
        const w_h = deserialize_js(canvas_width);
        context.renderer.setSize(w_h[0], w_h[1]);
        var canvas = $(canvas)
        canvas.style.width = w_h[0];
        canvas.style.height = w_h[1];
    }""")
    connect_scene_events!(session, scene, comm)
    mousedrag(scene, nothing)
    three = ThreeDisplay(context)
    push!(scene.current_screens, three)
    return three, canvas
end


function AbstractPlotting.backend_display(::WGLBackend, scene::Scene)
    three = nothing
    inline_display = JSServe.with_session() do s, request
        session = s
        three, canvas = three_display(s, scene)
        return canvas
    end
    electron_display = display(inline_display)
    return three
end
