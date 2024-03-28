# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    with_theme(
    Theme(
        palette = (color = [:red, :blue], marker = [:circle, :xcross]),
        Scatter = (cycle = [:color, :marker],)
    )) do
    scatter(fill(1, 10))
    scatter!(fill(2, 10))
    scatter!(fill(3, 10))
    scatter!(fill(4, 10))
    scatter!(fill(5, 10))
    current_figure()
end
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_8aeb260f_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_8aeb260f.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide