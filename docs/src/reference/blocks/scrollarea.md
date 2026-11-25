# ScrollArea

A `ScrollArea` is a clipped, scrollable region with its own `Scene` and
`GridLayout` — the same shape as a `Figure`, scoped to a sub-region. It is the
building block for "make this content scrollable": put content into a
`ScrollArea`, and it clips to its bounds and scrolls when the content overflows.

Because a `ScrollArea` is an ordinary `Block`, it drops into **any** layout slot
— a figure cell, a [`Modal`](@ref), a [`Tabs`](@ref) tab, or nested inside
another `ScrollArea`. Scrollbars appear only on overflow, so you rarely have to
think about it; `scrollable = false` turns it into a plain clipped panel (no
scrollbars, no scroll input), which is how `Modal`/`Tabs` host their content.

## A scrollable form

Content size is derived from the inner `GridLayout`'s determinable size, so
giving rows a `Fixed` height makes a long form overflow and scroll:

```@figure backend=GLMakie
using GLMakie
import Makie.GridLayoutBase as GLB
GLMakie.activate!() # hide

fig = Figure(size = (360, 300))

area = ScrollArea(fig[1, 1])
for i in 1:30
    Label(area[i, 1], "param $i"; halign = :right, tellwidth = false)
    Slider(area[i, 2]; range = 0:100, startvalue = (i * 7) % 100, width = 150)
    GLB.rowsize!(area.layout, i, GLB.Fixed(30))
end
GLB.rowgap!(area.layout, 5)
GLB.colgap!(area.layout, 8)

fig
```

Only the visible rows are drawn (the rest are scissor-clipped), and a scrollbar
appears on the right. Scroll with the wheel/trackpad, or drag the scrollbar
thumb. You can also set the scroll position programmatically:

```julia
area.scroll[] = Vec2f(0, area.contentsize[][2])   # jump to the bottom
```

## Composing: fixed + scrolling regions

Because scroll is opt-in, you mix fixed and scrolling content by placing only the
scrollable part in a `ScrollArea`. This is the idiomatic way to build a
[`Modal`](@ref) with a fixed header and a scrolling body:

```julia
modal = Modal(fig; title = "Settings", width = 360, height = 340)
Label(modal[1, 1], "Fixed header — stays put"; font = :bold, halign = :left, tellwidth = false)

body = ScrollArea(modal[2, 1])          # only this region scrolls
for i in 1:25
    Label(body[i, 1], "row $i"; halign = :right, tellwidth = false)
    Slider(body[i, 2]; range = 0:100, width = 150)
    GLB.rowsize!(body.layout, i, GLB.Fixed(28))
end
open!(modal)
```

The same pattern works inside a `Tabs` tab, or nested — a `ScrollArea` inside a
`ScrollArea` clips and scrolls correctly at each level.

## Plotting directly

You can also plot straight into the area's `Scene` (in viewport-local pixel
coordinates) via `content_scene(area)`, though placing blocks into
`area[row, col]` is usually what you want.

## Attributes

```@attrdocs
ScrollArea
```
