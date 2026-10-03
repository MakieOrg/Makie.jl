# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using GLMakie
GLMakie.activate!() # hide

fig = Figure()
ax = LScene(fig[1, 1], show_axis=false)
p1 = mesh!(ax, Rect2f(-2, -2, 4, 4), color = (:red, 0.5), shading = NoShading, transparency = true)
p2 = mesh!(ax, Rect2f(-2, -2, 4, 4), color = (:blue, 0.5), shading = NoShading, transparency = true)
p3 = mesh!(ax, Rect2f(-2, -2, 4, 4), color = (:red, 0.5), shading = NoShading, transparency = true)
for (dz, p) in zip((-1, 0, 1), (p1, p2, p3))
    translate!(p, 0, 0, dz)
end
fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_861e08c7_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_861e08c7.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide