# SpecApi

!!! warning
    The SpecApi is still under active development and might introduce breaking changes quickly in the future.
    It's also slower for animations then using the normal Makie API, since it needs to re-create plots often and needs to go over the whole plot tree to find different values.
    While the performance will always be slower then directly using Observables to update attributes, it's still not much optimized so we expect to improve it in the future.
    You should also expect bugs, since the API is still very new while offering lots of new and complex functionality.
    Don't hesitate to open issues if you run into unexpected behaviour.
    PRs are also more then welcome, the code isn't actually that complex and should be easy to dive into (src/basic_recipes/specapi.jl).

The `SpecApi` is a convenient scope for creating PlotSpec objects.
PlotSpecs are a simple way to create plots in a declarative way, which can then get converted to Makie plots.
You can use `Observable{SpecApi.PlotSpec}`, or `Observable{SpecApi.Figure}` to create complete figures that can be updated dynamically.

The API is supposed mirror the normal Makie API 1:1, just prefixed by `SpecApi`:
```julia
import Makie.SpecApi as S # For convenience import it as a shorter name
S.scatter(1:4) # create a single PlotSpec object

# Create a complete figure
f = S.Figure() #
ax = S.Axis(f[1, 1])
S.scatter!(ax, 1:4)
fig_observable = Observable(f)
plot(fig_observable) # Plot the whole figure
# Efficiently update the complete figure with a new FigureSpec
fig_observable[] = S.Figure(S.Axis(; title="lines", plots=[S.lines(1:4)]))
```

You can also drop to the lower level constructors:

```julia
s = Makie.PlotSpec(:scatter, 1:4; color=:red)
axis = Makie.BlockSpec(:Axis; position=(1, 1), title="Axis at layout position (1, 1)")
```

Or use the Declarative API:
```julia
f = S.Figure([
    S.Axis(
        plots = [
            S.scatter(1:4)
        ]
    )
])
```
For the declaritive API, `S.Figure` accepts a vector of blockspecs or matrix of blockspecs, which places the Blocks at the indices of those arrays:
\begin{examplefigure}{}
```julia
using GLMakie, DelimitedFiles, FileIO
import Makie.SpecApi as S
GLMakie.activate!() # hide
volcano = readdlm(Makie.assetpath("volcano.csv"), ',', Float64)
brain = load(assetpath("brain.stl"))
r = LinRange(-1, 1, 100)
cube = [(x .^ 2 + y .^ 2 + z .^ 2) for x = r, y = r, z = r]

ax1 = S.Axis(; title="Axis 1", plots=map(x -> S.density(x * randn(200) .+ 3x, color=:y), 1:5))
ax2 = S.Axis(; title="Axis 2", plots=[S.contourf(volcano; colormap=:inferno)])
ax3 = S.Axis3(; title="Axis3", plots=[S.mesh(brain, colormap=:Spectral, color=[tri[1][2] for tri in brain for i in 1:3])])
ax4 = S.Axis3(; plots=[S.contour(cube, alpha=0.5)])


spec_array = S.Figure([ax1, ax2]);
spec_matrix = S.Figure([ax1 ax2; ax3 ax4]);
f = Figure(; size=(1000, 500))
plot(f[1, 1], spec_array)
plot(f[1, 2], spec_matrix)
f
```
\end{examplefigure}

# Usage in convert_arguments

!!! warning
    It's not decided yet how to forward keyword arguments from `plots(...; kw...)` to `convert_arguments` for the SpecApi in a more convenient and performant way. Until then, one needs to use the regular mechanism via `Makie.used_attributes`, which completely redraws the entire Spec on change of any attribute.

You can overload `convert_arguments` and return an array of `PlotSpecs` or a `FigureSpec`.
The main difference between those is, that returning an array of `PlotSpecs` can be plotted like any recipe into axes etc, while overloads returning a whole Figure spec can only be plotted to whole layout position (e.g. `figure[1, 1]`).

## convert_arguments for FigureSpec

Simple example to create a dynamic grid of axes:

\begin{examplefigure}{}
```julia
using CairoMakie
import Makie.SpecApi as S
struct PlotGrid
    nplots::Tuple{Int,Int}
end

Makie.used_attributes(::Type{<:AbstractPlot}, ::PlotGrid) = (:color,)
function Makie.convert_arguments(::Type{<:AbstractPlot}, obj::PlotGrid; color=:black)
    f = S.Figure(; fontsize=30)
    for i in 1:obj.nplots[1]
        for j in 1:obj.nplots[2]
            ax = S.Axis(f[i, j])
            S.lines!(ax, cumsum(randn(1000)); color=color)
        end
    end
    return f
end

f = Figure()
plot(f[1, 1], PlotGrid((1, 1)); color=Cycled(1))
plot(f[1, 2], PlotGrid((2, 2)); color=Cycled(2))
f
```
\end{examplefigure}

## convert_arguments for PlotSpec

With this we can dynamically create plots in convert_arguments.
Note, that this still doesn't allow to easily forward keyword arguments from the plot command to `convert_arguments`, so we put the plot arguments into `LineScatter` in this example:

\begin{examplefigure}{}
```julia
using CairoMakie
import Makie.SpecApi as S
struct LineScatter
    show_lines::Bool
    show_scatter::Bool
    kw::Dict{Symbol,Any}
end
LineScatter(lines, scatter; kw...) = LineScatter(lines, scatter, Dict{Symbol,Any}(kw))

function Makie.convert_arguments(::Type{<:AbstractPlot}, obj::LineScatter, data...)
    plots = PlotSpec[]
    if obj.show_lines
        push!(plots, S.lines(data...; obj.kw...))
    end
    if obj.show_scatter
        push!(plots, S.scatter(data...; obj.kw...))
    end
    return plots
end

f = Figure()
ax = Axis(f[1, 1])
# Can be plotted into Axis, since it doesn't create its own axes like FigureSpec
plot!(ax, LineScatter(true, true; markersize=20, color=1:4), 1:4)
plot!(ax, LineScatter(true, false; color=:darkcyan, linewidth=3), 2:4)
f
```
\end{examplefigure}


# Interactivity

The SpecApi is geared towards dashboards and interactively creating complex plots.
Here is a simple example using Slider and Menu, to visualize a fake simulation:

~~~
<input id="hidecode" class="hidecode" type="checkbox">
~~~
```julia:simulation
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
m = Menu(f[1, 2], options=[:scatter, :lines, :barplot])
sim = lift(s.value, m.selection) do n_plots, p
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
```
~~~
<label for="hidecode" class="hidecode"></label>
~~~

\video{interactive_specapi, autoplay = true}
