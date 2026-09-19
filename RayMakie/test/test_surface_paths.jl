# A surface has to draw in a scene that is not ray-traced.
#
# `mesh!` has had a fork between the traced and the raster path since the
# beginning; `surface!` had only the traced half. So it pushed into
# `screen.state.hikari_scene`, which is `nothing` for an overlay-only state, and
# died with `MethodError: push!(::Nothing, …)` — inside a compute-graph edge,
# which RayMakie reports as "an overlay render object failed to resolve; this
# plot will not be drawn". No stack trace at the call site, no exception for the
# caller, just an empty axis.
#
# Two ordinary calls land there:
#
#   * `surface!` into a 2D `Axis`, which Makie allows and GLMakie draws.
#   * any surface whose scene has no 3D camera. `surface(fill(3f0, 20, 20))` is
#     one: a flat surface gives `LScene` nothing to fit, so it keeps an
#     `EmptyCamera`, `should_raytrace` is false, and the whole figure becomes
#     overlay-only.
#
# A surface IS a mesh, so the fix hands the same flat vertex arrays to the same
# pipeline `mesh!` uses rather than growing a second one.
using Test, Makie, RayMakie, Hikari, GeometryBasics, Colors

"""Saturation, which finds a colormapped surface in an otherwise grey figure."""
sat(c) = maximum((red(c), green(c), blue(c))) - minimum((red(c), green(c), blue(c)))

@testset "surface! draws in a 2D Axis" begin
    zs = [Float32(abs(sin(i * 0.7) * cos(j * 0.9))) for i in 1:20, j in 1:20]
    fig = Figure(size = (300, 220))
    ax = Axis(fig[1, 1])
    plt = surface!(ax, zs)
    img = Makie.colorbuffer(fig; backend = RayMakie)

    # It resolved at all — with the bug this is the traced NamedTuple's absence,
    # because the edge threw and the plot was dropped.
    @test plt[:trace_renderobject][] isa RayMakie.RenderObject

    # …and it is actually on the screen. A dropped plot leaves the axis empty,
    # so the only coloured thing in the figure is the surface itself.
    coloured = count(c -> sat(c) > 0.15, img)
    @test coloured > 0.2 * length(img)
end

@testset "a flat surface draws" begin
    # Zero z extent: `LScene` keeps an `EmptyCamera`, so nothing is traced and
    # every plot in the figure takes the raster path.
    fig = surface(fill(3.0f0, 20, 20))
    img = Makie.colorbuffer(fig; backend = RayMakie)
    coloured = count(c -> sat(c) > 0.15, img)
    @test coloured > 0.2 * length(img)

    # One z means one colour — the surface is a single flat patch, not a
    # gradient, and not the grey fallback.
    px = [c for c in img if sat(c) > 0.15]
    @test length(unique(px)) <= 4
end

@testset "surface! still traces where it can" begin
    # The fork must not steal the traced path from a proper 3D scene.
    zs = [Float32(abs(sin(i * 0.7) * cos(j * 0.9))) for i in 1:12, j in 1:12]
    fig = Figure(size = (200, 160))
    ls = LScene(fig[1, 1])
    plt = surface!(ls, zs)
    Makie.colorbuffer(fig; backend = RayMakie)
    robj = plt[:trace_renderobject][]
    # The traced path returns a NamedTuple carrying the Hikari handle, the
    # raster one returns a RenderObject.
    @test robj isa NamedTuple
    @test haskey(robj, :handle)
end
