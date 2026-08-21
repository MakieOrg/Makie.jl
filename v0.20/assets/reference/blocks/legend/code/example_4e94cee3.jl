# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie

f = Figure()

Axis(f[1, 1])

elem_1 = [LineElement(color = :red, linestyle = nothing),
          MarkerElement(color = :blue, marker = 'x', markersize = 15,
          strokecolor = :black)]

elem_2 = [PolyElement(color = :red, strokecolor = :blue, strokewidth = 1),
          LineElement(color = :black, linestyle = :dash)]

elem_3 = LineElement(color = :green, linestyle = nothing,
        points = Point2f[(0, 0), (0, 1), (1, 0), (1, 1)])

elem_4 = MarkerElement(color = :blue, marker = 'π', markersize = 15,
        points = Point2f[(0.2, 0.2), (0.5, 0.8), (0.8, 0.2)])

elem_5 = PolyElement(color = :green, strokecolor = :black, strokewidth = 2,
        points = Point2f[(0, 0), (1, 0), (0, 1)])

Legend(f[1, 2],
    [elem_1, elem_2, elem_3, elem_4, elem_5],
    ["Line & Marker", "Poly & Line", "Line", "Marker", "Poly"],
    patchsize = (35, 35), rowgap = 10)

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_4e94cee3_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_4e94cee3.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_4e94cee3.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide