# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    f = Figure()
plot(f[1, 1], PlotGrid((2, 2)); color=Cycled(1))
plot(f[1, 2], PlotGrid((3, 2)); color=Cycled(2))
f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_ee06fb9b_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_ee06fb9b.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_ee06fb9b.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide