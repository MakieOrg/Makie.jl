@testset "Resampler" begin
    # Note: `Pyramid` is shadowed by `GeometryBasics.Pyramid` in the test scope,
    # so the datashader one always has to be qualified.

    # sample through the same path a HeatmapShader uses when it redraws
    function resample(resampler, n, sz)
        x = Makie.EndPoints{Float32}(0.0f0, Float32(sz))
        return Makie.resample_image(x, x, resampler.data, (n, n), Rect2f(0, 0, sz, sz))[3]
    end

    data32 = [Float32(sin(x) * cos(y)) for x in LinRange(0, 10, 256), y in LinRange(0, 10, 256)]
    data64 = Float64.(data32)
    rgb8 = [Makie.RGB{Makie.N0f8}(x / 256, y / 256, 0.5) for x in 1:256, y in 1:256]

    @testset "resampling keeps the element type narrow" begin
        # Resampling must not widen to Float64 - these images are expected to be huge,
        # so a promotion doubles the size of every buffer we hand to the backend.
        @test eltype(resample(Makie.Resampler(data32), 64, 256)) == Float32
        @test eltype(resample(Makie.Resampler(data64), 64, 256)) == Float32
        @test eltype(resample(Makie.Resampler(rgb8), 64, 256)) == Makie.RGB{Float32}

        for data in (data32, rgb8)
            pyramid = Makie.Pyramid(data; min_resolution = 64)
            @test length(pyramid.data) > 1  # more than one level, so restriction is covered
            @test eltype(resample(Makie.Resampler(pyramid), 64, 256)) ==
                (data === data32 ? Float32 : Makie.RGB{Float32})
        end
    end

    @testset "Pyramid values are unaffected by the knot type" begin
        pyramid = Makie.Pyramid(data32; min_resolution = 64)
        xs = LinRange(1.0f0, 256.0f0, 51)
        got = pyramid(xs, xs)
        @test eltype(got) == Float32
        # the finest level is a plain bilinear interpolation of `data32`
        finest = Makie.Interpolations.interpolate(
            Float64, Float64, (LinRange(1, 256, 256), LinRange(1, 256, 256)),
            data64, Makie.Interpolations.Gridded(Makie.Interpolations.Linear())
        )
        @test pyramid.data[1](xs, xs) ≈ finest(Float64.(xs), Float64.(xs)) rtol = 1.0f-6
    end

    @testset "Resampler does not copy the whole array to get an element type" begin
        big = rand(Float64, 1024, 1024)
        Makie.Resampler(big)  # warm up
        allocated = @allocated Makie.Resampler(big)
        # `interpolate` builds and keeps one Float32 coefficient array; deriving the
        # element type must not allocate a second, throwaway copy on top of that.
        @test allocated < 1.5 * (sizeof(big) ÷ 2)
    end
end
