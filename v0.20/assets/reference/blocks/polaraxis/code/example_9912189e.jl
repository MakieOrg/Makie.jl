# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    fig = Figure(size = (600, 300))
ax1 = PolarAxis(fig[1, 1], radius_at_origin = 0.0, clip_r = true, title = "clip_r = true")
ax2 = PolarAxis(fig[1, 2], radius_at_origin = 0.0, clip_r = false, title = "clip_r = false")
for ax in (ax1, ax2)
    lines!(ax, 0..2pi, phi -> cos(2phi) - 0.5, color = :red, linewidth = 4)
    lines!(ax, 0..2pi, phi -> sin(2phi), color = :black, linewidth = 4)
end
fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_9912189e_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_9912189e.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_9912189e.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide