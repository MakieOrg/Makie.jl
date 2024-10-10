# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str # hide
__result = begin # hide
    using CairoMakie
using CairoMakie # hide
CairoMakie.activate!() # hide
f = Figure()

ax1 = Axis(f[1, 1], ytrimspine = false)
ax2 = Axis(f[1, 2], ytrimspine = true)
ax3 = Axis(f[1, 3], ytrimspine = (true, false))
ax4 = Axis(f[1, 4], ytrimspine = (false, true))

for ax in [ax1, ax2, ax3, ax4]
    ax.xgridvisible = false
    ax.ygridvisible = false
    ax.rightspinevisible = false
    ax.topspinevisible = false
    ylims!(ax, 0.5, 5.5)
end

f
end # hide
save(joinpath(@OUTPUT, "example_7494008406582555718.png"), __result; ) # hide
save(joinpath(@OUTPUT, "example_7494008406582555718.svg"), __result; ) # hide
nothing # hide