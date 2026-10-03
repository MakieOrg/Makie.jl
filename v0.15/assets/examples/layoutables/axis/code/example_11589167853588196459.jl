# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure()

axes = [Axis(f[i, j]) for i in 1:2, j in 1:2]

xs = LinRange(0, 2pi, 50)
for (i, ax) in enumerate(axes)
    ax.title = "Axis $i"
    lines!(ax, xs, sin.(xs))
end

axes[1].xticks = 0:6

axes[2].xticks = 0:pi:2pi
axes[2].xtickformat = xs -> ["$(x/pi)π" for x in xs]

axes[3].xticks = (0:pi:2pi, ["start", "middle", "end"])

axes[4].xticks = 0:pi:2pi
axes[4].xtickformat = "{:.2f}ms"
axes[4].xlabel = "Time"

f

  end # hide
  save(joinpath(@OUTPUT, "example_11589167853588196459.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_11589167853588196459.svg"), __result) # hide
  nothing # hide