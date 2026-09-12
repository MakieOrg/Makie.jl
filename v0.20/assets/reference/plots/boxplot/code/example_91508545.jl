# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide


categories = rand(1:3, 1000)
values = randn(1000)
dodge = rand(1:2, 1000)

boxplot(categories, values, dodge = dodge, show_notch = true, color = map(d->d==1 ? :blue : :red, dodge) , outliercolor = rand([:red, :green, :blue, :black, :yellow], 1000))
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_91508545_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_91508545.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide