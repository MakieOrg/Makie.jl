# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide


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
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_8d97e49f_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_8d97e49f.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_8d97e49f.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide