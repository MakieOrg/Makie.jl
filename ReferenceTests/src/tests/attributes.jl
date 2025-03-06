@reference_test "visible" begin
    fig = Figure()
    colors = Makie.resample(to_colormap(:deep), 20)
    scatter(fig[1, 1], RNG.randn(20), color=colors, markersize=10, visible=true)
    scatter(fig[1, 2], RNG.randn(20), color=colors, markersize=10, visible=false)
    fig
end

@reference_test "(mesh)scatter with NaN rotation and markersize, edge cases" begin
    parent = Scene(size = (300, 300))
    scene = Scene(parent, viewport = Rect2f(0,0, 150, 300))
    xs = [-0.6, 0.0, 0.6]
    scatter!(scene,     xs, fill( 0.75, 3), marker = :ltriangle, rotation = [0.5, NaN, -0.5], markersize = 50)
    scatter!(scene,     xs, fill( 0.25, 3), marker = :ltriangle, markersize = [50, NaN, 50])
    meshscatter!(scene, xs, fill(-0.25, 3), marker = Rect2f(-0.5,-0.5,1,1), rotation = [0.5, NaN, -0.5], markersize = 0.2)
    meshscatter!(scene, xs, fill(-0.75, 3), marker = Rect2f(-0.5,-0.5,1,1), markersize = [0.2, NaN, 0.2])

    # Edge case: Quaternionf(0,0,0,1) should not default billboard to true
    scene3 = Scene(parent, viewport = Rect2f(150, 0, 150, 300), camera = cam3d!)
    scatter!(scene3, [-0.5, 0.5], [0.5, 0.5], [0, 0], marker = Rect,
        rotation = [Quaternionf(0,0,0,1), Quaternionf(0.01,0,0,1)], markersize = 0.5, markerspace = :data)
    scatter!(scene3, [-0.5, 0.5], [-0.5, -0.5], [0, 0], marker = Rect, markersize = 0.5, markerspace = :data)

    parent
end