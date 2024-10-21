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
