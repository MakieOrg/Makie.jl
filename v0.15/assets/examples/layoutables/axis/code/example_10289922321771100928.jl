# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie

f = Figure()

for i in 1:2, j in 1:2
    Axis(
        f[i, j],
        limits = (0, 5, 0, 5),
        xaxisposition = (i == 1 ? :top : :bottom),
        yaxisposition = (j == 1 ? :left : :right))
end

f

  end # hide
  save(joinpath(@OUTPUT, "example_10289922321771100928.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_10289922321771100928.svg"), __result) # hide
  nothing # hide