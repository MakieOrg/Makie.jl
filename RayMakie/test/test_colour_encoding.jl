# A Makie colour is sRGB-encoded; the tracer needs a linear reflectance.
#
# RayMakie handed the encoded value to Hikari as the reflectance, and the film
# then encoded the traced image for display once more. Every colour came out
# brighter than it was asked for: `RGBf(0.3, 0.2, 0.1)` under a unit ambient
# light read back (0.65, 0.56, 0.38), and a dark skin tone projected onto a mesh
# from a photograph rendered pale. Pure black and white are fixed points of both
# curves, which is how it went unnoticed.
#
# A flat, unoccluded, matte quad under a unit ambient light reflects exactly its
# reflectance, so with the tone curve off and the film's gamma on, the picture
# has to give the colour back. Up to gamma 2.2 standing in for the sRGB curve,
# which is why the colour stays out of the darks where the two part.

using Test, Makie, RayMakie, Mantle, GeometryBasics, Colors
using Makie: Scene, cam3d!, mesh!, cameracontrols, update_cam!, AmbientLight, RGBf, Vec3f, Point3f

function ce_quad_scene(color)
    sc = Scene(size = (48, 48), lights = [AmbientLight(RGBf(1, 1, 1))])
    cam3d!(sc)
    ps = [Point3f(-1, 0, -1), Point3f(1, 0, -1), Point3f(1, 0, 1), Point3f(-1, 0, 1)]
    msh = GeometryBasics.normal_mesh(ps, [TriangleFace{Int}(1, 2, 3), TriangleFace{Int}(1, 3, 4)])
    mesh!(sc, msh; color)
    cam = cameracontrols(sc)
    cam.eyeposition[] = Vec3f(0, -3, 0)
    cam.lookat[] = Vec3f(0, 0, 0)
    cam.upvector[] = Vec3f(0, 0, 1)
    cam.fov[] = 20
    update_cam!(sc, cam)
    return sc
end

@testset "a colour renders as the colour it names" begin
    c = RGBf(0.8, 0.5, 0.3)
    # RASTER mode decodes the same way, so it keeps standing in for the traced
    # picture. It needs a graphics pipeline.
    modes = Mantle.supports_graphics(Mantle.defaultbackend()) ? (false, true) : (false,)
    @testset "$(rasterize ? "raster" : "traced"), $(vertex ? "per vertex" : "uniform")" for rasterize in modes,
                                                                                             vertex in (false, true)
        sc = ce_quad_scene(vertex ? fill(c, 4) : c)
        img = Makie.colorbuffer(sc; backend = RayMakie, samples = 4, max_depth = 2,
                                tonemap = nothing, rasterize)
        px = img[24, 24]
        @test isapprox(red(px), red(c); atol = 0.02)
        @test isapprox(green(px), green(c); atol = 0.02)
        @test isapprox(blue(px), blue(c); atol = 0.02)
    end
end
