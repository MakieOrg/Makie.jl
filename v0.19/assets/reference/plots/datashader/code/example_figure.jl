# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str # hide
__result = begin # hide
    normaldist = randn(Point2f, 1_000_000)
ds1 = normaldist .+ (Point2f(-1, 0),)
ds2 = normaldist .+ (Point2f(1, 0),)
fig, ax, pl = datashader(Dict("a" => ds1, "b" => ds2))
hidedecorations!(ax)
fig
end # hide
save(joinpath(@OUTPUT, "example_18324868884190079829.png"), __result; ) # hide

nothing # hide