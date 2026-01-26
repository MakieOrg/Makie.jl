# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
using CairoMakie # hide
CairoMakie.activate!() # hide
f = Figure()

kwargs = (; yminorticksvisible = true, yminorgridvisible = true)
Axis(f[1, 1]; yminorticks = IntervalsBetween(2), kwargs...)
Axis(f[1, 2]; yminorticks = IntervalsBetween(5), kwargs...)
Axis(f[1, 3]; yminorticks = [1, 2, 3, 4], kwargs...)

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_3ea723fe_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_3ea723fe.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_3ea723fe.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide