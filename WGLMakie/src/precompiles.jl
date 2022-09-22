using SnoopPrecompile

macro compile(block)
    return quote
        figlike = $(esc(block))
        scene = Makie.get_scene(figlike)
        three_display(Session(), scene)
        JSServe.jsrender(Session(), figlike)
        s = serialize_scene(scene)
        JSServe.serialize_binary(Session(), Dict(:data=>s))
    end
end

let
    @precompile_all_calls begin
        WGLMakie.activate!()
        base_path = normpath(joinpath(dirname(pathof(Makie)), "..", "precompile"))
        shared_precompile = joinpath(base_path, "shared-precompile.jl")
        include(shared_precompile)
    end
end
