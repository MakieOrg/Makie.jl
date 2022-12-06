

# Label

A Label is text within a rectangular boundingbox.
The `halign` and `valign` attributes always refer to unrotated horizontal and vertical.
This is different from `text`, where alignment is relative to text flow direction.

A Label's size is known, so if `tellwidth` and `tellheight` are set to `true` (the default values) a GridLayout with `Auto` column or row sizes can shrink to fit.

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide

fig = Figure()

fig[1:2, 1:3] = [Axis(fig) for _ in 1:6]

supertitle = Label(fig[0, :], "Six plots", fontsize = 30)

sideinfo = Label(fig[2:3, 0], "This text is vertical", rotation = pi/2)

fig
```
\end{examplefigure}

Justification and lineheight of a label can be controlled just like with normal text.

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide

f = Figure()

Label(f[1, 1],
    "Left Justified\nMultiline\nLabel\nLineheight 0.9",
    justification = :left,
    lineheight = 0.9
)
Label(f[1, 2],
    "Center Justified\nMultiline\nLabel\nLineheight 1.1",
    justification = :center,
    lineheight = 1.1
)
Label(f[1, 3],
    "Right Justified\nMultiline\nLabel\nLineheight 1.3",
    justification = :right,
    lineheight = 1.3
)

f
```
\end{examplefigure}