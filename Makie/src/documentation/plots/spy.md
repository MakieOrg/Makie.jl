# spy

## Examples

### Sparse Matrix Visualization

```@figure
using SparseArrays

A = sprand(10, 10, 0.1)
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

### Orientation

`spy`, like `heatmap` and `image`, treats the first index of the given matrix as the x dimension and the second as the y dimension.
This is different from when a matrix is printed, where the first index expands downwards and the second to the right.
`rotr90` can be used to match the Makie plot with the way Julia prints the matrix.

```@figure
using SparseArrays

S = spzeros(4, 4)
S[:, 1] .= 2.0
S[1, 2:4] .= 1.0
#=
Prints as:
4×4 SparseMatrixCSC{Float64, Int64} with 7 stored entries:
 2.0  1.0  1.0  1.0
 2.0   ⋅    ⋅    ⋅
 2.0   ⋅    ⋅    ⋅
 2.0   ⋅    ⋅    ⋅
=#

M = Matrix(S)

f = Figure(size = (600, 500))

a, p = heatmap(
    f[1, 1], M,
    colorrange = (1, 2), lowclip = :transparent,
    colormap = Categorical(:viridis), # just for Colorbar
    axis = (title = "heatmap",)
)
Colorbar(f[1:2, 3], p)
a, p = spy(f[1, 2], S, axis = (title = "spy",))

a, p = heatmap(
    f[2, 1], rotr90(M),
    colorrange = (1, 2), lowclip = :transparent,
    axis = (title = "rotated heatmap",)
)
a, p = spy(f[2, 2], rotr90(S), axis = (title = "rotated spy",))

f
```
