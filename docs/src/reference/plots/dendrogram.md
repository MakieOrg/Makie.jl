# dendrogram

```@shortdocs; canonical=false
dendrogram
```

## Examples

```@figure
# Relative positions of leaf nodes
# These positions will be translated to place the root node at `origin`
leaves = Point2f[
    (1,0),
    (2,0.5),
    (3,1),
    (4,2),
    (5,0)
]

# connections between nodes which merge into a new node
merges = [
    (1, 2), # creates node 6
    (6, 3), # 7
    (4, 5), # 8
    (7, 8), # 9
]

dendrogram(leaves, merges)
```

```@figure
leaves = Point2f[(1,0), (2,0.5), (3,1), (4,2), (5,0)]
merges = [(1, 2), (6, 3), (4, 5), (7, 8)]

# Adding groups for each leaf node will result in branches of a common group
# to be colored the same (based on colormap). Branches with miss-matched groups
# use ungrouped_color
f, a, p = dendrogram(leaves, merges,
    groups = [1, 1, 2, 3, 3],
    colormap = [:red, :green, :blue],
    ungrouped_color = :black)

# Makie.dendrogram_node_positions(plot) can be used to get final node positions
# of all nodes. The N input nodes are the first N returned
textlabel!(a, map(ps -> ps[1:5], Makie.dendrogram_node_positions(p)), text = ["A", "A", "B", "C", "C"],
    shape = Circle(Point2f(0.5), 0.5), keep_aspect = true)
f
```


```@figure
leaves = Point2f[(1,0), (2,0.5), (3,1), (4,2), (5,0)]
merges = [(1, 2), (6, 3), (4, 5), (7, 8)]

f, a, p = dendrogram(leaves, merges, rotation = :right, branch_shape = :tree)
dendrogram!(a, leaves, merges, origin = (4, 4), rotation = :left, color = :orange)
f
```

```@figure
leaves = Point2f[(1,0), (2,0.5), (3,1), (4,2), (5,0)]
merges = [(1, 2), (6, 3), (4, 5), (7, 8)]

f = Figure()
a = PolarAxis(f[1, 1])
dendrogram!(a, leaves, merges, linewidth = 3, color = :black, linestyle = :dash, origin = Point2f(0, 1))
f
```

By default the tree is translated so that its root sits at `origin`, which means
the leaf positions depend on the structure of the tree. Pass `absolute = true` to
keep the input coordinates as given instead. This makes it easy to align the
leaves to other plot elements such as the rows and columns of a heatmap: place the
leaves at `1:n` and link the axes.

```@figure
n = 8
leaves = Point2f.(1:n, 0)
merges_rows = [(1,2), (3,4), (5,6), (7,8), (9,10), (11,12), (13,14)]
merges_cols = [(1,2), (9,3), (10,4), (5,6), (12,7), (13,8), (11,14)]
data = [abs(i - j) for i in 1:n, j in 1:n]

f = Figure()
ax_left = Axis(f[1, 1], width = 80)
ax_bot = Axis(f[2, 2], height = 80, yreversed = true)
ax_h = Axis(f[1, 2], width = 300, height = 300, xticks = 1:n, yticks = 1:n)
lw = ax_h.spinewidth[]
dendrogram!(ax_left, leaves, merges_rows, rotation = :right, absolute = true, color = :black, linewidth = lw)
dendrogram!(ax_bot, leaves, merges_cols, rotation = :down, absolute = true, color = :black, linewidth = lw)
heatmap!(ax_h, 1:n, 1:n, data)
linkyaxes!(ax_left, ax_h)
linkxaxes!(ax_bot, ax_h)
hidedecorations!(ax_left); hidespines!(ax_left)
hidedecorations!(ax_bot); hidespines!(ax_bot)
colgap!(f.layout, 6); rowgap!(f.layout, 6)
resize_to_layout!(f)
f
```

## Attributes

```@attrdocs
Dendrogram
```
