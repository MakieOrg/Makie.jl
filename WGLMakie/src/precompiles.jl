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
        include(Makie.SHARED_PRECOMPILE_PATH)
        # The binary websocket message path: packing a serialized scene is
        # what a live browser connection compiles on first display.
        let
            figlike = Makie.scatter(1:4; color = rand(4))
            session = Session()
            app = App(() -> DOM.div(figlike))
            dom = Bonito.session_dom(session, app)
            show(IOBuffer(), dom)
            data = WGLMakie.serialize_scene(Makie.get_scene(figlike))
            Bonito.serialize_binary(session, data)
            close(session)
        end
        # Cleanup globals to avoid serializing stale state (servers, sessions, fonts, figures, tasks)
        # Note: __init__ doesn't run during precompilation, so we must always clean up here
        Bonito.cleanup_globals()
        Makie.cleanup_globals()
        nothing
    end
end
