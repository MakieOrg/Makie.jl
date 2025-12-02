# guard against some future changes silently making simple vector graphics be
# rasterized if they are using features unsupported by the SVG spec
function svg_has_image(x)
    return mktempdir() do path
        path = joinpath(path, "test.svg")
        save(path, x)
        # this is rough but an easy way to catch rasterization,
        # if an image element is present in the svg
        return occursin("<image id=", read(path, String))
    end
end

@testset "Internal rasterization" begin
    fig = Figure()
    ax = Axis(fig[1, 1])
    lp = lines!(ax, vcat(1:10, 10:-1:1))
    pts = Makie.GeometryBasics.Point2f[(0, 0), (1, 0), (0, 1)]
    pl = poly!(ax, Makie.GeometryBasics.Polygon(pts))

    @testset "Unrasterized SVG" begin
        @test !svg_has_image(fig)
    end

    @testset "Rasterized SVG" begin
        lp.rasterize = true
        @test svg_has_image(fig)
        lp.rasterize = 10
        @test svg_has_image(fig)
    end

end
