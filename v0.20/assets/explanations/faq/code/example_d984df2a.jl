# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie

f = Figure()

Axis(f[1, 1], title = "Shrunk")
Axis(f[2, 1], title = "Expanded")
Label(f[1, 2], "This Label has the setting\ntellheight = true\ntherefore the row it is in has\nadjusted to match its height.", tellheight = true)
Label(f[2, 2], "This Label has the setting\ntellheight = false.\nThe row it is in can use\nall the remaining space.", tellheight = false)

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_d984df2a_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_d984df2a.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_d984df2a.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide