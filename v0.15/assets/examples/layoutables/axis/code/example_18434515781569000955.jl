# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure()

axes = [Axis(f[i, j]) for j in 1:3, i in 1:2]

for (i, ax) in enumerate(axes)
    ax.title = "Axis $i"
    poly!(ax, Point2f[(9, 9), (3, 1), (1, 3)],
        color = cgrad(:inferno, 6, categorical = true)[i])
end

xlims!(axes[1], [0, 10]) # as vector
xlims!(axes[2], 10, 0) # separate, reversed
ylims!(axes[3], 0, 10) # separate
ylims!(axes[4], (10, 0)) # as tuple, reversed
limits!(axes[5], 0, 10, 0, 10) # x1, x2, y1, y2
limits!(axes[6], BBox(0, 10, 0, 10)) # as rectangle

f

  end # hide
  save(joinpath(@OUTPUT, "example_18434515781569000955.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_18434515781569000955.svg"), __result) # hide
  nothing # hide