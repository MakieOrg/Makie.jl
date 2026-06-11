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
            # the render loop polls every displayed plot type for
            # renderobject updates - cover that per plot type here
            WGLMakie.poll_all_plots(Makie.get_scene(figlike))
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
            # every real display triggers a resize (browser reports the actual
            # canvas size), which re-resolves the whole graph - cover it so the
            # typed resolve chains built on that path are precompiled
            resize!(Makie.get_scene(figlike), 850, 650)
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
        # Serve a real figure app through Bonito's loopback workload helper
        # (page + asset request, websocket announce + observable update).
        # Bonito's own workload already covers the plain serve path, but
        # loading Makie INVALIDATES the precompiled listener/stream-handler/
        # ws-decoder instances (~3.5s of recompilation on the first
        # colorbuffer otherwise) - re-exercising the serve path here caches
        # the post-Makie versions in WGLMakie's pkgimage, and serving an
        # actual figure additionally compiles the figure jsrender path.
        Bonito.serve_workload(App(() -> DOM.div(Makie.scatter(1:4), Bonito.Slider(1:10))))
        # the canvas readback decodes a base64 png string (session2image)
        Bonito.Base64.base64decode(Bonito.Base64.base64encode(rand(UInt8, 256)))
        # Cleanup globals to avoid serializing stale state (servers, sessions, fonts, figures, tasks)
        # Note: __init__ doesn't run during precompilation, so we must always clean up here
        Bonito.cleanup_globals()
        Makie.cleanup_globals()
        nothing
    end
end

# Electron cannot run while precompiling, so the display entry points are
# compiled via directives. Bonito has the same display directive, but loading
# Makie invalidates it - these re-cache the post-Makie versions.
precompile(Base.display, (Bonito.HTTPServer.ElectronDisplay, Bonito.App))
precompile(Tuple{typeof(Core.kwcall), NamedTuple{(:figure,), Tuple{Makie.FigureAxisPlot}}, typeof(Makie.colorbuffer), Screen, Makie.ImageStorageFormat})
precompile(Tuple{typeof(Core.kwcall), NamedTuple{(:px_per_unit,), Tuple{Int64}}, typeof(Makie.colorbuffer), Makie.FigureAxisPlot})
# the resize/serialize task every real display runs once the browser reports
# the actual canvas size (the JS payload arrives as Vector{Any})
precompile(apply_real_size!, (Screen, Makie.Scene, Makie.TrackedTask, Observable{Union{Nothing, Dict{Symbol, Any}}}, Observable{Any}, Tuple{Int, Int}, Vector{Any}))
# the canvas readback that colorbuffer waits on
precompile(session2image, (Bonito.Session{Bonito.WebSocketConnection}, Makie.Scene))
# the 100Hz renderobject polling task every display starts
precompile(run_polling_loop, (Screen, Makie.Scene, Threads.Atomic{Bool}))
# post-init wiring + per-tick body: these only run once the browser finishes
# initializing, so the workload cannot reach them by execution
precompile(connect_post_init_events, (Screen, Makie.Scene))
precompile(scene_tick!, (Makie.Scene, Makie.Events, Makie.TickCallback, Makie.BudgetedTimer))
