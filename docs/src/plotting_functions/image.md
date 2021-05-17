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

f = Figure()
Axis(f[1, 1], aspect = DataAspect())

image!(img)

f
```
