# guard against some future changes silently making simple vector graphics be
# rasterized if they are using features unsupported by the SVG spec
function svg_isnt_rasterized(x)
    return mktempdir() do path
        path = joinpath(path, "test.svg")
        save(path, x)
        # this is rough but an easy way to catch rasterization,
        # if an image element is present in the svg
        return !occursin("<image id=", read(path, String))
    end
end

@testset "SVG rasterization" begin
    @test svg_isnt_rasterized(Scene())
    @test svg_isnt_rasterized(
        begin
            f = Figure(); Axis(f[1, 1]); f
        end
    )
    @test svg_isnt_rasterized(
        begin
            f = Figure(); Axis3(f[1, 1]); f
        end
    )
    @test svg_isnt_rasterized(
        begin
            f = Figure(); PolarAxis(f[1, 1]); f
        end
    )
    @test svg_isnt_rasterized(scatter(1:3))
    @test svg_isnt_rasterized(lines(1:3))
    @test svg_isnt_rasterized(heatmap(rand(5, 5)))
    @test !svg_isnt_rasterized(image(rand(5, 5)))
    # issue 2510
    @test svg_isnt_rasterized(
        begin
            fig = Figure()
            ax = Axis(fig[1, 1])
            poly!(ax, Makie.GeometryBasics.Polygon(Point2.([[0, 0], [1, 0], [0, 1], [0, 0]])), color = ("#FF0000", 0.7), label = "foo")
            poly!(ax, Makie.GeometryBasics.Polygon(Point2.([[0, 0], [1, 0], [0, 1], [0, 0]])), color = (:blue, 0.7), label = "bar")
            fig[1, 2] = Legend(fig, ax, "Bar")
            fig
        end
    )
    @test svg_isnt_rasterized(poly(Circle(Point2f(0, 0), 10)))
    @test svg_isnt_rasterized(
        poly(
            BezierPath(
                [
                    MoveTo(0.0, 0.0), LineTo(1.0, 0.0), LineTo(1.0, 1.0), CurveTo(1.0, 1.0, 0.5, 1.0, 0.5, 0.5), ClosePath(),
                ]
            )
        )
    )
    @test !svg_isnt_rasterized(poly(rand(Point2f, 10); color = rand(RGBAf, 10)))

    poly1 = Makie.GeometryBasics.Polygon(rand(Point2f, 10))
    @test svg_isnt_rasterized(poly(Makie.GeometryBasics.MultiPolygon([poly1, poly1])))
    @test svg_isnt_rasterized(poly(Makie.GeometryBasics.MultiPolygon([poly1, poly1]), color = :red))
    @test svg_isnt_rasterized(poly(Makie.GeometryBasics.MultiPolygon([poly1, poly1]), color = [:red, :blue]))
end

struct PolyWrapper
    poly::Any
end
function Makie.convert_arguments(::Type{<:Poly}, poly::PolyWrapper)
    return convert_arguments(Poly, poly.poly)
end
struct MultiPolyWrapper
    poly::Vector
end
function Makie.convert_arguments(::Type{<:Poly}, poly::MultiPolyWrapper)
    return convert_arguments(Poly, poly.poly)
end

@testset "Polygon Wrappers" begin
    poly1 = Makie.GeometryBasics.Polygon(rand(Point2f, 10))
    poly2 = PolyWrapper(poly1)
    @test svg_isnt_rasterized(poly(poly2))
    @test svg_isnt_rasterized(poly(poly2; color = :red))
    @test svg_isnt_rasterized(poly(MultiPolyWrapper([poly1, poly1]); color = [:red, :blue]))
end

@testset "reproducible svg ids" begin
    # https://github.com/MakieOrg/Makie.jl/issues/2406
    f, ax, sc = scatter(1:10)
    save("test1.svg", f)
    save("test2.svg", f)
    @test read("test1.svg") == read("test2.svg")
    rm("test1.svg")
    rm("test2.svg")
end
