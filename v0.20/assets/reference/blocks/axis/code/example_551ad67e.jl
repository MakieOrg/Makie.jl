# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
using CairoMakie # hide
CairoMakie.activate!() # hide
f = Figure()

Axis(f[1, 1], title = "Title", subtitle = "Subtitle")
Axis(f[2, 1], title = "Title", subtitle = L"\sum_i{x_i \times y_i}")
Axis(f[3, 1], title = "Title", subtitle = rich(
    "Rich text subtitle",
    subscript(" with subscript", color = :slategray)
))

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_551ad67e_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_551ad67e.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_551ad67e.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide