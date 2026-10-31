using Test, Makie, GLMakie

@testset "render stages respect plot filters" begin
    for transparency in (false, true)
        scene = Scene(; size = (160, 100), camera = campixel!, backgroundcolor = :black)
        scatter!(scene, [Point2f(80, 50)]; markersize = 60,
            color = (:white, 0.5), strokewidth = 0, fxaa = false, transparency)
        screen = GLMakie.Screen(; visible = false, start_renderloop = false,
            px_per_unit = 1, scalefactor = 1,
            render_pipeline = Makie.minimal_render_pipeline())
        try
            display(screen, scene)
            images = map((Makie.minimal_render_pipeline(),
                    Makie.default_pipeline(; ssao = false, fxaa = false, oit = false))) do pipeline
                GLMakie.gl_render_pipeline!(screen, pipeline)
                copy(Makie.colorbuffer(screen))
            end
            # With ignored pass filters the default pipeline draws the half
            # transparent marker twice: its centre becomes 0.75 instead of 0.5.
            @test images[1] == images[2]
            @test 0.49 < Makie.red(images[2][50, 80]) < 0.51
        finally
            close(screen)
            Makie.free(scene)
        end
    end
end
