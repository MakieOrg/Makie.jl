# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

N = 1000
xs = rand(1:3, N)
side = rand([:left, :right], N)
color = map(xs, side) do x, s
    colors = s == :left ? [:red, :orange, :yellow] : [:blue, :teal, :cyan]
    return colors[x]
end
ys = map(side) do s
    return s == :left ? randn() : rand()
end

violin(xs, ys, side = side, color = color)

  end # hide
  save(joinpath(@OUTPUT, "example_10086317265396201589.png"), __result) # hide
  
  nothing # hide