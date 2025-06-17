@testset "Basic Figures" begin
    fig = Figure()
    @test current_figure() === fig

    fig2 = Figure()
    @test fig !== fig2
    @test current_figure() === fig2

    current_figure!(fig)
    @test current_figure() === fig
end

@testset "FigureAxisPlot" begin
    fap = scatter(rand(100, 2))
    @test fap isa Makie.FigureAxisPlot
    fig, ax, p = scatter(rand(100, 2))
    @test fig isa Figure
    @test ax isa Axis
    @test p isa Scatter
    @test_throws ArgumentError lines!(fap, 1:10)

    fig2, ax2, p2 = scatter(rand(100, 3))
    @test fig2 isa Figure
    @test ax2 isa LScene # 3d plot
    @test p2 isa Scatter
end

@testset "AxisPlot and Axes" begin
    fig = Figure()
    @test current_axis() === nothing
    @test current_figure() === fig

    gridpos = fig[1, 1]
    @test gridpos isa GridPosition
    ap = scatter(gridpos, rand(100, 2))
    @test ap isa Makie.AxisPlot
    @test current_axis() === ap.axis
    @test_throws ArgumentError lines!(ap, 1:10)

    ax2, p2 = scatter(fig[1, 2], rand(100, 2))
    @test ax2 isa Axis
    @test p2 isa Scatter
    @test current_axis() === ax2

    ax3, p3 = scatter(fig[1, 3], rand(100, 3))
    @test ax3 isa LScene
    @test p3 isa Scatter
    @test current_axis() === ax3

    @test ap.axis in fig.content
    @test ax2 in fig.content
    @test ax3 in fig.content

    current_axis!(fig, ax2)
    @test current_axis(fig) === ax2
    @test current_axis() === ax2

    fig2 = Figure()
    @test current_figure() === fig2
    @test current_axis() === nothing
    @test current_axis(fig) === ax2

    # current axis can also switch current figure when called without figure argument
    current_axis!(ax2)
    @test current_axis() === ax2
    @test current_figure() === fig

end

@testset "Deleting from figures" begin
    fig = Figure()
    ax = fig[1, 1] = Axis(fig)
    @test current_axis() === ax
    @test ax in fig.content
    delete!(ax)
    @test !(ax in fig.content)
    @test ax.parent === nothing
    @test current_axis() === nothing
end

@testset "Clearing figures" begin
    fig = Figure()
    Label(fig[1, 1], "test")
    ax = Axis(fig[2, 1])
    scatter!(ax, rand(10))

    @test !isempty(fig.scene.children)
    @test !isempty(ax.scene.plots)
    @test !isempty(fig.layout.content)
    @test !isempty(fig.content)
    @test current_axis() === ax

    empty!(fig)

    @test isempty(fig.scene.children)
    @test isempty(ax.scene.plots)
    @test isempty(fig.layout.content)
    @test isempty(fig.content)
    @test current_axis() === nothing
end

@testset "Getting figure content" begin
    fig = Figure()
    ax = fig[1, 1] = Axis(fig)
    @test contents(fig[1, 1], exact = true) == [ax]
    @test contents(fig[1, 1], exact = false) == [ax]
    @test contents(fig[1:2, 1:2], exact = true) == []
    @test contents(fig[1:2, 1:2], exact = false) == [ax]

    @test content(fig[1, 1]) == ax
    @test_throws ErrorException content(fig[2, 2])
    @test_throws ErrorException content(fig[1:2, 1:2])

    label = fig[1, 1] = Label(fig)
    @test contents(fig[1, 1], exact = true) == [ax, label]
    @test contents(fig[1, 1], exact = false) == [ax, label]
    @test contents(fig[1:2, 1:2], exact = true) == []
    @test contents(fig[1:2, 1:2], exact = false) == [ax, label]

    @test_throws ErrorException content(fig[1, 1])

    ax2 = fig[1, 2][1, 1] = Axis(fig)
    @test contents(fig[1, 2][1, 1], exact = true) == [ax2]
    @test contents(fig[1, 2][1, 1], exact = false) == [ax2]
    @test contents(fig[1, 2][1:2, 1:2], exact = true) == []
    @test contents(fig[1, 2][1:2, 1:2], exact = false) == [ax2]

    label2 = fig[1, 2][1, 1] = Label(fig)
    @test contents(fig[1, 2][1, 1], exact = true) == [ax2, label2]
    @test contents(fig[1, 2][1, 1], exact = false) == [ax2, label2]
    @test contents(fig[1, 2][1:2, 1:2], exact = true) == []
    @test contents(fig[1, 2][1:2, 1:2], exact = false) == [ax2, label2]

    @test_throws ErrorException content(fig[1, 2][1, 1])
end

@testset "Nested axis assignment" begin
    fig = Figure()
    Axis(fig[1, 1]) isa Axis
    Axis(fig[1, 1][2, 3]) isa Axis
    Axis(fig[1, 1][2, 3][4, 5]) isa Axis
    @test_throws ArgumentError scatter(fig[1, 1])
    @test_throws ArgumentError scatter(fig[1, 1][2, 3])
    @test_throws ArgumentError scatter(fig[1, 1][2, 3][4, 5])
    scatter(fig[1, 2], 1:10) isa Makie.AxisPlot
    scatter(fig[1, 1][1, 1], 1:10) isa Makie.AxisPlot
    scatter(fig[1, 1][1, 1][1, 1], 1:10) isa Makie.AxisPlot

    fig = Figure()
    fig[1, 1] = GridLayout()
    Axis(fig[1, 1][1, 1]) isa Axis
    fig[1, 1] = GridLayout()
    @test_throws ErrorException Axis(fig[1, 1][1, 1])
end

@testset "Not implemented error" begin
    @test_throws ErrorException("Not implemented for scatter. You might want to put:  `using Makie` into your code!") scatter()
end

@testset "Figure and axis kwargs validation" begin
    @test_throws ArgumentError lines(1:10, axis = (aspect = DataAspect()), figure = (size = (100, 100)))
    @test_throws ArgumentError lines(1:10, figure = (size = (100, 100)))
    @test_throws ArgumentError lines(1:10, axis = (aspect = DataAspect()))

    # these just shouldn't error
    lines(1:10, axis = (aspect = DataAspect(),))
    lines(1:10, axis = Attributes(aspect = DataAspect()))
    lines(1:10, axis = Dict(:aspect => DataAspect()))

    f = Figure()
    @test_throws ArgumentError lines(f[1, 1], 1:10, axis = (aspect = DataAspect()))
    @test_throws ArgumentError lines(f[1, 1][2, 2], 1:10, axis = (aspect = DataAspect()))
end

@testset "show with a backend" begin
    fig = Figure()
    io = IOBuffer()
    # if there were no show method with backend and update kwargs then MethodError would be thrown instead
    @test_throws ErrorException show(io, MIME"text/plain"(), fig, backend = missing, update = false)
end
