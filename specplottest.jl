using DataFrames
import Makie.SpecApi as S
using Random
using WGLMakie
function gen_data(N=1000)
    return DataFrame(
        :continuous2 => cumsum(randn(N)),
        :continuous3 => cumsum(randn(N)),
        :continuous4 => cumsum(randn(N)),
        :continuous5 => cumsum(randn(N)),

        :condition2 => rand(["string1", "string2"], N),
        :condition3 => rand(["cat", "dog", "fox"], N),
        :condition4 => rand(["eagle", "nashorn"], N),
        :condition5 => rand(["bug", "honey", "riddle", "carriage"], N),

        :data_condition2 => cumsum(randn(N)),
        :data_condition3 => cumsum(randn(N)),
        :data_condition4 => cumsum(randn(N)),
        :data_condition5 => cumsum(randn(N)),
    )
end


function plot_data(data, categorical_vars, continuous_vars)
    fig = S.Figure()
    mpalette = [:circle, :star4, :xcross, :diamond]
    cpalette = Makie.wong_colors()
    cat_styles = [:color => cpalette, :marker => mpalette, :markersize => [5, 10, 20, 30], :marker => ['c', 'x', 'y', 'm']]
    cat_values = [unique(data[!, cat]) for cat in categorical_vars]
    scatter_styles = Dict([cat => (style[1] => Dict(zip(vals, style[2]))) for (style, vals, cat) in zip(cat_styles, cat_values, categorical_vars)])

    continous_styles = [:viridis, :heat, :rainbow, :turku50]
    continuous_values = [extrema(data[!, con]) for con in continuous_vars]
    line_styles = Dict([cat => (; colormap=style, colorrange=limits) for (style, limits, cat) in zip(continous_styles, continuous_values, continuous_vars)])
    ax = S.Axis(fig[1, 1])
    for var in categorical_vars
        values = data[!, var]
        kw, vals = scatter_styles[var]
        args = [kw => map(x-> vals[x], values)]
        d = data[!, Symbol("data_$var")]
        S.scatter!(ax, d; args...)
    end
    for var in continuous_vars
        points = data[!, var]
        S.lines!(ax, points; line_styles[var]..., color=points)
    end
    fig
end


using WGLMakie, JSServe
App() do
    data = gen_data(1000)
    continous_vars = Observable(["continuous2", "continuous3"])
    categorical_vars = Observable(["condition2", "condition4"])
    s = JSServe.Slider(1:10)

    obs = lift(continous_vars, categorical_vars) do con_vars, cat_vars
        plot_data(data, cat_vars, con_vars)
    end
    all_vars = ["continuous$i" for i in 2:5]
    all_cond_vars = ["condition$i" for i in 2:5]
    on(s.value) do va
        continous_vars[] =  shuffle!(all_vars[unique(rand(1:4, rand(1:4)))])
        categorical_vars[] = shuffle!(all_cond_vars[unique(rand(1:4, rand(1:4)))])
    end
    fig = plot(obs)
    DOM.div(s, fig)
end

for i in 1:1000
    all_vars = ["continuous$i" for i in 2:5]
    all_cond_vars = ["condition$i" for i in 2:5]

    continous_vars[] =  shuffle!(all_vars[unique(rand(1:4, rand(1:4)))])
    categorical_vars[] = shuffle!(all_cond_vars[unique(rand(1:4, rand(1:4)))])
    yield()
end
end_size = Base.summarysize(fig) / 10^6

obs[] = S.Figure()
obs[] = S.Figure(S.Axis((1, 1), plots=[S.scatter(1:4), S.lines(1:4; color=:red)]),
                 S.Axis3((1, 2), plots=[S.scatter(rand(Point3f, 10); color=:red)]))


using Makie
import Makie.SpecApi as S
using GLMakie
GLMakie.activate!(; float=true)

function test(f_obs)
    f_obs[] = begin
        f = S.Figure()
        ax = S.Axis(f[1, 1])
        S.scatter!(ax, 1:4)
        ax2 = S.Axis3(f[1, 2])
        S.scatter!(ax2, rand(Point3f, 10); color=1:10, markersize=20)
        S.Colorbar(f[1, 3]; limits=(0, 1), colormap=:heat)
        f
    end
    yield()
    f_obs[] = begin
        S.Figure(S.Axis((1, 1),
                        S.scatter(1:4),
                        S.lines(1:4; color=:red)),
                 S.Axis3((1, 2), S.scatter(rand(Point3f, 10); color=:red)))
    end
    return yield()
end

begin
    f = S.Figure()
    f_obs = Observable(f)
    fig = Makie.update_fig(Figure(), f_obs)
end
f_obs[] = begin
    f = S.Figure()
    ax = S.Axis(f[1, 1])
    S.scatter(ax, 0:0.01:1, 0:0.01:1)
    S.scatter(ax, rand(Point2f, 10); color=:green, markersize=20)
    S.scatter(ax, rand(Point2f, 10); color=:red, markersize=20)
    f
end;

for i in 1:20
    f_obs[] = begin
        f = S.Figure()
        ax = S.Axis(f[1, 1])
        S.scatter!(ax, 1:4)
        ax2 = S.Axis3(f[1, 2])
        S.scatter!(ax2, rand(Point3f, 10); color=1:10, markersize=20)
        S.scatter!(ax2, rand(Point3f, 10); color=1:10, markersize=20)
        f
    end
    yield()
    f_obs[] = begin
        S.Figure(S.Axis((1, 1),
                    S.scatter(1:4),
                    S.lines(1:4; color=:red)),
                 S.Axis3((1, 2), S.scatter(rand(Point3f, 10); color=:red)))
    end
    yield()
end
[GC.gc(true) for i in 1:5]

using JSServe, WGLMakie
rm(JSServe.bundle_path(WGLMakie.WGL))
rm(JSServe.bundle_path(JSServe.JSServeLib))
WGLMakie.activate!()
fig = Figure()
ax = LScene(fig[1, 1]);
ax = Axis3(fig[1, 2]);
scatter(1:4)

using SnoopCompileCore, Makie

macro ctime(x)
    return quote
        tstart = time_ns()
        $(esc(x))
        ts = Float64(time_ns() - tstart) / 10^9
        println("time: $(round(ts, digits=5))s")
    end
end

tinf = @snoopi_deep @ctime scatter(1:4; color=1:4, colormap=:turbo, markersize=20, visible=true);
# tinf = @snoopi_deep(@ctime(colorbuffer(fig)));
using SnoopCompile, ProfileView; ProfileView.view(flamegraph(tinf))


using GLMakie

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
s = Slider(f[1, 1], range = 1:10)
m = Menu(f[1, 2], options = [:scatter, :lines, :barplot])
sim = lift(s.value, m.selection) do n_plots, p
    args = [rand(Point2f, 10) for i in 1:n_plots]
    return MySimulation(p, args)
end
ax, pl = plot(f[2, :], sim)
display(f)

resample_cmap(:viridis, 2)

using GLMakie
import Makie.SpecApi as S
plot(Observable(
    [S.scatter(1:4), S.scatter(2:5)]
))

function Makie.convert_arguments(T::Type{<:AbstractPlot}, data::Matrix)
    return map(1:size(data, 2)) do i
        return PlotSpec(plotkey(T), data[:, i]; color=Parent())
    end
end

scatter(rand(10, 4); color=:red)

using GLMakie
struct MySpec3
    type::Any
    args::Any
    kws::Any
end
MySpec3(type, args...; kws...) = MySpec3(type, args, kws)

function Makie.convert_arguments(::Type{<:AbstractPlot}, obj::MySpec3)
    f = S.Figure()
    Makie.BlockSpec(obj.type, f[1, 1], obj.args...; obj.kws...)
    return f
end
GLMakie.activate!(; float=true)
obs = Observable(MySpec3(:Axis; title="test"))
f = plot(obs)
elem_1 = [LineElement(; color=:red, linestyle=nothing),
          MarkerElement(; color=:blue, marker='x', markersize=15,
                        strokecolor=:black)]

elem_2 = [PolyElement(; color=:red, strokecolor=:blue, strokewidth=1),
          LineElement(; color=:black, linestyle=:dash)]

elem_3 = LineElement(; color=:green, linestyle=nothing,
                     points=Point2f[(0, 0), (0, 1), (1, 0), (1, 1)])

elem_4 = MarkerElement(; color=:blue, marker='π', markersize=15,
                       points=Point2f[(0.2, 0.2), (0.5, 0.8), (0.8, 0.2)])

elem_5 = PolyElement(; color=:green, strokecolor=:black, strokewidth=2,
                     points=Point2f[(0, 0), (1, 0), (0, 1)])
obs[] = MySpec3(:Slider; range=1:10);

using GLMakie

import Makie.SpecApi as S

struct PlotGrid
    nplots::Tuple{Int,Int}
end

function Makie.convert_arguments(::Type{<:AbstractPlot}, obj::PlotGrid)
    f = S.Figure(; fontsize=30)
    for i in 1:obj.nplots[1]
        for j in 1:obj.nplots[2]
            ax = S.Axis(f[i, j])
            S.lines!(ax,cumsum(randn(1000)))
        end
    end
    return f
end


f = Figure()
s1 = Slider(f[1, 1]; range=1:4)
s2 = Slider(f[1, 2]; range=1:4)
obs = lift(s1.value, s2.value) do i, j
    PlotGrid((i, j))
end

plot(f[2, :], obs)
f


f = S.Figure(; fontsize=30)
for i in 1:2
    for j in 1:2
        ax = S.Axis(f[i, j])
        S.lines!(ax, cumsum(randn(1000)))
    end
end

f = Figure()
fs = f[1, :]
ax1, pl = scatter(fs[1, 1], 1:4)
ax2, pl = scatter(fs[1, 2], 1:4)
f


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
plot(f[1, 1], PlotGrid((1, 1)); color=:red)
plot(f[1, 2], PlotGrid((2, 2)); color=:black)
f


struct LineScatter
    show_lines::Bool
    show_scatter::Bool
end

function Makie.convert_arguments(::Type{<:AbstractPlot}, obj::LineScatter, data...)
    plots = PlotSpec[]
    if obj.show_lines
        push!(plots, S.lines(data...))
    end
    if obj.show_scatter
        push!(plots, S.scatter(data...))
    end
    return plots
end

f = Figure()
ax = Axis(f[1, 1])
# Can be plotted into Axis, since it doesn't create its own axes like FigureSpec
plot!(ax, LineScatter(true, true), 1:4)
plot!(ax, LineScatter(true, false), 2:4)
f
```
