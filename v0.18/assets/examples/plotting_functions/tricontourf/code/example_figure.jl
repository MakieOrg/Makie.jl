# This file was generated, do not modify it. # hide
__result = begin # hide
    using CairoMakie
CairoMakie.activate!() # hide

using Random
Random.seed!(1234)

x = randn(50)
y = randn(50)
z = -sqrt.(x .^ 2 .+ y .^ 2) .+ 0.1 .* randn.()

f, ax, tr = tricontourf(x, y, z, mode = :relative, levels = 0.2:0.1:1)
scatter!(x, y, color = z, strokewidth = 1, strokecolor = :black)
Colorbar(f[1, 2], tr)
f
end # hide
save(joinpath(@OUTPUT, "example_7280075066285086727.png"), __result; ) # hide
save(joinpath(@OUTPUT, "example_7280075066285086727.svg"), __result; ) # hide
nothing # hide