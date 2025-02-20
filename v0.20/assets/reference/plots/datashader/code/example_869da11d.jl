# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using DelimitedFiles, GLMakie
GLMakie.activate!() # hide
# For saving/showing/inlining into documentation we need to disable async calculation.
Makie.set_theme!(DataShader = (; async=false))
airports = Point2f.(eachrow(readdlm(assetpath("airportlocations.csv"))))
fig, ax, ds = datashader(airports,
    colormap=[:white, :black],
    # use type=Axis, so that Makie doesn't need to infer
    # the axis type, which can be expensive for a large amount of points
    axis = (; type=Axis),
    # for documentation output we shouldn't calculate the image async,
    # since it won't wait for the render to finish and inline a blank image
    async = false,
    figure = (; figurepadding=0, size=(360*2, 160*2))
)
Colorbar(fig[1, 2], ds, label="Number of airports")
hidedecorations!(ax); hidespines!(ax)
fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_869da11d_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_869da11d.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide