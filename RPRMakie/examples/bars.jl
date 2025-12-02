using GeometryBasics, RPRMakie
using Colors, FileIO, ImageShow
using Colors: N0f8

RPRMakie.activate!(plugin = RPR.Northstar, resource = RPR.GPU0)
fig = Figure(; size = (800, 600), fontsize = 26)
radiance = 10000
lights = [
    EnvironmentLight(0.5, load(RPR.assetpath("studio026.exr"))),
    PointLight(Vec3f(0, 0, 20), RGBf(radiance, radiance, radiance)),
]

ax = LScene(fig[1, 1]; scenekw = (lights = lights, showaxis = false))
rectMesh = Rect(Vec3f(-0.5, -0.5, 0), Vec3f(1))
recmesh = GeometryBasics.normal_mesh(rectMesh)
n = 100
pos = [Point3f(i, j, 0) ./ 10 for i in 1:n for j in 1:n]
z = rand(n, n)
mat = (type = :Microfacet, color = :gray, roughness = 0.2, ior = 1.39)
meshscatter!(ax, pos; marker = recmesh, markersize = Vec3f.(0.1, 0.1, z[:]), material = mat, color = vec(z))

cam = cameracontrols(ax.scene)
cam.eyeposition[] = Float32[5, 22, 12]
cam.lookat[] = Float32[5, 5, -0.5]
cam.upvector[] = Float32[0.0, 0.0, 1.0]
cam.fov[] = 14.0

@time display(ax.scene)
