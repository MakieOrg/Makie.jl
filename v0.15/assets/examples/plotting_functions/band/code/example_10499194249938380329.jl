# This file was generated, do not modify it. # hide
__result = begin # hide
  
using Statistics
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure()
Axis(f[1, 1])

n, m = 100, 101
t = range(0, 1, length=m)
X = cumsum(randn(n, m), dims = 2)
X = X .- X[:, 1]
μ = vec(mean(X, dims=1)) # mean
lines!(t, μ)              # plot mean line
σ = vec(std(X, dims=1))  # stddev
band!(t, μ + σ, μ - σ)   # plot stddev band
f

  end # hide
  save(joinpath(@OUTPUT, "example_10499194249938380329.png"), __result) # hide
  
  nothing # hide