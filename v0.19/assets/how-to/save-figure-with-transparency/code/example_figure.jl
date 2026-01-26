# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str # hide
__result = begin # hide
    using GLMakie
GLMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure(backgroundcolor = (:blue, 0.4))
Axis(f[1, 1], backgroundcolor = (:tomato, 0.5))
f
end # hide
save(joinpath(@OUTPUT, "example_5467780000570908020.png"), __result; ) # hide

nothing # hide