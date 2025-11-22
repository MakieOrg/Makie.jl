# This file was generated, do not modify it. # hide
__result = begin # hide
  
using GLMakie
GLMakie.activate!() # hide
# FigureAxisPlot takes figure and axis keywords
fig, ax, p = lines(cumsum(randn(1000)),
    figure = (resolution = (1000, 600),),
    axis = (ylabel = "Temperature",),
    color = :red)

# AxisPlot takes axis keyword
lines(fig[2, 1], cumsum(randn(1000)),
    axis = (xlabel = "Time (sec)", ylabel = "Stock Value"),
    color = :blue)

fig

  end # hide
  save(joinpath(@OUTPUT, "example_15985286866026406005.png"), __result) # hide
  
  nothing # hide