@testset "Clip plane uniform updates" begin
    points = Point2f[(x, y) for x in 0.1:0.1:0.9 for y in 0.1:0.1:0.9]
    plane = Plane3f(Point3f(0.5), Vec3f(1, 1, 0))
    f, ax, plot = scatter(points; color = :red, figure = (; size = (300, 250)))
    try
        display(edisplay, App(f))
        @test Bonito.wait_for(() -> events(f).window_open[]; timeout = 20) == :success
        unclipped = colorbuffer(f)
        for planes in ([plane], Plane3f[], fill(plane, 8), Plane3f[])
            plot.clip_planes[] = planes
            image = colorbuffer(f)
            if isempty(planes)
                @test image == unclipped
            else
                @test image != unclipped
            end
            uniforms = Bonito.evaljs_value(
                f.scene.current_screens[1].session, js"""
                (() => {
                    const uniforms = WGL.plot_cache[$(WGLMakie.js_uuid(plot))].material.uniforms;
                    return [uniforms.uniform_num_clip_planes.value,
                        uniforms.uniform_clip_planes.value.length];
                })()
                """
            )
            @test uniforms == [length(planes), 32]
        end
    finally
        display(edisplay, App(nothing))
    end
end
