# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie

f = Figure()

traces = cumsum(randn(10, 5), dims = 1)

for (i, (merge, unique)) in enumerate(
        Iterators.product([false, true], [false true]))

    axis = Axis(f[fldmod1(i, 2)...],
        title = "merge = $merge, unique = $unique")

    for trace in eachcol(traces)
        lines!(trace, label = "single", color = (:black, 0.2))
    end

    mu = vec(sum(traces, dims = 2) ./ 5)
    lines!(mu, label = "mean")
    scatter!(mu, label = "mean")

    axislegend(axis, merge = merge, unique = unique)

end

f

  end # hide
  save(joinpath(@OUTPUT, "example_16982711902626239414.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_16982711902626239414.svg"), __result) # hide
  nothing # hide