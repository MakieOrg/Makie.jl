# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str # hide
__result = begin # hide
    using CairoMakie

#Gantt data
gantt = (
    machine = [1,2,1,2],
    job = [1,1,2,3],
    task = [1,2,3,3],
    start = [1, 3, 3.5, 5],
    stop = [3, 4, 5, 6]
)

#Figure and axis
fig = Figure()
ax = Axis(
    fig[2,1],
    yticks = (1:2, ["A","B"]),
    ylabel = "Machine",
    xlabel = "Time"
)
xlims!(ax, 0, maximum(gantt.stop))

#Colors
colors = cgrad(:tab10)

#Plot bars
barplot!(
    gantt.machine,
    gantt.stop,
    fillto = gantt.start,
    direction = :x,
    color = colors[gantt.job],
    gap = 0.5
)

#Add labels
bar_labels = ["task #$i" for i in gantt.task]
text!(
    ["task #$i" for i in gantt.task],
    position = Point2f.(
        (gantt.start .+ gantt.stop) ./ 2,
        gantt.machine
    ),
    color = :white,
    align = (:center, :center)
)

#Add Legend
labels = ["job #$i" for i in unique(gantt.job)]
elements = [PolyElement(polycolor = colors[i]) for i in unique(gantt.job)]
Legend(fig[1,1], elements, labels, "Jobs", orientation=:horizontal, tellwidth = false, tellheight = true)

fig
end # hide
save(joinpath(@OUTPUT, "example_9730935723775148367.png"), __result; ) # hide

nothing # hide