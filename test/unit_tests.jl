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

@testset "Pick a plot element or plot elements inside a rectangle" begin
    N = 100000
    scene = scatter(1:N, 1:N)
    xlims!((99990,100000))
    ylims!((99990,100000))
    display(scene)

    # test for pick a single data point (with idx > 65535)
    plot,idx = pick(scene, project(scene,Point((100000,100000))))
    @test idx == 100000

    # test for pick a rectangle of data points (also with some indices > 65535)
    rect = FRect2D(99990.5,99990.5,8,8)
    origin_px = project(scene,Point(origin(rect)))
    tip_px    = project(scene,Point(origin(rect) .+ widths(rect)))
    rect_px = IRect2D(round.(origin_px), round.(tip_px .- origin_px))
    #! there is no pick(::Scene,::IRect2D)
    plot_idx = pick(AbstractPlotting.getscreen(scene),rect_px)

    # objects returned in plot_idx should be either grid lines (i.e. LineSegments) or Scatter points
    @test all(pi-> pi[1] isa Union{LineSegments,Scatter}, plot_idx)
    # scatter points should have indices equal to those in 99991:99998
    scatter_plot_idx = filter(pi -> pi[1] isa Scatter, plot_idx)
    @test Set(last.(scatter_plot_idx)) == Set(99991:99998)
end
