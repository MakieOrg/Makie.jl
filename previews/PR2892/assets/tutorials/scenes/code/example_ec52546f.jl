# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    GLMakie.activate!() # hide
w, h = size(scene)
nearplane = 0.1f0
farplane = 100f0
aspect = Float32(w / h)
cam.projection[] = Makie.perspectiveprojection(45f0, aspect, nearplane, farplane)
# Now, we also need to change the view matrix
# to "put" the camera into some place.
eyeposition = Vec3f(10)
lookat = Vec3f(0)
upvector = Vec3f(0, 0, 1)
cam.view[] = Makie.lookat(eyeposition, lookat, upvector)
scene
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_ec52546f_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_ec52546f.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide