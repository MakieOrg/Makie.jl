# spy

```@shortdocs; canonical=false
spy
```


## Examples

```@figure
using SparseArrays

N = 10 # dimension of the sparse matrix
p = 0.1 # independent probability that an entry is zero

A = sprand(N, N, p)
f, ax, plt = spy(A, framecolor = :lightgrey, axis=(;
    aspect=1,
    title = "Visualization of a random sparse matrix")
)

hidedecorations!(ax) # remove axis labeling

f
```

## Attributes

```@attrdocs
Spy
```
