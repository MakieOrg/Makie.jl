# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie

f = Figure()

markersizes = [5, 10, 15, 20]
colors = [:red, :green, :blue, :orange]

group_size = [MarkerElement(marker = :circle, color = :black,
    strokecolor = :transparent,
    markersize = ms) for ms in markersizes]

group_color = [PolyElement(color = color, strokecolor = :transparent)
    for color in colors]

legends = [Legend(f,
    [group_size, group_color],
    [string.(markersizes), string.(colors)],
    ["Size", "Color"], tellheight = true) for _ in 1:4]

f[1, 1:2] = legends[1:2]
f[2, :] = legends[3]
f[3, :] = legends[4]

for l in legends[3:4]
    l.orientation = :horizontal
    l.tellheight = true
    l.tellwidth = false
end

legends[2].titleposition = :left
legends[4].titleposition = :left

legends[1].nbanks = 2
legends[4].nbanks = 2

Label(f[1, 1, Left()], "titleposition = :top\norientation = :vertical\nnbanks = 2", font = :italic, padding = (0, 10, 0, 0))
Label(f[1, 2, Right()], "titleposition = :left\norientation = :vertical\nnbanks = 1", font = :italic, padding = (10, 0, 0, 0))
Label(f[2, 1:2, Top()], "titleposition = :top, orientation = :horizontal\nnbanks = 1", font = :italic)
Label(f[3, 1:2, Top()], "titleposition = :left, orientation = :horizontal\nnbanks = 2", font = :italic)

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_a443be2a_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_a443be2a.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_a443be2a.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide