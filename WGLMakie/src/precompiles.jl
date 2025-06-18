using PrecompileTools

macro compile(block)
    return quote
        let
            figlike = $(esc(block))
            # We don't do something like colorbuffer(fig)
            # since we can't guarantee that the user has a browser setup
            # while precompiling
            # So we just do all parts of the stack we can do without browser
            session = Session()
            app = App(() -> DOM.div(figlike))
            dom = Bonito.session_dom(session, app)
            show(IOBuffer(), Bonito.Hyperscript.Pretty(dom))
            Makie.second_resolve(figlike, :wgl_renderobject)
            close(session)
            return nothing
        end
    end
end

let
    @compile_workload begin
        WGLMakie.activate!()
        base_path = normpath(joinpath(dirname(pathof(Makie)), "..", "precompile"))
        shared_precompile = joinpath(base_path, "shared-precompile.jl")
        include(shared_precompile)
        empty!(SCENE_ATLASES)
        Makie.CURRENT_FIGURE[] = nothing
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
