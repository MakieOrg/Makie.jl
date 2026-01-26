# This file was generated, do not modify it. # hide
__result = begin # hide
    using CairoMakie
CairoMakie.activate!() # hide


f = Figure()

xs = LinRange(0, 4pi, 21)
ys = sin.(xs)

stairs(f[1, 1], xs, ys)
stairs(f[2, 1], xs, ys; step=:post, color=:blue, linestyle=:dash)
stairs(f[3, 1], xs, ys; step=:center, color=:red, linestyle=:dot)

f
end # hide
save(joinpath(@OUTPUT, "example_7983703081124967899.png"), __result; ) # hide

nothing # hide