@reference_test "glowcolor, glowwidth" begin
    scatter(RNG.randn(10), color=:blue, glowcolor=:orange, glowwidth=10)
end

@reference_test "isorange, isovalue" begin
    r = range(-1, stop=1, length=100)
    matr = [(x.^2 + y.^2 + z.^2) for x = r, y = r, z = r]
    volume(matr .* (matr .> 1.4), algorithm=:iso, isorange=0.05, isovalue=1.7)
end

@reference_test "levels" begin
    x = LinRange(-1, 1, 20)
    y = LinRange(-1, 1, 20)
    z = x .* y'
    contour(x, y, z, linewidth=3, colormap=:colorwheel, levels=50)
end


@reference_test "position" begin
    fig, ax, sc = scatter(RNG.rand(10), color=:red)
    text!(ax, 5, 1.1, text = "adding text", textsize=0.6)
    fig
end

@reference_test "rotation" begin
    text("Hello World", rotation=1.1)
end

@reference_test "shading" begin
    mesh(Sphere(Point3f(0), 1f0), color=:orange, shading=false)
end

@reference_test "visible" begin
    fig = Figure()
    colors = Makie.resample(to_colormap(:deep), 20)
    scatter(fig[1, 1], RNG.randn(20), color=colors, markersize=10, visible=true)
    scatter(fig[1, 2], RNG.randn(20), color=colors, markersize=10, visible=false)
    fig
end
