using PrecompileTools

macro compile(block)
    return quote
        let
            figlike = $(esc(block))
            # We don't do something like colorbuffer(fig)
            # since we can't guarantee that the user has a browser setup
            # while precompiling
            # So we just do all parts of the stack we can do without browser
            scene = Makie.get_scene(figlike)
            session = Session(Bonito.NoConnection(); asset_server=Bonito.NoServer())
            three_display(Screen(scene), session, scene)
            Bonito.jsrender(session, figlike)
            s = serialize_scene(scene)
            Bonito.SerializedMessage(session, Dict(:data => s))
            session = Session()
            app = App(()-> DOM.div(figlike))
            dom = Bonito.session_dom(session, app)
            show(IOBuffer(), Bonito.Hyperscript.Pretty(dom))
            close(session)
            return nothing
        end
    end
end

let
    @compile_workload begin
        DISABLE_JS_FINALZING[] = true # to not start cleanup task
        WGLMakie.activate!()
        base_path = normpath(joinpath(dirname(pathof(Makie)), "..", "precompile"))
        shared_precompile = joinpath(base_path, "shared-precompile.jl")
        include(shared_precompile)
        Makie.CURRENT_FIGURE[] = nothing
        Observables.clear(TEXTURE_ATLAS)
        TEXTURE_ATLAS[] = Float32[]
        # This should happen in atexit in Bonito, but on Julia versions below v1.11
        # atexit isn't called
        for (task, (task, close_ref)) in Bonito.SERVER_CLEANUP_TASKS
            close_ref[] = false
        end
        Bonito.CURRENT_SESSION[] = nothing
        if !isnothing(Bonito.GLOBAL_SERVER[])
            close(Bonito.GLOBAL_SERVER[])
        end
        Bonito.GLOBAL_SERVER[] = nothing
        nothing
    end
end
