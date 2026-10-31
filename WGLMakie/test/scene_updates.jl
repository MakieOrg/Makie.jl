@testset "Scene redraw and listener disposal" begin
    checks = Bonito.evaljs_value(
        edisplay.browserdisplay.handler.session, js"""
        (() => {
            const Observable = Object.values(WGL.scene_cache)[0].viewport.constructor;
            const observable = value => new Observable("test-redraw", value);
            const identity = [1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1];
            let redraws = 0;
            const data = {
                uuid: "test-scene-redraw", viewport: observable([0,0,4,4]),
                backgroundcolor: observable("#ffffff"), backgroundcolor_alpha: observable(1),
                clearscene: observable(true), visible: observable(true),
                camera: observable([identity, identity, [4,4], [0,0,1]]),
                camera_relative_light: observable(false), light_direction: observable([0,0,-1]),
                ambient: observable([0,0,0]), light_color: observable([1,1,1]),
                plots: [], children: []
            };
            const screen = {canvas: document.createElement("canvas"), request_render: () => redraws++};
            const scene = WGL.deserialize_scene(data, screen);
            redraws = 0;
            const keys = ["viewport", "backgroundcolor", "backgroundcolor_alpha", "clearscene",
                "visible", "light_direction", "ambient", "light_color"];
            for (const key of keys) data[key].notify(data[key].value, true);
            const checks = [redraws === keys.length];
            WGL.delete_scene(data.uuid);
            const before = redraws;
            for (const key of keys) data[key].notify(data[key].value, true);
            checks.push(redraws === before && scene.disposed);
            return checks;
        })()
        """
    )
    @test checks == [true, true]
end

@testset "Render on demand wakes after updates" begin
    scene = Scene(size = (200, 160), backgroundcolor = :white)
    plot = scatter!(scene, Point2f[(0, 0), (1, 1)]; color = :red)
    try
        display(edisplay, App(scene))
        screen_js = "WGL.find_scene('$(WGLMakie.js_uuid(scene))')?.screen"
        @test Bonito.wait_for(; timeout = 20) do
            run(edisplay.window, "Boolean($screen_js?.frame_count)")
        end == :success
        @test run(edisplay.window, "$screen_js.render_on_demand")
        @test Bonito.wait_for(; timeout = 10) do
            run(edisplay.window, "$screen_js.requires_update === false")
        end == :success
        sleep(0.2)
        frames = run(edisplay.window, "$screen_js.frame_count")
        sleep(0.2)
        @test run(edisplay.window, "$screen_js.frame_count") == frames

        scene.backgroundcolor[] = RGBAf(0, 0, 0, 1)
        @test Bonito.wait_for(; timeout = 10) do
            run(edisplay.window, "$screen_js.frame_count > $frames")
        end == :success
        frames = run(edisplay.window, "$screen_js.frame_count")
        plot.color = :blue
        @test Bonito.wait_for(; timeout = 10) do
            run(edisplay.window, "$screen_js.frame_count > $frames")
        end == :success
    finally
        display(edisplay, App(nothing))
    end
end
