# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    rainclouds(category_labels, data_array;
    ylabel = "Categories of Distributions",
    xlabel = "Samples", title = "My Title",
    orientation = :horizontal,
    plot_boxplots = true, cloud_width=0.5, clouds=hist,
    color = colors[indexin(category_labels, unique(category_labels))])
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_cbee27ac_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_cbee27ac.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide