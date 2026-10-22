using Test
using Makie, GeometryBasics, Hikari, RayMakie, LinearAlgebra
using Makie: Scene, cam3d!, mesh!, Point3f, Vec3f, Rect3f
using RayMakie: raster_emitter, placed, raster_emitter_node!, RasterEmitter

# A glowing mesh is one rectangle of light in the raster path. Finding it walks
# every face and averages the emission texture, so it is found once in the
# mesh's own space and only moved per frame: a turning globe with city lights
# otherwise held its scene to 3 fps.

const GLOW = Hikari.MediumInterface(Hikari.Diffuse(); emission = Hikari.Emissive(Le = Hikari.RGBSpectrum(2f0)))

softbox() = normal_mesh(Rect3f(Point3f(-12, -2.5, 0), Vec3f(24, 5, 0.2)))

function world_mesh(m, model::Mat4f)
    P = map(p -> (h = model * Vec4f(p..., 1f0); Point3f(h[1], h[2], h[3]) / h[4]), coordinates(m))
    return P, faces(m)
end

@testset "raster emitters" begin
    @testset "a softbox is its lit side" begin
        m = softbox()
        e = only(raster_emitter(coordinates(m), faces(m), GLOW))
        @test e.area ≈ 120f0
        @test abs(e.normal[3]) ≈ 1f0
        @test sort([e.half...]) ≈ [2.5f0, 12f0]
        @test isempty(raster_emitter(coordinates(m), faces(m), Hikari.Diffuse()))
    end

    @testset "placing equals finding it on the moved mesh" begin
        m = softbox()
        local_e = only(raster_emitter(coordinates(m), faces(m), GLOW))
        model = Makie.transformationmatrix(Vec3f(1, -2, 3), Vec3f(1.7f0),
                                           Makie.qrotation(normalize(Vec3f(1, 2, 0.5)), 0.9f0))
        moved = only(raster_emitter(world_mesh(m, Mat4f(model))..., GLOW))
        e = placed(local_e, Mat4f(model))
        @test e.centre ≈ moved.centre atol = 1f-3
        @test e.normal ≈ moved.normal atol = 1f-4
        @test e.area ≈ moved.area rtol = 1f-4
        @test abs(dot(e.axis, moved.axis)) ≈ 1f0 atol = 1f-4
        @test e.half ≈ moved.half rtol = 1f-3
    end

    @testset "found again for a new material, not for a new model matrix" begin
        scene = Scene(); cam3d!(scene)
        plot = mesh!(scene, softbox(); material = GLOW)
        raster_emitter_node!(plot)
        first_found = plot.raster_emitter_local[]
        Makie.rotate!(plot, Vec3f(0, 0, 1), 0.4f0)
        @test plot.raster_emitter_local[] === first_found
        plot.material = Hikari.MediumInterface(Hikari.Diffuse(); emission = Hikari.Emissive(Le = Hikari.RGBSpectrum(5f0)))
        @test plot.raster_emitter_local[] !== first_found
        @test only(plot.raster_emitter_local[]).L ≈ 2.5f0 * only(first_found).L
    end
end
