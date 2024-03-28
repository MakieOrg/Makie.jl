# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide

data = randn(1000)

hist(data, normalization = :pdf, bar_labels = :values,
     label_formatter=x-> round(x, digits=2), label_size = 15,
     strokewidth = 0.5, strokecolor = (:black, 0.5), color = :values)

  end # hide
  save(joinpath(@OUTPUT, "example_18267513311309602405.png"), __result) # hide
  
  nothing # hide