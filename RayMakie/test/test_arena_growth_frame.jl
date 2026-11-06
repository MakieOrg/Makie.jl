# A frame stays live when a later plan moves the arena under it.
#
# A screen's frame plan holds a rebindable draw, so it is walked every run and has
# no recording. FXAA is the pass that reads a transient BUFFER through its fragment
# arguments. Mantle's `notify_move!` patches recordings only, so after a larger
# plan grew the arena those arguments kept the retired block's address: on Vulkan
# the picture froze at whatever that memory last held, and went to garbage once the
# block was reused. In the editor, the look effect's plans were enough to do it.

using Test, Makie, RayMakie, GeometryBasics, KernelAbstractions
import Mantle
using GeometryBasics: Vec3f, Rect3f

@kernel function fillarena_kernel!(buf)
    i = @index(Global)
    @inbounds buf[i] = 0x00000000
end

"Device addresses are per backend, so what a move changes is asked of the arena's region."
arenaregions(dev) = [a.region for a in values(Mantle.pool(dev).arenas)]

"A plan needing twice the buffer arena's current size, which it can only get by moving it."
function growarena(dev)
    bytes = maximum(a.bytes for (kind, a) in Mantle.pool(dev).arenas if Mantle.basekind(kind) isa Mantle.Buffers)
    n = 2 * bytes ÷ sizeof(UInt32)
    g = Mantle.Graph(dev)
    t = Mantle.Transient.Buffer(g, UInt32, n)
    Mantle.dispatch!(g, fillarena_kernel!, (t,), n; name = "fill arena")
    plan = Mantle.record!(Mantle.Plan(g))
    Mantle.run!(plan)
    KernelAbstractions.synchronize(dev)
    return plan
end

function colourcounts(img)
    reds = count(c -> Float32(c.r) > 0.3f0 && Float32(c.g) < 0.1f0, img)
    greens = count(c -> Float32(c.g) > 0.3f0 && Float32(c.r) < 0.1f0, img)
    return (; reds, greens)
end

@testset "a frame stays live when a later plan moves the arena" begin
    scene = Scene(size = (96, 64), camera = cam3d!, backgroundcolor = :black)
    box = mesh!(scene, Rect3f(Vec3f(-0.4), Vec3f(0.8)); color = :red)
    update_cam!(scene, Vec3f(4, -6, 4), Vec3f(0), Vec3f(0, 0, 1))
    screen = RayMakie.Screen(scene; rasterize = true, samples = 1, visible = false, fxaa = true)
    frame() = colourcounts(colorbuffer(screen, Makie.GLNative; clear = true, samples = 1))
    @test frame().reds > 50
    box.color = :green
    @test frame().greens > 50

    dev = Mantle.Device()
    before = arenaregions(dev)
    plan = growarena(dev)
    @test arenaregions(dev) != before    # …or this tests nothing

    box.color = :red
    seen = frame()
    @test seen.reds > 50 && seen.greens == 0
    box.color = :green
    seen = frame()
    @test seen.greens > 50 && seen.reds == 0

    Mantle.free!(plan)
    close(screen)
end
