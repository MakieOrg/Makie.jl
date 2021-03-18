# text

```@docs
text
```

### Examples

```@example
using GLMakie
GLMakie.activate!() # hide
AbstractPlotting.inline!(true) # hide

scene = Scene(camera = campixel!, show_axis = false, resolution = (600, 600))

text!(scene, "AbstractPlotting", position = Point2f0(300, 500),
    textsize = 30, align = (:left, :bottom), show_axis = false)
text!(scene, "AbstractPlotting", position = Point2f0(300, 400),
    color = :red, textsize = 30, align = (:right, :center), show_axis = false)
text!(scene, "AbstractPlotting\nMakie", position = Point2f0(300, 300),
    color = :blue, textsize = 30, align = (:center, :center), show_axis = false)
text!(scene, "AbstractPlotting\nMakie", position = Point2f0(300, 200),
    color = :green, textsize = 30, align = (:center, :top), rotation = pi/4, show_axis = false)

scene
```

