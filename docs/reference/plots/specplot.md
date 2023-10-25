# SpecPlot


```julia

using GLMakie

struct MySimulation
    plottype::Symbol
    arguments::AbstractVector
end

function Makie.convert_arguments(::Type{<:AbstractPlot}, sim::MySimulation)
    colors = resample_cmap(:viridis, length(sim.arguments) + 1)
    return map(enumerate(sim.arguments)) do (i, data)
        return PlotSpec(sim.plottype, data; color=colors[i])
    end
end
f = Figure()
s = Slider(f[1, 1], range = 1:10)
m = Menu(f[1, 2], options = [:scatter, :lines, :barplot])
sim = lift(s.value, m.selection) do n_plots, p
    args = [rand(Point2f, 10) for i in 1:n_plots]
    return MySimulation(p, args)
end
plot(f[2, :], sim)
display(f)
```
