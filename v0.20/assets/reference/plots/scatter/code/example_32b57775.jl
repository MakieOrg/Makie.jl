# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using GLMakie
GLMakie.activate!() # hide

ps = rand(Point3f, 500)
cs = rand(500)
f = Figure(size = (900, 650))
Label(f[1, 1], "base", tellwidth = false)
scatter(f[2, 1], ps, color = cs, markersize = 20, fxaa = false)
Label(f[1, 2], "fxaa = true", tellwidth = false)
scatter(f[2, 2], ps, color = cs, markersize = 20, fxaa = true)

Label(f[3, 1], "transparency = true", tellwidth = false)
scatter(f[4, 1], ps, color = cs, markersize = 20, transparency = true)
Label(f[3, 2], "overdraw = true", tellwidth = false)
scatter(f[4, 2], ps, color = cs, markersize = 20, overdraw = true)

Label(f[1, 3], "depthsorting = true", tellwidth = false)
scatter(f[2, 3], ps, color = cs, markersize = 20, depthsorting = true)
Label(f[3, 3], "depthsorting = true", tellwidth = false)
scatter(f[4, 3], ps, color = cs, markersize = 20, depthsorting = true)
mesh!(Rect3f(Point3f(0), Vec3f(0.9, 0.9, 0.9)), color = :orange)
f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_32b57775_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_32b57775.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide