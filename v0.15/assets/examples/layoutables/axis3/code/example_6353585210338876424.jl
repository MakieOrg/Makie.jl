# This file was generated, do not modify it. # hide
__result = begin # hide
  
using GLMakie
using FileIO
GLMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure()

brain = load(assetpath("brain.stl"))

aspects = [:data, (1, 1, 1), (1, 2, 3), (3, 2, 1)]

for (i, aspect) in enumerate(aspects)
    ax = Axis3(f[fldmod1(i, 2)...], aspect = aspect, title = "$aspect")
    mesh!(brain, color = :bisque)
end

f

  end # hide
  save(joinpath(@OUTPUT, "example_6353585210338876424.png"), __result) # hide
  
  nothing # hide