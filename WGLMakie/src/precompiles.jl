using PrecompileTools

macro compile(block)
    return quote
        let
            figlike = $(esc(block))
            # Exercise rendering without starting Electron during precompilation.
            session = Session()
            app = App(() -> DOM.div(figlike))
            dom = Bonito.session_dom(session, app)
            show(IOBuffer(), dom)
            Makie.second_resolve(figlike, :wgl_renderobject)
            serialize_scene(Makie.get_scene(figlike))
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
        # Cover binary messages and the first interaction/resize after display.
        let
            figlike = Makie.scatter(1:4; color = rand(4))
            session = Session()
            app = App(() -> DOM.div(figlike))
            dom = Bonito.session_dom(session, app)
            show(IOBuffer(), dom)
            data = WGLMakie.serialize_scene(Makie.get_scene(figlike))
            Bonito.serialize_binary(session, data)
            figlike.plot.color = rand(4)
            figlike.plot.markersize = 20.0f0
            Makie.xlims!(figlike.axis, 0, 5)
            resize!(Makie.get_scene(figlike), 850, 650)
            Makie.second_resolve(figlike, :wgl_renderobject)
            close(session)
            # Also cover scalar colors on a default-colored scatter.
            fig2 = Makie.scatter(rand(Point2f, 4))
            WGLMakie.serialize_scene(Makie.get_scene(fig2))
            fig2.plot.color = :red
            fig2.plot.markersize = 10.0f0
            Makie.xlims!(fig2.axis, 0, 5)
            Makie.second_resolve(fig2, :wgl_renderobject)
        end
        # Loading Makie invalidates Bonito's serving methods; cache them again with a figure.
        Bonito.serve_workload(App(() -> DOM.div(Makie.scatter(1:4), Bonito.Slider(1:10))))
        # the canvas readback decodes a base64 png string (session2image)
        Bonito.Base64.base64decode(Bonito.Base64.base64encode(rand(UInt8, 256)))
        # Do not retain servers, figures or tasks in the package image.
        Bonito.cleanup_globals()
        Makie.cleanup_globals()
        nothing
    end
end

# Electron cannot run in a precompile workload; compile these entry points directly.
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
