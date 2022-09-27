function Base.display(screen::Screen, scene::Scene; connect=true)
    ShaderAbstractions.switch_context!(screen.glscreen)
    empty!(screen)
    resize!(screen, size(scene)...)
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
