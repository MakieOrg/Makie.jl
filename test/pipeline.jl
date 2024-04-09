# extracted from interfaces.jl
function test_copy(; kw...)
    scene = Scene()
    return Makie.merged_get!(
        ()-> Makie.default_theme(scene, Lines),
        :lines, scene, Attributes(kw)
    )
end

function test_copy2(attr; kw...)
    return merge!(Attributes(kw), attr)
end

@testset "don't copy in theme merge" begin
    x = Observable{Any}(1)
    res=test_copy(linewidth=x)
    res.linewidth === x
end

@testset "don't copy observables in when calling merge!" begin
    x = Observable{Any}(1)
    res=test_copy2(Attributes(linewidth=x))
    res.linewidth === x
end

@testset "don't copy attributes in recipe" begin
    fig = Figure()
    ax = Axis(fig[1, 1])
    list = Observable{Any}([1, 2, 3, 4])
    xmax = Observable{Any}([0.25, 0.5, 0.75, 1])

    p = hlines!(ax, list, xmax = xmax, color = :blue)
    @test getfield(p, :args)[1] === list
    @test p.xmax === xmax
    fig
end


@testset "Figure / Axis / Gridposition creation test" begin
    @testset "proper errors for wrongly used (non) mutating plot functions" begin
        f = Figure()
        x = range(0, 10, length=100)
        @test_throws ErrorException scatter!(f[1, 1], x, sin)
        @test_throws ErrorException scatter!(f[1, 2][1, 1], x, sin)
        @test_throws ErrorException scatter!(f[1, 2][1, 2], x, sin)

        @test_throws ErrorException meshscatter!(f[2, 1], x, sin; axis=(type=Axis3,))
        @test_throws ErrorException meshscatter!(f[2, 2][1, 1], x, sin; axis=(type=Axis3,))
        @test_throws ErrorException meshscatter!(f[2, 2][1, 2], x, sin; axis=(type=Axis3,))

        @test_throws ErrorException meshscatter!(f[3, 1], rand(Point3f, 10); axis=(type=LScene,))
        @test_throws ErrorException meshscatter!(f[3, 2][1, 1], rand(Point3f, 10); axis=(type=LScene,))
        @test_throws ErrorException meshscatter!(f[3, 2][1, 2], rand(Point3f, 10); axis=(type=LScene,))

        sub = f[4, :]
        f = Figure()
        @test_throws ErrorException scatter(Axis(f[1, 1]), x, sin)
        @test_throws ErrorException meshscatter(Axis3(f[1, 1]), x, sin)
        @test_throws ErrorException meshscatter(LScene(f[1, 1]), rand(Point3f, 10))

        f
    end

    @testset "creating plot object for different (non) mutating plotting functions into figure" begin
        f = Figure()
        x = range(0, 10; length=100)
        ax, pl = scatter(f[1, 1], x, sin)
        @test ax isa Axis
        @test pl isa AbstractPlot

        ax, pl = scatter(f[1, 2][1, 1], x, sin)
        @test ax isa Axis
        @test pl isa AbstractPlot

        ax, pl = scatter(f[1, 2][1, 2], x, sin)
        @test ax isa Axis
        @test pl isa AbstractPlot

        ax, pl = meshscatter(f[2, 1], x, sin; axis=(type=Axis3,))
        @test ax isa Axis3
        @test pl isa AbstractPlot

        ax, pl = meshscatter(f[2, 2][1, 1], x, sin; axis=(type=Axis3,))
        @test ax isa Axis3
        @test pl isa AbstractPlot
        ax, pl = meshscatter(f[2, 2][1, 2], x, sin; axis=(type=Axis3,))
        @test ax isa Axis3
        @test pl isa AbstractPlot

        ax, pl = meshscatter(f[3, 1], rand(Point3f, 10); axis=(type=LScene,))
        @test ax isa LScene
        @test pl isa AbstractPlot
        ax, pl = meshscatter(f[3, 2][1, 1], rand(Point3f, 10); axis=(type=LScene,))
        @test ax isa LScene
        @test pl isa AbstractPlot
        ax, pl = meshscatter(f[3, 2][1, 2], rand(Point3f, 10); axis=(type=LScene,))
        @test ax isa LScene
        @test pl isa AbstractPlot

        sub = f[4, :]

        pl = scatter!(Axis(sub[1, 1]), x, sin)
        @test pl isa AbstractPlot
        pl = meshscatter!(Axis3(sub[1, 2]), x, sin)
        @test pl isa AbstractPlot
        pl = meshscatter!(LScene(sub[1, 3]), rand(Point3f, 10))
        @test pl isa AbstractPlot

        f = Figure()
        @test_throws ErrorException lines!(f, [1, 2])
    end
end

@testset "Cycled" begin
    # Test for https://github.com/MakieOrg/Makie.jl/issues/3266
    f, ax, pl = lines(1:4; color=Cycled(2))
    cpalette = ax.scene.theme.palette[:color][]
    @test pl.calculated_colors[] == cpalette[2]
    pl2 = lines!(ax, 1:4; color=Cycled(1))
    @test pl2.calculated_colors[] == cpalette[1]
end

function test_default(arg)
    _, _, pl1 = plot(arg)

    fig = Figure()
    _, pl2 = plot(fig[1, 1], arg)

    fig = Figure()
    ax = Axis(fig[1, 1])
    pl3 = plot!(ax, arg)
    return [pl1, pl2, pl3]
end

@testset "plot defaults" begin
    plots = test_default([10, 15, 20])
    @test all(x-> x isa Scatter, plots)

    plots = test_default(rand(4, 4))
    @test all(x -> x isa Heatmap, plots)

    poly = Polygon(decompose(Point, Circle(Point2f(0), 1.0f0)))

    plots = test_default(poly)
    @test all(x -> x isa Poly, plots)

    plots = test_default(rand(4, 4, 4))
    @test all(x -> x isa Volume, plots)
end

@testset "validated attributes" begin
    InvalidAttributeError = Makie.MakieCore.InvalidAttributeError
    @test_throws InvalidAttributeError heatmap(zeros(10, 10); does_not_exist = 123)
    @test_throws InvalidAttributeError image(zeros(10, 10); does_not_exist = 123)
    @test_throws InvalidAttributeError scatter(1:10; does_not_exist = 123)
    @test_throws InvalidAttributeError lines(1:10; does_not_exist = 123)
    @test_throws InvalidAttributeError linesegments(1:10; does_not_exist = 123)
    @test_throws InvalidAttributeError text(1:10; does_not_exist = 123)
    @test_throws InvalidAttributeError volume(zeros(3, 3, 3); does_not_exist = 123)
    @test_throws InvalidAttributeError meshscatter(1:10; does_not_exist = 123)
    @test_throws InvalidAttributeError poly(Point2f[]; does_not_exist = 123)
    @test_throws InvalidAttributeError mesh(rand(Point3f, 3); does_not_exist = 123)
end
