# This file was generated, do not modify it. # hide
__result = begin # hide
    using CairoMakie

f = Figure()

ax1 = Axis(f[1, 1], yticklabelcolor = :blue)
ax2 = Axis(f[1, 1], yticklabelcolor = :red, yaxisposition = :right)
hidespines!(ax2)
hidexdecorations!(ax2)

lines!(ax1, 0..10, sin, color = :blue)
lines!(ax2, 0..10, x -> 100 * cos(x), color = :red)

f
end # hide
save(joinpath(@OUTPUT, "example_2115761524578697646.png"), __result; ) # hide
save(joinpath(@OUTPUT, "example_2115761524578697646.svg"), __result; ) # hide
nothing # hide