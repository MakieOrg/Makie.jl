# This file was generated, do not modify it. # hide
__result = begin # hide
    using CairoMakie, SparseArrays
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

N = 100 # dimension of the sparse matrix
p = 0.1 # independent probability that an entry is zero

A = sprand(N, N, p)

f, ax, plt = spy(A, markersize = 4, marker = :circle, framecolor = :lightgrey)

hidedecorations!(ax) # remove axis labeling
ax.title = "Visualization of a random sparse matrix"

f
end # hide
save(joinpath(@OUTPUT, "example_16812066884587372690.png"), __result; ) # hide

nothing # hide