# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie

f = Figure()

Axis(f[1, 1])

markersizes = [5, 10, 15, 20]
colors = [:red, :green, :blue, :orange]

for ms in markersizes, color in colors
    scatter!(randn(5, 2), markersize = ms, color = color)
end

group_size = [MarkerElement(marker = :circle, color = :black,
    strokecolor = :transparent,
    markersize = ms) for ms in markersizes]

group_color = [PolyElement(color = color, strokecolor = :transparent)
    for color in colors]

legends = [Legend(f,
    [group_size, group_color],
    [string.(markersizes), string.(colors)],
    ["Size", "Color"]) for _ in 1:6]

f[1, 2:4] = legends[1:3]
f[2:4, 2] = legends[4:6]

for l in legends[4:6]
    l.orientation = :horizontal
    l.tellheight = true
    l.tellwidth = false
end

legends[2].titleposition = :left
legends[5].titleposition = :left

legends[3].nbanks = 2
legends[5].nbanks = 2
legends[6].nbanks = 2

f

  end # hide
  save(joinpath(@OUTPUT, "example_13748480395996139778.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_13748480395996139778.svg"), __result) # hide
  nothing # hide