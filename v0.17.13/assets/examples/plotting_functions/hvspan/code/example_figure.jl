# This file was generated, do not modify it. # hide
__result = begin # hide
    using CairoMakie
CairoMakie.activate!() # hide

lines(0..20, sin)
vspan!([0, 2pi, 4pi], [pi, 3pi, 5pi],
    color = [(c, 0.2) for c in [:red, :orange, :pink]])
hspan!(-1.1, -0.9, color = (:blue, 0.2))
current_figure()
end # hide
save(joinpath(@OUTPUT, "example_16063035256945583048.png"), __result; ) # hide
save(joinpath(@OUTPUT, "example_16063035256945583048.svg"), __result; ) # hide
nothing # hide