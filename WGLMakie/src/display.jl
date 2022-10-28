
function JSServe.jsrender(session::Session, scene::Scene)
    three, canvas = three_display(session, scene)
    Makie.push_screen!(scene, three)
    return canvas
end

function JSServe.jsrender(session::Session, fig::Makie.FigureLike)
    Makie.update_state_before_display!(fig)
    return JSServe.jsrender(session, Makie.get_scene(fig))
end

const WEB_MIMES = (
    MIME"text/html",
    MIME"application/vnd.webio.application+html",
    MIME"application/prs.juno.plotpane+html",
    MIME"juliavscode/html")


"""
* `framerate = 30`: Set framerate (frames per second) to a higher number for smoother animations, or to a lower to use less resources.
"""
struct ScreenConfig
    framerate::Float64 # =30.0
end

"""
    Screen(args...; screen_config...)

# Arguments one can pass via `screen_config`:

$(Base.doc(ScreenConfig))

# Constructors:

$(Base.doc(MakieScreen))
"""
mutable struct Screen <: Makie.MakieScreen
    three::Channel{ThreeDisplay}
    display::Any
end

for M in WEB_MIMES
    @eval begin
        function Makie.backend_show(screen::Screen, io::IO, m::$M, scene::Scene)
            inline_display = App() do session::Session
                three, canvas, init_obs = three_display(session, scene)
                Makie.push_screen!(scene, three)
                on(init_obs) do _
                    put!(screen.three, three)
                end
                return canvas
            end
            Base.show(io, m, inline_display)
            return screen
        end
    end
end

function Makie.backend_showable(::Type{Screen}, ::T) where {T<:MIME}
    return T in WEB_MIMES
end

function Base.size(screen::Screen)
    return size(get_three(screen))
end

function get_three(screen::Screen)::ThreeDisplay
    return fetch(screen.three)
end

Screen() = Screen(Channel{ThreeDisplay}(1), nothing)

# TODO, create optimized screens, forward more options to JS/WebGL
Screen(::Scene; kw...) = Screen()
Screen(::Scene, ::IO, ::MIME; kw...) = Screen()
Screen(::Scene, ::Makie.ImageStorageFormat; kw...) = Screen()
function Base.empty!(::WGLMakie.Screen)
    # TODO, empty state in JS, to be able to reuse screen
end

function Base.display(screen::Screen, scene::Scene; kw...)
    Makie.push_screen!(scene, screen)
    # Reference to three object which gets set once we serve this to a browser
    app = App() do session, request
        three, canvas, done_init = three_display(session, scene)
        on(done_init) do _
            put!(screen.three, three)
        end
        return canvas
    end
    actual_display = display(app)
    screen.display = actual_display
    return screen
end

function Base.delete!(td::Screen, scene::Scene, plot::AbstractPlot)
    delete!(get_three(td), scene, plot)
end

function session2image(sessionlike)
    yield()
    s = JSServe.session(sessionlike)
    to_data = js"""function (){
        $(WGL).current_renderloop()
        return document.querySelector('canvas').toDataURL()
    }()
    """
    picture_base64 = JSServe.evaljs_value(s, to_data; time_out=100)
    picture_base64 = replace(picture_base64, "data:image/png;base64," => "")
    bytes = JSServe.Base64.base64decode(picture_base64)
    return ImageMagick.load_(bytes)
end

function Makie.colorbuffer(screen::ThreeDisplay)
    return session2image(screen)
end

function Makie.colorbuffer(screen::Screen)
    return session2image(get_three(screen))
end

function Base.insert!(td::Screen, scene::Scene, plot::Combined)
    disp = get_three(td)
    disp === nothing && error("Plot needs to be displayed to insert additional plots")
    insert!(disp, scene, plot)
end
