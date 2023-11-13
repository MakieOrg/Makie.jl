import Makie.SpecApi as S

function synchronize()
    # This is very unfortunate, but deletion and updates
    # are async in WGLMakie and there is no way for  use to synchronize on them YET
    if nameof(Makie.CURRENT_BACKEND[]) == :WGLMakie
        sleep(2)
    end
end

function sync_step!(stepper)
    display(stepper.figlike)
    synchronize()
    Makie.step!(stepper)
end

@reference_test "FigureSpec" begin
    f, _, pl = plot(S.Figure())
    st = Makie.Stepper(f)
    sync_step!(st)
    obs = pl[1]
    obs[] = S.Figure([S.Axis(; plots=[S.lines(1:4; color=:black, linewidth=5), S.scatter(1:4; markersize=20)])
                     S.Axis3(; plots=[S.scatter(Rect3f(Vec3f(0), Vec3f(1)); color=:red, markersize=50)])])
    sync_step!(st)
    obs[] = begin
        ax = S.Axis(; plots=[S.scatter(1:4)])
        ax2 = S.Axis3(; title="Title 0", plots=[S.scatter(1:4; color=1:4, markersize=20)])
        c = S.Colorbar(; limits=(0, 1), colormap=:heat)
        S.Figure([ax ax2 c])
    end
    sync_step!(st)

    obs[] = begin
        p1 = S.scatter(1:4; markersize=50)
        ax = S.Axis(; plots=[p1], title="Title 1")
        p2 = S.scatter(2:4; color=1:3, markersize=30)
        ax2 = S.Axis3(; plots=[p2])
        c = S.Colorbar(; limits=(2, 10), colormap=:viridis, width=50)
        S.Figure([ax ax2 c])
    end
    sync_step!(st)
    ax1 = S.Axis(; plots=[S.scatter(1:4; markersize=20), S.lines(1:4; color=:darkred, linewidth=6)])
    ax2 = S.Axis3(; plots=[S.scatter(Rect3f(Vec3f(0), Vec3f(1)); color=(:red, 0.5), markersize=30)
    obs[] = S.Figure([ax1 ax2])
    sync_step!(st)

    elem_1 = [LineElement(; color=:red, linestyle=nothing),
              MarkerElement(; color=:blue, marker='x', markersize=15,
                            strokecolor=:black)]

    elem_2 = [PolyElement(; color=:red, strokecolor=:blue, strokewidth=1),
              LineElement(; color=:black, linestyle=:dash)]

    elem_3 = LineElement(; color=:green, linestyle=nothing,
                         points=Point2f[(0, 0), (0, 1), (1, 0), (1, 1)])

    obs[] = begin
        S.Figure(S.Legend([elem_1, elem_2, elem_3], ["elem 1", "elem 2", "elem 3"], "Legend Title"))
    end
    sync_step!(st)

    obs[] = begin
        l = S.Legend([elem_1, elem_2], ["elem 1", "elem 2"], "New Title")
        S.Figure(l)
    end
    sync_step!(st)

    obs[] = S.Figure()
    sync_step!(st)

    st
end

struct PlotGrid
    nplots::Tuple{Int,Int}
end

function Makie.convert_arguments(::Type{<:AbstractPlot}, obj::PlotGrid)
    plots = [S.lines(1:4; linewidth=5, color=Cycled(1)),
             S.lines(2:5; linewidth=7, color=Cycled(2))]
    axes = [S.Axis(; plots=plots) for i in 1:obj.nplots[1], j in 1:obj.nplots[2]]
    return S.Figure(axes; fontsize=30)
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
    f
    ax, p2 = plot(f[1, 2], LineScatter(true, true), 1:4)
    st = Makie.Stepper(f)
    sync_step!(st)
    p1[1] = PlotGrid((2, 2))
    p2[1] = LineScatter(false, true)
    sync_step!(st)

    p1[1] = PlotGrid((3, 3))
    p2[1] = LineScatter(true, false)
    sync_step!(st)

    p1[1] = PlotGrid((2, 1))
    p2[1] = LineScatter(true, true)
    sync_step!(st)
    st
end
