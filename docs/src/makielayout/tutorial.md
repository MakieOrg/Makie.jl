```@eval
using CairoMakie
CairoMakie.activate!()
```

# MakieLayout Tutorial

In this tutorial, we will see some of the capabilities of MakieLayout.jl while
building a complex figure step by step. This is the final result we will create:

![step_22](step_22.svg)

All right, let's get started!

## Scene and Layout

First, we import the necessary packages and then create the main scene and layout.
The function `layoutscene` is a convenience function that creates a `Scene`
which has a `GridLayout` attached to it that always fills the whole scene area.
You can pass the outer padding of the top layout as the first argument.

```@example tutorial
using AbstractPlotting.MakieLayout
using Random # hide
using AbstractPlotting
Random.seed!(2) # hide

outer_padding = 30
scene, layout = layoutscene(outer_padding, resolution = (1200, 700),
    backgroundcolor = RGBf0(0.98, 0.98, 0.98))

save("step_001.svg", scene) # hide
nothing # hide
```
![step_001](step_001.svg)

## First LAxis

The scene is completely empty, I have made the background light gray so it's easier
to see. Now we add an LAxis. This is an axis or subplot type that MakieLayout defines
which knows how to behave in a layout (which the Makie version doesn't).

We create the axis and place it into the layout in one go. You place objects in
a layout by using indexing syntax. You can save the axis in a variable by chaining
the `=` expressions.

We call the axis title "Pre Treatment" because we're going to plot some made up measurements,
like they could result from an experimental trial.

```@example tutorial
ax1 = layout[1, 1] = LAxis(scene, title = "Pre Treatment")

save("step_002.svg", scene) # hide
nothing # hide
```
![step_002](step_002.svg)

## Plotting into an LAxis

We can plot into the axis with the ! versions of Makie's plotting functions.
Contrary to Makie, these calls return the plot objects, not the Scene or LAxis,
so it's easier to save them.

```@example tutorial
data1 = randn(50, 2) * [1 2.5; 2.5 1] .+ [10 10]

line1 = lines!(ax1, 5..15, x -> x, color = :red, linewidth = 2)
scat1 = scatter!(ax1, data1,
    color = (:red, 0.3), markersize = 15px, marker = '■')

save("step_003.svg", scene) # hide
nothing # hide
```
![step_003](step_003.svg)

## Multiple Axes

This looks nice already, but we want another axis with a second dataset, to
the right of the one we have. Currently our layout has one row and one cell, and
only one LAxis inside of it:

```@example tutorial
layout
```

We can extend the grid by indexing into new grid cells. Let's place a new axis
next to the one we have, in row 1 and column 2.

```@example tutorial
ax2 = layout[1, 2] = LAxis(scene, title = "Post Treatment")

save("step_004.svg", scene) # hide
nothing # hide
```
![step_004](step_004.svg)

As you can see, the first axis has shrunk to the left to make space for the new
axis on the right. We can take another look at the `layout` to see how it has
changed:

```@example tutorial
layout
```

Let's plot into the new axis, the same way we did the scatter plots before.


```@example tutorial
data2 = randn(50, 2) * [1 -2.5; -2.5 1] .+ [13 13]

line2 = lines!(ax2, 7..17, x -> -x + 26, color = :blue, linewidth = 2)
scat2 = scatter!(ax2, data2,
    color = (:blue, 0.3), markersize = 15px, marker = '▲')


save("step_005.svg", scene) # hide
nothing # hide
```
![step_005](step_005.svg)


## Linking Axes

We want to make the left and right axes correspond to each other, so we can compare
the plots more easily. To do that, we link both x and y axes. That will keep them
synchronized.

```@example tutorial
linkaxes!(ax1, ax2)

save("step_006.svg", scene) # hide
nothing # hide
```
![step_006](step_006.svg)


This looks good, but now both y-axes are the same, so we can hide the right one
to make the plot less cluttered. We keep the grid lines, though. You can see that
now that the y-axis is gone, the two LAxes grow to fill the gap.

```@example tutorial
hideydecorations!(ax2, grid = false)

save("step_007.svg", scene) # hide
nothing # hide
```
![step_007](step_007.svg)


Even though our plots are entirely made up, we should follow best practice and label
the axes. We can do this with the `xlabel` and `ylabel` attributes of the `LAxis`.

```@example tutorial
ax1.xlabel = "Weight [kg]"
ax2.xlabel = "Weight [kg]"
ax1.ylabel = "Maximum Velocity [m/sec]"

save("step_007_2.svg", scene) # hide
nothing # hide
```
![step_007 2](step_007_2.svg)

## Adding a Legend

Let's add a legend to our plot that describes elements from both axes. We use
LLegend for that. LLegend is a relatively complex object and there are many
ways to create it, but here we'll keep it simple. We place the legend on the
right again, in row 1 and column 3. Instead of specifying column three, we can
also say `end+1`.

```@example tutorial
leg = layout[1, end+1] = LLegend(scene,
    [line1, scat1, line2, scat2],
    ["f(x) = x", "Data", "f(x) = -x + 26", "Data"])

save("step_008.svg", scene) # hide
nothing # hide
```
![step_008](step_008.svg)

You can see one nice feature of MakieLayout here, which is that the legend takes
much less horizontal space than the two axes. In fact, it takes exactly the space
that it needs. This is possible because objects in MakieLayout can tell their width
or height to their parent `GridLayout`, which can then shrink the row or column
appropriately.

One thing that could be better about this plot, is that the legend looks like
it belongs only to the right axis, even though it describes elements from both
axes. So let's move it in the middle below the two. This is easily possible in
MakieLayout, without having to recreate the plot from scratch. We simply assign
the legend to its new slot.

We want it in the second row, and spanning the first two columns.

```@example tutorial
layout[2, 1:2] = leg

save("step_009.svg", scene) # hide
nothing # hide
```
![step_009](step_009.svg)


## Fixing Spacing Issues

There are a couple of things wrong with this. The legend is where we want it, below the
two axes. But it takes too much space vertically, and there is a large gap on the right.

Let's deal with the gap on the right first. It's the hole that was left by the
legend, and it's even bigger now because it gets an equal share of space with the
two axes, now that there is no legend shrinking the column width to its own size.

We can remove empty cells in a layout by calling `trim!` on it:

```@example tutorial
trim!(layout)

save("step_010.svg", scene) # hide
nothing # hide
```
![step_010](step_010.svg)

This is much better already! But the legend still takes too much space vertically.
The reason for that is the default `tellheight` setting of the legend. It's set to
`false`, which essentially means that it can compute its own height, but
doesn't tell the layout about it. This makes sense for the most common situation
where the legend sits on the right of an axis. We wouldn't want the axis to shrink
to the height of the legend. But now that the legend has its own row, we do want
this behavior. So we set the `tellheight` attribute to `true`.


```@example tutorial
leg.tellheight = true

save("step_011.svg", scene) # hide
nothing # hide
```
![step_011](step_011.svg)


Now the legend's row is shrunk to fit. One thing that we can do to improve the
use of space is to change the legend's orientation to `:horizontal`.

```@example tutorial
leg.orientation = :horizontal

save("step_012.svg", scene) # hide
nothing # hide
```
![step_012](step_012.svg)


## Sublayouts

Let's add two new axes with heatmaps! We want them stacked on top of each other
on the right side of the figure. We'll do the naive thing first, which is to
place them in the first and second row of the third column. There are multiple
versions of layout assignment syntax for convenience. Here, we create and assign
two axes at once. The number of cells and objects has to match to do this.

```@example tutorial
hm_axes = layout[1:2, 3] = [LAxis(scene, title = t) for t in ["Cell Assembly Pre", "Cell Assembly Post"]]

heatmaps = [heatmap!(ax, i .+ rand(20, 20)) for (i, ax) in enumerate(hm_axes)]

save("step_013.svg", scene) # hide
nothing # hide
```
![step_013](step_013.svg)


This looks weird, the two axes do not have the same height. Rather, the lower
one has the height of the legend in the same row. What can we do to remedy this
situation?

We have to recognize that what we want is not possible with one layout. We don't care
about the heatmap axes being the same height as the other two axes and the legend,
respectively. We only care that the top and the bottom of the two groups are aligned.

There is usually more than one solution for any given layout problem. In other
plotting software, people sometimes circumvent our current issue by dividing the layout
into many more cells than there are content objects, and have the content span several rows or
columns. For example the left axes span rows 1:10, the legend 10:12, while the
heatmap axes span rows 1:6 and 7:12, respectively.
This is complicated, not very flexible, and luckily unnecessary in MakieLayout.

We will instead help ourselves by using a nested `GridLayout`, just for the two
heatmap axes. We move the axes into it by assigning them to their new slots.
The detaching from the main layout happens automatically.

```@example tutorial
hm_sublayout = GridLayout()
layout[1:2, 3] = hm_sublayout

# there is another shortcut for filling a GridLayout vertically with
# a vector of content
hm_sublayout[:v] = hm_axes

save("step_014.svg", scene) # hide
nothing # hide
```
![step_014](step_014.svg)

We don't care about the axis decorations, as it's often the case with image plots.
The function `hidedecorations!` hides both x and y decorations at once.
Also, the default autolimits are computed with a small margin, which doesn't look
good in our case. We can set the autolimit margins to zero using `tightlimits!`.


```@example tutorial

tightlimits!.(hm_axes)
hidedecorations!.(hm_axes)

save("step_015.svg", scene) # hide
nothing # hide
```
![step_015](step_015.svg)


## Adding a Colorbar

Now, we also want to add a color bar for the two heatmaps. Right now, their colors
are independently scaled from each other. We choose a scale that makes sense for
both of them (in our case, we know data ranges only from 1 to 3) and assign that
to both heatmaps. Then we create an `LColorbar` object with one of the heatmaps.
This way, the color bar copies color range and color map from that heatmap.

We want to place the color bar to the right of the heatmaps, spanning the full
height. We could either place it within the sublayout we just created, or in the
main layout. Both versions can be made to look the same, but we'll choose the
sublayout, because that is a more meaningful grouping, and we could move the whole
assembly around later by moving only the sublayout.

We can place an object along all existing rows or columns using the `:` notation.

```@example tutorial
for hm in heatmaps
    hm.colorrange = (1, 3)
end

cbar = hm_sublayout[:, 2] = LColorbar(scene, heatmaps[1], label = "Activity [spikes/sec]")

save("step_016.svg", scene) # hide
nothing # hide
```
![step_016](step_016.svg)


The color bar is quite chunky because it takes 50% of the available width in the
sublayout. Let's give it a fixed width of 30 units.


```@example tutorial
cbar.width = 30

save("step_017.svg", scene) # hide
nothing # hide
```
![step_017](step_017.svg)


Much better! Note that you can usually set all attributes during creation of an object
(`LColorbar(scene, width = 30)`) or after the fact, like in this example.

Objects can also have a width or height relative to the space given to them by their
parent `GridLayout`. If we feel that the colorbar is a bit too tall, we can shrink it
to two thirds of the available height using `Relative(2/3)`.

If you only specify a number like `30`, it is interpreted as `Fixed(30)`.


```@example tutorial
cbar.height = Relative(2/3)

save("step_18.svg", scene) # hide
nothing # hide
```
![step_18](step_18.svg)


We don't really like the automatically chosen tick values here. Sometimes, the automatic
algorithms just don't choose the values we want, so let's change them.
We can set the `ticks` attribute to any iterable of numbers that we want.

```@example tutorial
cbar.ticks = 1:0.5:3

save("step_18b.svg", scene) # hide
nothing # hide
```
![step_18b](step_18b.svg)


## Adding a Title

Now the plot could use a title! While other plotting packages sometimes have
functions like `supertitle`, they often don't work quite right or force you to
make manual adjustments. In MakieLayout, the `LText` object is much more flexible
as it allows you to place text anywhere you want. We therefore create our super
title not with a dedicated function but as a simple part of the whole layout.

How can we place content in a row above row 1? This is easy in MakieLayout, as
indexing outside of the current GridLayout cells works not only with higher numbers
but also with lower numbers. Therefore, we can index into the zero-th row, which
will create a new row and push all other content down.

Note that after this, all the cell indices of our current content will have changed
to reflect the new GridLayout size.


```@example tutorial
supertitle = layout[0, :] = LText(scene, "Plotting with MakieLayout",
    textsize = 30, font = "Noto Sans Bold", color = (:black, 0.25))

save("step_19.svg", scene) # hide
nothing # hide
```
![step_19](step_19.svg)


## Subplot Labels

In figures meant for publication, you often need to label subplots with letters
or numbers. These can sometimes cause trouble because they overlap with other
content, which has to be fixed after the fact in vector graphics software.

This is not necessary in MakieLayout. Let's place letters in the upper left corners
of the left group and the right group. To do that, we will make use of a property
of layouts that we have used without mentioning it. When we place our letters, we
want them to act similarly to the axis titles or labels. In MakieLayout, layoutable
objects have an inner part, which is considered the "important" area that should
align with other "important" inner areas. You can see that the three upper axes
align with their top spines, and not their titles.

All that is outside of the main area is part of the "protrusions". These help keeping
the logic of the layout simple while allowing to easily align what is supposed to
be aligned.

So for our corner letters, we don't want to create new columns or rows. Doing that
would probably cause alignment issues in most cases. Instead, we place these objects
*inside* the protrusions of existing cells. That means they are part of the gaps
between columns and rows, which is fitting for our labels.

We can do this by specifying the `Side` as a third argument when indexing the layout.
The default we have used so far is `Inside()`. For us, `TopLeft()` is the correct
choice. (Remember that our previously first row is now the second row, due to the
super title.)

```@example tutorial
label_a = layout[2, 1, TopLeft()] = LText(scene, "A", textsize = 35,
    font = "Noto Sans Bold", halign = :right)
label_b = layout[2, 3, TopLeft()] = LText(scene, "B", textsize = 35,
    font = "Noto Sans Bold", halign = :right)

save("step_20.svg", scene) # hide
nothing # hide
```
![step_20](step_20.svg)

That looks good! You can see that the letters, larger than the axis titles, have
increased the gap between the title and the axes to fit them. In most other
plotting software, you can easily get overlap issues when you add labels like these between other elements.

We still want to give the labels a bit of padding at the bottom and the right,
so they are not too close to the axes. The order of the padding values
is (left, right, bottom, top).

```@example tutorial
label_a.padding = (0, 6, 16, 0)
label_b.padding = (0, 6, 16, 0)

save("step_21.svg", scene) # hide
nothing # hide
```
![step_21](step_21.svg)

## Tweaking aspect ratios

One last thing we could improve is the shape of the heatmaps. We have square heatmaps in terms of data ratios,
but they are a bit rectangular in the plot. In order to correctly make them square and have the rest of the layout
adapt correctly, we don't just set the aspect ratio of each heatmap axis to 1. This would be possible,
but would leave gaps where the assigned space which is still rectangular isn't used.

Instead, we will tell the layout, that we want the column in which both heatmaps are should be at an aspect ratio of
1 with the first row. As both rows are at Auto size, they will both be square afterwards, and the layout will still be tight
because the left two axes will grow to fill the remaining space.

```@example tutorial
# Aspect(1, 1) means that relative to row 1
# (row because we're setting a colsize,
# and aspect ratios are always about the other side)
# we set the column to an aspect ratio of 1

colsize!(hm_sublayout, 1, Aspect(1, 1))

save("step_22.svg", scene) # hide
nothing # hide
```
![step_22](step_22.svg)

And there we have it! Hopefully this tutorial has given you an overview how to
approach the creation of a complex figure in MakieLayout. Check the rest of the
documentation for more details and other dynamic parts like sliders and buttons!

```@eval
using GLMakie
GLMakie.activate!()
```