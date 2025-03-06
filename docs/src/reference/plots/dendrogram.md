# dendrogram

```@shortdocs; canonical=false
dendrogram
```

## Examples

```@figure
leaves = Point2f.([
    (1,0),
    (2,0.5),
    (3,1),
    (4,2),
    (5,0)
])

merges = [
    (1, 2), # 6
    (6, 3), # 7
    (4, 5), # 8
    (7, 8), # 9
]

dendrogram(leaves, merges)
```

WIP!

```@figure
f = Figure() 
Axis(f[1, 1])

for i in 1:10
    arc!(Point2f(0, i), i, -π, π)
end

f
```

```@figure
f = Figure()
Axis(f[1, 1])

for i in 1:4
    radius = 1/(i*2)
    left = 1/(i*2)
    right = (i*2-1)/(i*2)
    arc!(Point2f(left, 0), radius, 0, π)
    arc!(Point2f(right, 0), radius, 0, π)
end
for i in 3:4
    radius = 1/(i*(i-1)*2)
    left = (1/i) + 1/(i*(i-1)*2)
    right = ((i-1)/i) - 1/(i*(i-1)*2)
    arc!(Point2f(left, 0), radius, 0, π)
    arc!(Point2f(right, 0), radius, 0, π)
end

f
```

## Attributes

```@attrdocs
Dendrogram
```
