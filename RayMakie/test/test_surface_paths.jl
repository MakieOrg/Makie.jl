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
# A surface IS a mesh: the raster path is Makie's `surface_as_mesh` drawn by the
# port of GLMakie's mesh shader, as `mesh!` is (GLMakie parity in
# test_mesh_raster.jl).
using Test, Makie, RayMakie, Hikari, GeometryBasics, Colors

"""Saturation, which finds a colormapped surface in an otherwise grey figure."""
sat(c) = maximum((red(c), green(c), blue(c))) - minimum((red(c), green(c), blue(c)))

@testset "surface! draws in a 2D Axis" begin
    zs = [Float32(abs(sin(i * 0.7) * cos(j * 0.9))) for i in 1:20, j in 1:20]
    fig = Figure(size = (300, 220))
    ax = Axis(fig[1, 1])
    plt = surface!(ax, zs)
    img = Makie.colorbuffer(fig; backend = RayMakie)

    # It resolved at all: with the bug the edge threw and the plot was dropped.
    @test plt[:raster_renderobject][] isa RayMakie.RenderObject
    @test plt[:trace_renderobject][] === nothing

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

# ── A surface in RASTER mode, and what is behind it ─────────────────────────
#
# `display(surface(z; axis = (; type = Axis3)); rasterize = true)` came out as an
# empty axis on a grey panel. The surface built its raster object and nothing
# drew it: the overlay pass only walked scenes holding a plot the TRACER cannot
# draw, and an `Axis3` scene holds nothing but the surface. (An `LScene` hid
# this by holding its own axis lines.) The walk asks the screen's mode now.
#
# The grey was the scene's ambient light. Hikari's `AmbientLight` is pbrt's
# uniform infinite light and is visible where a camera ray escapes, but a Makie
# `AmbientLight` is a shading term and never a background, and every Makie
# scene has one (0.45 by default): every 3D scene, traced or rasterised, came
# out on a flat grey sky instead of its `backgroundcolor`.

const WHITE = RGBA{Float32}(1, 1, 1, 1)
axis3_surface() = surface([Float32(abs(sin(i * 0.7) * cos(j * 0.9))) for i in 1:10, j in 1:10];
                          axis = (; type = Axis3), figure = (; size = (300, 240)))

@testset "an Axis3 surface is drawn when the screen rasterises" begin
    fig, ax, plt = axis3_surface()
    img = Makie.colorbuffer(fig; backend = RayMakie, rasterize = true)
    @test plt[:raster_renderobject][] isa RayMakie.RenderObject
    @test count(c -> sat(c) > 0.15, img) > 0.1 * length(img)
    # Inside the Axis3's scene, away from the surface: the background.
    @test img[25, 25] == WHITE
end

@testset "a traced 3D scene shows its background, not its ambient light" begin
    fig, ax, plt = axis3_surface()
    img = Makie.colorbuffer(fig; backend = RayMakie, samples = 1, max_depth = 2)
    @test plt[:trace_renderobject][] isa NamedTuple
    @test img[25, 25] == WHITE
end

@testset "setrasterize! switches a surface both ways" begin
    # The surface read the screen's CONFIG, which the switch does not change, and
    # had no `:rasterize` input for it to drop, so it stayed traced.
    fig, ax, plt = axis3_surface()
    scr = RayMakie.Screen(fig.scene; visible = false, samples = 1, max_depth = 2)
    Makie.update_state_before_display!(fig)
    Makie.colorbuffer(scr)
    @test plt[:trace_renderobject][] isa NamedTuple
    setrasterize!(scr, true)
    Makie.colorbuffer(scr)
    @test plt[:raster_renderobject][] isa RayMakie.RenderObject
    @test plt[:trace_renderobject][] === nothing
    setrasterize!(scr, false)
    Makie.colorbuffer(scr)
    @test plt[:trace_renderobject][] isa NamedTuple
    close(scr)
end

@testset "a rasterised surface follows the camera" begin
    # The raster object bakes the projection in, and the node had no camera input:
    # orbiting moved the axes and left the surface where it was.
    fig, ax, plt = axis3_surface()
    Makie.colorbuffer(fig; backend = RayMakie, rasterize = true)
    robj = plt[:raster_renderobject][]
    view = robj.uniforms[:view]
    ax.azimuth[] += 0.5
    Makie.colorbuffer(fig; backend = RayMakie, rasterize = true)
    @test plt[:raster_renderobject][] === robj        # updated in place
    @test robj.uniforms[:view] != view
end

@testset "a plot added to a traced Axis3 after display is traced" begin
    # `insert!` gave a new plot to the first state whose scene contained it: the
    # figure's root state, which traces nothing. The mesh went down the raster path
    # in a traced scene.
    fig, ax, plt = axis3_surface()
    scr = RayMakie.Screen(fig.scene; visible = false, samples = 1, max_depth = 2)
    Makie.update_state_before_display!(fig)
    Makie.colorbuffer(scr)
    sph = mesh!(ax, Sphere(Point3f(5, 5, 0.5), 1f0); color = :red)
    Makie.colorbuffer(scr)
    @test sph[:trace_renderobject][] isa NamedTuple
    @test sph[:raster_renderobject][] === nothing
    close(scr)
end
