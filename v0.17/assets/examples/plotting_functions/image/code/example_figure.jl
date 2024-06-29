# This file was generated, do not modify it. # hide
__result = begin # hide
    using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide
using FileIO

img = load(assetpath("cow.png"))

f = Figure()

image(f[1, 1], img,
    axis = (title = "Default",))

image(f[1, 2], img,
    axis = (aspect = DataAspect(), title = "DataAspect()",))

image(f[2, 1], rotr90(img),
    axis = (aspect = DataAspect(), title = "rotr90",))

image(f[2, 2], img',
    axis = (aspect = DataAspect(), yreversed = true,
        title = "img' and reverse y-axis",))

f
end # hide
save(joinpath(@OUTPUT, "example_3614004436634172483.png"), __result; ) # hide

nothing # hide