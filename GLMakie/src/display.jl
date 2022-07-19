function Makie.backend_display(::GLBackend, scene::Scene; start_renderloop=true, visible=true, connect=true)
    screen = singleton_screen(size(scene); start_renderloop=start_renderloop, visible=visible)
    ShaderAbstractions.switch_context!(screen.glscreen)
    display_loading_image(screen)
    Makie.backend_display(screen, scene; connect=connect)
    return screen
end

function Makie.backend_display(screen::Screen, scene::Scene; connect=true)
    ShaderAbstractions.switch_context!(screen.glscreen)
    empty!(screen)
    # So, the GLFW window events are not guarantee to fire
    # when we close a window, so we ensure this here!
    window_open = events(scene).window_open
    on(screen.window_open) do open
        window_open[] = open
    end
    connect && connect_screen(scene, screen)
    pollevents(screen)
    insertplots!(screen, scene)
    pollevents(screen)
    return screen
end

function Base.display(screen::Screen, fig::Makie.FigureLike)
    scene = Makie.get_scene(fig)
    Base.resize!(screen, size(scene)...)
    Makie.backend_display(screen, scene)
    return screen
end

"""
    scene2image(scene::Scene)

Buffers the `scene` in an image buffer.
"""
function scene2image(scene::Scene)
    screen = singleton_screen(size(scene), visible=false, start_renderloop=false)
    ShaderAbstractions.switch_context!(screen.glscreen)
    empty!(screen)
    insertplots!(screen, scene)
    return Makie.colorbuffer(screen)
end

function Makie.backend_show(::GLBackend, io::IO, m::MIME"image/png", scene::Scene)
    img = scene2image(scene)
    FileIO.save(FileIO.Stream{FileIO.format"PNG"}(Makie.raw_io(io)), img)
    return
end

function Makie.backend_show(::GLBackend, io::IO, m::MIME"image/jpeg", scene::Scene)
    img = scene2image(scene)
    FileIO.save(FileIO.Stream{FileIO.format"JPEG"}(Makie.raw_io(io)), img)
    return
end
