# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using GLMakie
GLMakie.activate!() # hide
fig = Figure()

ax = Axis(fig[1, 1])
fig[2, 1] = buttongrid = GridLayout(tellwidth = false)

counts = Observable([1, 4, 3, 7, 2])

buttonlabels = [lift(x -> "Count: $(x[i])", counts) for i in 1:5]

buttons = buttongrid[1, 1:5] = [Button(fig, label = l) for l in buttonlabels]

for i in 1:5
    on(buttons[i].clicks) do n
        counts[][i] += 1
        notify(counts)
    end
end

barplot!(counts, color = cgrad(:Spectral)[LinRange(0, 1, 5)])
ylims!(ax, 0, 20)

fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_3a169952_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_3a169952.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide