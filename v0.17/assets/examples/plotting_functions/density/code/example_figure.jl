# This file was generated, do not modify it. # hide
__result = begin # hide
    using CairoMakie, Distributions
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

N = 100_000
x = rand(Uniform(-2, 2), N)

w = pdf.(Normal(), x)

fig = Figure()
density(fig[1,1], x)
density(fig[1,2], x, weights = w)

fig
end # hide
save(joinpath(@OUTPUT, "example_504294024256947752.png"), __result; ) # hide

nothing # hide