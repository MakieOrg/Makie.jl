using GeometryBasics, RPRMakie
using Colors, FileIO
using Colors: N0f8

img = begin
    radiance = 500
    lights = [
        EnvironmentLight(1.0, load(RPR.assetpath("studio026.exr"))),
        PointLight(Vec3f(10), RGBf(radiance, radiance, radiance * 1.1)),
    ]
    fig = Figure(; size = (1500, 700))
    ax = LScene(fig[1, 1]; show_axis = false, scenekw = (lights = lights,))
    screen = RPRMakie.Screen(ax.scene; plugin = RPR.Northstar, iterations = 1000)

    matsys = screen.matsys
    emissive = RPR.EmissiveMaterial(matsys)
    diffuse = RPR.DiffuseMaterial(matsys)
    glass = RPR.Glass(matsys)
    plastic = RPR.Plastic(matsys)
    chrome = RPR.Chrome(matsys)
    dielectric = RPR.DielectricBrdfX(matsys)
    gold = RPR.SurfaceGoldX(matsys)

    materials = [
        glass chrome;
        gold dielectric;
        emissive plastic
    ]

    mesh!(ax, load(Makie.assetpath("matball_floor.obj")); color = :white)
    palette = reshape(Makie.DEFAULT_PALETTES.color[][1:6], size(materials))

    for i in CartesianIndices(materials)
        x, y = Tuple(i)
        mat = materials[i]
        mplot = if mat === emissive
            matball!(ax, diffuse; inner = emissive, color = nothing)
        else
            matball!(ax, mat; color = nothing)
        end
        v = Vec3f(((x, y) .- (0.5 .* size(materials)) .- 0.5)..., 0)
        translate!(mplot, 0.9 .* (v .- Vec3f(0, 3, 0)))
    end
    cam = cameracontrols(ax.scene)
    cam.eyeposition[] = Vec3f(-0.3, -5.5, 0.9)
    cam.lookat[] = Vec3f(0.5, 0, -0.5)
    cam.upvector[] = Vec3f(0, 0, 1)
    cam.fov[] = 35
    emissive.color = Vec3f(4, 2, 2)
    colorbuffer(screen)
end

save("materials.png", img)
