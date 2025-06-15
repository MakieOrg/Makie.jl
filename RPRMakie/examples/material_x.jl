# download material from: https://matlib.gpuopen.com/main/materials/all?material=8686536a-8041-445b-97f1-f249f4c3b0af
using RPRMakie, ImageShow

material = "Pinwheel_Pattern_Marble_Tiles_4k_16b" # folder you downloaded & extracted

img = begin
    radiance = 1000
    lights = [
        EnvironmentLight(0.5, load(RPR.assetpath("studio026.exr"))),
        PointLight(Vec3f(5), RGBf(radiance, radiance, radiance * 1.1)),
    ]
    fig = Figure(; size = (1500, 700))
    ax = LScene(fig[1, 1]; show_axis = false, scenekw = (lights = lights,))
    screen = RPRMakie.Screen(ax.scene; plugin = RPR.Northstar, iterations = 500, resource = RPR.GPU0)
    matsys = screen.matsys
    marble_tiles = RPR.Matx(matsys, joinpath(material, "Pinwheel_Pattern_Marble_Tiles.mtlx"))

    mesh!(ax, load(Makie.assetpath("matball_floor.obj")); color = :white)
    matball!(ax, marble_tiles; color = nothing)
    cam = cameracontrols(ax.scene)
    cam.eyeposition[] = Vec3f(0.0, -2, 1)
    cam.lookat[] = Vec3f(0)
    cam.upvector[] = Float32[0.0, -0.01, 1.0]
    update_cam!(ax.scene, cam)
    # TODO, material doesn't show up?
    colorbuffer(screen)
end
