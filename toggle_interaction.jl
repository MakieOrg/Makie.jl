using GLMakie

fig = Figure()

ax = Axis(fig[1, 1], backgroundcolor = :black)

limits!(ax, 0, 600, -2, 2)
hidedecorations!(ax)

t = Observable(0.0)
points = lift(t) do t
    x = range(t-1, t+1, length = 500)
    @. sin(x) * sin(2x) * sin(4x) * sin(23x)
end

lin = lines!(ax, points, color = (1:500) .^ 2, linewidth = 2, colormap = [(:lime, 0.0), :lime])

gl = GridLayout(fig[2, 1], tellwidth = false)
Label(gl[1, 1], "Live Update")
toggle = Toggle(gl[1, 2])

on(fig.scene.events.tick) do tick
    @show tick.delta_time
    toggle.active[] || return
    t[] += tick.delta_time
end

fig

##

using ..FakeInteraction

events = [
    Wait(0.5),
    Lazy() do fig
        MouseTo(relative_pos(toggle, (0.7, 0.3)))
    end,
    Wait(0.2),
    LeftClick(),
    Wait(3.0),
    LeftClick(),
    Wait(1.5),
]

interaction_record(fig, "button_example.mp4", events)


