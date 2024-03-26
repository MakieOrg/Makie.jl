function Base.isapprox(r1::Rect{D}, r2::Rect{D}; kwargs...) where D
    left  = vcat(minimum(r1), widths(r1))
    right = vcat(minimum(r2), widths(r2))
    return all((isnan.(left) .& isnan.(right)) .| (left .≈ right))
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

    fig = Figure()
    ax = Axis(fig[1, 1], yscale=log, xscale=log)
    scatter!(ax, [0.5, 1, 2], [0.5, 1, 2])
    p1 = vlines!(ax, [0.5])
    p2 = hlines!(ax, [0.5])
    p3 = vspan!(ax, [0.25], [0.75])
    p4 = hspan!(ax, [0.25], [0.75])

    @test data_limits(p1) ≈ Rect3f(Point3f(0.5, NaN, 0), Vec3f(0, NaN, 0))
    @test data_limits(p2) ≈ Rect3f(Point3f(NaN, 0.5, 0), Vec3f(NaN, 0, 0))
    @test data_limits(p3) ≈ Rect3f(Point3f(0.25, NaN, 0), Vec3f(0.5, NaN, 0))
    @test data_limits(p4) ≈ Rect3f(Point3f(NaN, 0.25, 0), Vec3f(NaN, 0.5, 0))
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
        rotation = Makie.rotation_between.((Vec3f(0,0,1),), Vec3f[(1,0,0), (0,1,0), (0,0,1)])
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
    bb = boundingbox(p, :pixel)
    @test bb.origin ≈ Point3f(343.0, 345.0, 0)
    @test bb.widths ≈ Vec3f(32.24, 23.3, 0)
    bb = boundingbox(p, :data)
    @test bb.origin ≈ Point3f(10, 10, 0)
    @test bb.widths ≈ Vec3f(0)
end

@testset "invalid contour bounding box" begin
    a = b = 1:3
    levels = collect(1:3)
    c = [0 1 2; 1 2 3; 4 5 NaN]
    contour(a, b, c; levels, labels = true)
    c = [0 1 2; 1 2 3; 4 5 Inf]
    contour(a, b, c; levels, labels = true)
end

# Testing mostly how it interacts with marker transforms
@testset "scatter boundingbox & data_limits" begin
    f, a, p = scatter(
        Point2f(0), markersize = 5, markerspace = :data,
        marker = Rect, rotation = 0, transform_marker = false
    )
    @test data_limits(p) ≈ Rect3f(Point3d(-2.5, -2.5, 0), Vec3d(5, 5, 0))
    @test boundingbox(p) ≈ Rect3f(Point3d(-2.5, -2.5, 0), Vec3d(5, 5, 0))

    # model should not affect either with transform_marker = false
    scale!(p, Vec3d(0.5))
    @test data_limits(p) ≈ Rect3f(Point3d(-2.5, -2.5, 0), Vec3d(5, 5, 0))
    @test boundingbox(p) ≈ Rect3f(Point3d(-2.5, -2.5, 0), Vec3d(5, 5, 0))

    # rotation should affect both, always
    p.rotation = pi/6
    bb1 = Rect3{Float64}([-3.4150635094610964, -3.4150635094610964, 0.0], [6.830127018922193, 6.830127018922193, 0.0])
    @test data_limits(p) ≈ bb1
    @test boundingbox(p) ≈ bb1

    # with transform_marker = true both should apply to boundingbox, only p.rotation to data_limits
    p.transform_marker = true
    bb2 = Rect3{Float64}([-1.7075317547305482, -1.7075317547305482, 0.0], [3.4150635094610964, 3.4150635094610964, 0.0])
    @test data_limits(p) ≈ bb1
    @test boundingbox(p) ≈ bb2

    # further model transformations should (only) affect boundingbox
    Makie.rotate!(p, pi/4)
    bb3 = Rect3{Float64}([-1.5309311648155406, -1.5309311648155406, 0.0], [3.061862329631081, 3.061862329631081, 0.0])
    @test data_limits(p) ≈ bb1
    @test boundingbox(p) ≈ bb3
end
