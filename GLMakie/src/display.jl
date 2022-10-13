function Base.display(screen::Screen, scene::Scene; connect=true)
    empty!(screen)
    resize!(screen, size(scene)...)
    # So, the GLFW window events are not guarantee to fire
    # when we close a window, so we ensure this here!
    on(screen.window_open) do open
        events(scene).window_open[] = open
    end
    connect && connect_screen(scene, screen)
    Makie.push_screen!(scene, screen)
    pollevents(screen)
    insertplots!(screen, scene)
    pollevents(screen)
    return screen
end

Makie.backend_showable(::Type{Screen}, ::Union{MIME"image/jpeg", MIME"image/png"}) = true
