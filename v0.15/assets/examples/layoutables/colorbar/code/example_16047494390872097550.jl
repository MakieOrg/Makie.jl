# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie

fig = Figure()

Axis(fig[1, 1])

# vertical colorbars
Colorbar(fig[1, 2], limits = (0, 10), colormap = :viridis,
    flipaxis = false)
Colorbar(fig[1, 3], limits = (0, 5),
    colormap = cgrad(:Spectral, 5, categorical = true), size = 25)
Colorbar(fig[1, 4], limits = (-1, 1), colormap = :heat,
    highclip = :cyan, lowclip = :red, label = "Temperature")

# horizontal colorbars
Colorbar(fig[2, 1], limits = (0, 10), colormap = :viridis,
    vertical = false)
Colorbar(fig[3, 1], limits = (0, 5), size = 25,
    colormap = cgrad(:Spectral, 5, categorical = true), vertical = false)
Colorbar(fig[4, 1], limits = (-1, 1), colormap = :heat,
    label = "Temperature", vertical = false, flipaxis = false,
    highclip = :cyan, lowclip = :red)

fig

  end # hide
  save(joinpath(@OUTPUT, "example_16047494390872097550.png"), __result) # hide
  
  nothing # hide