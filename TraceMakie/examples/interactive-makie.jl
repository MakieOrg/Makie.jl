using Hikari, TraceMakie, FileIO, GLMakie
begin
    model = load(joinpath(dirname(pathof(Hikari)), "..", "docs", "src", "assets", "models", "caustic-glass.ply"))
    glass = Hikari.GlassMaterial(
        Hikari.ConstantTexture(Hikari.RGBSpectrum(0.9f0)),
        Hikari.ConstantTexture(Hikari.RGBSpectrum(0.88f0)),
        Hikari.ConstantTexture(0.0f0),
        Hikari.ConstantTexture(0.0f0),
        Hikari.ConstantTexture(1.4f0),
        true,
    )
    plastic = Hikari.PlasticMaterial(
        Hikari.ConstantTexture(Hikari.RGBSpectrum(0.6399999857f0, 0.6399999857f0, 0.5399999857f0)),
        Hikari.ConstantTexture(Hikari.RGBSpectrum(0.1000000015f0, 0.1000000015f0, 0.1000000015f0)),
        Hikari.ConstantTexture(0.010408001f0),
        true,
    )
    plastic_ceil = Hikari.PlasticMaterial(
        Hikari.ConstantTexture(Hikari.RGBSpectrum(0.3399999857f0, 0.6399999857f0, 0.8399999857f0)),
        Hikari.ConstantTexture(Hikari.RGBSpectrum(1.4f0)),
        Hikari.ConstantTexture(0.000408001f0),
        true,
    )
    scene = Scene(size=(1024, 1024); lights=[
        Makie.AmbientLight(RGBf(1, 1, 1)),
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

    # render_interactive(scene, ArrayType; max_depth=5)
    TraceMakie.render_interactive(scene; backend=GLMakie, max_depth=5)
end
