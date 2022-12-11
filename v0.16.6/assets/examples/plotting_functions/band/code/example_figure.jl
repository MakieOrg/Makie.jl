# This file was generated, do not modify it. # hide
__result = begin # hide
    using GLMakie
GLMakie.activate!() # hide
Makie.inline!(true) # hide
lower = fill(Point3f(0,0,0), 100)
upper = [Point3f(sin(x), cos(x), 1.0) for x in range(0,2pi, length=100)]
col = repeat([1:50;50:-1:1],outer=2)
band(lower, upper, color=col, axis=(type=Axis3,))
end # hide
save(joinpath(@OUTPUT, "example_426580578809721985.png"), __result) # hide

nothing # hide