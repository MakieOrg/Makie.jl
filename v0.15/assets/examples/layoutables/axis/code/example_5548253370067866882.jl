# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

data = LinRange(0.01, 0.99, 200)

f = Figure(resolution = (800, 800))

for (i, scale) in enumerate([identity, log10, log2, log, sqrt, Makie.logit])

    row, col = fldmod1(i, 2)
    Axis(f[row, col], yscale = scale, title = string(scale),
        yminorticksvisible = true, yminorgridvisible = true,
        yminorticks = IntervalsBetween(8))

    lines!(data, color = :blue)
end

f

  end # hide
  save(joinpath(@OUTPUT, "example_5548253370067866882.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_5548253370067866882.svg"), __result) # hide
  nothing # hide