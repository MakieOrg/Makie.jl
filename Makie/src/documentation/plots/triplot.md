# triplot

## Examples

### Example 1

```@figure
using DelaunayTriangulation

points = rand(2, 50)
tri = triangulate(points)
triplot(tri)
```
