using GLMakie
using Test
using AbstractPlotting: backend_display, getscreen

@testset "Window handling" begin
    screen = GLMakie.global_gl_screen((100, 100), false)
    @test isopen(screen)
    scene = scatter(1:4);
    screen2 = display(scene)
    @test screen === screen2
    @test getscreen(scene) === screen
    close(screen)

    # assure we correctly close screen and remove it from plot
    @test getscreen(scene) === nothing
    @test !events(scene).window_open[]
    @test isempty(events(scene).window_open.listeners)
end
