# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
using CairoMakie # hide
CairoMakie.activate!() # hide
fig = Figure()
ax = Axis(fig[1, 1])
lin = lines!(ax, 1:10, linestyle = :dash)
pol = poly!(ax, [(5, 0), (10, 0), (7.5, 5)])
sca = scatter!(ax, 4:13)
Legend(fig[1, 2],
    [[lin], [pol], [sca]],
    [["Line"], ["Poly"], ["Scatter"]],
    ["Default", "Group 2", "Group 3"];

)
Legend(fig[1, 3],
    [[lin], [pol], [sca]],
    [["Line"], ["Poly"], ["Scatter"]],
    ["groupgap = 30", "Group 2", "Group 3"];
    groupgap = 30,
)
fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_9de3d761_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_9de3d761.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_9de3d761.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide