# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using GLMakie
GLMakie.activate!() # hide

fig = Figure(size = (800, 400))
ax1 = LScene(fig[1, 1], show_axis=false)
p1 = mesh!(ax1, Rect2f(-2, -2, 4, 4), color = :red, shading = NoShading, transparency = true)
p2 = mesh!(ax1, Rect2f(-2, -2, 4, 4), color = :blue, shading = NoShading, transparency = true)
p3 = mesh!(ax1, Rect2f(-2, -2, 4, 4), color = :red, shading = NoShading, transparency = true)
for (dz, p) in zip((-1, 0, 1), (p1, p2, p3))
    translate!(p, 0, 0, dz)
end

ax2 = LScene(fig[1, 2], show_axis=false)
p1 = mesh!(ax2, Rect2f(-1.5, -1, 3, 3), color = (:red, 0.5), shading = NoShading, transparency=true)
p2 = mesh!(ax2, Rect2f(-1.5, -2, 3, 3), color = (:blue, 0.5), shading = NoShading, transparency=true)
rotate!(p1, Vec3f(0, 1, 0), 0.1)
rotate!(p2, Vec3f(0, 1, 0), -0.1)
fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_7b464b34_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_7b464b34.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide