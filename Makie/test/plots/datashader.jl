using Makie.Aggregation
using Makie.Aggregation: Canvas, aggregate!, bin_scale, null, update, value

function reference_aggregation(points, bounds, resolution, op)
    (xmin, ymin), (xmax, ymax) = extrema(bounds)
    xscale = resolution[1] / ((xmax - xmin) + eps(xmax - xmin))
    yscale = resolution[2] / ((ymax - ymin) + eps(ymax - ymin))
    out = fill(null(op), resolution)
    for p in points
        x, y = p[1], p[2]
        (xmin <= x <= xmax && ymin <= y <= ymax) || continue
        i = min(resolution[1], 1 + floor(Int, xscale * (x - xmin)))
        j = min(resolution[2], 1 + floor(Int, yscale * (y - ymin)))
        out[i, j] = length(p) == 2 ? update(op, out[i, j]) : update(op, out[i, j], p[3])
    end
    return value.(Ref(op), out)
end

@testset "aggregation" begin
    bounds = Rect2(-3.0, -3.0, 6.0, 6.0)
    resolution = (133, 77)

    @testset "$op" for (op, points) in [
            AggCount{Float32}() => Point2f[(-1.2, 0.3), (-1.2, 0.3), (0.0, 0.0), (2.9, -2.9)],
            AggCount{Int}() => Point2f[(-1.2, 0.3), (-1.2, 0.3), (0.0, 0.0)],
            AggAny() => Point2f[(-1.2, 0.3), (2.0, 2.0)],
            AggSum{Float64}() => Point3f[(-1.2, 0.3, 2.0), (-1.2, 0.3, 3.5), (1.0, 1.0, -1.0)],
            AggMean{Float64}() => Point3f[(-1.2, 0.3, 2.0), (-1.2, 0.3, 3.0), (1.0, 1.0, -1.0)],
        ]
        seeded = copy(points)
        if eltype(points) <: Point2
            append!(seeded, [Point2f(5 * randn(), 5 * randn()) for _ in 1:10_000])
        else
            append!(seeded, [Point3f(5 * randn(), 5 * randn(), rand()) for _ in 1:10_000])
        end
        expected = reference_aggregation(seeded, bounds, resolution, op)
        for method in (AggSerial(), AggThreads())
            canvas = Canvas(bounds; resolution = resolution, op = op)
            aggregate!(canvas, seeded; method = method)
            result = reshape(canvas.pixelbuffer, resolution)
            @test all(splat((a, b) -> a == b || (isnan(a) && isnan(b))), zip(result, expected))
            finite = filter(isfinite, vec(expected))
            @test canvas.data_extrema == (minimum(finite), maximum(finite))
        end
    end

    @testset "bin_scale maps the widest offset into the last bin" begin
        for (size, width) in [(133, 6.0), (800, 6.0), (1, 1.0), (999, 3.7), (2048, 1.0e-6)]
            scale = bin_scale(size, width)
            @test scale * width < size
            @test 1 + unsafe_trunc(Int, scale * width) == size
        end
        @test bin_scale(800, 0.0) == 0.0
    end

    @testset "zero width bounds put everything in the first bin" begin
        for method in (AggSerial(), AggThreads())
            canvas = Canvas(Rect2(1.0, 1.0, 0.0, 0.0); resolution = (4, 4), op = AggCount{Int}())
            aggregate!(canvas, [Point2f(1, 1), Point2f(1, 1)]; method = method)
            @test reshape(canvas.pixelbuffer, (4, 4))[1, 1] == 2
            @test sum(canvas.pixelbuffer) == 2
        end
    end

    @testset "points at the max bounds land in the last bin" begin
        for method in (AggSerial(), AggThreads())
            canvas = Canvas(bounds; resolution = resolution, op = AggCount{Int}())
            aggregate!(canvas, [Point2f(3, 3), Point2f(-3, -3)]; method = method)
            result = reshape(canvas.pixelbuffer, resolution)
            @test result[end, end] == 1
            @test result[1, 1] == 1
        end
    end

    @testset "NaN and out-of-bounds points are skipped" begin
        for method in (AggSerial(), AggThreads())
            canvas = Canvas(bounds; resolution = resolution, op = AggCount{Int}())
            aggregate!(canvas, [Point2f(NaN), Point2f(4, 0), Point2f(0, -4), Point2f(0, 0)]; method = method)
            @test sum(canvas.pixelbuffer) == 1
        end
    end

    @testset "empty input" begin
        for method in (AggSerial(), AggThreads())
            canvas = Canvas(bounds; resolution = resolution, op = AggCount{Int}())
            aggregate!(canvas, Point2f[]; method = method)
            @test all(==(0), canvas.pixelbuffer)
        end
    end

    @testset "equalize_histogram" begin
        values = Float32[0 0 0 0; 1 1 2 3]
        eq = Makie.equalize_histogram(values; nbins = 4)
        @test size(eq) == size(values)
        # counts 4, 2, 1, 1 give a cdf of 0.5, 0.75, 0.875, 1, and each value is
        # interpolated by how far it sits into its own bin
        @test all(==(0.5f0), eq[1, :])
        @test eq[2, 1] ≈ 0.75f0 + (0.875f0 - 0.75f0) / 3
        @test eq[2, 2] == eq[2, 1]
        @test eq[2, 3] ≈ 0.875f0 + (1.0f0 - 0.875f0) * 2 / 3
        @test eq[2, 4] == 1.0f0

        with_nan = Float32[0 NaN; 1 2]
        eq_nan = Makie.equalize_histogram(with_nan; nbins = 4)
        @test isnan(eq_nan[1, 2])
        @test !any(isnan, eq_nan[[1, 2, 4]])

        constant = fill(5.0f0, 3, 3)
        @test Makie.equalize_histogram(constant) == fill(1.0f0, 3, 3)
    end

    @testset "point_transform" begin
        points = [Point2f(0.5, -1.5), Point2f(2.0, 1.0)]
        expected = reference_aggregation(map(reverse, points), bounds, resolution, AggCount{Int}())
        for method in (AggSerial(), AggThreads())
            canvas = Canvas(bounds; resolution = resolution, op = AggCount{Int}())
            aggregate!(canvas, points; method = method, point_transform = reverse)
            @test reshape(canvas.pixelbuffer, resolution) == expected
        end
    end
end
