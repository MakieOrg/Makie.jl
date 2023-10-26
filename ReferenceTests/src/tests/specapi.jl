import Makie.SpecApi as S

@reference_test "FigureSpec" begin
    f, _, pl = plot(S.Figure())
    st = Makie.Stepper(f)
    obs = pl[1]
    obs[] = S.Figure(S.Axis((1, 1);
                            plots=[S.lines(1:4; color=:black, linewidth=5), S.scatter(1:4; markersize=20)]),
                     S.Axis3((1, 2); plots=[S.scatter(rand(Point3f, 10); color=:red, markersize=50)]))
    Makie.step!(st)
    obs[] = begin
        f = S.Figure()
        ax = S.Axis(f[1, 1])
        S.scatter!(ax, 1:4)
        ax2 = S.Axis3(f[1, 2]; title="Title 0")
        S.scatter!(ax2, 1:4; color=1:4, markersize=20)
        S.Colorbar(f[1, 3]; limits=(0, 1), colormap=:heat)
        f
    end
    Makie.step!(st)

    obs[] = begin
        f = S.Figure()
        ax = S.Axis(f[1, 1]; title="Title 1")
        S.scatter!(ax, 1:4; markersize=50)
        ax2 = S.Axis3(f[1, 2])
        S.scatter!(ax2, 2:4; color=1:4, markersize=30)
        S.Colorbar(f[1, 3]; limits=(2, 10), colormap=:viridis, width=50)
        f
    end
    Makie.step!(st)

    obs[] = S.Figure(S.Axis((1, 1);
                            plots=[S.scatter(1:4; markersize=20), S.lines(1:4; color=:darkred, linewidth=6)]),
                     S.Axis3((1, 2); plots=[S.scatter(rand(Point3f, 10); color=(:red, 0.5), markersize=30)]))
    Makie.step!(st)


    elem_1 = [LineElement(; color=:red, linestyle=nothing),
              MarkerElement(; color=:blue, marker='x', markersize=15,
                            strokecolor=:black)]

    elem_2 = [PolyElement(; color=:red, strokecolor=:blue, strokewidth=1),
              LineElement(; color=:black, linestyle=:dash)]

    elem_3 = LineElement(; color=:green, linestyle=nothing,
                         points=Point2f[(0, 0), (0, 1), (1, 0), (1, 1)])

    obs[] = begin
        f = S.Figure()
        S.Legend(f[1, 1], [elem_1, elem_2, elem_3], ["elem 1", "elem 2", "elem 3"], "Legend Title")
        f
    end
    Makie.step!(st)

    obs[] = begin
        f = S.Figure()
        S.Legend(f[1, 1], [elem_1, elem_2], ["elem 1", "elem 2"], "New Title")
        f
    end
    Makie.step!(st)

    obs[] = S.Figure()
    Makie.step!(st)

    st
end

struct PlotGrid
    nplots::Tuple{Int,Int}
end

function Makie.convert_arguments(::Type{<:AbstractPlot}, obj::PlotGrid)
    f = S.Figure(; fontsize=30)
    for i in 1:obj.nplots[1]
        for j in 1:obj.nplots[2]
            ax = S.Axis(f[i, j])
            S.lines!(ax, 1:4; linewidth=5)
            S.lines!(ax, 2:5; linewidth=7)
        end
    end
    return f
end
struct LineScatter
    show_lines::Bool
    show_scatter::Bool
end
function Makie.convert_arguments(::Type{<:AbstractPlot}, obj::LineScatter, data...)
    plots = PlotSpec[]
    if obj.show_lines
        push!(plots, S.lines(data...; linewidth=5))
    end
    if obj.show_scatter
        push!(plots, S.scatter(data...; markersize=20))
    end
    return plots
end

@reference_test "SpecApi in convert_arguments" begin
    f = Figure()
    p1 = plot(f[1, 1], PlotGrid((1, 1)))
    ax, p2 = plot(f[1, 2], LineScatter(true, true), 1:4)
    st = Makie.Stepper(f)
    p1[1] = PlotGrid((2, 2))
    p2[1] = LineScatter(false, true)
    Makie.step!(st)

    p1[1] = PlotGrid((3, 3))
    p2[1] = LineScatter(true, false)
    Makie.step!(st)

    p1[1] = PlotGrid((2, 1))
    p2[1] = LineScatter(true, true)
    Makie.step!(st)
    st
end
