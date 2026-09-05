ENV["ENABLE_COMPUTE_CHECKS"] = "true"
ENV["ELECTRON_LOG_FILE"] = joinpath(@__DIR__, "electron.log")
ENV["ELECTRON_ENABLE_LOGGING"] = "true"

using FileIO
using WGLMakie, Makie, Test
using WGLMakie.Bonito
using ReferenceTests
using Makie: N0f8, RGBA
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

excludes = Set(
    [
        "Image on Surface Sphere", # TODO: texture rotated 180°
        "Array of Images Scatter", # scatter does not support texture images
        "Order Independent Transparency",
        "Mesh with 3d volume texture", # Not implemented yet
        "matcap", # not yet implemented
    ]
)

Makie.inline!(Makie.automatic)
edisplay = Bonito.use_electron_display(devtools = true)

@testset "reference tests" begin
    WGLMakie.activate!()

    @testset "ComputeGraph Sanity Checks" begin
        # This is supposed to catch changes in ComputePipeline causing nodes to
        # be skipped or become duplicated. This will also trigger if plot attributes
        # are modified in which case the numbers should just be updated
        f, a, p = scatter(rand(10))
        colorbuffer(f)
        @test length(p.attributes.inputs) == 38
        @test length(p.attributes.outputs) == 95
    end

    @testset "refimages" begin
        ReferenceTests.mark_broken_tests(excludes)
        attempted_tests, recording_dir = @include_reference_tests WGLMakie "refimages.jl" joinpath(@__DIR__, "html_widgets_refimages.jl")
        missing_images, scores, exempt = ReferenceTests.record_comparison(recording_dir, "WGLMakie"; attempted_tests)
        ReferenceTests.test_comparison(scores; threshold = 0.05, exempt)
    end

    @testset "js texture atlas" begin
        atlas = Makie.get_texture_atlas()
        marker = collect(keys(atlas.mapping))

        positions = map(enumerate(marker)) do (i, m)
            Point2f((i % 19) * 50, (i ÷ 19) * 50)
        end
        msize = map(marker) do m
            uv = atlas.uv_rectangles[atlas.mapping[m]]
            reverse(Vec2f((uv[Vec(3, 4)] .- uv[Vec(1, 2)]) .* 2048))
        end
        # Make sure all sdfs inside texture atlas are send to JS!
        s = Scene()
        cam2d!(s)
        scatter!(s, positions, marker = marker, markersize = msize, markerspace = :data)
        center!(s)
        img = colorbuffer(s)

        js_tex_atlas = evaljs_value(s.current_screens[1].session, js"WGL.get_texture_atlas().data")
        js_atlas_data = reshape(Bonito.decode_extension_and_addbits(js_tex_atlas), (2048, 2048))
        # Code to look at the atlas (reference test?)
        # f, ax, pl = contour(js_atlas_data, color=:red, levels=[0.0, 15.0], alpha=0.5)
        # hidedecorations!(ax)
        # pl = contour!(ax, atlas.data, color=:black, levels=[0.0, 15.0], alpha=1.0)
        # ax3, pl = image(f[1, 2], img, uv_transform=Mat{2,3,Float32}(0, 1, 1, 0, 0, 0))
        # hidedecorations!(ax3)
        # f
        @test atlas.data ≈ js_atlas_data
    end


    @testset "window open/closed" begin
        f, a, p = scatter(rand(10))
        @test events(f).window_open[] == false
        @test Makie.isclosed(f.scene) == false
        @test isempty(f.scene.current_screens) || !isopen(first(f.scene.current_screens))
        # This may take a bit
        @testset "screen closing after not begin displayed anymore" begin
            display(edisplay, App(f))
            Bonito.wait_for(() -> events(f).window_open[])
            @test !isempty(f.scene.current_screens)
            screen = f.scene.current_screens[1]
            @test events(f).window_open[] == true
            @test Makie.isclosed(f.scene) == false
            @test isopen(screen)
            display(edisplay, App(nothing))
            Bonito.wait_for(() -> events(f).window_open[] == false)
            @test !isopen(screen)
            @test events(f).window_open[] == false
            @test Makie.isclosed(f.scene) == true
        end
        @testset "screen with explicit close" begin
            f, a, p = scatter(rand(10))
            display(edisplay, App(f))
            Bonito.wait_for(() -> events(f).window_open[])
            @test !isempty(f.scene.current_screens)
            screen = f.scene.current_screens[1]
            @test events(f).window_open[] == true
            @test Makie.isclosed(f.scene) == false
            close(f.scene.current_screens[1])
            @test events(f).window_open[] == false
            @test Makie.isclosed(f.scene) == true
            @test Makie.isopen(f.scene) == false
        end
    end

    @testset "small float passthrough" begin
        scene = Scene()
        p1 = volume!(scene, fill(N0f8(0.5), 4, 4, 4)::Array{N0f8, 3})
        p2 = volume!(scene, fill(Float16(0.5), 4, 4, 4))
        p3 = volume!(scene, fill(RGBA{N0f8}(0.5, 0.5, 0.5, 0.5), 4, 4, 4), algorithm = :absorptionrgba)
        p4 = volume!(scene, fill(RGBA{Float16}(0.5, 0.5, 0.5, 0.5), 4, 4, 4), algorithm = :absorptionrgba)
        # p5 = mesh!(scene, Rect2f(0,0,1,1), color = rand(RGBA{N0f8}, 4, 4))
        # p6 = scatter!(scene, 1:4, color = rand(N0f8, 4))
        display(edisplay, App(scene))
        Bonito.wait_for(() -> events(scene).window_open[])
        sleep(2)

        @test eltype(p1.wgl_renderobject[][:uniforms][:uniform_color][:data]) === N0f8
        @test eltype(p2.wgl_renderobject[][:uniforms][:uniform_color][:data]) === Float16
        @test eltype(p3.wgl_renderobject[][:uniforms][:uniform_color][:data]) === UInt8 # RGBA gets splatted
        @test_broken eltype(p4.wgl_renderobject[][:uniforms][:uniform_color][:data]) === Float16 # can we allow Float16 to pass to js?
        # @test eltype(p5.gl_renderobject[][:image]) === RGBA{N0f8}
        # @test eltype(p6.gl_renderobject[].vertexarray.buffers["intensity"]) === N0f8
    end

    @testset "Tick Events" begin
        function check_tick(tick, state, count)
            @test tick.state == state
            @test tick.count == count
            @test tick.time > 1.0e-9
            @test tick.delta_time > 1.0e-9
        end

        @testset "save()" begin
            f, a, p = scatter(rand(10))
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
        end

        @testset "record()" begin
            f, a, p = scatter(rand(10))
            filename = "$(tempname()).mp4"
            try
                tick_record = Makie.Tick[]
                on(tick -> push!(tick_record, tick), events(f).tick)
                record(_ -> nothing, f, filename, 1:10, framerate = 30)

                start = findfirst(tick -> tick.state == Makie.OneTimeRenderTick, tick_record)
                dt = 1.0 / 30.0

                for (i, tick) in enumerate(tick_record[start:end])
                    @test tick.state == Makie.OneTimeRenderTick
                    @test tick.count == i - 1
                    @test tick.time ≈ dt * (i - 1)
                    @test tick.delta_time ≈ dt
                end
            finally
                rm(filename)
            end

            # test destruction of tick overwrite
            f, a, p = scatter(rand(10))
            colorbuffer(f) # trigger screen creation

            let
                io = VideoStream(f)
                @test events(f).tick[] == Makie.Tick(Makie.OneTimeRenderTick, 0, 0.0, 1.0 / io.options.framerate)
                nothing
            end
            tick = Makie.Tick(Makie.UnknownTickState, 1, 1.0, 1.0)
            events(f).tick[] = tick
            @test events(f).tick[] == tick
        end


        @testset "normal render()" begin
            f, a, p = scatter(rand(10))
            tick_record = Makie.Tick[]
            on(t -> push!(tick_record, t), events(f).tick)
            sleep(0.2)

            # should be empty (or at least not contain Render ticks yet?)
            @test isempty(tick_record)

            render_time = 20
            colorbuffer(f)
            sleep(render_time)
            close(f.scene.current_screens[1])
            sleep(5)

            # Check:
            # 1. `colorbuffer` started producing ticks at roughly 30 ticks/s
            # 2. `close` stopped tick production
            # To verify this we check that the number of ticks is proportional
            # to the real render time, which should be close to the sleep time.
            @test render_time * 30 - 1 <= length(tick_record) <= render_time * 30 + 20

            t = 0.0
            for (i, tick) in enumerate(tick_record)
                @test tick.state == Makie.RegularRenderTick
                @test tick.count == i
                @test tick.time > t
                t = tick.time
            end

            # Each tick aims to trigger at t = N * 1/30 + t0 where N is some
            # whole number. Consecutive ticks will usually be at N and N+1, but
            # can skip to N+2 or more if other sources delay them too much.
            # Sleep is also fairly inaccurate so the variance is rather large
            # Test: tick.time follow N * 1/30
            dt = 1 / 30
            dist_from_target = map(tick -> ((tick.time + 0.5dt) % dt) - 0.5dt, tick_record)
            t0 = mean(dist_from_target)
            dist_from_target .-= t0
            standard_error = sqrt(mapreduce(t -> t * t, +, dist_from_target) / length(dist_from_target))
            @test standard_error < 0.2dt

            # Ticks will usually get increasing delayed (or early) and eventually
            # correct themselves by sleeping less. This will then average out
            # to a lower error over multiple samples
            window = 10
            windowed_dist = [mean(dist_from_target[i:(i + window)]) for i in 1:(length(dist_from_target) - window)]
            standard_error = sqrt(mapreduce(t -> t * t, +, windowed_dist) / length(windowed_dist))
            @test standard_error < 0.05dt

            # delta times should average out to 1/30, with the caveat that ticks
            # can sometimes get skipped/merge into a N * 1/30 tick. Those ticks
            # need to count as N ticks in the mean then.
            # This is somewhat self-fulling...
            av = last(tick_record).time / round(Int, last(tick_record).time * 30)
            @test abs(av - dt) < 0.005dt
        end
    end

    @testset "html-widgets" begin
        include("html-widgets.jl")
    end

    @testset "memory leaks" begin
        Makie.CURRENT_FIGURE[] = nothing
        app = App(nothing)
        display(edisplay, app)
        GC.gc(true)
        # Somehow this may take a while to get emptied completely
        p_key = "Object.keys(WGL.plot_cache)"
        value = @time Bonito.wait_for(() -> (GC.gc(true); isempty(run(edisplay.window, p_key))); timeout = 50)
        @show run(edisplay.window, p_key)
        @test value == :success

        s_keys = "Object.keys(Bonito.Sessions.SESSIONS)"
        value = @time Bonito.wait_for(() -> (GC.gc(true); length(run(edisplay.window, s_keys)) == 2); timeout = 50)
        @show run(edisplay.window, s_keys)
        @show app.session[].id
        @show app.session[].parent
        # It seems, we don't free all sessions right now, which needs fixing.
        # @test value == :success

        wgl_plots = run(edisplay.window, "Object.keys(WGL.scene_cache)")
        @test isempty(wgl_plots)

        session = edisplay.browserdisplay.handler.session
        # Measure Bonito's own session state, NOT the transport layer underneath it.
        # `session.connection.handler.socket` is an HTTP.jl WebSocket whose send
        # buffer (`WSConn.outgoing`) retains the capacity of the largest frame ever
        # sent (by design: zero-alloc steady-state writes) and is freed only when the
        # connection closes. This is the *hot* page session, kept open for the whole
        # run, so a plain `summarysize` would charge it tens of MB of HTTP send-buffer
        # capacity that isn't session state. Stop the walk at the HTTP WebSocket
        # boundary; everything Bonito owns is still counted (verified: stashing an
        # array in `session_objects` still grows this number).
        http_socket_type = typeof(session.connection.handler.socket).name.wrapper
        session_size = Base.summarysize(
            session;
            exclude = Union{DataType, Core.TypeName, Core.MethodInstance, http_socket_type},
        ) / 10^6

        @test length(session.session_objects) == 0
        # getproperty, not getfield: in Bonito v5 `inbox` lives on the shared
        # RootSession and getfield would throw a FieldError (works via the shim on both).
        @testset "Session fields empty" for field in [:on_document_load, :stylesheets, :message_queue, :deregister_callbacks]
            @test isempty(getproperty(session, field))
        end
        # `inbox` is the live WS receive channel on the still-connected display
        # root, so a message can be mid-flight when we check — asserting it empty
        # instantly is racy. Give the reader task a moment to drain it; a genuinely
        # stuck reader (a real leak/hang) would still fail via the timeout.
        @test Bonito.wait_for(() -> isempty(getproperty(session, :inbox)); timeout = 10) == :success
        # Figure/widget assets are emitted into their sub-session's own fragment
        # and freed from the root when that sub closes, so after `App(nothing)`
        # the page root retains only its own connection shell (Bonito's
        # Websocket.js), not the WGLMakie/widget bundles. A count above this small
        # page-shell surface means sub imports are leaking onto the root again.
        @test length(session.imports) <= 2
        server = session.connection.server
        @test length(server.websocket_routes.table) == 1
        @test server.websocket_routes.table[1][2] == session.connection
        @test length(server.routes.table) == 2
        @test server.routes.table[1][1] == "/browser-display"
        @test server.routes.table[2][2] isa HTTPAssetServer

        # With the HTTP transport excluded, the hot session's own footprint is ~1.3 MB
        # (almost all of it the retained JS import bundle). Keep headroom for env
        # differences, but tight enough to catch a real multi-MB session leak.
        @show session_size
        @test session_size < 5

        js_sessions = run(edisplay.window, "Bonito.Sessions.SESSIONS")
        js_objects = run(edisplay.window, "Bonito.Sessions.GLOBAL_OBJECT_CACHE")
        # @test Set([app.session[].id, app.session[].parent.id]) == keys(js_sessions)
        # we used Retain for global_obs, so it should stay as long as root session is open
    end
end

println("###########################")
println("WGLMakie tests DONE")
println("Open Tasks: ", length(Makie.TRACKED_TASKS))
println("###########################")
