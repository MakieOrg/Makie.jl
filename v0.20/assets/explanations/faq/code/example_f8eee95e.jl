# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide

f = Figure()

ax1 = Axis(f, title = "Squashed")
ax2 = Axis(f[1, 1], title = "Placed in Layout")
ax3 = Axis(f, bbox = BBox(200, 600, 100, 500),
  title = "Placed at BBox(200, 600, 100, 500)")

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_f8eee95e_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_f8eee95e.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_f8eee95e.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide