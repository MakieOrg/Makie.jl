# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide

scene = Scene(size = (400, 275))
campixel!(scene)
scatter!(
    scene, [100, 200, 300], [100, 100, 100],
    color = [RGBAf(1,0,0,0.5), RGBAf(0,0,1,0.5), RGBAf(1,0,0,0.5)],
    markersize=200
)
scatter!(scene, Point2f(150, 175), color = (:green, 0.5), markersize=200)
p = scatter!(scene, Point2f(250, 175), color = (:green, 0.5), markersize=200)
translate!(p, 0, 0, -1)
scene
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_eb44e1b8_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_eb44e1b8.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide