# This file was generated, do not modify it. # hide
__result = begin # hide
    using CairoMakie
CairoMakie.activate!() # hide
v = rand(10,2)
scatter(v[:,1], v[:,2], rasterize = 10, markersize = 30.0)
end # hide
save(joinpath(@OUTPUT, "example_13020492903260766064.png"), __result; ) # hide
save(joinpath(@OUTPUT, "example_13020492903260766064.svg"), __result; ) # hide
nothing # hide