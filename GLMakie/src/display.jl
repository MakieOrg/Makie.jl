function Base.display(screen::Screen, scene::Scene; connect = true)
    # So, the GLFW window events are not guarantee to fire
    # when we close a window, so we ensure this here!
    if !Makie.is_displayed(screen, scene)
        if !isnothing(screen.scene)
            delete!(screen, screen.scene)
            screen.scene = nothing
        end
        display_scene!(screen, scene)
    else
        @assert screen.scene === scene "internal error. Scene already displayed by screen but not as root scene"
    end
    pollevents(screen, Makie.BackendTick)
    return screen
end

Makie.backend_showable(::Type{Screen}, ::Union{MIME"image/jpeg", MIME"image/png", Makie.WEB_MIMES...}) = true
