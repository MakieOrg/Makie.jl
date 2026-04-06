# pkg"add https://github.com/SimonDanisch/RayMakie.jl https://github.com/pxl-th/Hikari.jl#sd/tmp"

using RayMakie, FileIO, ImageShow, GLMakie, BenchmarkTools
using Hikari, AMDGPU
using Chairmarks

begin
    catmesh = load(Makie.assetpath("cat.obj"))
    scene = Scene(size=(1024, 1024);
        lights=[Makie.AmbientLight(RGBf(0.7, 0.6, 0.6)), Makie.PointLight(RGBf(1.3, 1.3, 1.3), Vec3f(0, 1, 0.5))]
    )
    cam3d!(scene)
    mesh!(scene, catmesh, color=load(Makie.assetpath("diffusemap.png")))
    center!(scene)
    screen = display(scene; backend=RayMakie, integrator=Hikari.Hikari.Whitted(samples=20))

    # @b RayMakie.render_gpu(scene, ROCArray; samples_per_pixel=1)
    # 1.024328 seconds (16.94 M allocations: 5.108 GiB, 46.19% gc time, 81 lock conflicts)
    # 0.913530 seconds (16.93 M allocations: 5.108 GiB, 42.52% gc time, 57 lock conflicts)
    # 0.416158 seconds (75.58 k allocations: 88.646 MiB, 2.44% gc time, 16 lock conflicts)
    # 0.135438 seconds (76.03 k allocations: 82.406 MiB, 8.57% gc time)
    ###
    # After film refactor:
    # 130.762 ms (1200951 allocations: 378.42 MiB)
    # With inbounds = true
    # 103.273 ms (75501 allocations: 86.48 MiB)
    # RayMakie.render_interactive(scene; backend=GLMakie, max_depth=5)
end
colorbuffer(screen)
display(scene; backend=RayMakie, integrator=Hikari.Hikari.FastWavefront())

using ImageShow, AMDGPU

begin
    scene = Scene(size=(1024, 1024);
        lights=[Makie.AmbientLight(RGBf(0.4, 0.4, 0.4)), Makie.PointLight(RGBf(500, 500, 500), Vec3f(4, 4, 10))]
    )
    cam3d!(scene)
    xs = LinRange(0, 10, 100)
    ys = LinRange(0, 15, 100)
    zs = [cos(x) * sin(y) for x in xs, y in ys]
    surface!(scene, xs, ys, zs)
    center!(scene)

    @btime RayMakie.render_whitted(scene)

    screen = display(scene; backend=RayMakie, integrator=Hikari.Hikari.Whitted(samples=20))

    # @b RayMakie.render_gpu(scene, ROCArray)
    # @time RayMakie.render_gpu(scene, ROCArray)
    # 1.598740s
    # 1.179450 seconds (17.30 M allocations: 5.126 GiB, 36.48% gc time, 94 lock conflicts)
    # 0.976180 seconds (443.12 k allocations: 107.841 MiB, 6.60% gc time, 12 lock conflicts)
    # @time render_gpu(scene, ArrayType)
    # 0.236231 seconds (443.48 k allocations: 101.598 MiB, 3.92% gc time)
    ###
    # After film refactor:
    # 195.110 ms (1796726 allocations: 456.83 MiB)

    # render_interactive(scene, ArrayType; max_depth=5)
    # RayMakie.render_interactive(scene; backend=GLMakie, max_depth=5)
    colorbuffer(screen)
end
begin
    model = load(joinpath(dirname(pathof(Hikari)), "..", "docs", "src", "assets", "models", "caustic-glass.ply"))
    glass = Hikari.Dielectric(
        Hikari.ConstantTexture(Hikari.RGBSpectrum(0.9f0)),
        Hikari.ConstantTexture(Hikari.RGBSpectrum(0.88f0)),
        Hikari.ConstantTexture(0.0f0),
        Hikari.ConstantTexture(0.0f0),
        Hikari.ConstantTexture(1.4f0),
        true,
    )
    plastic = Hikari.Plastic(color=(0.64, 0.64, 0.54), roughness=0.01)
    plastic_ceil = Hikari.Plastic(color=(0.34, 0.64, 0.84), roughness=0.0004)
    scene = Scene(size=(1024, 1024); lights=[
        AmbientLight(RGBf(1, 1, 1)),
        PointLight(RGBf(150, 150, 150), Vec3f(4, 4, 10)),
        PointLight(RGBf(60, 60, 60), Vec3f(-3, 10, 2.5)),
        PointLight(RGBf(40, 40, 40), Vec3f(0, 3, 0.5))
    ])
    cam3d!(scene)
    cm = scene.camera_controls
    mesh!(scene, model, material=glass)
    mini, maxi = extrema(Rect3f(decompose(Point, model)))
    floorrect = Rect3f(Vec3f(-10, mini[2], -10), Vec3f(20, -1, 20))
    mesh!(scene, floorrect, material=plastic_ceil)
    ceiling = Rect3f(Vec3f(-25, 11, -25), Vec3f(50, -1, 50))
    mesh!(scene, ceiling, material=plastic)
    center!(scene)
    update_cam!(scene, Vec3f(-1.6, 6.2, 0.2), Vec3f(-3.6, 2.5, 2.4), Vec3f(0, 1, 0))

    # @btime RayMakie.render_whitted(scene; samples_per_pixel=1)
    # 9.820304 seconds (1.69 M allocations: 235.165 MiB, 0.51% gc time, 3 lock conflicts)
    # @time render_gpu(scene, ArrayType)
    # 6.128600 seconds (1.70 M allocations: 228.875 MiB, 1.09% gc time)
    # @time render_sppm(scene; iterations=500)
    # @time colorbuffer(scene; backend=RPRMakie)
    # 6.321123 seconds (10.09 k allocations: 66.559 MiB, 0.15% gc time)
    ###
    # After film refactor:
    # 2.090 s (9087937 allocations: 2.10 GiB)
    # Inbounds = true
    # 1.686 s (1707363 allocations: 233.62 MiB)

    # render_interactive(scene, ArrayType; max_depth=5)
    RayMakie.render_whitted(scene; samples_per_pixel=8)
    # RayMakie.render_interactive(scene; backend=GLMakie, max_depth=5)
    # RayMakie.render_gpu(scene, ROCArray)
end

using GeometryBasics
mesh = load(Makie.assetpath("cat.obj"))
fs = decompose(TriangleFace{UInt32}, mesh)
vertices = decompose(Point3f, mesh)
normals = Normal3f.(decompose_normals(mesh))
uvs = Point2f.(GeometryBasics.decompose_uv(mesh))
