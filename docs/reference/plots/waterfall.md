# waterfall

{{doc waterfall}}

### Examples

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide

y = [6, 4, 2, -8, 3, 5, 1, -2, -3, 7]

waterfall(y)
```
\end{examplefigure}

The direction of the bars might be easier to parse with some visual support.

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide

y = [6, 4, 2, -8, 3, 5, 1, -2, -3, 7]

waterfall(y, show_direction=true)
```
\end{examplefigure}

You can customize the markers that indicate the bar directions.

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide

y = [6, 4, 2, -8, 3, 5, 1, -2, -3, 7]

waterfall(y, show_direction=true, marker_pos=:cross, marker_neg=:hline, direction_color=:gold)
```
\end{examplefigure}

If the `dodge` attribute is provided, bars are stacked by `dodge`.

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
colors = Makie.wong_colors()

x = repeat(1:2, inner=5)
y = [6, 4, 2, -8, 3, 5, 1, -2, -3, 7]
group = repeat(1:5, outer=2)

waterfall(x, y, dodge=group, color=colors[group])
```
\end{examplefigure}

It can be easier to compare final results of different groups if they are shown in the background.

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
colors = Makie.wong_colors()

x = repeat(1:2, inner=5)
y = [6, 4, 2, -8, 3, 5, 1, -2, -3, 7]
group = repeat(1:5, outer=2)

waterfall(x, y, dodge=group, color=colors[group], show_direction=true, show_final=true)
```
\end{examplefigure}

The color of the final bars in the background can be modified.

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
colors = Makie.wong_colors()

x = repeat(1:2, inner=5)
y = [6, 4, 2, -8, 3, 5, 1, -2, -3, 7]
group = repeat(1:5, outer=2)

waterfall(x, y, dodge=group, color=colors[group], show_final=true, final_color=(colors[6], 1//3))
```
\end{examplefigure}

You can also specify to stack grouped waterfall plots by `x`.

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
colors = Makie.wong_colors()

x = repeat(1:5, outer=2)
y = [6, 4, 2, -8, 3, 5, 1, -2, -3, 7]
group = repeat(1:2, inner=5)

waterfall(x, y, dodge=group, color=colors[group], show_direction=true, stack=:x)
```
\end{examplefigure}
