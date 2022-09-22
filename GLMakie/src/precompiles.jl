using SnoopPrecompile

macro compile(block)
    return quote
        let
            figlike = $(esc(block))
            screen = Screen(visible=false)
            Makie.backend_display(screen, Makie.get_scene(figlike))
            Makie.colorbuffer(screen)
            close(screen)
        end
    end
end

let
    @precompile_all_calls begin
        GLMakie.activate!()
        GLMakie.inline!(false)
        base_path = normpath(joinpath(dirname(pathof(Makie)), "..", "precompile"))
        shared_precompile = joinpath(base_path, "shared-precompile.jl")
        include(shared_precompile)
    end
    closeall(GLFW_WINDOWS)
    closeall(SINGLETON_SCREEN)
    closeall(SINGLETON_SCREEN_NO_RENDERLOOP)
    nothing
end
