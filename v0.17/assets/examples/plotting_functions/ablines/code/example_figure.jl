# This file was generated, do not modify it. # hide
__result = begin # hide
    using CairoMakie
CairoMakie.activate!() # hide

ablines(0, 1)
ablines!([1, 2, 3], [1, 1.5, 2], color = [:red, :orange, :pink], linestyle=:dash, linewidth=2)
current_figure()
end # hide
save(joinpath(@OUTPUT, "example_6848846738315747837.png"), __result; ) # hide
save(joinpath(@OUTPUT, "example_6848846738315747837.svg"), __result; ) # hide
nothing # hide