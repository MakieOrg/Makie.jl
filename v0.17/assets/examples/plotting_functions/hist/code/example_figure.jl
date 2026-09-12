# This file was generated, do not modify it. # hide
__result = begin # hide
    using CairoMakie, Distributions
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

N = 100_000
x = rand(Uniform(-5, 5), N)

w = pdf.(Normal(), x)

fig = Figure()
hist(fig[1,1], x)
hist(fig[1,2], x, weights = w)

fig
end # hide
save(joinpath(@OUTPUT, "example_16278248207784189099.png"), __result; ) # hide

nothing # hide