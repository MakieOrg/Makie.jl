using DataFrames
import Makie.PlotspecApi as P
using Random

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
    fig = P.Figure()
    mpalette = [:circle, :star4, :xcross, :diamond]
    cpalette = Makie.wong_colors()
    cat_styles = [:color => cpalette, :marker => mpalette, :markersize => [5, 10, 20, 30], :marker => ['c', 'x', 'y', 'm']]
    cat_values = [unique(data[!, cat]) for cat in categorical_vars]
    scatter_styles = Dict([cat => (style[1] => Dict(zip(vals, style[2]))) for (style, vals, cat) in zip(cat_styles, cat_values, categorical_vars)])

    continous_styles = [:viridis, :heat, :rainbow, :turku50]
    continuous_values = [extrema(data[!, con]) for con in continuous_vars]
    line_styles = Dict([cat => (; colormap=style, colorrange=limits) for (style, limits, cat) in zip(continous_styles, continuous_values, continuous_vars)])
    ax = P.Axis(fig[1, 1])
    for var in categorical_vars
        values = data[!, var]
        kw, vals = scatter_styles[var]
        args = [kw => map(x-> vals[x], values)]
        d = data[!, Symbol("data_$var")]
        P.scatter(ax, d; args...)
    end
    for var in continuous_vars
        points = data[!, var]
        P.lines(ax, points; line_styles[var]..., color=points)
    end
    fig
end
using WGLMakie, JSServe
rm(JSServe.bundle_path(JSServe.JSServeLib))
begin
    data = gen_data(1000)
    continous_vars = Observable(["continuous2", "continuous3"])
    categorical_vars = Observable(["condition2", "condition4"])
    fig = nothing
    obs = lift(continous_vars, categorical_vars) do con_vars, cat_vars
        plot_data(data, cat_vars, con_vars)
    end

    fig = Makie.update_fig(Figure(), obs)
    display(fig)
end
start_size = Base.summarysize(fig) / 10^6

for i in 1:1000
    all_vars = ["continuous$i" for i in 2:5]
    all_cond_vars = ["condition$i" for i in 2:5]

    continous_vars[] =  shuffle!(all_vars[unique(rand(1:4, rand(1:4)))])
    categorical_vars[] = shuffle!(all_cond_vars[unique(rand(1:4, rand(1:4)))])
    yield()
end
end_size = Base.summarysize(fig) / 10^6

obs[] = P.Figure()
obs[] = P.Figure(P.Axis((1, 1), P.scatter(1:4), P.lines(1:4; color=:red)),
                 P.Axis3((1, 2), P.scatter(rand(Point3f, 10); color=:red)))



using Makie
import Makie.PlotspecApi as P
using GLMakie
GLMakie.activate!(; float=true)

function test(f_obs)
    f_obs[] = begin
        f = P.Figure()
        ax = P.Axis(f[1, 1])
        P.scatter(ax, 1:4)
        ax2 = P.Axis3(f[1, 2])
        P.scatter(ax2, rand(Point3f, 10); color=1:10, markersize=20)
        P.Colorbar(f[1, 3]; limits=(0, 1), colormap=:heat)
        f
    end
    yield()
    f_obs[] = begin
        P.Figure(P.Axis((1, 1),
                        P.scatter(1:4),
                        P.lines(1:4; color=:red)),
                 P.Axis3((1, 2), P.scatter(rand(Point3f, 10); color=:red)))
    end
    return yield()
end
test(obs)

begin
    f = P.Figure()
    f_obs = Observable(f)
    fig = Makie.update_fig(Figure(), f_obs)
end
f_obs[] = begin
    f = P.Figure()
    ax = P.Axis(f[1, 1])
    P.scatter(ax, 0:0.01:1, 0:0.01:1)
    P.scatter(ax, rand(Point2f, 10); color=:green, markersize=20)
    P.scatter(ax, rand(Point2f, 10); color=:red, markersize=20)
    f
end;

for i in 1:20
    f_obs[] = begin
        f = P.Figure()
        ax = P.Axis(f[1, 1])
        P.scatter(ax, 1:4)
        ax2 = P.Axis3(f[1, 2])
        P.scatter(ax2, rand(Point3f, 10); color=1:10, markersize=20)
        P.scatter(ax2, rand(Point3f, 10); color=1:10, markersize=20)
        f
    end
    yield()
    f_obs[] = begin
        P.Figure(P.Axis((1, 1),
                        P.scatter(1:4),
                        P.lines(1:4; color=:red)),
                 P.Axis3((1, 2), P.scatter(rand(Point3f, 10); color=:red)))
    end
    yield()
end
[GC.gc(true) for i in 1:5]

using JSServe, WGLMakie
rm(JSServe.bundle_path(WGLMakie.WGL))
rm(JSServe.bundle_path(JSServe.JSServeLib))

App() do
    s = JSServe.Slider(1:20)
    data = gen_data(1000)
    continous_vars = Observable(["continuous2", "continuous3"])
    categorical_vars = Observable(["condition2", "condition4"])
    fig = nothing
    obs = lift(continous_vars, categorical_vars) do con_vars, cat_vars
        return plot_data(data, cat_vars, con_vars)
    end
    on(s.value) do val
        all_vars = ["continuous$i" for i in 2:5]
        all_cond_vars = ["condition$i" for i in 2:5]
        continous_vars[] = shuffle!(all_vars[unique(rand(1:4, rand(1:4)))])
        categorical_vars[] = shuffle!(all_cond_vars[unique(rand(1:4, rand(1:4)))])
        return
    endf
    fig = Makie.update_fig(Figure(), obs)
    return DOM.div(s, fig)
end

using WGLMakie, Test

begin
    f = Figure()
    l = Legend(f[1, 1], [LineElement(; color=:red)], ["Line"])
    s = display(f)
    @test f.scene.current_screens[1] === s
    @test f.scene.children[1].current_screens[1] === s
    @test f.scene.children[1].children[1].current_screens[1] === s
    delete!(l)
    @test f.scene.current_screens[1] === s
    ## legend should be gone
    ax = Axis(f[1, 1])
    scatter!(ax, 1:4; markersize=200, color=1:4)
    f
end

using SnoopCompileCore, WGLMakie
result = @snoopi_deep scatter(1:4; color=1:4, colormap=:turbo, markersize=20, visible=true);
using SnoopCompile, ProfileView; ProfileView.view(flamegraph(result))
