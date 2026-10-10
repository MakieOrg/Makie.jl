# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    with_theme(
    Theme(
        palette = (color = [:red, :blue], linestyle = [:dash, :dot]),
        Lines = (cycle = Cycle([:color, :linestyle], covary = true),)
    )) do
    lines(fill(5, 10))
    lines!(fill(4, 10))
    lines!(fill(3, 10))
    lines!(fill(2, 10))
    lines!(fill(1, 10))
    current_figure()
end
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_4d999030_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_4d999030.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide