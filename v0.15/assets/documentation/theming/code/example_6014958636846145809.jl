# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

function example_plot()
    f = Figure()
    for i in 1:2, j in 1:2
        lines(f[i, j], cumsum(randn(50)))
    end
    f
end

example_plot()

  end # hide
  save(joinpath(@OUTPUT, "example_6014958636846145809.png"), __result) # hide
  
  nothing # hide