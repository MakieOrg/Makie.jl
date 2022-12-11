# This file was generated, do not modify it. # hide
__result = begin # hide
    using CairoMakie

heatmap(randn(20, 20),
    figure = (backgroundcolor = :pink,),
    axis = (aspect = 1, xlabel = "x axis", ylabel = "y axis")
)
end # hide
save(joinpath(@OUTPUT, "example_15035588595016389094.png"), __result) # hide
save(joinpath(@OUTPUT, "example_15035588595016389094.svg"), __result) # hide
nothing # hide