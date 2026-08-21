# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    f = Figure(size = (600, 600), backgroundcolor = :black)
ax = PolarAxis(
    f[1, 1],
    backgroundcolor = :black,
    # r minor grid
    rminorgridvisible = true, rminorgridcolor = :red,
    rminorgridwidth = 1.0, rminorgridstyle = :dash,
    # theta minor grid
    thetaminorgridvisible = true, thetaminorgridcolor = :lightblue,
    thetaminorgridwidth = 1.0, thetaminorgridstyle = :dash,
    # major grid
    rgridwidth = 2, rgridcolor = :red,
    thetagridwidth = 2, thetagridcolor = :lightblue,
    # r labels
    rticklabelsize = 18, rticklabelcolor = :red,
    rticklabelstrokewidth = 1.0, rticklabelstrokecolor = :white,
    # theta labels
    thetaticklabelsize = 18, thetaticklabelcolor = :lightblue
)

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_d78b242a_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_d78b242a.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_d78b242a.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide