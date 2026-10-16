# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using GLMakie
GLMakie.activate!() # hide
# FigureAxisPlot takes figure and axis keywords
fig, ax, p = lines(cumsum(randn(1000)),
    figure = (size = (1000, 600),),
    axis = (ylabel = "Temperature",),
    color = :red)

# AxisPlot takes axis keyword
lines(fig[2, 1], cumsum(randn(1000)),
    axis = (xlabel = "Time (sec)", ylabel = "Stock Value"),
    color = :blue)

fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_4640d0c4_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_4640d0c4.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide