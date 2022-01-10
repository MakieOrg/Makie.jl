using RPRMakie
using Test

RPRMakie.activate!(resource=RPR.RPR_CREATION_FLAGS_ENABLE_CPU, iterations=50)
f, ax, pl = meshscatter(rand(Point3f, 100), color=:blue)
out = joinpath(@__DIR__, "recorded")
isdir(out) && rm(out)
mkdir("recorded")
save(joinpath(out, "test.png"), ax.scene);
