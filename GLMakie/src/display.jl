function Base.display(screen::Screen, scene::Scene; connect=true)
    # So, the GLFW window events are not guarantee to fire
    # when we close a window, so we ensure this here!
    if !Makie.is_displayed(screen, scene)
        display_scene!(screen, scene)
    else
        @assert screen.root_scene === scene "internal error. Scene already displayed by screen but not as root scene"
    end
    pollevents(screen)
    return screen
end

Makie.backend_showable(::Type{Screen}, ::Union{MIME"image/jpeg", MIME"image/png"}) = true
