# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

N = 1000
xs = rand(1:3, N)
dodge = rand(1:2, N)
side = rand([:left, :right], N)
color = @. ifelse(side == :left, :orange, :teal)
ys = map(side) do s
    return s == :left ? randn() : rand()
end

violin(xs, ys, dodge = dodge, side = side, color = color)

  end # hide
  save(joinpath(@OUTPUT, "example_16140503757206530997.png"), __result) # hide
  
  nothing # hide