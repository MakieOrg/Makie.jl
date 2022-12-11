# This file was generated, do not modify it. # hide
__result = begin # hide
    using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure(fontsize = 24, fonts = (; regular = "Dejavu", weird = "Blackchancery"))
Axis(f[1, 1], title = "A title", xlabel = "An x label", xlabelfont = :weird)

f
end # hide
save(joinpath(@OUTPUT, "example_6205795135311329679.png"), __result; ) # hide
save(joinpath(@OUTPUT, "example_6205795135311329679.svg"), __result; ) # hide
nothing # hide