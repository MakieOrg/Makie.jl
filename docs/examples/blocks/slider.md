

# Slider

A simple slider without a label. You can create a label using a `Label` object,
for example. You need to specify a range that constrains the slider's possible values.

The currently selected value is in the attribute `value`.
Don't change this value manually, but use the function `set_close_to!(slider, value)`.
This is necessary to ensure the value is actually present in the `range` attribute.

If the slider value is used for a relatively slow task, it may be more effective to
use the attribute `value_dragstop` instead of `value`.  The `value_dragstop` is only
updated when the mouse is released to conclude the slider drag operation.  It is 
is synchronized with `value` when calling `set_cloe_to!(slider, value)` or one a mouse
click or double click event.

You can double-click the slider to reset it (approximately) to the value present in `startvalue`.

If you set the attribute `snap = false`, the slider will move continously while dragging and only jump to the closest available value when releasing the mouse.

\begin{examplefigure}{}
```julia
using GLMakie
GLMakie.activate!() # hide
fig = Figure()

ax = Axis(fig[1, 1])

sl_x = Slider(fig[2, 1], range = 0:0.01:10, startvalue = 3)
sl_y = Slider(fig[1, 2], range = 0:0.01:10, horizontal = false, startvalue = 6)

point = lift(sl_x.value, sl_y.value) do x, y
    Point2f(x, y)
end

scatter!(point, color = :red, markersize = 20)

limits!(ax, 0, 10, 0, 10)

fig
```
\end{examplefigure}


This slightly more complicated example compares the behavior of the `value`
and `value_dragstop` slide attributes.

\begin{examplefigure}{}
```julia
using GLMakie
GLMakie.activate!() # hide
fig = Figure()

ax = Axis(fig[1, 1])

sl_x = Slider(fig[2, 1], range = 0:0.5:10, startvalue = 3)
sl_y = Slider(fig[1, 2], range = 0:0.5:10, horizontal = false, startvalue = 6)

x_text = lift(sl_x.value) do x
   "x slider value=$(x)"
end
x_text_stop = lift(sl_x.value_dragstop) do x
   "mouse release x slider value=$(x)"
end
y_text = lift(sl_y.value) do y
    "y slider value=$(y)"
end
y_text_stop = lift(sl_y.value_dragstop) do y
   "mouse release y slider value=$(y)"
end

point = lift(sl_x.value, sl_y.value) do x, y
    Point2f(x, y)
end

scatter!(point, color = :red, markersize = 20)
text!(2.5,9.5, text = x_text, align = (:center, :center))
text!(2.5,9.0, text = x_text_stop, align = (:center, :center))
text!(7.5,9.5, text = y_text, align = (:center, :center))
text!(7.5,9.0, text = y_text_stop, align = (:center, :center))

limits!(ax, 0, 10, 0, 10)

fig
```
\end{examplefigure}


## Labelled sliders and grids

The functions \apilink{labelslider!} and \apilink{labelslidergrid!} are deprecated, use \apilink{SliderGrid} instead.
