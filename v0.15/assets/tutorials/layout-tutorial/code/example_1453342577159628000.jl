# This file was generated, do not modify it. # hide
__result = begin # hide
  
for (i, label) in enumerate(["sleep", "awake", "test"])
    Box(gd[i, 3], color = :gray90)
    Label(gd[i, 3], label, rotation = pi/2, tellheight = false)
end

f

  end # hide
  save(joinpath(@OUTPUT, "example_1453342577159628000.png"), __result) # hide
  
  nothing # hide