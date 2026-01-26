# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie

f = Figure(size = (800, 800))

Axis(f[1, 1])
for i in 1:3
    Axis(f[:, end+1])
    Axis(f[end+1, :])
end

Label(f[0, :], text = "Super Title", fontsize = 50)
Label(f[end+1, :], text = "Sub Title", fontsize = 50)
Label(f[1:end-1, 0], text = "Left Text", fontsize = 50,
    rotation = pi/2)
Label(f[1:end-1, end+1], text = "Right Text", fontsize = 50,
    rotation = -pi/2)

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_3c466c94_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_3c466c94.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_3c466c94.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide