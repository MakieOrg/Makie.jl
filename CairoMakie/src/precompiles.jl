using SnoopPrecompile

macro compile(block)
    return quote
        figlike = $(esc(block))
        screen = Makie.backend_display(Makie.get_scene(figlike))
        Makie.colorbuffer(screen)
    end
end

let
    @precompile_all_calls begin
        CairoMakie.activate!()
        CairoMakie.inline!(false)
        base_path = normpath(joinpath(dirname(pathof(Makie)), "..", "precompile"))
        shared_precompile = joinpath(base_path, "shared-precompile.jl")
        include(shared_precompile)
    end
end
