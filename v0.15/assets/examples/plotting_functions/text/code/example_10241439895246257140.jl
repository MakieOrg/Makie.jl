# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure()
LScene(f[1, 1])

text!(
    fill("Makie", 7),
    rotation = [i / 7 * 1.5pi for i in 1:7],
    position = [Point3f(0, 0, i/2) for i in 1:7],
    color = [cgrad(:viridis)[x] for x in LinRange(0, 1, 7)],
    align = (:left, :baseline),
    textsize = 1,
    space = :data
)

f

  end # hide
  save(joinpath(@OUTPUT, "example_10241439895246257140.png"), __result) # hide
  
  nothing # hide