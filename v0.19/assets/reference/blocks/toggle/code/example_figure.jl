# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str # hide
__result = begin # hide
    using GLMakie
GLMakie.activate!() # hide
fig = Figure()

ax = Axis(fig[1, 1])

toggles = [Toggle(fig, active = active) for active in [true, false]]
labels = [Label(fig, lift(x -> x ? "$l visible" : "$l invisible", t.active))
    for (t, l) in zip(toggles, ["sine", "cosine"])]

fig[1, 2] = grid!(hcat(toggles, labels), tellheight = false)

line1 = lines!(0..10, sin, color = :blue, visible = false)
line2 = lines!(0..10, cos, color = :red)

connect!(line1.visible, toggles[1].active)
connect!(line2.visible, toggles[2].active)

fig
end # hide
save(joinpath(@OUTPUT, "example_2263797281113359503.png"), __result; ) # hide

nothing # hide