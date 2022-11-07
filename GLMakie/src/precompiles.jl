using SnoopPrecompile

macro compile(block)
    return quote
        let
            figlike = $(esc(block))
            screen = Screen(visible=false)
            display(screen, figlike)
            Makie.colorbuffer(screen)
            close(screen)
        end
    end
end

let
    @precompile_all_calls begin
        GLMakie.activate!()
        base_path = normpath(joinpath(dirname(pathof(Makie)), "..", "precompile"))
        shared_precompile = joinpath(base_path, "shared-precompile.jl")
        include(shared_precompile)
    end
    closeall()
    nothing
end
