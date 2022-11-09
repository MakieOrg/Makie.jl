using SnoopPrecompile

macro compile(block)
    return quote
        let
            figlike = $(esc(block))
            Makie.colorbuffer(figlike)
        end
    end
end

let
    @precompile_all_calls begin
        GLMakie.activate!()
        screen = GLMakie.singleton_screen(false)
        close(screen)
        destroy!(screen)
        fig = scatter(1:4)
        screen = Screen(Makie.get_scene(fig), Makie.JuliaNative)
        close(screen)
        screen = Screen()
        fig = scatter(1:4)
        insertplots!(screen, Makie.get_scene(fig))
        close(screen)
        base_path = normpath(joinpath(dirname(pathof(Makie)), "..", "precompile"))
        shared_precompile = joinpath(base_path, "shared-precompile.jl")
        include(shared_precompile)
    end
    closeall()
    nothing
end
