# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using GLMakie, GeometryBasics
GLMakie.activate!() # hide

ps = [
    Point3f(cosd(phi) * cosd(theta), sind(phi) * cosd(theta), sind(theta))
    for theta in range(-20, 20, length = 21) for phi in range(60, 340, length=30)
]
faces = [QuadFace(30j + i, 30j + mod1(i+1, 30), 30*(j+1) + mod1(i+1, 30), 30*(j+1) + i) for j in 0:19 for i in 1:29]
marker_mesh = GeometryBasics.Mesh(meta(ps, normals = ps), decompose(GLTriangleFace, faces))

lights = [PointLight(RGBf(10, 4, 2), Point3f(0, 0, 0), 5)]

fig = Figure(size = (600, 600), backgroundcolor = :black)
ax = LScene(fig[1, 1], scenekw = (lights = lights,), show_axis = false)
update_cam!(ax.scene, ax.scene.camera_controls, Rect3f(Point3f(-2), Vec3f(4)))
meshscatter!(
    ax, [Point3f(0) for _ in 1:14], marker = marker_mesh, markersize = 0.1:0.2:3.0,
    color = :white, backlight = 1, transparency = false)
fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_fa1acde1_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_fa1acde1.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide