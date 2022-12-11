# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

processors = ["VAX-11/780", "Sun-4/260", "PowerPC 604",
    "Alpha 21164", "Intel Pentium III", "Intel Xeon"]
relative_speeds = [1, 9, 117, 280, 1779, 6505]

barplot(relative_speeds, fillto = 0.5,
    axis = (yscale = log10, ylabel ="relative speed",
        xticks = (1:6, processors), xticklabelrotation = pi/8))

ylims!(0.5, 10000)
current_figure()

  end # hide
  save(joinpath(@OUTPUT, "example_14294748689859113481.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_14294748689859113481.svg"), __result) # hide
  nothing # hide