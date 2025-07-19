# This file was generated, do not modify it. # hide
__result = begin # hide
    using GLMakie
GLMakie.activate!() # hide


f = Figure()

xs = LinRange(0, 4pi, 30)

stem(f[1, 1], 0.5xs, 2 .* sin.(xs), 2 .* cos.(xs),
    offset = Point3f.(0.5xs, sin.(xs), cos.(xs)),
    stemcolor = LinRange(0, 1, 30), stemcolormap = :Spectral, stemcolorrange = (0, 0.5))

f
end # hide
save(joinpath(@OUTPUT, "example_15964671494016948088.png"), __result; ) # hide

nothing # hide