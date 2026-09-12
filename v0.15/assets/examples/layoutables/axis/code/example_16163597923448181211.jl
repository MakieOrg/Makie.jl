# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
using FileIO
using Random # hide
Random.seed!(1) # hide

f = Figure()

axes = [Axis(f[i, j]) for i in 1:2, j in 1:3]
tightlimits!.(axes)

img = rotr90(load(assetpath("cow.png")))

for ax in axes
    image!(ax, img)
end

axes[1, 1].title = "Default"

axes[1, 2].title = "DataAspect"
axes[1, 2].aspect = DataAspect()

axes[1, 3].title = "AxisAspect(418/348)"
axes[1, 3].aspect = AxisAspect(418/348)

axes[2, 1].title = "AxisAspect(1)"
axes[2, 1].aspect = AxisAspect(1)

axes[2, 2].title = "AxisAspect(2)"
axes[2, 2].aspect = AxisAspect(2)

axes[2, 3].title = "AxisAspect(2/3)"
axes[2, 3].aspect = AxisAspect(2/3)

f

  end # hide
  save(joinpath(@OUTPUT, "example_16163597923448181211.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_16163597923448181211.svg"), __result) # hide
  nothing # hide