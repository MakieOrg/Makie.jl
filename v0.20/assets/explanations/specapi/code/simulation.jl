# This file was generated, do not modify it. # hide
using GLMakie
import Makie.SpecApi as S
GLMakie.activate!() # hide

struct MySimulation
    plottype::Symbol
    arguments::AbstractVector
end

function Makie.convert_arguments(::Type{<:AbstractPlot}, sim::MySimulation)
    return map(enumerate(sim.arguments)) do (i, data)
        return PlotSpec(sim.plottype, data)
    end
end
f = Figure()
s = Slider(f[1, 1], range=1:10)
m = Menu(f[1, 2], options=[:Scatter, :Lines, :BarPlot])
sim = lift(s.value, m.selection) do n_plots, p
    Random.seed!(123)
    args = [cumsum(randn(100)) for i in 1:n_plots]
    return MySimulation(p, args)
end
ax, pl = plot(f[2, :], sim)
tight_ticklabel_spacing!(ax)
# lower priority to make sure the call back is always called last
on(sim; priority=-1) do x
    autolimits!(ax)
end

record(f, "interactive_specapi.mp4", framerate=1) do io
    pause = 0.1
    m.i_selected[] = 1
    for i in 1:4
        set_close_to!(s, i)
        sleep(pause)
        recordframe!(io)
    end
    m.i_selected[] = 2
    sleep(pause)
    recordframe!(io)
    for i in 5:7
        set_close_to!(s, i)
        sleep(pause)
        recordframe!(io)
    end
    m.i_selected[] = 3
    sleep(pause)
    recordframe!(io)
    for i in 7:10
        set_close_to!(s, i)
        sleep(pause)
        recordframe!(io)
    end
end