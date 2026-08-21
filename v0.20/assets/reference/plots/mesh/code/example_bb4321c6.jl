# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using FileIO
using GLMakie
GLMakie.activate!() # hide


brain = load(assetpath("brain.stl"))

mesh(
    brain,
    color = [tri[1][2] for tri in brain for i in 1:3],
    colormap = Reverse(:Spectral)
)
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_bb4321c6_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_bb4321c6.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide