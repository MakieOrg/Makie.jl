using SnoopPrecompile

function compileit(figlike)
    # while precompiling
    # So we just do all parts of the stack we can do without browser
    scene = Makie.get_scene(figlike)
    session = Session(JSServe.NoConnection(); asset_server=JSServe.NoServer())
    three_display(session, scene)
    JSServe.jsrender(session, figlike)
    s = serialize_scene(scene)
    JSServe.SerializedMessage(session, Dict(:data => s))
    close(session)
    return nothing
end

let
    @precompile_all_calls begin
        DISABLE_JS_FINALZING[] = true # to not start cleanup task
        WGLMakie.activate!()
        logo = Makie.logo()
        fig = Makie.cheatsheet_3d(randn(10), logo)
        compileit(fig)
        fig = Makie.cheatsheet_2d(logo)
        compileit(fig)
        Makie._current_figure[] = nothing
        Observables.clear(TEXTURE_ATLAS)
        TEXTURE_ATLAS[] = Float32[]
        nothing
    end
end
