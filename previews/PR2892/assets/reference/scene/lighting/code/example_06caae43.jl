# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using GLMakie
GLMakie.activate!() # hide

lights = [
    PointLight(RGBf(1, 1, 1), Point3f(0, 0, 5), 50),
    PointLight(RGBf(2, 0, 0), Point3f(-3, -3, 2), 10),
    PointLight(RGBf(0, 2, 0), Point3f(-3,  3, 2), 10),
    PointLight(RGBf(0, 0, 2), Point3f( 3,  3, 2), 10),
    PointLight(RGBf(2, 2, 0), Point3f( 3, -3, 2), 10),
]

fig = Figure(size = (600, 600))
ax = LScene(fig[1, 1], scenekw = (lights = lights,))
ps = [Point3f(x, y, 0) for x in -5:5 for y in -5:5]
meshscatter!(ax, ps, color = :white, markersize = 0.75)
scatter!(ax, map(l -> l.position[], lights), color = map(l -> l.color[], lights), strokewidth = 1, strokecolor = :black)
fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_06caae43_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_06caae43.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide