# This file was generated, do not modify it. # hide
__result = begin # hide
    using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure()
Axis(f[1, 1])

x = rand(200)
w = @. x^2 * (1 - x)^2 
ecdfplot!(x)
ecdfplot!(x; weights = w, color=:orange)

f
end # hide
save(joinpath(@OUTPUT, "example_1135201972689776596.png"), __result; ) # hide

nothing # hide