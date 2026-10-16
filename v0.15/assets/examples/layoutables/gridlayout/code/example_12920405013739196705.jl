# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie

f = Figure(resolution = (800, 800))

Axis(f[1, 1])
for i in 1:3
    Axis(f[:, end+1])
    Axis(f[end+1, :])
end

Label(f[0, :], text = "Super Title", textsize = 50)
Label(f[end+1, :], text = "Sub Title", textsize = 50)
Label(f[2:end-1, 0], text = "Left Text", textsize = 50,
    rotation = pi/2)
Label(f[2:end-1, end+1], text = "Right Text", textsize = 50,
    rotation = -pi/2)

f

  end # hide
  save(joinpath(@OUTPUT, "example_12920405013739196705.png"), __result) # hide
  
  nothing # hide