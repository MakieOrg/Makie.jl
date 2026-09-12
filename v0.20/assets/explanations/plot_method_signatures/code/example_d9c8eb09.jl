# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using GLMakie
GLMakie.activate!() # hide
fig = Figure()

# first row, first column
scatter(fig[1, 1], 1.0..10, sin)

# first row, second column
lines(fig[1, 2], 1.0..10, sin)

# first row, third column, then nested first row, first column
lines(fig[1, 3][1, 1], cumsum(randn(1000)), color = :blue)

# first row, third column, then nested second row, first column
lines(fig[1, 3][2, 1], cumsum(randn(1000)), color = :red)

# second row, first to third column
ax, hm = heatmap(fig[2, 1:3], randn(30, 10))

# across all rows, new column after the last one
fig[:, end+1] = Colorbar(fig, hm)

fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_d9c8eb09_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_d9c8eb09.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide