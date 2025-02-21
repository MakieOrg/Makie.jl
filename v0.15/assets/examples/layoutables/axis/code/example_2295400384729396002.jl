# This file was generated, do not modify it. # hide
__result = begin # hide
  
lineobject = lines!(ax, 0..10, sin, color = :red)
scatobject = scatter!(0:0.5:10, cos, color = :orange)

f

  end # hide
  save(joinpath(@OUTPUT, "example_2295400384729396002.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_2295400384729396002.svg"), __result) # hide
  nothing # hide