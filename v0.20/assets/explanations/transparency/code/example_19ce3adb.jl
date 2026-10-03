# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie, FileIO
CairoMakie.activate!() # hide

# color
fig, ax, p = image(0..11, -1..11, rotr90(FileIO.load(Makie.assetpath("cow.png"))))
scatter!(ax, 1:10,fill(10, 10), markersize = 40, color = :red)
scatter!(ax, 1:10, fill(9, 10), markersize = 40, color = (:red, 0.5))
scatter!(ax, 1:10, fill(8, 10), markersize = 40, color = RGBf(0.8, 0.6, 0.1))
scatter!(ax, 1:10, fill(7, 10), markersize = 40, color = RGBAf(0.8, 0.6, 0.1, 0.5))

# colormap
scatter!(ax, 1:10, fill(5, 10), markersize = 40, color = 1:10, colormap = :viridis)
scatter!(ax, 1:10, fill(4, 10), markersize = 40, color = 1:10, colormap = (:viridis, 0.5),)
scatter!(ax, 1:10, fill(3, 10), markersize = 40, color = 1:10, colormap = [:red, :orange],)
scatter!(ax, 1:10, fill(2, 10), markersize = 40, color = 1:10, colormap = [(:red, 0.5), (:orange, 0.5)])
cm = [RGBf(x^2, 1 - x^2, 0.2) for x in range(0, 1, length=100)]
scatter!(ax, 1:10, fill(1, 10), markersize = 40, color = 1:10, colormap = cm)
cm = [RGBAf(x^2, 1 - x^2, 0.2, 0.5) for x in range(0, 1, length=100)]
scatter!(ax, 1:10, fill(0, 10), markersize = 40, color = 1:10, colormap = cm)
fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_19ce3adb_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_19ce3adb.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide