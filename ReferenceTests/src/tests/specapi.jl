import Makie.SpecApi as S

function synchronize()
    # This is very unfortunate, but deletion and updates
    # are async in WGLMakie and there is no way for  use to synchronize on them YET
    return if nameof(Makie.CURRENT_BACKEND[]) == :WGLMakie
        sleep(2)
    end
end

function sync_step!(stepper)
    synchronize()
    return Makie.step!(stepper)
end

@reference_test "FigureSpec" begin
    f, _, pl = plot(S.GridLayout())
    st = Makie.Stepper(f)
    sync_step!(st)
    pl[1] = S.GridLayout(
        [
            S.Axis(; plots = [S.Lines(1:4; color = :black, linewidth = 5), S.Scatter(1:4; markersize = 20)])
            S.Axis3(; plots = [S.Scatter(Rect3f(Vec3f(0), Vec3f(1)); color = :red, markersize = 50)])
        ]
    )
    sync_step!(st)
    pl[1] = begin
        ax = S.Axis(; plots = [S.Scatter(1:4)])
        ax2 = S.Axis3(; title = "Title 0", plots = [S.Scatter(1:4; color = 1:4, markersize = 20)])
        c = S.Colorbar(; limits = (0, 1), colormap = :heat)
        S.GridLayout([ax ax2 c])
    end
    sync_step!(st)

    pl[1] = begin
        p1 = S.Scatter(1:4; markersize = 50)
        ax = S.Axis(; plots = [p1], title = "Title 1")
        p2 = S.Scatter(2:4; color = 1:3, markersize = 30)
        ax2 = S.Axis3(; plots = [p2])
        c = S.Colorbar(; limits = (2, 10), colormap = :viridis, width = 50)
        S.GridLayout([ax ax2 c])
    end
    sync_step!(st)
    ax1 = S.Axis(; plots = [S.Scatter(1:4; markersize = 20), S.Lines(1:4; color = :darkred, linewidth = 6)])
    ax2 = S.Axis3(; plots = [S.Scatter(Rect3f(Vec3f(0), Vec3f(1)); color = (:red, 0.5), markersize = 30)])
    pl[1] = S.GridLayout([ax1 ax2])
    sync_step!(st)

    elem_1 = [
        LineElement(; color = :red, linestyle = nothing),
        MarkerElement(;
            color = :blue, marker = 'x', markersize = 15,
            strokecolor = :black
        ),
    ]

    elem_2 = [
        PolyElement(; color = :red, strokecolor = :blue, strokewidth = 1),
        LineElement(; color = :black, linestyle = :dash),
    ]

    elem_3 = LineElement(;
        color = :green, linestyle = nothing,
        points = Point2f[(0, 0), (0, 1), (1, 0), (1, 1)]
    )

    pl[1] = begin
        S.GridLayout(S.Legend([elem_1, elem_2, elem_3], ["elem 1", "elem 2", "elem 3"], "Legend Title"))
    end
    sync_step!(st)

    pl[1] = begin
        l = S.Legend([elem_1, elem_2], ["elem 1", "elem 2"], "New Title")
        S.GridLayout(l)
    end
    sync_step!(st)

    pl[1] = S.GridLayout()
    sync_step!(st)

    st
end

struct PlotGrid
    nplots::Tuple{Int, Int}
end

function Makie.convert_arguments(::Type{<:AbstractPlot}, obj::PlotGrid)
    plots = [
        S.Lines(1:4; linewidth = 5, color = Cycled(1)),
        S.Lines(2:5; linewidth = 7, color = Cycled(2)),
    ]
    axes = [S.Axis(; plots = plots) for i in 1:obj.nplots[1], j in 1:obj.nplots[2]]
    return S.GridLayout(axes)
end

struct LineScatter
    show_lines::Bool
    show_scatter::Bool
end
function Makie.convert_arguments(::Type{<:AbstractPlot}, obj::LineScatter, data...)
    plots = PlotSpec[]
    if obj.show_lines
        push!(plots, S.Lines(data...; linewidth = 5))
    end
    if obj.show_scatter
        push!(plots, S.Scatter(data...; markersize = 20))
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

AxNoTicks(; kw...) = S.Axis(;
    xticksvisible = false,
    yticksvisible = false, yticklabelsvisible = false,
    xticklabelsvisible = false, kw...
)

@reference_test "Moving Plots in SpecApi" begin
    pl1 = S.Heatmap((1, 4), (1, 4), Makie.peaks(50))
    pl2 = S.Scatter(1:4; color = 1:4, markersize = 30, strokewidth = 1, strokecolor = :black)
    ax1 = AxNoTicks(; plots = [pl1, pl2])
    grid = S.GridLayout(AxNoTicks())
    f, _, pl = plot(S.GridLayout([ax1 grid]; colgaps = Fixed(4)); figure = (; figure_padding = 2, size = (500, 100)))
    cb1 = copy(colorbuffer(f))

    pl1 = S.Heatmap((1, 4), (1, 4), Makie.peaks(50); colormap = :inferno)
    ax1 = AxNoTicks()
    grid = S.GridLayout(AxNoTicks(; plots = [pl1, pl2]))
    pl[1] = S.GridLayout([ax1 grid]; colgaps = Fixed(4))
    cb2 = copy(colorbuffer(f))

    pl1 = S.Heatmap((1, 4), (1, 4), Makie.peaks(50))
    ax1 = AxNoTicks(; plots = [pl1])
    ax2 = S.GridLayout(AxNoTicks(; plots = [pl2]))
    pl[1] = S.GridLayout([ax1 ax2]; colgaps = Fixed(4))
    cb3 = copy(colorbuffer(f))

    imgs = hcat(rotr90.((cb1, cb2, cb3))...)
    s = Scene(; size = size(imgs))
    image!(s, imgs; space = :pixel)
    s
end

function to_plot(plots)
    axes = map(permutedims(plots)) do plot
        ax = AxNoTicks(; plots = [plot])
        return S.GridLayout([ax S.Colorbar(plot)])
    end
    return S.GridLayout(axes)
end

@reference_test "Colorbar from Plots" begin
    data = vcat((1:4)', (4:-1:1)')
    plots = [
        S.Heatmap(data),
        S.Image(data),
        S.Lines(1:4; linewidth = 4, color = 1:4),
        S.Scatter(1:4; markersize = 20, color = 1:4),
    ]
    obs = Observable(to_plot(plots))
    fig = plot(obs; figure = (; size = (700, 150)))
    img1 = copy(colorbuffer(fig))
    plots = [
        S.Heatmap(data; colormap = :inferno),
        S.Image(data; colormap = :inferno),
        S.Lines(1:4; linewidth = 4, color = 1:4, colormap = :inferno),
        S.Scatter(1:4; markersize = 20, color = 1:4, colormap = :inferno),
    ]
    obs[] = to_plot(plots)
    img2 = copy(colorbuffer(fig))

    plots = [
        S.Heatmap(data; colorrange = (2, 3)),
        S.Image(data; colorrange = (2, 3)),
        S.Lines(1:4; linewidth = 4, color = 1:4, colorrange = (2, 3)),
        S.Scatter(1:4; markersize = 20, color = 1:4, colorrange = (2, 3)),
    ]
    obs[] = to_plot(plots)
    img3 = copy(colorbuffer(fig))

    imgs = hcat(rotr90.((img3, img2, img1))...)
    s = Scene(; size = size(imgs))
    image!(s, imgs; space = :pixel)
    s
end

@reference_test "Axis links" begin
    axiis = broadcast(1:2, (1:2)') do x, y
        S.Axis(; title = "$x, $y")
    end
    f, _, pl = plot(
        S.GridLayout(axiis; xaxislinks = vec(axiis[1:2, 1]), yaxislinks = vec(axiis[1:2, 2]));
        figure = (; size = (500, 250)),
    )
    for ax in f.content[[1, 3]]
        limits!(ax, 2, 3, 2, 3)
    end

    img1 = rotr90(colorbuffer(f; update = false))
    for ax in f.content
        limits!(ax, 0, 10, 0, 10)
    end
    pl[1] = S.GridLayout(axiis; xaxislinks = vec(axiis[1:2, 2]), yaxislinks = vec(axiis[1:2, 1]))
    for ax in f.content[[1, 3]]
        limits!(ax, 2, 3, 2, 3)
    end
    sleep(0.1)
    img2 = rotr90(colorbuffer(f; update = false))
    large = hcat(img2, img1)
    s = Scene(; size = size(large))
    image!(s, large; space = :pixel)
    s
end

# This is the first test, repackaged in a Block
# Currently Blocks just drop everything and handle the SpecApi input if they get
# one. So any (argument-less) block works here
@reference_test "Spec in a Block" begin
    f, b1 = Box(S.GridLayout())
    b2 = Box(f[1, 2], S.GridLayout())
    st = Makie.Stepper(f)
    sync_step!(st)
    b1[1] = S.GridLayout(
        [
            S.Axis(; plots = [S.Lines(1:4; color = :black, linewidth = 5), S.Scatter(1:4; markersize = 20)])
            S.Axis3(; plots = [S.Scatter(Rect3f(Vec3f(0), Vec3f(1)); color = :red, markersize = 50)])
        ]
    )
    sync_step!(st)
    b2[1] = begin
        ax = S.Axis(; plots = [S.Scatter(1:4)])
        ax2 = S.Axis3(; title = "Title 0", plots = [S.Scatter(1:4; color = 1:4, markersize = 20)])
        c = S.Colorbar(; limits = (0, 1), colormap = :heat)
        S.GridLayout([S.GridLayout([ax c]), ax2])
    end
    sync_step!(st)

    b1[1] = begin
        p1 = S.Scatter(1:4; markersize = 50)
        ax = S.Axis(; plots = [p1], title = "Title 1")
        p2 = S.Scatter(2:4; color = 1:3, markersize = 30)
        ax2 = S.Axis3(; plots = [p2])
        c = S.Colorbar(; limits = (2, 10), colormap = :viridis, width = 50)
        S.GridLayout([S.GridLayout([ax c]), ax2])
    end

    ax1 = S.Axis(; plots = [S.Scatter(1:4; markersize = 20), S.Lines(1:4; color = :darkred, linewidth = 6)])
    ax2 = S.Axis3(; plots = [S.Scatter(Rect3f(Vec3f(0), Vec3f(1)); color = (:red, 0.5), markersize = 30)])
    b2[1] = S.GridLayout([ax1, ax2])
    sync_step!(st)

    elem_1 = [
        LineElement(; color = :red, linestyle = nothing),
        MarkerElement(;
            color = :blue, marker = 'x', markersize = 15,
            strokecolor = :black
        ),
    ]

    elem_2 = [
        PolyElement(; color = :red, strokecolor = :blue, strokewidth = 1),
        LineElement(; color = :black, linestyle = :dash),
    ]

    elem_3 = LineElement(;
        color = :green, linestyle = nothing,
        points = Point2f[(0, 0), (0, 1), (1, 0), (1, 1)]
    )

    b1[1] = begin
        S.GridLayout(S.Legend([elem_1, elem_2, elem_3], ["elem 1", "elem 2", "elem 3"], "Legend Title"))
    end

    b2[1] = begin
        l = S.Legend([elem_1, elem_2], ["elem 1", "elem 2"], "New Title")
        S.GridLayout(l)
    end
    sync_step!(st)

    b1[1] = S.Box(color = :lightblue)
    b2[1] = S.Box(color = :lightgreen)
    sync_step!(st)

    st
end

struct MultiData
    plottype::Symbol
    show_dim_distributions::Bool
    dim_distribution_plot_type::Symbol
    sets::Vector{Vector{<:Makie.VecTypes{2}}}
end

function Makie.convert_arguments(::Type{<:Makie.Block}, multidata::MultiData)
    colors = Makie.wong_colors()
    plots = map(enumerate(multidata.sets)) do (i, data)
        return PlotSpec(multidata.plottype, data, color = colors[mod1(i, end)])
    end
    main_axis = S.Axis(; plots = plots)

    if multidata.show_dim_distributions
        no_decorations = (
            xgridvisible = false, ygridvisible = false,
            xticksvisible = false, yticksvisible = false,
            xticklabelsvisible = false, yticklabelsvisible = false,
            xlabelvisible = false, ylabelvisible = false,
        )
        plotsym = multidata.dim_distribution_plot_type

        column_axes = map(enumerate(multidata.sets)) do (i, data)
            color = colors[mod1(i, end)]
            plt = PlotSpec(plotsym, first.(data), color = color)
            return S.Axis(; plots = [plt], yreversed = true, height = 50, no_decorations...)
        end
        column = S.GridLayout(column_axes)

        row_axes = map(enumerate(multidata.sets)) do (i, data)
            color = colors[mod1(i, end)]
            dir = ifelse(plotsym === :Density, :y, :x)
            plt = PlotSpec(plotsym, last.(data), direction = dir, color = color)
            return S.Axis(; plots = [plt], width = 50, no_decorations...)
        end
        row = S.GridLayout(reshape(row_axes, (1, length(row_axes))))

        return S.GridLayout(
            [main_axis row; column S.GridLayout()],
            xaxislinks = [main_axis, column_axes...],
            yaxislinks = [main_axis, row_axes...]
        )
    else
        return main_axis
    end
end

@reference_test "Block SpecApi Conversion" begin
    fig = Figure()

    # Static parts of the figure
    Label(fig[1, 1], "Main plot type", tellwidth = false)
    m1 = Menu(fig[2, 1], options = [:Scatter, :Lines])
    Label(fig[1, 2][1, 1], "Distribution plot type", tellwidth = false)
    t = Toggle(fig[1, 2][1, 2])
    m2 = Menu(fig[2, 2], options = [:Hist, :Density])

    # Dynamic description of the axis layout
    data1 = [Point2f(cos(x), sin(x)) / (1 + 0.1x) for x in range(0, 30, 300)]
    data2 = [Point2f(x / 10 - 1, cos(x)) for x in range(0, 20, 120)]
    dataset = map(m1.selection, t.active, m2.selection) do mainplot, showdist, distplot
        return MultiData(mainplot, showdist, distplot, [data1, data2])
    end

    # block containing the GridLayoutSpec/BlockSpec produced by the `MultiData`
    # conversion.
    block = Makie.Block(fig[3, 1:2], dataset)

    # Limits don't re-compute automatically, so we need to trigger them manually
    # lower priority to make sure the call back is always called last
    on(dataset; priority = -1) do x
        foreach(autolimits!, block.blocks)
    end

    st = Makie.Stepper(fig)
    step!(st)

    t.active[] = true
    step!(st)

    m2.i_selected[] = 2
    step!(st)

    m1.i_selected[] = 2
    step!(st)

    t.active[] = false
    step!(st)
end
