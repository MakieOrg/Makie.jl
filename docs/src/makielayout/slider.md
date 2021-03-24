```@eval
using CairoMakie
CairoMakie.activate!()
```

# Slider

A simple slider without a label. You can create a label using a `Label` object,
for example. You need to specify a range that constrains the slider's possible values.
You can then lift the `value` observable to make interactive plots.

```@example
using CairoMakie

fig = Figure(resolution = (1200, 900))

ax = Axis(fig[1, 1])

sl_x = Slider(fig[2, 1], range = 0:0.01:10, startvalue = 3)
sl_y = Slider(fig[1, 2], range = 0:0.01:10, horizontal = false,
    startvalue = 6,
    tellwidth = true, height = nothing, width = Auto())

point = @lift(Point2f0($(sl_x.value), $(sl_y.value)))

scatter!(point, color = :red, markersize = 20)

limits!(ax, 0, 10, 0, 10)

fig
```

To create a horizontal layout containing a label, a slider, and a value label, use the convenience function [`AbstractPlotting.MakieLayout.labelslider!`](@ref), or, if you need multiple aligned rows of sliders, use [`AbstractPlotting.MakieLayout.labelslidergrid!`](@ref).

```@example
using CairoMakie
fig = Figure(resolution = (1200, 900))

ax = Axis(fig[1, 1])

lsgrid = labelslidergrid!(
    fig,
    ["Voltage", "Current", "Resistance"],
    [0:0.1:10, 0:0.1:20, 0:0.1:30];
    formats = [x -> "$(round(x, digits = 1))$s" for s in ["V", "A", "Ω"]],
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
```

If you want to programmatically move the slider, use the function [`AbstractPlotting.MakieLayout.set_close_to!`](@ref).
Don't manipulate the `value` attribute directly, as there is no guarantee that
this value exists in the range underlying the slider, and the slider's displayed value would
not change anyway by changing the slider's output.

