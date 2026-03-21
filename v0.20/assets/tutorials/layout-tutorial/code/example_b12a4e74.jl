# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    brain = load(assetpath("brain.stl"))

ax3d = Axis3(gc[1, 1], title = "Brain activation")
m = mesh!(
    ax3d,
    brain,
    color = [tri[1][2] for tri in brain for i in 1:3],
    colormap = Reverse(:magma),
)
Colorbar(gc[1, 2], m, label = "BOLD level")

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_b12a4e74_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_b12a4e74.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide