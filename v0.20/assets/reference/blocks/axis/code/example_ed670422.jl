# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
using CairoMakie # hide
CairoMakie.activate!() # hide
using FileIO

f = Figure()

ax1 = Axis(f[1, 1], aspect = nothing, title = "nothing")
ax2 = Axis(f[1, 2], aspect = DataAspect(), title = "DataAspect()")
ax3 = Axis(f[2, 1], aspect = AxisAspect(1), title = "AxisAspect(1)")
ax4 = Axis(f[2, 2], aspect = AxisAspect(2), title = "AxisAspect(2)")

img = rotr90(load(assetpath("cow.png")))
for ax in [ax1, ax2, ax3, ax4]
    image!(ax, img)
end

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_ed670422_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_ed670422.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_ed670422.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide