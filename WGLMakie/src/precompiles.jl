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
        foreach(include, Makie.shared_precompile_paths())
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
            # First-update path: attribute updates, the renderobject re-resolve
            # and the resulting websocket update message are what an
            # animation/interaction compiles on its first frame.
            figlike.plot.color = rand(4)
            figlike.plot.markersize = 20.0f0
            Makie.xlims!(figlike.axis, 0, 5)
            Makie.second_resolve(figlike, :wgl_renderobject)
            close(session)
            # scalar color update + limits change (the zoom/pan path) on a
            # default-colored scatter. The serialize_scene is required: it
            # creates the wgl_renderobject nodes whose second resolve (the
            # first update) is the expensive specialization.
            fig2 = Makie.scatter(rand(Point2f, 4))
            WGLMakie.serialize_scene(Makie.get_scene(fig2))
            fig2.plot.color = :red
            fig2.plot.markersize = 10.0f0
            Makie.xlims!(fig2.axis, 0, 5)
            Makie.second_resolve(fig2, :wgl_renderobject)
        end
        # Cleanup globals to avoid serializing stale state (servers, sessions, fonts, figures, tasks)
        # Note: __init__ doesn't run during precompilation, so we must always clean up here
        Bonito.cleanup_globals()
        Makie.cleanup_globals()
        nothing
    end
end
