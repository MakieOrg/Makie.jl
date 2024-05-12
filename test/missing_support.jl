using Makie

@testset "Missings in colors" begin
    @testset "Grid-like plots" begin
        @testset "Direct in heatmap" begin
            data = Union{Missing, Float64}[missing 2; 3 4]
            @test_nowarn heatmap(data)
            f, a, p = heatmap(data; nan_color = RGBAf(1, 0, 0, 1))
            colors = Makie.to_color(p.calculated_colors[])
            @test colors[1] == RGBAf(1, 0, 0, 1)
        end
        @testset "Color in surface" begin
            data = Union{Missing, Float64}[missing 2 3; 3 4 5; 6 7 8]
            @test_nowarn surface(rand(3, 3); color = data)
            f, a, p = surface(rand(3, 3); color = data)
            colors = Makie.to_color(p.calculated_colors[])
            @test colors[1] == RGBAf(0, 0, 0, 0)
        end
    end

    @testset "PointBased" begin
        data = Vector{Union{Float64, Missing}}(undef, 100)
        data .= rand(100)
        data[50] = missing

        @test_nowarn lines(rand(100); color = data, nan_color = RGBAf(1, 0, 0, 1))
        f, a, p = lines(rand(100); color = data, nan_color = RGBAf(1, 0, 0, 1))
        colors = Makie.to_color(p.calculated_colors[])
        @test colors[50] == RGBAf(1, 0, 0, 1)
    end
end

@testset "Missings in data" begin
end