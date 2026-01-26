# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    GLMakie.activate!() # hide
scene = Scene()
cam3d!(scene)
sphere_plot = mesh!(scene, Sphere(Point3f(0), 0.5), color=:red)
scale!(scene, 0.5, 0.5, 0.5)
rotate!(scene, Vec3f(1, 0, 0), 0.5) # 0.5 rad around the y axis
scene
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_a5c5927e_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_a5c5927e.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide