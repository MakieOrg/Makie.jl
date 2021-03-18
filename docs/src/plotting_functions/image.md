# image

```@docs
image
```

### Examples

```@example
using CairoMakie
CairoMakie.activate!() # hide
AbstractPlotting.inline!(true) # hide
using FileIO

img = rotr90(load("../assets/cow.png"))

f = Figure(resolution = (800, 600))
Axis(f[1, 1], aspect = DataAspect())

image!(img)

f
save("example_image_1.svg", f); nothing # hide
```

![example_image_1](example_image_1.svg)


