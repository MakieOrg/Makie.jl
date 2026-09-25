# RASTER mode draws `mesh` through the port of GLMakie's mesh shader
# (src/overlay/mesh.jl). Before it, a raster mesh was one flat colour per vertex
# worked out on the CPU: unlit, no stroke, and a colormapped `color = values`
# came out as a single colour while the tracer mapped it.
#
# The strongest check is the original: with the film mapping switched off
# (`tonemap = nothing, gamma = nothing`), GLMakie and RASTER mode must draw the
# same picture of the same scene. `plane_scene` fills the frame, so the ambient
# term is compared on every pixel.

using Test, Makie, RayMakie, Hikari, GeometryBasics, Colors
import GLMakie
# Loading GLMakie activates it, and every later file's `getscreen` would then look
# for a GLMakie screen. The comparisons below name their backend.
RayMakie.activate!()
using Makie: Scene, cam3d!, cam2d!, mesh!, surface!, cameracontrols, update_cam!, Point2f, Point3f,
             Vec3f, Sphere, RGBf, Rect2f, PointLight, AmbientLight, DirectionalLight,
             EnvironmentLight, NoShading

raster_screen(scene; kw...) =
    RayMakie.Screen(scene; samples = 1, max_depth = 1, hw_accel = false,
                    rasterize = true, kw...)

lum(c) = 0.2126f0 * red(c) + 0.7152f0 * green(c) + 0.0722f0 * blue(c)
backdrop(c) = green(c) > 0.9 && red(c) < 0.1 && blue(c) < 0.1   # the scenes' pure green

function sphere_scene(; lights, color, size = (96, 96), kw...)
    sc = Scene(; size, lights, backgroundcolor = RGBf(0, 1, 0))
    cam3d!(sc)
    msh = GeometryBasics.normal_mesh(Sphere(Point3f(0), 1f0))
    c = color === :height ? [p[3] for p in GeometryBasics.coordinates(msh)] : color
    mesh!(sc, msh; color = c, fxaa = false, kw...)
    cam = cameracontrols(sc)
    cam.eyeposition[] = Vec3f(0, -6, 3)
    cam.lookat[] = Vec3f(0, 0, 0)
    cam.upvector[] = Vec3f(0, 0, 1)
    cam.fov[] = 45
    update_cam!(sc, cam)
    return sc
end

function plane_scene(; lights, size = (96, 96))
    sc = Scene(; size, lights, backgroundcolor = RGBf(0, 1, 0))
    cam3d!(sc)
    ps = [Point3f(-50, -50, 0), Point3f(50, -50, 0), Point3f(50, 50, 0), Point3f(-50, 50, 0)]
    msh = GeometryBasics.Mesh(ps, [GLTriangleFace(1, 2, 3), GLTriangleFace(1, 3, 4)];
                              normal = fill(Vec3f(0, 0, 1), 4))
    mesh!(sc, msh; color = :orange, fxaa = false)
    cam = cameracontrols(sc)
    cam.eyeposition[] = Vec3f(0, -3, 3)
    cam.lookat[] = Vec3f(0, 0, 0)
    cam.upvector[] = Vec3f(0, 0, 1)
    cam.fov[] = 45
    update_cam!(sc, cam)
    return sc
end

function quads_scene(; strokewidth, size = (120, 80))
    sc = Scene(; size, backgroundcolor = :white)
    cam2d!(sc)
    ps = [Point2f(x, y) for y in 0:1 for x in 0:2]
    quads = [QuadFace{Int}(1, 2, 5, 4), QuadFace{Int}(2, 3, 6, 5)]
    mesh!(sc, GeometryBasics.Mesh(ps, quads); color = :lightblue, shading = NoShading,
          strokewidth, strokecolor = :black, strokeedges = :all, fxaa = false)
    update_cam!(sc, Rect2f(-0.2, -0.2, 2.4, 1.4))
    return sc
end

# A surface in RASTER mode is Makie's `surface_as_mesh` through the same shader.
# It had a flat, unlit pipeline of its own until 2026-09-25. A colour matrix of
# the grid's size pins the half-texel shift GLMakie's surface.vert applies: without
# it every colour smears half a cell towards the far edge, which a checkerboard
# shows on 11% of the pixels and a smooth gradient hides.
function surface_scene(; lights, size = (96, 96), kw...)
    sc = Scene(; size, lights, backgroundcolor = RGBf(0, 1, 0))
    cam3d!(sc)
    zs = [Float32(0.6 * sin(i * 0.8) * cos(j * 0.6)) for i in 1:8, j in 1:6]
    surface!(sc, range(-1, 1, length = 8), range(-1, 1, length = 6), zs; fxaa = false, kw...)
    cam = cameracontrols(sc)
    cam.eyeposition[] = Vec3f(2.5, -3, 2.5)
    cam.lookat[] = Vec3f(0, 0, 0)
    cam.upvector[] = Vec3f(0, 0, 1)
    cam.fov[] = 45
    update_cam!(sc, cam)
    return sc
end

"""Fraction of pixels differing by more than `tol` in any channel, and the mean difference."""
function disagreement(a, b; tol = 0.1)
    size(a) == size(b) || error("images differ in size: $(size(a)) vs $(size(b))")
    bad = 0; total = 0.0
    for (p, q) in zip(a, b)
        d = max(abs(Float32(red(p)) - Float32(red(q))), abs(Float32(green(p)) - Float32(green(q))),
                abs(Float32(blue(p)) - Float32(blue(q))))
        bad += d > tol
        total += d
    end
    return (fraction = bad / length(a), mean = total / length(a))
end

@testset "raster mesh: GLMakie's mesh shader" begin
    @testset "an environment's irradiance" begin
        # A white map of intensity 1 lights every normal to exactly 1: the
        # identity the spherical-harmonic projection has to keep.
        sh, has = RayMakie.environment_sh([EnvironmentLight(1f0, fill(RGBf(1, 1, 1), 64, 64))])
        @test has == 1
        for n in (Vec3f(0, 0, 1), Vec3f(1, 0, 0), Vec3f(0, -1, 0), RayMakie._unit(Vec3f(1, 1, 1)))
            @test isapprox(RayMakie.env_irradiance(sh, n), Vec3f(1, 1, 1); atol = 0.02)
        end
        # A sky and no ground: up is fully lit and down not at all, which nine
        # coefficients reproduce exactly for a hemisphere.
        n = 64
        sky = [Hikari.equal_area_square_to_sphere(Point2f((i - 0.5f0) / n, (j - 0.5f0) / n))[3] > 0 ?
               RGBf(1, 1, 1) : RGBf(0, 0, 0) for j in 1:n, i in 1:n]
        sh2, _ = RayMakie.environment_sh([EnvironmentLight(1f0, sky)])
        @test RayMakie.env_irradiance(sh2, Vec3f(0, 0, 1))[1] > 0.9
        @test RayMakie.env_irradiance(sh2, Vec3f(0, 0, -1))[1] < 0.1
        # No environment light, no environment term.
        @test RayMakie.environment_sh([PointLight(RGBf(1, 1, 1), Point3f(0))])[2] == 0
    end

    @testset "a colormapped mesh maps per vertex" begin
        # The CPU path knew colours and single colours, not values through a
        # colormap, so `color = values` drew one colour.
        sc = sphere_scene(; lights = Makie.AbstractLight[], color = :height,
                          colormap = [:blue, :red], shading = NoShading)
        px = filter(!backdrop, Makie.colorbuffer(raster_screen(sc)))
        @test count(c -> blue(c) > 0.6 && red(c) < 0.4, px) > 50
        @test count(c -> red(c) > 0.6 && blue(c) < 0.4, px) > 50
    end

    @testset "a lit mesh is shaded" begin
        # Unlit, every pixel of a uniformly coloured sphere had the same value.
        sc = sphere_scene(; lights = [PointLight(RGBf(60, 60, 60), Point3f(4, -4, 6))], color = :white)
        l = lum.(filter(!backdrop, Makie.colorbuffer(raster_screen(sc; tonemap = nothing, gamma = nothing))))
        @test length(l) > 500
        @test maximum(l) - minimum(l) > 0.3
    end

    @testset "the edge stroke" begin
        dark(c) = lum(c) < 0.2
        stroked = count(dark, Makie.colorbuffer(RayMakie.Screen(quads_scene(; strokewidth = 4))))
        plain = count(dark, Makie.colorbuffer(RayMakie.Screen(quads_scene(; strokewidth = 0))))
        @test stroked > 500
        @test plain < 20
    end

    @testset "the same picture as GLMakie" begin
        # Each scene is built twice: a plot a backend has displayed carries that
        # backend's nodes.
        sun = DirectionalLight(RGBf(0.8, 0.8, 0.8), Vec3f(-1, 1, -1))
        scenes = [
            "fast shading" => () -> sphere_scene(; color = :orange, lights = [sun]),
            "ambient" => () -> plane_scene(; lights = [AmbientLight(RGBf(0.3, 0.3, 0.3)), sun]),
            "colormapped" => () -> sphere_scene(; lights = Makie.AbstractLight[], color = :height,
                                                 shading = NoShading),
            "stroked quads" => () -> quads_scene(; strokewidth = 4),
            "lit surface" => () -> surface_scene(; lights = [AmbientLight(RGBf(0.3, 0.3, 0.3)), sun]),
            "surface, one colour per vertex" => () -> surface_scene(; lights = Makie.AbstractLight[],
                color = [isodd(i + j) ? RGBf(1, 0.2, 0) : RGBf(0, 0.2, 1) for i in 1:8, j in 1:6],
                shading = NoShading),
            "stroked surface" => () -> surface_scene(; lights = [sun], strokewidth = 2,
                                                      strokecolor = :black),
        ]
        for (label, make) in scenes
            gl = Makie.colorbuffer(make(); backend = GLMakie, px_per_unit = 1)
            rm = Makie.colorbuffer(raster_screen(make(); tonemap = nothing, gamma = nothing))
            d = disagreement(gl, rm)
            @testset "$label" begin
                @test d.fraction < 0.03
                @test d.mean < 0.02
            end
        end
    end
end
