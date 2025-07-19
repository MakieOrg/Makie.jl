# This file was generated, do not modify it. # hide
__result = begin # hide
  
n_day_1 = length(0:0.1:6pi)
n_day_2 = length(0:0.1:10pi)

colsize!(gd, 1, Auto(n_day_1))
colsize!(gd, 2, Auto(n_day_2))

f

  end # hide
  save(joinpath(@OUTPUT, "example_17650476251627665022.png"), __result) # hide
  
  nothing # hide