using Makie: _get_tricontour_levels, _calculate_tricontour_lines!
import DelaunayTriangulation as DelTri

@testset "tricontour" begin
    @testset "_get_tricontour_levels" begin
        zs = Float32[0.0, 0.5, 1.0, 0.25, 0.75]

        @testset "integer levels" begin
            lvls = _get_tricontour_levels(zs, 5)
            @test lvls isa Vector{Float32}
            @test length(lvls) == 5
            @test first(lvls) ≈ 0.0f0
            @test last(lvls) ≈ 1.0f0
            @test issorted(lvls)
        end

        @testset "vector levels passed through" begin
            explicit = [0.2f0, 0.5f0, 0.8f0]
            lvls = _get_tricontour_levels(zs, explicit)
            @test lvls == Float32.(explicit)
        end

        @testset "constant field returns empty levels" begin
            zs_const = fill(3.14f0, 10)
            lvls = _get_tricontour_levels(zs_const, 8)
            @test isempty(lvls)
        end
    end

    @testset "convert_arguments" begin
        xs = [0.0, 1.0, 0.0, 1.0]
        ys = [0.0, 0.0, 1.0, 1.0]
        zs = [0.0, 1.0, 0.5, 0.2]

        result = Makie.convert_arguments(Makie.Tricontour, xs, ys, zs)
        @test length(result) == 2
        tri, z = result
        @test tri isa DelTri.Triangulation
        @test z isa AbstractVector{<:AbstractFloat}
        @test length(z) == length(zs)
    end

    @testset "convert_arguments with manual triangulation" begin
        xs = [0.0, 1.0, 0.0, 1.0]
        ys = [0.0, 0.0, 1.0, 1.0]
        zs = [0.0, 1.0, 0.5, 0.2]
        # 3×2 matrix: each column is one triangle
        tris = [1 2; 2 3; 3 4]

        result = Makie.convert_arguments(Makie.Tricontour, xs, ys, zs; triangulation = tris)
        tri, z = result
        @test tri isa DelTri.Triangulation
        @test length(z) == length(zs)
    end

    @testset "_calculate_tricontour_lines! basic output" begin
        xs = [0.0, 1.0, 0.0, 1.0]
        ys = [0.0, 0.0, 1.0, 1.0]
        zs = Float32[0.0, 1.0, 0.0, 1.0]
        tri, z = Makie.convert_arguments(Makie.Tricontour, xs, ys, zs)

        xs_out = Float32[]
        ys_out = Float32[]
        colors = Float32[]
        levels = Float32[0.5]

        _calculate_tricontour_lines!(xs_out, ys_out, colors, tri, z, levels)

        non_nan = .!isnan.(xs_out)
        @test any(non_nan)
        @test length(xs_out) == length(ys_out) == length(colors)
        @test all(colors[non_nan] .≈ 0.5f0)
    end

    @testset "_calculate_tricontour_lines! no output outside data range" begin
        xs = [0.0, 1.0, 0.0]
        ys = [0.0, 0.0, 1.0]
        zs = Float32[0.0, 0.5, 1.0]
        tri, z = Makie.convert_arguments(Makie.Tricontour, xs, ys, zs)

        xs_out = Float32[]
        ys_out = Float32[]
        colors = Float32[]

        _calculate_tricontour_lines!(xs_out, ys_out, colors, tri, z, Float32[5.0])
        non_nan = .!isnan.(xs_out)
        @test !any(non_nan)
    end
end

@testset "tricontour constant field recipe" begin
    xs = rand(20); ys = rand(20)
    zs_const = fill(3.14f0, 20)

    _, _, p = tricontour(xs, ys, zs_const; levels = 6)
    @test isempty(p.computed_levels[])
    # must be empty
    @test isempty(filter(!isnan, p.line_xs[]))
end

@testset "Colorbar extract_colormap for tricontour" begin
    xs = rand(30); ys = rand(30)
    zs = sin.(2π .* xs) .* cos.(2π .* ys)

    _, _, tr = tricontour(xs, ys, zs; levels = 6)
    cmap = Makie.extract_colormap(tr)
    @test cmap isa Makie.ColorMapping
    lo, hi = cmap.colorrange[]
    @test isfinite(lo) && isfinite(hi)
    @test lo < hi
end

@testset "Colorbar extract_colormap for 2D contour" begin
    xs = ys = range(0, 1; length = 20)
    zs = [sin(2π * x) * cos(2π * y) for x in xs, y in ys]

    _, _, p = contour(xs, ys, zs; levels = 5)
    cmap = Makie.extract_colormap(p)
    @test cmap isa Makie.ColorMapping
    lo, hi = cmap.colorrange[]
    @test isfinite(lo) && isfinite(hi)
    @test lo < hi
end

@testset "constant colorrange expansion" begin
    n = 10
    xs = ys = range(0, 1; length = n)
    c = 1.0f0

    @testset "heatmap scaled_colorrange expands (c,c)" begin
        _, _, p = heatmap(xs, ys, fill(c, n, n); colorrange = (c, c))
        sr = p.scaled_colorrange[]
        @test sr[1] < c < sr[2]
    end

    @testset "heatmap automatic range handles constant data" begin
        _, _, p = heatmap(xs, ys, fill(c, n, n))
        sr = p.scaled_colorrange[]
        @test sr[1] < c < sr[2]
    end
end

@testset "contourf constant field levels" begin
    xs = ys = range(0, 1; length = 10)
    zs_const = fill(2.0f0, 10, 10)

    _, _, p = contourf(xs, ys, zs_const; levels = 6)
    computed = p.computed_levels[]
    @test length(computed) == 7 # levels + 1
    @test issorted(computed)
    @test computed[1] < 2.0f0 < computed[end]
end

@testset "contour constant field" begin
    xs = ys = range(0, 1; length = 10)
    zs_const = fill(2.0f0, 10, 10)

    _, _, p = contour(xs, ys, zs_const)
    @test isempty(p.zlevels[])
end
