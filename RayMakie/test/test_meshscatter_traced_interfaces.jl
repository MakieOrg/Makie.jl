# A traced meshscatter pushes one Hikari interface per instance. They were
# pushed one at a time, each a device `findfirst` over the whole interface array
# and a one-element `push!` that copied it: quadratic in the instance count, 2.7
# GB of GPU memory held at 20k instances and 100k could not be built. Hikari's
# `push_interfaces!` does it as one batch, and instances in one colour share one
# interface. Giving them colours of their own afterwards must split that
# interface (`meshscatter_update!` rebuilds), or every instance would take the
# colour written last.

using Test, Makie, RayMakie, GeometryBasics, Colors, Random
import Mantle
RayMakie.activate!()

tracedscreen(fig; samples = 4) = RayMakie.Screen(fig.scene; visible = false, vsync = false,
                                                 rasterize = false, samples, max_depth = 8)
spheres(n) = (r = Xoshiro(3); [Point3f(6rand(r) - 3, 6rand(r) - 3, rand(r)) for _ in 1:n])
reds(img) = count(c -> red(c) > 0.3 && green(c) < 0.1 && blue(c) < 0.1, img)
blues(img) = count(c -> blue(c) > 0.3 && red(c) < 0.1 && green(c) < 0.15, img)
greens(img) = count(c -> green(c) > 0.3 && red(c) < 0.1 && blue(c) < 0.15, img)

@testset "traced meshscatter interfaces" begin
    @testset "one colour shares one interface, own colours get their own" begin
        fig = Figure(; size = (400, 250))
        ax = LScene(fig[1, 1]; show_axis = false)
        ms = meshscatter!(ax, spheres(300); markersize = 0.15, color = :red)
        screen = tracedscreen(fig)
        i0 = copy(colorbuffer(screen))
        @test length(unique(ms.trace_renderobject[].mi_indices)) == 1
        @test reds(i0) > 1000
        ms.color = [isodd(i) ? RGBAf(0, 0, 1, 1) : RGBAf(0, 1, 0, 1) for i in 1:300]
        i1 = copy(colorbuffer(screen))
        @test length(unique(ms.trace_renderobject[].mi_indices)) == 300
        @test reds(i1) == 0 && blues(i1) > 500 && greens(i1) > 500
        ms.color = :red
        i2 = copy(colorbuffer(screen))
        @test reds(i2) > 1000 && blues(i2) == 0
        close(screen)
    end
end
