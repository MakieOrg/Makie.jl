# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure()

data = rand(100, 2) .* 0.7 .+ 0.15

Axis(f[1, 1], title = "xlims!(nothing, 1)")
scatter!(data)
xlims!(nothing, 1)

Axis(f[1, 2], title = "xlims!(low = 0)")
scatter!(data)
xlims!(low = 0)

Axis(f[2, 1], title = "ylims!(0, nothing)")
scatter!(data)
ylims!(0, nothing)

Axis(f[2, 2], title = "ylims!(high = 1)")
scatter!(data)
ylims!(high = 1)

f

  end # hide
  save(joinpath(@OUTPUT, "example_17889597297920463892.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_17889597297920463892.svg"), __result) # hide
  nothing # hide