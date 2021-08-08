using PyPlot
x = range(0, stop=1, length=50)
plot(x, sin.(2x).*exp.(-x/3))
savefig(joinpath(@__DIR__, "output", "script2.svg"))
