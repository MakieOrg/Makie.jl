# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
using CairoMakie # hide
CairoMakie.activate!() # hide
f = Figure()

kwargs = (; xminorticksvisible = true, xminorgridvisible = true)
Axis(f[1, 1]; xminorticks = IntervalsBetween(2), kwargs...)
Axis(f[2, 1]; xminorticks = IntervalsBetween(5), kwargs...)
Axis(f[3, 1]; xminorticks = [1, 2, 3, 4], kwargs...)

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_eee44ef9_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_eee44ef9.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_eee44ef9.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide