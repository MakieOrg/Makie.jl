# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    GLMakie.activate!() # hide
# Now, rotate the "joints"
rotate!(s2, Vec3f(0, 1, 0), 0.5)
rotate!(s3, Vec3f(1, 0, 0), 0.5)
parent
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_a0974cd1_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_a0974cd1.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide