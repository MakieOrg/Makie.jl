# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure()

horsepower = [52, 78, 80, 112, 140]
cars = ["Kia", "Mini", "Honda", "Mercedes", "Ferrari"]

ax = Axis(f[1, 1], xlabel = "horse power")
tightlimits!(ax, Left())
hideydecorations!(ax)

barplot!(horsepower, direction = :x)
text!(cars, position = Point.(horsepower, 1:5), align = (:right, :center),
    offset = (-20, 0), color = :white)

f

  end # hide
  save(joinpath(@OUTPUT, "example_8467954534360929428.png"), __result) # hide
  
  nothing # hide