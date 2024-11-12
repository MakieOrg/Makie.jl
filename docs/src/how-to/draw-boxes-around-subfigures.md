# How to draw boxes around subfigures

If you want to show that several elements in a `Figure` belong together, you can do this by placing them all in a container.
The trick is to use a nested `GridLayout` for each group of objects and place a `Box` at the same position as this `GridLayout`.
Then the `alignmode = Outside(some_padding)` ensures that objects with protrusions sticking out, like `Axis`, are fully contained within the enclosing boxes.

```@figure
f = Figure()

g1 = GridLayout(f[1, 1], alignmode = Outside(15))
g2 = GridLayout(f[1, 2], alignmode = Outside(15))
box1 = Box(f[1, 1], cornerradius = 10, color = (:tomato, 0.5), strokecolor = :transparent)
box2 = Box(f[1, 2], cornerradius = 10, color = (:teal, 0.5), strokecolor = :transparent)

# move the boxes back so the Axis background polys are in front of them
Makie.translate!(box1.blockscene, 0, 0, -100)
Makie.translate!(box2.blockscene, 0, 0, -100)

Axis(g1[1, 1], backgroundcolor = :white)
Axis(g1[2, 1], backgroundcolor = :white)

Axis(g2[1, 1], backgroundcolor = :white)
Axis(g2[1, 2], backgroundcolor = :white)
Axis(g2[2, 1:2], backgroundcolor = :white)

Label(f[0, :], "Two boxes indicate groups of axes that belong together")

f
```

In other situations you may simply want to encircle parts of an existing layout without otherwise changing it. You can use the `Outer` side to position the boxes at the outer edge of their neighbors, in combination with a slightly negative `Outside(...)` alignmode (what margins look good here needs to be adjusted to taste).

```@figure
using Random # hide
Random.seed!(1234) # hide
f = Figure()

for i in 1:3, j in 1:4
    Axis(f[i, j], title = "$i & $j")
    lines!(cumsum(randn(100)), color = :gray80)
end

b = Box(
    f[1:2, 1:3, Makie.GridLayoutBase.Outer()],
    alignmode = Outside(-5, -12, -8, -5),
    cornerradius = 4,
    color = (:tomato, 0.1),
    strokecolor = :tomato,
    strokewidth = 2,
)
translate!(b.blockscene, 0, 0, -200)

b2 = Box(
    f[2:3, 3:4, Makie.GridLayoutBase.Outer()],
    alignmode = Outside(-5, -12, -8, -5),
    cornerradius = 4,
    color = (:teal, 0.1),
    strokecolor = :teal,
    strokewidth = 2,
)
translate!(b2.blockscene, 0, 0, -200)

Legend(
    f[end+1, :],
    [LineElement(color = :tomato), LineElement(color = :teal)],
    ["Group 1", "Group 2"],
    framevisible = false,
    orientation = :horizontal)
f
```
