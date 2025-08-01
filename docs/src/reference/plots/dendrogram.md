# dendrogram

```@shortdocs; canonical=false
dendrogram
```

## Examples

```@figure
using CairoMakie

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
using CairoMakie

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
using CairoMakie

leaves = Point2f[(1,0), (2,0.5), (3,1), (4,2), (5,0)]
merges = [(1, 2), (6, 3), (4, 5), (7, 8)]

f, a, p = dendrogram(leaves, merges, rotation = :right, branch_shape = :tree)
dendrogram!(a, leaves, merges, origin = (4, 4), rotation = :left, color = :orange)
f
```

```@figure
using CairoMakie

leaves = Point2f[(1,0), (2,0.5), (3,1), (4,2), (5,0)]
merges = [(1, 2), (6, 3), (4, 5), (7, 8)]

f = Figure()
a = PolarAxis(f[1, 1])
dendrogram!(a, leaves, merges, linewidth = 3, color = :black, linestyle = :dash, origin = Point2f(0, 1))
f
```

## Attributes

```@attrdocs
Dendrogram
```
