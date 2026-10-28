function try_empty_plot(func, args...; kwargs...)
    scene = Scene()
    func(scene, args...; kwargs...)
    colorbuffer(scene)
    if Symbol(Makie.current_backend()) === :WGLMakie
        sleep(1)
        colorbuffer(Scene())
    end
    return true # if we reach this we succeeded
end

@testset "empty primitives" begin
    @test try_empty_plot(scatter!, Point2f[])
    @test try_empty_plot(text!, Point2f[], text = String[])
    @test try_empty_plot(lines!, Point2f[])
    @test try_empty_plot(linesegments!, Point2f[])

    @test try_empty_plot(mesh!, GeometryBasics.mesh(Point2f[], GLTriangleFace[]))
    @test try_empty_plot(meshscatter!, Point2f[])

    # fails setting up value limits. fix if someone cares
    @test_broken try_empty_plot(voxels!, Array{Float32, 3}(undef, 0, 0, 0))

    if Symbol(Makie.current_backend()) === :WGLMakie
        @test_broken try_empty_plot(volume!, Array{Float32, 3}(undef, 0, 0, 0))
        @test_broken try_empty_plot(heatmap!, Matrix{Float32}(undef, 0, 0))
        @test_broken try_empty_plot(image!, Matrix{Float32}(undef, 0, 0))
        @test_broken try_empty_plot(surface!, Matrix{Float32}(undef, 0, 0))
    else
        @test try_empty_plot(volume!, Array{Float32, 3}(undef, 0, 0, 0))
        @test try_empty_plot(heatmap!, Matrix{Float32}(undef, 0, 0))
        @test try_empty_plot(image!, Matrix{Float32}(undef, 0, 0))
        @test try_empty_plot(surface!, Matrix{Float32}(undef, 0, 0))
    end

    # CairoMakie special cases (no harm testing these for every backend. Maybe
    # we should test all recipes anyway?)
    @test try_empty_plot(poly!, Rect2f[])
    @test try_empty_plot(band!, Float32[], Float32[], Float32[])

    # fails building contour, probably acceptable?
    @test_broken try_empty_plot(tricontourf!, Float32[], Float32[], Float32[])
end
