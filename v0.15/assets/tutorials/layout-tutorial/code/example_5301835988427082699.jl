# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
using FileIO
CairoMakie.activate!() # hide

noto_sans = assetpath("fonts", "NotoSans-Regular.ttf")
noto_sans_bold = assetpath("fonts", "NotoSans-Bold.ttf")

f = Figure(backgroundcolor = RGBf(0.98, 0.98, 0.98),
    resolution = (1000, 700), font = noto_sans)

  end # hide
  save(joinpath(@OUTPUT, "example_5301835988427082699.png"), __result) # hide
  
  nothing # hide