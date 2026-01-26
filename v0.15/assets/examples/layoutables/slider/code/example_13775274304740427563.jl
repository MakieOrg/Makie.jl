# This file was generated, do not modify it. # hide
__result = begin # hide
  
using GLMakie

fig = Figure()

ax = Axis(fig[1, 1])

lsgrid = labelslidergrid!(
    fig,
    ["Voltage", "Current", "Resistance"],
    [0:0.1:10, 0:0.1:20, 0:0.1:30];
    formats = "{:.1f}" .* ["V", "A", "Ω"],
    width = 350,
    tellheight = false)

fig[1, 2] = lsgrid.layout

sliderobservables = [s.value for s in lsgrid.sliders]
bars = lift(sliderobservables...) do slvalues...
    [slvalues...]
end

barplot!(ax, bars, color = [:yellow, :orange, :red])
ylims!(ax, 0, 30)

set_close_to!(lsgrid.sliders[1], 5.3)
set_close_to!(lsgrid.sliders[2], 10.2)
set_close_to!(lsgrid.sliders[3], 15.9)

fig

  end # hide
  save(joinpath(@OUTPUT, "example_13775274304740427563.png"), __result) # hide
  
  nothing # hide