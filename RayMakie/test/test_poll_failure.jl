using Test, Makie, RayMakie

@testset "failed plot resolution rejects the frame" begin
    scene = Scene()
    p = mesh!(scene, Rect3f(Vec3f(0), Vec3f(1)))
    Makie.add_input!(p.attributes, :fail_render, false)
    Makie.ComputePipeline.map!(p.attributes, :fail_render, :trace_renderobject) do fail
        fail && error("test render object unavailable")
        nothing
    end
    RayMakie.poll_all_plots(nothing, scene)
    Makie.update!(p; fail_render = true)
    try
        # A failed node must propagate on every attempt, including after its
        # diagnostic has already been logged. Otherwise retry publishes a
        # frame with missing or stale geometry.
        @test_logs (:error, r"failed to resolve") @test_throws Exception RayMakie.poll_all_plots(nothing, scene)
        @test_throws Exception RayMakie.poll_all_plots(nothing, scene)
        Makie.update!(p; fail_render = false)
        @test RayMakie.poll_all_plots(nothing, scene) === nothing
    finally
        delete!(RayMakie.POLL_ERROR_LOGGED, objectid(p))
    end
end
