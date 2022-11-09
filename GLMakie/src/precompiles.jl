using SnoopPrecompile

macro compile(block)
    return quote
        let
            figlike = $(esc(block))
            Makie.display(figlike; visible=false)
            Makie.colorbuffer(figlike)
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
