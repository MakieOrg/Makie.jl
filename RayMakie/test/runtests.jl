using RayMakie
using Makie, Hikari, Raycore
using GeometryBasics
using KernelAbstractions
using Test

@testset "RayMakie.jl" begin

@testset "free! - MultiTypeSet" begin
    set = Raycore.MultiTypeSet(KernelAbstractions.CPU())
    push!(set, Hikari.Diffuse(Kd=(0.5, 0.5, 0.5)))
    push!(set, Hikari.Mirror(Kr=(0.9, 0.9, 0.9)))
    @test length(set) == 2
    Raycore.free!(set)
    @test isempty(set.texture_gpu_arrays)
end

@testset "free! - Film" begin
    film = Hikari.Film(Point2f(32, 32))
    @test size(film.framebuffer) == (32, 32)
    Hikari.free!(film)
end

@testset "free! - TLAS" begin
    tlas = Raycore.TLAS(KernelAbstractions.CPU())
    Raycore.free!(tlas)
    @test isempty(tlas.gpu_blas_arrays)
end

@testset "free! - Scene lifecycle (delete!)" begin
    scene = Scene(; size=(64, 64), lights=[PointLight(RGBf(10, 10, 10), Point3f(0, -5, 5))])
    cam3d!(scene)
    cam = cameracontrols(scene)
    cam.eyeposition[] = Vec3f(0, -5, 3)
    cam.lookat[] = Vec3f(0, 0, 0)
    update_cam!(scene, cam)

    mesh!(scene, Sphere(Point3f(0), 1f0); material=Hikari.Diffuse(Kd=(0.8, 0.2, 0.2)))

    RayMakie.activate!(; exposure=1.0f0, tonemap=:aces, gamma=2.2f0)
    screen = RayMakie.Screen(scene)
    display(screen, scene)

    @test !isnothing(screen.state)
    @test size(screen.state.film.framebuffer) == (64, 64)

    Base.delete!(screen, scene)
    @test isnothing(screen.state)
end

end
