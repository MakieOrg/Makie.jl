@testset "boundingbox(plot)" begin
    cat = FileIO.load(Makie.assetpath("cat.obj"))

    # Testing atomic plots here. Everything else should be derived from them

    fig, ax, p = mesh(cat)
    bb = boundingbox(p)
    @test bb.origin ≈ Point3f(-0.1678, -0.002068, -0.358661)
    @test bb.widths ≈ Vec3f(0.339423, 0.92186, 1.3318559)

    fig, ax, p = surface([x*y for x in 1:10, y in 1:10])
    bb = boundingbox(p)
    @test bb.origin ≈ Point3f(0.0, 0.0, 1.0)
    @test bb.widths ≈ Vec3f(10.0, 10.0, 99.0)

    fig, ax, p = meshscatter([Point3f(x, y, z) for x in 1:5 for y in 1:5 for z in 1:5])
    bb = boundingbox(p)
    @test bb.origin ≈ Point3f(1)
    @test bb.widths ≈ Vec3f(4)

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
    fig = Figure(resolution = (400, 400))
    ax = Axis(fig[1, 1])
    p = text!(ax, Point2f(10), text = "test", fontsize = 20)
    bb = boundingbox(p)
    @test bb.origin ≈ Point3f(340, 341, 0)
    @test bb.widths ≈ Vec3f(32.24, 23.3, 0)
end