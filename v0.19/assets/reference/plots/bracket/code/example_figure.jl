# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str # hide
__result = begin # hide
    using CairoMakie
CairoMakie.activate!() # hide

f = Figure()
ax = Axis(f[1, 1], xgridvisible = false, ygridvisible = false)
ylims!(ax, -1, 2)
bracket!(ax, 1, 0, 3, 0, text = "Curly", style = :curly)
bracket!(ax, 2, 1, 4, 1, text = "Square", style = :square)

f
end # hide
save(joinpath(@OUTPUT, "example_1749627910516873225.png"), __result; ) # hide

nothing # hide