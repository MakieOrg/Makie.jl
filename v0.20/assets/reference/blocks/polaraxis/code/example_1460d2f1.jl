# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    phis = range(pi/4, 9pi/4, length=201)
rs = 1.0 ./ sin.(range(pi/4, 3pi/4, length=51)[1:end-1])
rs = vcat(rs, rs, rs, rs, rs[1])

fig = Figure(size = (900, 300))
ax1 = PolarAxis(fig[1, 1], radius_at_origin = -2,  title = "radius_at_origin = -2")
ax2 = PolarAxis(fig[1, 2], radius_at_origin = 0,   title = "radius_at_origin = 0")
ax3 = PolarAxis(fig[1, 3], radius_at_origin = 0.5, title = "radius_at_origin = 0.5")
for ax in (ax1, ax2, ax3)
    lines!(ax, phis, rs .- 2, color = :red, linewidth = 4)
    lines!(ax, phis, rs, color = :black, linewidth = 4)
    lines!(ax, phis, rs .+ 0.5, color = :blue, linewidth = 4)
end
fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_1460d2f1_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_1460d2f1.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_1460d2f1.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide