# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    axtop = Axis(ga[1, 1])
axmain = Axis(ga[2, 1], xlabel = "before", ylabel = "after")
axright = Axis(ga[2, 2])

linkyaxes!(axmain, axright)
linkxaxes!(axmain, axtop)

labels = ["treatment", "placebo", "control"]
data = randn(3, 100, 2) .+ [1, 3, 5]

for (label, col) in zip(labels, eachslice(data, dims = 1))
    scatter!(axmain, col, label = label)
    density!(axtop, col[:, 1])
    density!(axright, col[:, 2], direction = :y)
end

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_014ac2be_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_014ac2be.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide