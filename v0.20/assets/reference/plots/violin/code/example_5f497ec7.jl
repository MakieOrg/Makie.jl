# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide


N = 1000
categories = rand(1:3, N)
side = rand([:left, :right], N)
color = map(categories, side) do x, s
    colors = s === :left ? [:red, :orange, :yellow] : [:blue, :teal, :cyan]
    return colors[x]
end
values = map(side) do s
    return s === :left ? randn() : rand()
end

violin(categories, values, side = side, color = color)
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_5f497ec7_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_5f497ec7.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide