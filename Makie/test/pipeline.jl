# extracted from interfaces.jl
function test_copy(; kw...)
    scene = Scene()
    return Makie.merged_get!(
        () -> Makie.default_theme(scene, Lines),
        :lines, scene, Attributes(kw)
    )
end

function test_copy2(attr; kw...)
    return merge!(Attributes(kw), attr)
end

@testset "don't copy in theme merge" begin
    x = Observable{Any}(1)
    res = test_copy(linewidth = x)
    @test res.linewidth === x
end

@testset "don't copy observables in when calling merge!" begin
    x = Observable{Any}(1)
    res = test_copy2(Attributes(linewidth = x))
    @test res.linewidth === x
end

@testset "don't copy attributes in recipe" begin
    fig = Figure()
    ax = Axis(fig[1, 1])
    list = Observable{Any}([1, 2, 3, 4])
    xmax = Observable{Any}([0.25, 0.5, 0.75, 1])

    p = hlines!(ax, list, xmax = xmax, color = :blue)
    @test p.args[] === (list[],)
    @test p.xmax[] === xmax[]
    fig
end


@testset "Figure / Axis / Gridposition creation test" begin
    @testset "proper errors for wrongly used (non) mutating plot functions" begin
        f = Figure()
        x = range(0, 10, length = 100)
        @test_throws ErrorException scatter!(f[1, 1], x, sin)
        @test_throws ErrorException scatter!(f[1, 2][1, 1], x, sin)
        @test_throws ErrorException scatter!(f[1, 2][1, 2], x, sin)

        @test_throws ErrorException meshscatter!(f[2, 1], x, sin; axis = (type = Axis3,))
        @test_throws ErrorException meshscatter!(f[2, 2][1, 1], x, sin; axis = (type = Axis3,))
        @test_throws ErrorException meshscatter!(f[2, 2][1, 2], x, sin; axis = (type = Axis3,))

        @test_throws ErrorException meshscatter!(f[3, 1], rand(Point3f, 10); axis = (type = LScene,))
        @test_throws ErrorException meshscatter!(f[3, 2][1, 1], rand(Point3f, 10); axis = (type = LScene,))
        @test_throws ErrorException meshscatter!(f[3, 2][1, 2], rand(Point3f, 10); axis = (type = LScene,))

        sub = f[4, :]
        f = Figure()
        @test_throws ErrorException scatter(Axis(f[1, 1]), x, sin)
        @test_throws ErrorException meshscatter(Axis3(f[1, 1]), x, sin)
        @test_throws ErrorException meshscatter(LScene(f[1, 1]), rand(Point3f, 10))

        f
    end

    @testset "creating plot object for different (non) mutating plotting functions into figure" begin
        f = Figure()
        x = range(0, 10; length = 100)
        ax, pl = scatter(f[1, 1], x, sin)
        @test ax isa Axis
        @test pl isa AbstractPlot

        ax, pl = scatter(f[1, 2][1, 1], x, sin)
        @test ax isa Axis
        @test pl isa AbstractPlot

        ax, pl = scatter(f[1, 2][1, 2], x, sin)
        @test ax isa Axis
        @test pl isa AbstractPlot

        ax, pl = meshscatter(f[2, 1], x, sin; axis = (type = Axis3,))
        @test ax isa Axis3
        @test pl isa AbstractPlot

        ax, pl = meshscatter(f[2, 2][1, 1], x, sin; axis = (type = Axis3,))
        @test ax isa Axis3
        @test pl isa AbstractPlot
        ax, pl = meshscatter(f[2, 2][1, 2], x, sin; axis = (type = Axis3,))
        @test ax isa Axis3
        @test pl isa AbstractPlot

        ax, pl = meshscatter(f[3, 1], rand(Point3f, 10); axis = (type = LScene,))
        @test ax isa LScene
        @test pl isa AbstractPlot
        ax, pl = meshscatter(f[3, 2][1, 1], rand(Point3f, 10); axis = (type = LScene,))
        @test ax isa LScene
        @test pl isa AbstractPlot
        ax, pl = meshscatter(f[3, 2][1, 2], rand(Point3f, 10); axis = (type = LScene,))
        @test ax isa LScene
        @test pl isa AbstractPlot

        sub = f[4, :]

        pl = scatter!(Axis(sub[1, 1]), x, sin)
        @test pl isa AbstractPlot
        pl = meshscatter!(Axis3(sub[1, 2]), x, sin)
        @test pl isa AbstractPlot
        pl = meshscatter!(LScene(sub[1, 3]), rand(Point3f, 10))
        @test pl isa AbstractPlot

        f = Figure()
        @test_throws ErrorException lines!(f, [1, 2])
    end
end

@testset "Cycled" begin
    # Test for https://github.com/MakieOrg/Makie.jl/issues/3266
    f, ax, pl = lines(1:4; color = Cycled(2))
    cpalette = ax.scene.theme.palette[:color][]
    @test pl.scaled_color[] == cpalette[2]
    pl2 = lines!(ax, 1:4; color = Cycled(1))
    @test pl2.scaled_color[] == cpalette[1]
end

function test_default(arg)
    _, _, pl1 = plot(arg)

    fig = Figure()
    _, pl2 = plot(fig[1, 1], arg)

    fig = Figure()
    ax = Axis(fig[1, 1])
    pl3 = plot!(ax, arg)
    return [pl1, pl2, pl3]
end

@testset "plot defaults" begin
    plots = test_default([10, 15, 20])
    @test all(x -> x isa Scatter, plots)

    plots = test_default(rand(4, 4))
    @test all(x -> x isa Heatmap, plots)

    poly = Polygon(decompose(Point, Circle(Point2f(0), 1.0f0)))

    plots = test_default(poly)
    @test all(x -> x isa Poly, plots)

    plots = test_default(rand(4, 4, 4))
    @test all(x -> x isa Volume, plots)
end

import Makie:
    InvalidAttributeError,
    attribute_names
import Makie: _attribute_docs

@testset "validated attributes" begin
    @test_throws InvalidAttributeError heatmap(zeros(10, 10); does_not_exist = 123)
    @test_throws InvalidAttributeError image(zeros(10, 10); does_not_exist = 123)
    @test_throws InvalidAttributeError scatter(1:10; does_not_exist = 123)
    @test_throws InvalidAttributeError lines(1:10; does_not_exist = 123)
    @test_throws InvalidAttributeError linesegments(1:10; does_not_exist = 123)
    @test_throws InvalidAttributeError text(1:10; text = string.(1:10), does_not_exist = 123)
    @test_throws InvalidAttributeError volume(zeros(3, 3, 3); does_not_exist = 123)
    @test_throws InvalidAttributeError meshscatter(1:10; does_not_exist = 123)
    @test_throws InvalidAttributeError poly(Point2f[]; does_not_exist = 123)
    @test_throws InvalidAttributeError mesh(rand(Point3f, 3); does_not_exist = 123)
end

import Makie: find_nearby_attributes, attribute_names, textdiff

@testset "attribute suggestions" begin
    @test find_nearby_attributes(Set([:clr]), sort(string.(collect(attribute_names(Lines))))) == ([("color", true)], true)
    triplot_attrs = sort(string.(collect(attribute_names(Triplot))))
    attrs = [:recompute_centres, :clr, :strokecolour, :blahblahblahblahblah]
    suggestions = find_nearby_attributes(attrs, triplot_attrs)
    @test suggestions == ([("recompute_centers", 1), ("marker", 0), ("strokecolor", 1), ("convex_hull_color", 0)], true)

    @test textdiff("clr", "color") == "c\e[34m\e[1mo\e[22m\e[39ml\e[34m\e[1mo\e[22m\e[39mr"
    @test textdiff("clor", "color") == "c\e[34m\e[1mo\e[22m\e[39mlor"
    @test textdiff("", "color") == "\e[34m\e[1mc\e[22m\e[39m\e[34m\e[1mo\e[22m\e[39m\e[34m\e[1ml\e[22m\e[39m\e[34m\e[1mo\e[22m\e[39m\e[34m\e[1mr\e[22m\e[39m"
    @test textdiff("colorcolor", "color") == "color"
    @test textdiff("cloourm", "color") == "co\e[34m\e[1ml\e[22m\e[39m\e[34m\e[1mo\e[22m\e[39mr"
    @test textdiff("ssoa", "ssao") == "ss\e[34m\e[1ma\e[22m\e[39m\e[34m\e[1mo\e[22m\e[39m"
end

@recipe(TestRecipe, x, y) do scene
    Attributes()
end

function Makie.plot!(p::TestRecipe)
    return lines!(p, Makie.attributes(p), p.x, p.y)
end

@testset "recipe attribute checking" begin
    # TODO, this has become harder since attributes(p) contains now more than just the attributes
    # And if p.colour isn't explicitly part of the attribute, it won't get passed
    # @test_throws InvalidAttributeError testrecipe(1:4, 1:4, colour=:red)
    @test testrecipe(1:4, 1:4, color = :red) isa Makie.FigureAxisPlot
end

@testset "validated attributes for blocks" begin
    err = InvalidAttributeError(Lines, Set{Symbol}())
    @test err.object_name == "plot"

    err = InvalidAttributeError(Axis, Set{Symbol}())
    @test err.object_name == "block"
    @test attribute_names(Axis3) == keys(_attribute_docs(Axis3))

    fig = Figure()
    @test_throws InvalidAttributeError Axis(fig[1, 1], does_not_exist = 123)
    @test_throws InvalidAttributeError Axis3(fig[1, 1], does_not_exist = 123, does_not_exist2 = 123)
    @test_throws InvalidAttributeError lines(1:10, axis = (does_not_exist = 123,))
    @test_throws InvalidAttributeError Colorbar(fig[1, 1], does_not_exist = 123)
    @test_throws InvalidAttributeError Label(fig[1, 1], does_not_exist = 123)
    @test_throws InvalidAttributeError Box(fig[1, 1], does_not_exist = 123)
    @test_throws InvalidAttributeError Slider(fig[1, 1], does_not_exist = 123)
    @test_throws InvalidAttributeError SliderGrid(fig[1, 1], does_not_exist = 123)
    @test_throws InvalidAttributeError IntervalSlider(fig[1, 1], does_not_exist = 123)
    @test_throws InvalidAttributeError Button(fig[1, 1], does_not_exist = 123)
    @test_throws InvalidAttributeError Toggle(fig[1, 1], does_not_exist = 123)
    @test_throws InvalidAttributeError Menu(fig[1, 1], does_not_exist = 123)
    @test_throws InvalidAttributeError Legend(fig[1, 1], does_not_exist = 123)
    @test_throws InvalidAttributeError LScene(fig[1, 1], does_not_exist = 123)
    @test_throws InvalidAttributeError Textbox(fig[1, 1], does_not_exist = 123)
    @test_throws InvalidAttributeError PolarAxis(fig[1, 1], does_not_exist = 123)

    @test Axis(fig[1, 1], palette = nothing) isa Axis # just checking that it doesn't error
    @test Menu(fig[1, 2], default = nothing) isa Menu
    @test Legend(fig[1, 3], entrygroups = []) isa Legend
    @test PolarAxis(fig[1, 4], palette = nothing) isa PolarAxis
    @test :palette in attribute_names(Axis)
    @test :default in attribute_names(Menu)
    @test :entrygroups in attribute_names(Legend)
    @test :palette in attribute_names(PolarAxis)
end

@testset "func2string" begin
    @test Makie.func2string(cos) == "cos"
    @test startswith(Makie.func2string(x -> x), "#")
end
