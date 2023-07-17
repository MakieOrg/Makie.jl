# SliderGrid

{{doc SliderGrid}}

The column with the value labels is automatically set to a fixed width, so that the layout doesn't jitter when sliders are dragged and the value labels change their widths.
This width is chosen by setting each slider to a few values and recording the maximum label width.
Alternatively, you can set the width manually with attribute `value_column_width`.

\begin{examplefigure}{}
```julia
using GLMakie

fig = Figure()

ax = Axis(fig[1, 1])

sg = SliderGrid(
    fig[1, 2],
    (label = "Voltage", range = 0:0.1:10, format = "{:.1f}V", startvalue = 5.3),
    (label = "Current", range = 0:0.1:20, format = "{:.1f}A", startvalue = 10.2),
    (label = "Resistance", range = 0:0.1:30, format = "{:.1f}Ω", startvalue = 15.9),
    width = 350,
    tellheight = false)

sliderobservables = [s.value for s in sg.sliders]
bars = lift(sliderobservables...) do slvalues...
    [slvalues...]
end

barplot!(ax, bars, color = [:yellow, :orange, :red])
ylims!(ax, 0, 30)

fig
```
\end{examplefigure}


## Attributes

\attrdocs{SliderGrid}