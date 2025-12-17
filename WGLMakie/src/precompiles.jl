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
            show(IOBuffer(), dom)
            Makie.second_resolve(figlike, :wgl_renderobject)
            close(session)
            yield()
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
        # Cleanup is handled by:
        # - Bonito.__init__ atexit (SERVER_CLEANUP_TASKS, CURRENT_SESSION, GLOBAL_SERVER)
        # - Bonito session metadata (SCENE_ATLASES, SCENE_ORDER - cleaned up with session)
        # - Makie.current_figure! atexit (CURRENT_FIGURE)
        # - Makie.async_tracked atexit (TRACKED_TASKS)
        nothing
    end
end
