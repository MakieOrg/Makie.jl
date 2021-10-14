

# Label

This is just normal text, except it's also block. A text's size is known,
so rows and columns in a GridLayout can shrink to the appropriate width or height.

\begin{examplefigure}{}
```julia
using CairoMakie

fig = Figure()

fig[1:2, 1:3] = [Axis(fig) for _ in 1:6]

supertitle = Label(fig[0, :], "Six plots", textsize = 30)

sideinfo = Label(fig[2:3, 0], "This text is vertical", rotation = pi/2)

fig
```
\end{examplefigure}