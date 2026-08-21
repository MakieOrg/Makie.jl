# This file was generated, do not modify it. # hide
__result = begin # hide
  

x = range(0, 10, length=100)
y = sin.(x)
lines(x, y)

  end # hide
  save(joinpath(@OUTPUT, "example_7476458710482869362.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_7476458710482869362.svg"), __result) # hide
  nothing # hide