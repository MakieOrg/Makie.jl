# This file was generated, do not modify it. # hide
__result = begin # hide
    using FileIO
using GLMakie
GLMakie.activate!() # hide
Makie.inline!(true) # hide

brain = load(assetpath("brain.stl"))

mesh(
    brain,
    color = [tri[1][2] for tri in brain for i in 1:3],
    colormap = Reverse(:Spectral),
    figure = (resolution = (1000, 1000),)
)
end # hide
save(joinpath(@OUTPUT, "example_4580049485859152347.png"), __result) # hide

nothing # hide