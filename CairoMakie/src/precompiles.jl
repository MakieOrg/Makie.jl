using SnoopPrecompile

macro compile(block)
    return quote
        figlike = $(esc(block))
        Makie.colorbuffer(figlike)
    end
end

let
    @precompile_all_calls begin
        CairoMakie.activate!()
        base_path = normpath(joinpath(dirname(pathof(Makie)), "..", "precompile"))
        shared_precompile = joinpath(base_path, "shared-precompile.jl")
        include(shared_precompile)
    end
end
