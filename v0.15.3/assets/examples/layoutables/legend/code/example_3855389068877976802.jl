# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie

f = Figure()

ax = f[1, 1] = Axis(f)

lines!(0..15, sin, label = "sin", color = :blue)
lines!(0..15, cos, label = "cos", color = :red)
lines!(0..15, x -> -cos(x), label = "-cos", color = :green)

f[1, 2] = Legend(f, ax, "Trig Functions", framevisible = false)

f

  end # hide
  save(joinpath(@OUTPUT, "example_3855389068877976802.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_3855389068877976802.svg"), __result) # hide
  nothing # hide