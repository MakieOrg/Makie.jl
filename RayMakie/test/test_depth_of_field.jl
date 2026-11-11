using Test, RayMakie, Makie, Hikari, GeometryBasics

@testset "Camera3D depth of field reaches the traced camera" begin
    sc = Scene(; size = (300, 200))
    cam3d!(sc; fstop = 2.0, aperture_blades = 6, aperture_rotation = 0.5)
    update_cam!(sc, Vec3f(0, -5, 0), Vec3f(0), Vec3f(0, 0, 1))
    box = mesh!(sc, Rect3f(Point3f(1, 1, -1), Vec3f(2, 2, 2)))
    camera = RayMakie.to_trace_camera(sc, Hikari.Film(Point2f(300, 200)))

    @test camera[].core.lens_radius ≈ 0.018 / (1.5 * tand(22.5)) / 4
    @test camera[].core.focal_distance ≈ 5
    @test (camera[].core.aperture_blades, camera[].core.aperture_rotation) == (6, 0.5f0)

    sc.camera_controls.focus[] = 3
    @test camera[].core.focal_distance ≈ 3
    sc.camera_controls.focus[] = box
    @test camera[].core.focal_distance ≈ 7
end
