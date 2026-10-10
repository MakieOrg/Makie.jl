# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie

haligns = [:left, :right, :center]
valigns = [:top, :bottom, :center]

f = Figure()

Axis(f[1, 1])

xs = 0:0.1:10
lins = [lines!(xs, sin.(xs .* i), color = color)
    for (i, color) in zip(1:3, [:red, :blue, :green])]

for (j, ha, va) in zip(1:3, haligns, valigns)
    Legend(
        f[1, 1], lins, ["Line $i" for i in 1:3],
        "$ha & $va",
        tellheight = false,
        tellwidth = false,
        margin = (10, 10, 10, 10),
        halign = ha, valign = va, orientation = :horizontal
    )
end

f

  end # hide
  save(joinpath(@OUTPUT, "example_6496361355257737470.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_6496361355257737470.svg"), __result) # hide
  nothing # hide