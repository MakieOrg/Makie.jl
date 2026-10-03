# This file was generated, do not modify it. # hide
__result = begin # hide
  
axtop = Axis(ga[1, 1])
axmain = Axis(ga[2, 1], xlabel = "before", ylabel = "after")
axright = Axis(ga[2, 2])

labels = ["treatment", "placebo", "control"]
data = randn(3, 100, 2) .+ [1, 3, 5]

for (label, col) in zip(labels, eachslice(data, dims = 1))
    scatter!(axmain, col, label = label)
    density!(axtop, col[:, 1])
    density!(axright, col[:, 2], direction = :y)
end

f

  end # hide
  save(joinpath(@OUTPUT, "example_7756328437581813496.png"), __result) # hide
  
  nothing # hide