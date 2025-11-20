# spy

## Examples

### Sparse Matrix Visualization

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


### Sparse matrix with structure and color

```@figure
using SparseArrays

N = 500
I, J, V = Int[], Int[], Float64[]

# Diagonal bands
for offset in [-50, -25, 0, 25, 50]
    for i in max(1, 1-offset):min(N, N-offset)
        if rand() < 0.3
            push!(I, i)
            push!(J, i + offset)
            push!(V, abs(offset) / 50)
        end
    end
end

# Corner blocks
for _ in 1:2000
    push!(I, rand(1:100))
    push!(J, rand(N-99:N))
    push!(V, 2.0)
end

x = sparse(I, J, V, N, N)

spy(x, colormap = :plasma, markersize = 3,
    axis = (aspect = 1, title = "Sparse matrix pattern"))
```
