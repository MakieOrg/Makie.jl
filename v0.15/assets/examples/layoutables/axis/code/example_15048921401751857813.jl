# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie

f = Figure()

ax1 = Axis(f[1, 1])
ax2 = Axis(f[1, 2])
ax3 = Axis(f[2, 2])

linkyaxes!(ax1, ax2)
linkxaxes!(ax2, ax3)

ax1.title = "y linked"
ax2.title = "x & y linked"
ax3.title = "x linked"

for (i, ax) in enumerate([ax1, ax2, ax3])
    lines!(ax, 1:10, 1:10, color = "green")
    if i != 1
        lines!(ax, 11:20, 1:10, color = "red")
    end
    if i != 3
        lines!(ax, 1:10, 11:20, color = "blue")
    end
end

f

  end # hide
  save(joinpath(@OUTPUT, "example_15048921401751857813.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_15048921401751857813.svg"), __result) # hide
  nothing # hide