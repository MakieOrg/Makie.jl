# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide

fig = Figure(size = (600, 600))
ax11 = LScene(fig[1, 1], scenekw = (lights = [],))
ax12 = LScene(fig[1, 2], scenekw = (lights = [AmbientLight(RGBf(0, 0, 0))],))
ax21 = LScene(fig[2, 1], scenekw = (lights = [AmbientLight(RGBf(0.7, 0.7, 0.7))],))
ax22 = LScene(fig[2, 2], scenekw = (lights = [AmbientLight(RGBf(0.8, 0.3, 0))],))
for ax in (ax11, ax12, ax21, ax22)
    mesh!(ax, Sphere(Point3f(0), 1f0), color = :white)
end
fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_b3109d0b_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_b3109d0b.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide