
function JSServe.jsrender(session::Session, scene::Scene)
    three, canvas = WGLMakie.three_display(session, scene)
    Makie.push_screen!(scene, three)
    return canvas
end

function JSServe.jsrender(session::Session, scene::Makie.FigureLike)
    return JSServe.jsrender(session, Makie.get_scene(scene))
end

const WEB_MIMES = (MIME"text/html", MIME"application/vnd.webio.application+html",
                   MIME"application/prs.juno.plotpane+html", MIME"juliavscode/html")

for M in WEB_MIMES
    @eval begin
        function Makie.backend_show(::WGLBackend, io::IO, m::$M, scene::Scene)
            three = nothing
            inline_display = App() do session::Session
                three, canvas = three_display(session, scene)
                Makie.push_screen!(scene, three)
                return canvas
            end
            Base.show(io, m, inline_display)
            return three
        end
    end
end

function scene2image(scene::Scene)
    if !JSServe.has_html_display()
        error("""
        There is no Display that can show HTML.
        If in the REPL and you have a browser,
        you can always run `JSServe.browser_display()` to show plots in the browser
        """)
    end
    three = nothing
    session = nothing
    app = App() do s::Session
        session = s
        three, canvas = three_display(s, scene)
        return canvas
    end
    # display in current
    display(app)
    done = Base.timedwait(()-> isready(session.js_fully_loaded), 30.0)
    if done == :timed_out
        error("JS Session not ready after 30s waiting, possibly errored while displaying")
    end
    return Makie.colorbuffer(three)
end

function Makie.backend_show(::WGLBackend, io::IO, m::MIME"image/png",
                                       scene::Scene)
    img = scene2image(scene)
    return FileIO.save(FileIO.Stream{FileIO.format"PNG"}(io), img)
end

function Makie.backend_show(::WGLBackend, io::IO, m::MIME"image/jpeg",
                                       scene::Scene)
    img = scene2image(scene)
    return FileIO.save(FileIO.Stream{FileIO.format"JPEG"}(io), img)
end

function Makie.backend_showable(::WGLBackend, ::T, scene::Scene) where {T<:MIME}
    return T in WEB_MIMES
end

struct WebDisplay <: Makie.AbstractScreen
    three::Base.RefValue{ThreeDisplay}
    display::Any
end
            
GeometryBasics.widths(screen::WebDisplay) = GeometryBasics.widths(screen.three[])

function Makie.backend_display(::WGLBackend, scene::Scene; kw...)
    # Reference to three object which gets set once we serve this to a browser
    three_ref = Base.RefValue{ThreeDisplay}()
    app = App() do s, request
        three, canvas = three_display(s, scene)
        three_ref[] = three
        return canvas
    end
    actual_display = display(app)
    return WebDisplay(three_ref, actual_display)
end

function Base.delete!(td::WebDisplay, scene::Scene, plot::AbstractPlot)
    delete!(get_three(td), scene, plot)
end

function session2image(sessionlike)
    s = JSServe.session(sessionlike)
    to_data = js"document.querySelector('canvas').toDataURL()"
    picture_base64 = JSServe.evaljs_value(s, to_data; time_out=100)
    picture_base64 = replace(picture_base64, "data:image/png;base64," => "")
    bytes = JSServe.Base64.base64decode(picture_base64)
    return ImageMagick.load_(bytes)
end

function Makie.colorbuffer(screen::ThreeDisplay)
    return session2image(screen)
end

function get_three(screen::WebDisplay; timeout = 30)::Union{Nothing, ThreeDisplay}
    # WebDisplay is not guaranteed to get displayed in the browser, so we wait a while
    # to see if anything gets displayed!
    tstart = time()
    while time() - tstart < timeout
        if isassigned(screen.three)
            three = screen.three[]
            session = JSServe.session(three)
            if isready(session.js_fully_loaded)
                # Error on js during init! We can't continue like this :'(
                if session.init_error[] !== nothing
                    throw(session.init_error[])
                end
                return three
            end
        end
        yield()
    end
    return nothing
end

function Makie.colorbuffer(screen::WebDisplay)
    return session2image(get_three(screen))
end

function Base.insert!(td::WebDisplay, scene::Scene, plot::Combined)
    disp = get_three(td)
    disp === nothing && error("Plot needs to be displayed to insert additional plots")
    insert!(disp, scene, plot)
end
