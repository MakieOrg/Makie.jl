# Aspect ratio and size control tutorial

A very common problem in plotting is dealing with aspect ratios and other ways to precisely control figures.

For example, many plots need square axes.
If you have looked at the documentation of `Axis`, you might know that it has an `aspect` attribute that can control the aspect ratio of the axis box.
This aspect is not concerned with what the data limits are, it's just about the relative visual length of the axes.

Let's look at one common example, a square axis with a colorbar next to it:


\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide

set_theme!(backgroundcolor = :gray90)

f = Figure(resolution = (800, 500))
ax = Axis(f[1, 1], aspect = 1)
Colorbar(f[1, 2])
f
```
\end{examplefigure}


As you can see, the axis is square, but there's also a large gap between it and the colorbar.
Why is that?

We can visualize the reason by adding a Box to the same cell where the axis is:


\begin{examplefigure}{svg = true, name = "aspect_tutorial_example"}
```julia
Box(f[1, 1], color = (:red, 0.2), strokewidth = 0)
f
```
\end{examplefigure}


The red area of the box extends out into the whitespace left by the Axis.
This demonstrates what the `aspect` keyword is actually doing.
It reduces the size of the Axis, such that the chosen aspect ratio is achieved.
It doesn't tell the layout that the Axis lives in "please make this cell adhere to this aspect ratio".
As far as the layout is concerned, the Axis has an undefined size and its layout cell can therefore have any size that the layout deems correct, based on all other content of the layout and the figure size.

Therefore, using `aspect` will always cause gaps, unless the layout cell where the Axis lives happens to have exactly the correct aspect ratio by chance.
This means `aspect` should only be used if the whitespace caused by it does not matter too much.

For all other cases, there is a different approach.

We want to force the layout to keep the axis cell at a specific aspect ratio.
Therefore, we have to manipulate the layout itself, not the axis.

By default, each GridLayout row and column has a size of `Auto()`.
This means that the size can depend on fixed-size content if there is any, otherwise it expands to fill the available space.
If we want to force a cell to have an aspect ratio, we need to set either its respective row or column size to `Aspect`.

Let's try the example from above again, but this time we force the column of the Axis to have an aspect ratio of 1.0 relative to the row of the Axis, which is row 1.


\begin{examplefigure}{svg = true}
```julia
f = Figure(resolution = (800, 500))
ax = Axis(f[1, 1])
Colorbar(f[1, 2])
colsize!(f.layout, 1, Aspect(1, 1.0))
f
```
\end{examplefigure}


As you can see, this time the colorbar sticks close to the axis, there is no unnecessary whitespace between them.
We can visualize the effect of `Aspect` again with a red box, that shows us the extent of the layout cell:


\begin{examplefigure}{svg = true}
```julia
# hide
Box(f[1, 1], color = (:red, 0.2), strokewidth = 0)
f
```
\end{examplefigure}


So this time the layout cell itself is square, therefore the Axis that fills it is also square.
Let me just demonstrate that we can play the same game again and give the Axis an `aspect` that is different from the square one that the layout cell has.
This will again cause unnecessary whitespace:


\begin{examplefigure}{svg = true}
```julia
ax.aspect = 0.5
f
```
\end{examplefigure}


And now we change the column aspect again, to remove this gap:


\begin{examplefigure}{svg = true}
```julia
colsize!(f.layout, 1, Aspect(1, 0.5))
f
```
\end{examplefigure}


Let's return to our previous state with a square axis:


\begin{examplefigure}{svg = true}
```julia
# hide
f = Figure(resolution = (800, 500))
ax = Axis(f[1, 1])
Colorbar(f[1, 2])
colsize!(f.layout, 1, Aspect(1, 1.0))
f
```
\end{examplefigure}


Now you might think that there is no whitespace anymore between Axis and Colorbar, but there is a lot of it to the left and the right.
Why can the layout not fix this problem for us?

Well, in Makie, the layout has to operate within the confines of the figure size that we have set.
It cannot just decrease the figure size if there's too little content.
This is because lots of times, figures are created to fit the sizing rules of some academic journal exactly, therefore the content you plot is not allowed to mess with the figure size.

So what we have done in our example is introducing constraints to the sizes of objects in our layout, such that it's impossible to fill all the space that is theoretically available.
If you think about it, it's impossible to fill this Figure with a square axis and a thin colorbar while filling the rectangular space.
We need a smaller figure!

But how small should it be exactly?
It would be quite difficult to eyeball this, but thankfully there's a function for this exact purpose.
By calling `resize_to_layout!`, we can adjust the figure size to the size that the layout needs for all its content.

Let's try it out:


\begin{examplefigure}{svg = true}
```julia
resize_to_layout!(f)
f
```
\end{examplefigure}


As you can see, the whitespace at the sides has been trimmed.
(If the scaling looks smaller or bigger, that is just because of the display on this site, not the underlying figure size).

This technique is useful for all kinds of situations where the content should decide the figure size, and not the other way around.

## Example: Facet plot

For example, let's say we have a facet plot with 25 square axes which are all of size 150 by 150.
We can just make these axes with fixed widths and heights.
The `Auto` sized columns and rows of the default layout pick up these measurements and adjust themselves accordingly.

Of course, the figure size will by default not be appropriate for such an arrangement, and the content will clip:


\begin{examplefigure}{svg = true}
```julia
f = Figure()
for i in 1:5, j in 1:5
    Axis(f[i, j], width = 150, height = 150)
end
f
```
\end{examplefigure}


But like before we can call `resize_to_layout!` and the size will be corrected so no clipping occurs.


\begin{examplefigure}{svg = true}
```julia
set_theme!() # hide
resize_to_layout!(f)
f
```
\end{examplefigure}

## Example: Marginal histogram


Marginal histograms compare two variables. The main plot is a 2D histogram, where
each rectangle represents a count of data points within its area.  Above the main
plot is a smaller histogram of the first variable, and to the right of the main
plot is a histogram of the second variable.

We begin by initializing a figure and an internal GridLayout to keep the marginal
histogram contained.  Then, we create the axes, and set the appropriate sizes for the columns.

\begin{examplefigure}{svg = true}
```julia
fig = Figure(resolution = (1000, 1000), backgroundcolor = RGBf(0.98, 0.98, 0.98))
histogram_gl = fig[1, 1] = GridLayout()

central_axis = Axis(histogram_gl[1, 1])

top_axis = Axis(histogram_gl[0, 1])
right_axis = Axis(histogram_gl[1, 2])

# Now we set the column and row sizes:
marginal_plot_width = 0.2
colsize!(histogram_gl, 2, Relative(marginal_plot_width))
rowsize!(histogram_gl, 0, Relative(marginal_plot_width))

fig
```
\end{examplefigure}

Now, we can remove the decorations and force the axes to be flush against each other:

\begin{examplefigure}{svg = true}
```julia
top_axis.xtickalign = 1
top_axis.ytickalign = 1
hidedecorations!(top_axis; grid = false, minorgrid = false, ticks = false)
top_axis.yticklabelsvisible = true

right_axis.xtickalign = 1
right_axis.ytickalign = 1
hidedecorations!(right_axis; grid = false, minorgrid = false, ticks = false)
right_axis.xticklabelsvisible = true

colgap!(histogram_gl, 1, 0)
rowgap!(histogram_gl, 1, 0)
fig
```
\end{examplefigure}

Finally, we plot to it:

\begin{examplefigure}{svg = true}
```julia
import Makie.StatsBase

x_data = randn(500)
y_data = randn(500)

nbins = 30

central_heatmap = plot!(central_axis, StatsBase.fit(StatsBase.Histogram, (x_data, y_data); nbins = nbins); interpolate = false)

# We use Makie's hist recipe for the rest:
top_hist   = hist!(top_axis, x_data; nbins = nbins, strokewidth = 1, strokecolor = (:black, 0.6))
right_hist = hist!(right_axis, y_data; nbins = nbins, direction = :x, strokewidth = 1, strokecolor = (:black, 0.6))

fig
```
\end{examplefigure}
