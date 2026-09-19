# This file was generated, do not modify it. # hide
__result = begin # hide
    using CairoMakie, Distributions
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

N = 100_000
x = rand(1:3, N)
y = rand(Uniform(-1, 5), N)

w = pdf.(Normal(), x .- y)

fig = Figure()

boxplot(fig[1,1], x, y)
boxplot(fig[1,2], x, y, weights = w)

fig
end # hide
save(joinpath(@OUTPUT, "example_16182352727935647258.png"), __result; ) # hide

nothing # hide