# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str # hide
__result = begin # hide
    using CairoMakie
CairoMakie.activate!() # hide

f = Figure()
Axis(f[1, 1])

for i in 1:4
    radius = 1/(i*2)
    left = 1/(i*2)
    right = (i*2-1)/(i*2)
    arc!(Point2f(left, 0), radius, 0, π)
    arc!(Point2f(right, 0), radius, 0, π)
end
for i in 3:4
    radius = 1/(i*(i-1)*2)
    left = (1/i) + 1/(i*(i-1)*2)
    right = ((i-1)/i) - 1/(i*(i-1)*2)
    arc!(Point2f(left, 0), radius, 0, π)
    arc!(Point2f(right, 0), radius, 0, π)
end

f
end # hide
save(joinpath(@OUTPUT, "example_446186802487841561.png"), __result; ) # hide
save(joinpath(@OUTPUT, "example_446186802487841561.svg"), __result; ) # hide
nothing # hide