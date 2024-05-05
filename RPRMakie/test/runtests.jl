using RPRMakie
using Test

RPRMakie.activate!(iterations = 50)
f, ax, pl = meshscatter(rand(Point3f, 100), color = :blue)
out = joinpath(@__DIR__, "recorded")
isdir(out) && rm(out; recursive = true, force = true)
mkdir(out)
save(joinpath(out, "test.png"), ax.scene);
