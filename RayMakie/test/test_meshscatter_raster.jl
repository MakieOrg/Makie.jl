# RASTER mode draws `meshscatter` as the marker mesh, once per instance, through
# the mesh stage (src/overlay/mesh.jl `instance_place`, a port of GLMakie's
# particles.vert). Before it there was no raster path at all: every instance
# became a Hikari material and a traced instance, about 85 KB of GPU memory each,
# so 10k spheres took 1.4 s a frame, 40k failed, and 100k filled a 24 GB card
# and froze the machine (amdgpu, 2026-10-06).
#
# Checked against the original: GLMakie draws the same scene to the same pixels.
# And the trace node must not touch the Hikari scene while rasterising.

using Test, Makie, RayMakie, GeometryBasics, Colors, Random, Statistics
import GLMakie
RayMakie.activate!()

lum(c) = 0.2126f0 * red(c) + 0.7152f0 * green(c) + 0.0722f0 * blue(c)
drawn(img) = count(c -> lum(c) < 0.99f0, img)

function scatter_scene(build)
    fig = Figure(; size = (400, 250))
    ax = LScene(fig[1, 1]; show_axis = false)
    ms = build(ax)
    return fig, ms
end

positions(n) = (r = Xoshiro(3); [Point3f(6rand(r) - 3, 6rand(r) - 3, rand(r)) for _ in 1:n])

const CASES = [
    "one colour" => ax -> meshscatter!(ax, positions(300); markersize = 0.1, color = :steelblue),
    "per-instance colour" => ax -> (r = Xoshiro(1); meshscatter!(ax, positions(300); markersize = 0.1,
        color = [RGBAf(rand(r), rand(r), rand(r), 1) for _ in 1:300])),
    "colormapped values" => ax -> (r = Xoshiro(1); meshscatter!(ax, positions(300); markersize = 0.1,
        color = rand(r, 300), colormap = :viridis)),
    "per-instance size and rotation" => ax -> (r = Xoshiro(1); meshscatter!(ax, positions(200);
        marker = Rect3f(Vec3f(-0.5), Vec3f(1)),
        markersize = [Vec3f(0.05, 0.1, 0.3) * rand(r) for _ in 1:200],
        rotation = [Makie.qrotation(Vec3f(0, 0, 1), 2pi * rand(r)) for _ in 1:200])),
    "marker not transformed by model" => ax -> meshscatter!(ax, positions(200); markersize = 0.1,
        transform_marker = false),
]

function frame(build, screenof)
    fig, _ = scatter_scene(build)
    screen = screenof(fig)
    colorbuffer(screen)
    img = copy(colorbuffer(screen))
    close(screen)
    return img
end
# One pixel per unit for both, and the film mapping off, so the images line up.
rasterscreen(fig) = RayMakie.Screen(fig.scene; visible = false, vsync = false, rasterize = true,
                                    tonemap = nothing, gamma = nothing)
glscreen(fig) = GLMakie.Screen(fig.scene; start_renderloop = false, visible = false, vsync = false,
                               px_per_unit = 1, scalefactor = 1)

@testset "meshscatter in RASTER mode" begin
    @testset "$name draws as GLMakie does" for (name, build) in CASES
        a = frame(build, glscreen)
        b = frame(build, rasterscreen)
        @test size(a) == size(b)
        @test drawn(b) > 1000
        @test abs(drawn(a) - drawn(b)) <= 0.01 * drawn(a)
        @test mean(abs.(lum.(a) .- lum.(b))) < 2e-3
    end

    @testset "nothing goes to the Hikari scene while rasterising" begin
        fig, ms = scatter_scene(CASES[1][2])
        screen = rasterscreen(fig)
        colorbuffer(screen)
        @test ms.trace_renderobject[] === nothing
        robj = ms.raster_renderobject[]
        @test robj isa RayMakie.RenderObject
        @test robj.instances == 300
        close(screen)
    end

    @testset "a mesh is one instance at the origin" begin
        fig = Figure(; size = (200, 200))
        ax = LScene(fig[1, 1]; show_axis = false)
        m = mesh!(ax, Sphere(Point3f(0), 1f0); color = :orange)
        screen = rasterscreen(fig)
        colorbuffer(screen)
        robj = m.raster_renderobject[]
        @test robj.instances == 1
        @test robj.uniforms[:transform_marker] == Int32(1)
        @test Array(robj.buffers[:instance_scales]) == [Vec3f(1)]
        close(screen)
    end

    @testset "colour changes kind" begin
        fig, ms = scatter_scene(ax -> meshscatter!(ax, positions(300); markersize = 0.15, color = :red))
        screen = rasterscreen(fig)
        reds(img) = count(c -> red(c) > 0.5 && green(c) < 0.2 && blue(c) < 0.2, img)
        greens(img) = count(c -> green(c) > 0.4 && red(c) < 0.2 && blue(c) < 0.2, img)
        colorbuffer(screen)
        i0 = copy(colorbuffer(screen))
        ms.color = fill(RGBAf(0, 1, 0, 1), 300)
        i1 = copy(colorbuffer(screen))
        ms.color = :red
        i2 = copy(colorbuffer(screen))
        @test reds(i0) > 1000
        @test reds(i1) == 0 && greens(i1) > 1000
        @test reds(i2) == reds(i0)
        close(screen)
    end

    @testset "the instance count is the frame's cost, not its memory" begin
        # 100k spheres: the case that froze a desktop. A frame must not need
        # more than a few hundred MB beyond the marker and the instance arrays.
        fig, _ = scatter_scene(ax -> meshscatter!(ax, positions(100_000); markersize = 0.03))
        screen = rasterscreen(fig)
        t = @elapsed colorbuffer(screen)
        t2 = @elapsed img = colorbuffer(screen)
        @test drawn(img) > 10_000
        @test t2 < 2.0
        close(screen)
    end
end
