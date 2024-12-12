ENV["ELECTRON_LOG_FILE"] = joinpath(@__DIR__, "electron.log")
ENV["ELECTRON_ENABLE_LOGGING"] = "true"

using FileIO
using WGLMakie, Makie, Test
using WGLMakie.Bonito
using ReferenceTests
import Electron

@testset "mimes" begin
    Makie.inline!(true)
    f, ax, pl = scatter(1:4)
    @testset for mime in Makie.WEB_MIMES
        @test showable(mime(), f)
    end
    # I guess we explicitly don't say we can show those since it's highly Inefficient compared to html
    # See: https://github.com/MakieOrg/Makie.jl/blob/master/WGLMakie/src/display.jl#L66-L68=
    @test !showable("image/png", f)
    @test !showable("image/jpeg", f)
    # see https://github.com/MakieOrg/Makie.jl/pull/2167
    @test !showable("blaaa", f)
end

excludes = Set([
    "Image on Surface Sphere", # TODO: texture rotated 180°
    # "heatmaps & surface", # TODO: fix direct NaN -> nancolor conversion
    "Array of Images Scatter", # scatter does not support texture images

    "Order Independent Transparency",
    "fast pixel marker",
    "Textured meshscatter", # not yet implemented
    "3D Contour with 2D contour slices", # looks like a z-fighting issue
])

Makie.inline!(Makie.automatic)
edisplay = Bonito.use_electron_display(devtools=true)

@testset "reference tests" begin
    @testset "refimages" begin
        WGLMakie.activate!()
        ReferenceTests.mark_broken_tests(excludes)
        recorded_files, recording_dir = @include_reference_tests WGLMakie "refimages.jl"
        missing_images, scores = ReferenceTests.record_comparison(recording_dir, "WGLMakie")
        ReferenceTests.test_comparison(scores; threshold = 0.05)
    end

    @testset "memory leaks" begin
        Makie.CURRENT_FIGURE[] = nothing
        app = App(nothing)
        display(edisplay, app)
        GC.gc(true);
        # Somehow this may take a while to get emptied completely
        p_key = "Object.keys(WGL.plot_cache)"
        value = @time Bonito.wait_for(() -> (GC.gc(true); isempty(run(edisplay.window, p_key))); timeout=50)
        @show run(edisplay.window, p_key)
        @test value == :success

        s_keys = "Object.keys(Bonito.Sessions.SESSIONS)"
        value = @time Bonito.wait_for(() -> (GC.gc(true); length(run(edisplay.window, s_keys)) == 2); timeout=50)
        @show run(edisplay.window, s_keys)
        @show app.session[].id
        @show app.session[].parent
        # It seems, we don't free all sessions right now, which needs fixing.
        # @test value == :success

        wgl_plots = run(edisplay.window, "Object.keys(WGL.scene_cache)")
        @test isempty(wgl_plots)

        session = edisplay.browserdisplay.handler.session
        session_size = Base.summarysize(session) / 10^6
        texture_atlas_size = Base.summarysize(WGLMakie.TEXTURE_ATLAS) / 10^6

        @test length(WGLMakie.TEXTURE_ATLAS.listeners) == 1 # Only one from permanent Retain
        @test length(session.session_objects) == 1 # Also texture atlas because of Retain
        @testset "Session fields empty" for field in [:on_document_load, :stylesheets, :imports, :message_queue, :deregister_callbacks, :inbox]
            @test isempty(getfield(session, field))
        end
        server = session.connection.server
        @test length(server.websocket_routes.table) == 1
        @test server.websocket_routes.table[1][2] == session.connection
        @test length(server.routes.table) == 2
        @test server.routes.table[1][1] == "/browser-display"
        @test server.routes.table[2][2] isa HTTPAssetServer
        @show typeof.(last.(WGLMakie.TEXTURE_ATLAS.listeners))
        @show length(WGLMakie.TEXTURE_ATLAS.listeners)
        @show session_size texture_atlas_size

        # TODO, this went up from 6 to 11mb, likely because of a session not getting freed
        # It could be related to the error in the console:
        # " Trying to send to a closed session"
        # So maybe a subsession closes and doesn't get freed?
        @test session_size < 11
        @test texture_atlas_size < 11

        js_sessions = run(edisplay.window, "Bonito.Sessions.SESSIONS")
        js_objects = run(edisplay.window, "Bonito.Sessions.GLOBAL_OBJECT_CACHE")
        # @test Set([app.session[].id, app.session[].parent.id]) == keys(js_sessions)
        # we used Retain for global_obs, so it should stay as long as root session is open
        @test keys(js_objects) == Set([WGLMakie.TEXTURE_ATLAS.id])
    end

    @testset "Tick Events" begin
        function check_tick(tick, state, count)
            @test tick.state == state
            @test tick.count == count
            @test tick.time > 1e-9
            @test tick.delta_time > 1e-9
        end

        f, a, p = scatter(rand(10));
        @test events(f).tick[] == Makie.Tick()

        filename = "$(tempname()).png"
        try
            tick_record = Makie.Tick[]
            on(tick -> push!(tick_record, tick), events(f).tick)
            save(filename, f)
            idx = findfirst(tick -> tick.state == Makie.OneTimeRenderTick, tick_record)
            tick = tick_record[idx]
            @test tick.state == Makie.OneTimeRenderTick
            @test tick.count == 0
            @test tick.time == 0.0
            @test tick.delta_time == 0.0
        finally
            close(f.scene.current_screens[1])
            rm(filename)
        end


        f, a, p = scatter(rand(10));
        filename = "$(tempname()).mp4"
        try
            tick_record = Makie.Tick[]
            on(tick -> push!(tick_record, tick), events(f).tick)
            record(_ -> nothing, f, filename, 1:10, framerate = 30)

            start = findfirst(tick -> tick.state == Makie.OneTimeRenderTick, tick_record)
            dt = 1.0 / 30.0

            for (i, tick) in enumerate(tick_record[start:end])
                @test tick.state == Makie.OneTimeRenderTick
                @test tick.count == i-1
                @test tick.time ≈ dt * (i-1)
                @test tick.delta_time ≈ dt
            end
        finally
            rm(filename)
        end

        # test destruction of tick overwrite
        f, a, p = scatter(rand(10));
        let
            io = VideoStream(f)
            @test events(f).tick[] == Makie.Tick(Makie.OneTimeRenderTick, 0, 0.0, 1.0 / io.options.framerate)
            nothing
        end
        tick = Makie.Tick(Makie.UnknownTickState, 1, 1.0, 1.0)
        events(f).tick[] = tick
        @test events(f).tick[] == tick

        # TODO: test normal rendering
    end
end
