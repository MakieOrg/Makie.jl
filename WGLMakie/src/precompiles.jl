using SnoopPrecompile

macro compile(block)
    return quote
        figlike = $(esc(block))
        # We don't do something like colorbuffer(fig)
        # since we can't guarantee that the user has a browser setup
        # while precompiling
        # So we just do all parts of the stack we can do without browser
        scene = Makie.get_scene(figlike)
        session = Session(JSServe.NoConnection(); asset_server=JSServe.NoServer())
        three_display(session, scene)
        JSServe.jsrender(session, figlike)
        s = serialize_scene(scene)
        JSServe.serialize_binary(session, Dict(:data => s))
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
