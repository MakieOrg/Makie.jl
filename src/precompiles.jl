using SnoopPrecompile

macro compile(block)
    return quote
        let
            $(esc(block))
        end
    end
end

let
    @precompile_all_calls begin
        base_path = normpath(joinpath(dirname(pathof(Makie)), "..", "precompile"))
        shared_precompile = joinpath(base_path, "shared-precompile.jl")
        include(shared_precompile)
        empty!(FONT_CACHE)
        empty!(_default_font)
        empty!(_alternative_fonts)
    end
    nothing
end
