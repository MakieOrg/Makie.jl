# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

theme = Attributes(
    Axis = (
        xminorticksvisible = true,
        yminorticksvisible = true,
        xminorgridvisible = true,
        yminorgridvisible = true,
    )
)

fig = with_theme(theme) do
    fig = Figure()
    axs = [Axis(fig[fldmod1(n, 2)...],
        title = "IntervalsBetween($(n+1))",
        xminorticks = IntervalsBetween(n+1),
        yminorticks = IntervalsBetween(n+1)) for n in 1:4]
    fig
end

fig

  end # hide
  save(joinpath(@OUTPUT, "example_9080452699255241236.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_9080452699255241236.svg"), __result) # hide
  nothing # hide