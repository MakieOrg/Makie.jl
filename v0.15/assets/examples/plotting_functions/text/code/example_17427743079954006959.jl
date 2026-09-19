# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure()

Axis(f[1, 1], aspect = DataAspect(), backgroundcolor = :gray50)

scatter!(Point2f(0, 0))
text!("center", position = (0, 0), align = (:center, :center))

circlepoints = [(cos(a), sin(a)) for a in LinRange(0, 2pi, 16)[1:end-1]]
scatter!(circlepoints)
text!(
    "this is point " .* string.(1:15),
    position = circlepoints,
    rotation = LinRange(0, 2pi, 16)[1:end-1],
    align = (:right, :baseline),
    color = cgrad(:Spectral)[LinRange(0, 1, 15)]
)

f

  end # hide
  save(joinpath(@OUTPUT, "example_17427743079954006959.png"), __result) # hide
  
  nothing # hide