# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide

fig = Figure()

categories = rand(1:3, 1000)
values = randn(1000)

ax_vert = Axis(fig[1,1];
    xlabel = "categories",
    ylabel = "values",
    xticks = (1:3, ["one", "two", "three"])
)
ax_horiz = Axis(fig[1,2];
    xlabel="values", # note that x/y still correspond to horizontal/vertical axes respectively
    ylabel="categories",
    yticks=(1:3, ["one", "two", "three"])
)

# Note: same order of category/value, despite different axes
violin!(ax_vert, categories, values) # `orientation=:vertical` is default
violin!(ax_horiz, categories, values; orientation=:horizontal)

fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_e24dfc5f_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_e24dfc5f.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide