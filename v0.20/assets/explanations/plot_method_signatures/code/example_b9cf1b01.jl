# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using GLMakie
GLMakie.activate!() # hide
fig = Figure()

lines(fig[1, 1], 1.0..10, sin, color = :blue)
# this works because the previous command created an axis at fig[1, 1]
lines!(fig[1, 1], 1.0..10, cos, color = :red)

# the following line wouldn't work yet because no axis exists at fig[1, 2]
# lines!(fig[1, 2], 1.0..10, sin, color = :green)

fig[1, 2] = Axis(fig)
# now it works
lines!(fig[1, 2], 1.0..10, sin, color = :green)

# also works with nested grids
fig[2, 1:2][1, 3] = Axis(fig)
lines!(fig[2, 1:2][1, 3], 1.0..10, cos, color = :orange)

# but often it's more convenient to save an axis to reuse it
ax, _ = lines(fig[2, 1:2][1, 1:2], 1.0..10, sin, color = :black)
lines!(ax, 1.0..10, cos, color = :yellow)

fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_b9cf1b01_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_b9cf1b01.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide