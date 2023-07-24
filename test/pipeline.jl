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

begin
    f = Figure()
    x = range(0, 10, length=100)
    scatter!(f[1, 1], x, sin)
    scatter!(f[1, 2][1, 1], x, sin)
    scatter!(f[1, 2][1, 2], x, sin)

    meshscatter!(f[2, 1], x, sin; axis=(type=Axis3,))
    meshscatter!(f[2, 2][1, 1], x, sin; axis=(type=Axis3,))
    meshscatter!(f[2, 2][1, 2], x, sin; axis=(type=Axis3,))

    meshscatter!(f[3, 1], rand(Point3f, 10); axis=(type=LScene,))
    meshscatter!(f[3, 2][1, 1], rand(Point3f, 10); axis=(type=LScene,))
    meshscatter!(f[3, 2][1, 2], rand(Point3f, 10); axis=(type=LScene,))

    sub = f[4, :]
    f = Figure()
    scatter(Axis(f[1, 1]), x, sin)
    meshscatter(Axis3(f[1, 1]), x, sin)
    meshscatter(LScene(f[1, 1]), rand(Point3f, 10))

    f
end
