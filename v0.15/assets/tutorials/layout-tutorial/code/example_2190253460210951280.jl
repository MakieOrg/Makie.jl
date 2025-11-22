# This file was generated, do not modify it. # hide
__result = begin # hide
  
xs = LinRange(0.5, 6, 50)
ys = LinRange(0.5, 6, 50)
data1 = [sin(x^1.5) * cos(y^0.5) for x in xs, y in ys] .+ 0.1 .* randn.()
data2 = [sin(x^0.8) * cos(y^1.5) for x in xs, y in ys] .+ 0.1 .* randn.()

ax1, hm = contourf(gb[1, 1], xs, ys, data1,
    levels = 6)
ax1.title = "Histological analysis"
contour!(xs, ys, data1, levels = 5, color = :black)
hidexdecorations!(ax1)

_, hm2 = contourf(gb[2, 1], xs, ys, data2,
    levels = 6)
contour!(xs, ys, data2, levels = 5, color = :black)

f

  end # hide
  save(joinpath(@OUTPUT, "example_2190253460210951280.png"), __result) # hide
  
  nothing # hide