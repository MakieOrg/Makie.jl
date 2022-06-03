# guard against some future changes silently making simple vector graphics be
# rasterized if they are using features unsupported by the SVG spec
function svg_isnt_rasterized(x)
    mktempdir() do path
        path = joinpath(path, "test.svg")
        save(path, x)
        # this is rough but an easy way to catch rasterization,
        # if an image element is present in the svg
        return !occursin("<image id=", read(path, String))
    end
end

@testset "SVG rasterization" begin
    @test svg_isnt_rasterized(Scene())
    @test svg_isnt_rasterized(begin f = Figure(); Axis(f[1, 1]); f end)
    @test svg_isnt_rasterized(scatter(1:3))
    @test svg_isnt_rasterized(lines(1:3))
    @test svg_isnt_rasterized(heatmap(rand(5, 5)))
    @test !svg_isnt_rasterized(image(rand(5, 5)))
end
