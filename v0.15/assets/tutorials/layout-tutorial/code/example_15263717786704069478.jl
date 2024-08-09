# This file was generated, do not modify it. # hide
__result = begin # hide
  
cb = Colorbar(gb[1:2, 2], hm, label = "cell group")
low, high = extrema(data1)
edges = range(low, high, length = 7)
centers = (edges[1:6] .+ edges[2:7]) .* 0.5
cb.ticks = (centers, string.(1:6))

f

  end # hide
  save(joinpath(@OUTPUT, "example_15263717786704069478.png"), __result) # hide
  
  nothing # hide