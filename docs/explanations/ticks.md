# Ticks

Ticks are the indicators of value on an axis, and are present on the spines of the axis.  In Makie, ticks are also associated with the grid lines, and give them position.

Makie offers multiple tick finders, and an interface to implement your own.

The tick itself is just a position; the text beneath it, which indicates value, is called a `ticklabel`.  You will be familiar with this through the `ax.[x/y]ticklabel*` attributes for axes.

A _tick finder_ finds ticks given a minimum and maximum value, usually those in a pleasing dimension.  Any tick finder `MyTickFinder` must implement the function `Makie.get_tickvalues(ticks::MyTickFinder, vmin::Real, vmax::Real)`.

## Pre-existing tick finders

The default 

{{doc LinearTicks}}
{{doc WilkinsonTicks}}
{{doc MultiplesTicks}}

Note that `WilkinsonTicks` are the tick finder of choice for most plotting libraries.


\begin{examplefigure}{svg}
fig = Figure()
axes = [Axis(fig[i, j]) for i in 1:2, j in 1:3]
hideydecorations!.(axes)
scatter!.(axes, (rand(100) .* 100, ), (rand(100) .* 100,))
axes[1, 1].title = "Default LinearTicks"
axes[1, 2].title = "WilkinsonTicks"
axes[1, 2].xticks = WilkinsonTicks(7; k_min = 4) # change parameters as you wish
axes[1, 3].title = "MultiplesTicks"
axes[1, 3].xticks = MultiplesTicks(5, pi, "π") # this can be any number
axes[2, 1].title = "Log-scale LinearTicks"
axes[2, 1].xscale = log10
axes[2, 2].title = "Log-scale LogTicks (default)"
axes[2, 2].xscale = log10
axes[2, 2].xticks = LogTicks(WilkinsonTicks(7; k_min = 4)) # wrap any tick finder here
axes[2, 3].title = "Manual ticks"
axes[2, 3].xticks = [5, 15, 35, 64] # place any specific ticks you like!
fig
\end{examplefigure}

## Tick labels

Tick labels are tunable by the `ticklabel` attributes, and the `tickformat` attribute as well, which affect only the text.
