# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using GLMakie
GLMakie.activate!() # hide
fig = Figure()

menu = Menu(fig, options = ["viridis", "heat", "blues"], default = "blues")

funcs = [sqrt, x->x^2, sin, cos]

menu2 = Menu(fig,
    options = zip(["Square Root", "Square", "Sine", "Cosine"], funcs),
    default = "Square")

fig[1, 1] = vgrid!(
    Label(fig, "Colormap", width = nothing),
    menu,
    Label(fig, "Function", width = nothing),
    menu2;
    tellheight = false, width = 200)

ax = Axis(fig[1, 2])

func = Observable{Any}(funcs[1])

ys = lift(func) do f
    f.(0:0.3:10)
end
scat = scatter!(ax, ys, markersize = 10px, color = ys)

cb = Colorbar(fig[1, 3], scat)

on(menu.selection) do s
    scat.colormap = s
end
notify(menu.selection)

on(menu2.selection) do s
    func[] = s
    autolimits!(ax)
end
notify(menu2.selection)

menu2.is_open = true

fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_3a2e513a_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_3a2e513a.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide