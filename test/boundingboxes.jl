function Base.isapprox(r1::Rect{D}, r2::Rect{D}; kwargs...) where D
    return isapprox(minimum(r1), minimum(r2); kwargs...) &&
            isapprox(widths(r1), widths(r2); kwargs...)
end

@testset "data_limits(plot)" begin
    ps = Point2f[(0, 0), (1, 1)]

    fig, ax, p = hexbin(ps)
    ms = to_ndim(Vec3f, Vec2f(p.plots[1].markersize[]), 0)
    @test data_limits(p) ≈ Rect3f(-ms, Vec3f(1, 1, 0) .+ 2ms)

    fig, ax, p = errorbars(ps, [0.5, 0.5])
    @test data_limits(p) ≈ Rect3f(-Point3f(0, 0.5, 0), Vec3f(1, 2, 0))

    fig, ax, p = bracket(ps...)
    @test data_limits(p) ≈ Rect3f(Point3f(0), Vec3f(1, 1, 0))
end

@testset "boundingbox(plot)" begin
    cat = FileIO.load(Makie.assetpath("cat.obj"))

    # Testing atomic plots here. Everything else should be derived from them

    fig, ax, p = mesh(cat)
    bb = boundingbox(p)
    @test bb.origin ≈ Point3f(-0.1678, -0.002068, -0.358661)
    @test bb.widths ≈ Vec3f(0.339423, 0.92186, 1.3318559)

    fig, ax, p = surface([x*y for x in 1:10, y in 1:10])
    bb = boundingbox(p)
    @test bb.origin ≈ Point3f(1.0, 1.0, 1.0)
    @test bb.widths ≈ Vec3f(9.0, 9.0, 99.0)

    fig, ax, p = meshscatter([Point3f(x, y, z) for x in 1:5 for y in 1:5 for z in 1:5])
    bb = boundingbox(p)
    # Note: awkwards numbers come from using mesh over Sphere
    @test bb.origin ≈ Point3f(0.9011624, 0.9004657, 0.9)
    @test bb.widths ≈ Vec3f(4.1986046, 4.199068, 4.2)

    fig, ax, p = meshscatter(
        [Point3f(0) for _ in 1:3],
        marker = Rect3f(Point3f(-0.1, -0.1, -0.1), Vec3f(0.2, 0.2, 1.2)),
        markersize = Vec3f(1, 1, 2),
        rotations = Makie.rotation_between.((Vec3f(0,0,1),), Vec3f[(1,0,0), (0,1,0), (0,0,1)])
    )
    bb = boundingbox(p)
    @test bb.origin ≈ Point3f(-0.2)
    @test bb.widths ≈ Vec3f(2.4)

    fig, ax, p = volume(rand(5, 5, 5))
    bb = boundingbox(p)
    @test bb.origin ≈ Point3f(0)
    @test bb.widths ≈ Vec3f(5)

    fig, ax, p = scatter(1:10)
    bb = boundingbox(p)
    @test bb.origin ≈ Point3f(1, 1, 0)
    @test bb.widths ≈ Vec3f(9, 9, 0)

    fig, ax, p = lines(1:10)
    bb = boundingbox(p)
    @test bb.origin ≈ Point3f(1, 1, 0)
    @test bb.widths ≈ Vec3f(9, 9, 0)

    fig, ax, p = linesegments(1:10)
    bb = boundingbox(p)
    @test bb.origin ≈ Point3f(1, 1, 0)
    @test bb.widths ≈ Vec3f(9, 9, 0)

    fig, ax, p = heatmap(rand(10, 10))
    bb = boundingbox(p)
    @test bb.origin ≈ Point3f(0.5, 0.5, 0)
    @test bb.widths ≈ Vec3f(10.0, 10.0, 0)

    fig, ax, p = image(rand(10, 10))
    bb = boundingbox(p)
    @test bb.origin ≈ Point3f(0)
    @test bb.widths ≈ Vec3f(10.0, 10.0, 0)

    # text transforms to pixel space atm (TODO)
    fig = Figure(size = (400, 400))
    ax = Axis(fig[1, 1])
    p = text!(ax, Point2f(10), text = "test", fontsize = 20)
    bb = boundingbox(p)
    @test bb.origin ≈ Point3f(343.0, 345.0, 0)
    @test bb.widths ≈ Vec3f(32.24, 23.3, 0)
end