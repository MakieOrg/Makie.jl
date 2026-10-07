# The memory half of `test_meshscatter_traced_interfaces.jl`: pushing the
# interfaces one at a time held 2.7 GB of GPU memory at 20k instances. Read
# through the Vulkan runtime's live-byte count, which is why this file is in
# `VULKAN_RUNTIME_TEST_FILES` — Metal has no counterpart in Mantle to ask.

using Test, Makie, RayMakie, GeometryBasics, Colors, Random
import Mantle
RayMakie.activate!()

@testset "traced meshscatter memory is linear in the instance count" begin
    spheres(n) = (r = Xoshiro(3); [Point3f(6rand(r) - 3, 6rand(r) - 3, rand(r)) for _ in 1:n])
    dev = Mantle.todevice(Mantle.defaultbackend())
    live() = Mantle.gpu_live_bytes(dev.ctx)
    GC.gc(true)
    before = live()
    fig = Figure(; size = (400, 250))
    ax = LScene(fig[1, 1]; show_axis = false)
    meshscatter!(ax, spheres(20_000); markersize = 0.03)
    screen = RayMakie.Screen(fig.scene; visible = false, vsync = false,
                             rasterize = false, samples = 1, max_depth = 8)
    colorbuffer(screen)
    # 2.7 GB before the batch push; the marker, 20k instance records and one
    # interface are a few MB.
    @test live() - before < 256 << 20
    close(screen)
end
