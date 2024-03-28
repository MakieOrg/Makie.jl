# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
using CairoMakie # hide
CairoMakie.activate!() # hide
f = Figure()

ax1 = Axis(f[1, 1], xtrimspine = false)
ax2 = Axis(f[2, 1], xtrimspine = true)
ax3 = Axis(f[3, 1], xtrimspine = (true, false))
ax4 = Axis(f[4, 1], xtrimspine = (false, true))

for ax in [ax1, ax2, ax3, ax4]
    ax.xgridvisible = false
    ax.ygridvisible = false
    ax.rightspinevisible = false
    ax.topspinevisible = false
    xlims!(ax, 0.5, 5.5)
end

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_d0f09193_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_d0f09193.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_d0f09193.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide