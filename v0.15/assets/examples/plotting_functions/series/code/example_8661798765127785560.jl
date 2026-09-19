# This file was generated, do not modify it. # hide
__result = begin # hide
  
data = cumsum(randn(4, 101), dims = 2)

series(0:0.1:10, data, solid_color=:black)

  end # hide
  save(joinpath(@OUTPUT, "example_8661798765127785560.png"), __result) # hide
  
  nothing # hide