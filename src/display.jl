
function JSServe.jsrender(session::Session, scene::Scene)
    three, canvas = WGLMakie.three_display(session, scene)
    return canvas
end

const WEB_MIMES = (MIME"text/html", MIME"application/vnd.webio.application+html", MIME"application/prs.juno.plotpane+html")
for M in WEB_MIMES
    @eval begin
        function AbstractPlotting.backend_show(::WGLBackend, io::IO, m::$M, scene::Scene)
            three = nothing
            inline_display = JSServe.with_session() do session, request
                three, canvas = three_display(session, scene)
                canvas
            end
            Base.show(io, m, inline_display)
            return three
        end
    end
end

function scene2image(scene::Scene)
    three = nothing; session = nothing
    inline_display = JSServe.with_session() do s, request
        session = s
        three, canvas = three_display(s, scene)
        canvas
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

function AbstractPlotting.backend_show(::WGLBackend, io::IO, m::MIME"image/png", scene::Scene)
    img = scene2image(scene)
    FileIO.save(FileIO.Stream(FileIO.format"PNG", io), img)
end

function AbstractPlotting.backend_show(::WGLBackend, io::IO, m::MIME"image/jpeg", scene::Scene)
    img = scene2image(scene)
    FileIO.save(FileIO.Stream(FileIO.format"JPEG", io), img)
end

function AbstractPlotting.backend_showable(::WGLBackend, ::T, scene::Scene) where T <: MIME
    return T in WEB_MIMES
end

function session2image(sessionlike)
    s = JSServe.session(sessionlike)
    picture_base64 = JSServe.evaljs_value(s, js"document.querySelector('canvas').toDataURL()")
    picture_base64 = replace(picture_base64, "data:image/png;base64," => "")
    bytes = JSServe.Base64.base64decode(picture_base64)
    return ImageMagick.load_(bytes)
end

function AbstractPlotting.colorbuffer(screen::ThreeDisplay)
    return session2image(screen)
end
