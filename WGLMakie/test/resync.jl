@testset "Reconnect preserves scene updates and resources" begin
    scene = Scene(size = (240, 160))
    scatter!(scene, Point2f[(0, 0), (1, 1)])
    display(edisplay, App(scene))
    screen = Makie.getscreen(scene, WGLMakie)
    @test Bonito.wait_for(() -> isready(screen.plot_initialized); timeout = 20) == :success
    root = edisplay.browserdisplay.handler.session
    window_id = edisplay.window.window.id
    listener_count = length(scene.compute.onchange.listeners)
    binding_count = length(scene.deregister_callbacks)
    child = nothing
    try
        run(
            edisplay.window, """
            (() => {
            const state = {setTimeout: window.setTimeout, timers: new Set()};
            window.resync_test = state;
            window.setTimeout = function(callback, delay, ...args) {
                if (callback.name !== '_check_screen' || delay !== 1000) {
                    return state.setTimeout.call(window, callback, delay, ...args);
                }
                const id = state.setTimeout.call(window, () => {
                    state.timers.delete(id);
                    callback(...args);
                }, delay);
                state.timers.add(id);
                return id;
            };
            return null;
            })();
            """
        )
        run(edisplay.window.app, "electron.BrowserWindow.fromId($window_id).webContents.debugger.attach('1.3')")
        for _ in 1:2
            run(
                edisplay.window.app, """
                (async () => {
                    const client = electron.BrowserWindow.fromId($window_id).webContents.debugger;
                    await client.sendCommand('Network.enable');
                    await client.sendCommand('Network.emulateNetworkConditions', {
                        offline: true, latency: 0, downloadThroughput: -1, uploadThroughput: -1
                    });
                    return true;
                })()
                """
            )
            for handler in Bonito.websocket_handlers(root.connection)
                socket = @atomic handler.socket
                socket === nothing || socket.close_transport!()
            end
            @test Bonito.wait_for(() -> !WGLMakie.connection_live(screen); timeout = 10) == :success
            child === nothing && (child = Scene(scene))
            queued = scatter!(child, Point2f[(0.2, 0.2)])
            @test screen.needs_resync
            run(
                edisplay.window.app,
                "electron.BrowserWindow.fromId($window_id).webContents.debugger.sendCommand('Network.emulateNetworkConditions', {offline: false, latency: 0, downloadThroughput: -1, uploadThroughput: -1}).then(() => true)"
            )
            child_id = WGLMakie.js_uuid(child)
            queued_id = WGLMakie.js_uuid(queued)
            ready = Bonito.wait_for(; timeout = 30) do
                WGLMakie.connection_live(screen) && run(edisplay.window, "!!WGL.find_scene('$child_id') && !!WGL.plot_cache['$queued_id']")
            end
            @test ready == :success
            ready == :success || error("Scene failed to initialize after reconnect")
            @test child_id in screen.displayed_scenes
            live = scatter!(child, Point2f[(0.8, 0.8)])
            live_id = WGLMakie.js_uuid(live)
            @test run(edisplay.window, "!!WGL.plot_cache['$live_id']")
        end
        sleep(1.2) # Let disposed scenes' one-second timers run and stop.
        @test run(edisplay.window, "resync_test.timers.size") == 1
        @test length(scene.compute.onchange.listeners) == listener_count
        @test length(scene.deregister_callbacks) == binding_count
        @test_throws Makie.ComputePipeline.ResolveException voxels!(scene, Array{Float32, 3}(undef, 0, 0, 0))
        delete!(scene, last(scene.plots))
        @test !screen.needs_resync
    finally
        run(edisplay.window, "window.setTimeout = resync_test.setTimeout; delete window.resync_test; null")
        run(edisplay.window.app, "electron.BrowserWindow.fromId($window_id).webContents.debugger.detach()")
        display(edisplay, App(nothing))
    end
end
