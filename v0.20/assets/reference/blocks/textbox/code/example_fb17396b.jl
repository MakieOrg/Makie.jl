# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using GLMakie
using CairoMakie # hide
CairoMakie.activate!() # hide

f = Figure()
Textbox(f[1, 1], placeholder = "Enter a string...")
Textbox(f[2, 1], width = 300)

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_fb17396b_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_fb17396b.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide