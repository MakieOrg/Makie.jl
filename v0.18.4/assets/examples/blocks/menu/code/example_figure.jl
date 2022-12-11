# This file was generated, do not modify it. # hide
__result = begin # hide
    using GLMakie
GLMakie.activate!() # hide

fig = Figure()

menu = Menu(fig[1, 1], options = ["A", "B", "C"])
menu2 = Menu(fig[3, 1], options = ["A", "B", "C"])

menu.is_open = true
menu2.is_open = true

fig
end # hide
save(joinpath(@OUTPUT, "example_1722623567756173517.png"), __result; ) # hide

nothing # hide