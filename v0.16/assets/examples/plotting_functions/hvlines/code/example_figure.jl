# This file was generated, do not modify it. # hide
__result = begin # hide
    using CairoMakie
CairoMakie.activate!() # hide

f = Figure()

ax1 = Axis(f[1, 1], title = "vlines")

lines!(ax1, 0..4pi, sin)
vlines!(ax1, [pi, 2pi, 3pi], color = :red)

ax2 = Axis(f[1, 2], title = "hlines")
hlines!(ax2, [1, 2, 3, 4], xmax = [0.25, 0.5, 0.75, 1], color = :blue)

f
end # hide
save(joinpath(@OUTPUT, "example_14190056973592732823.png"), __result) # hide

nothing # hide