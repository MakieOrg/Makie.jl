function test_updates(obs)
    updates = Ref(0)
    on(obs) do _
        return updates[] += 1
    end
    return updates
end

points = Point2f.(1:4, 1:4)

plot_types = [
    (f = scatter, args = (points,), new_kw = (; color = 2:5), kw = (; color = 1:4)),
    (f = lines, args = (points,), new_kw = (; color = 2:5), kw = (; color = 1:4)),
    (f = linesegments, args = (points,), new_kw = (; color = 2:5), kw = (; color = 1:4)),
    (f = meshscatter, args = (points,), new_kw = (; color = 2:5), kw = (; color = 1:4)),
    (f = text, args = (points,), new_kw = (; color = 2:5), kw = (; text = fill("aa", 4), color = 1:4)),
    (f = mesh, args = (Rect2f(0, 0, 1, 1),), new_kw = (; color = 2:5), kw = (; color = 1:4)),
    (f = heatmap, args = (rand(4, 4),), new_args = (rand(4, 4),)),
    (f = image, args = (rand(4, 4),), new_args = (rand(4, 4),)),
    (f = surface, args = (rand(4, 4),), new_args = (rand(4, 4),)),
    (f = volume, args = (rand(4, 4, 4),), new_args = (rand(4, 4, 4),)),
]

@testset "checking updates" begin
    for nt in plot_types
        @testset "updates to color for $(nt.f)" begin
            f, ax, pl = nt.f(nt.args...; get(nt, :kw, ())...)
            color = pl.scaled_color
            updates = test_updates(color)
            if haskey(nt, :new_args)
                pl[1] = nt.new_args[1]
                @test updates[] == 1
                @test color[] ≈ nt.new_args[1]
            else
                for (key, val) in pairs(nt.new_kw)
                    pl[key] = val
                end
                @test updates[] == 1
                @test color[] ≈ nt.new_kw.color
            end
        end
    end
end

@testset "text updating colormap" begin
    f, a, p = text(fill("aa", 10); position = rand(Point2f, 10), color = 1:10)
    p.colormap = :blues
    colors = to_colormap(:blues)
    @test p.text_color[][1] == colors[1]
    @test p.text_color[][end] == colors[2]
end

#=
# Reference image test for the above, that I dont think is necessary
##
n = 5
# FLoat32 is important, so that it doesn't get converted
A = Observable(Float32.(Makie.peaks(n)));
s = Scene(size=(200, 200))
r = -0.75 .. 0.75
hm = heatmap!(s, r, r, A, colorrange=(-5, 8))
im1 = copy(colorbuffer(s))
A[] .= fill(0f0, n, n)
notify(A)
im2 = copy(colorbuffer(s))
large = vcat(im1, im2)
s = Scene(size=size(large));
image!(s, large; space=:pixel);
s
=#
Makie.@recipe(AttrTest) do scene
    Attributes(
        kwargs = (;)
    )
end

function Makie.plot!(pl::AttrTest)
    return lines!(pl, pl.arg1, pl.arg2; pl.kwargs[]...)
end

@testset "passing through and updating Attributes" begin
    obs = Observable(:red)
    f, ax, pl = attrtest(1:5, 1:5; kwargs = (; color = obs, linewidth = 4))

    @test pl.plots[1].color[] == to_color(:red)
    obs[] = :blue
    @test pl.plots[1].color[] == to_color(:blue)
end

Makie.@recipe PassthroughTest begin
    kwargs = Attributes(
        color = :cyan,
        linewidth = 7,
    )
end

function Makie.plot!(pl::PassthroughTest)
    attrtest!(pl, pl.attributes, pl.converted_1, pl.converted_2)
    lines!(pl, pl.attributes.kwargs, pl.converted_1, pl.converted_2)
    return pl
end

@testset "Nested ComputeGraph passthrough" begin
    f, a, p = passthroughtest(1:5, 1:5)

    # passing ::ComputeGraph with nesting which should connect to nesting in AttrTest
    @test p.plots[1].plots[1].color[] == to_color(:cyan)
    @test p.plots[1].plots[1].linewidth[] == 7
    p.kwargs.color[] = :orange
    @test p.plots[1].plots[1].color[] == to_color(:orange)

    # passing ::ComputeGraphView which should connect nested nodes to unnested
    # nodes in lines
    @test p.plots[2].color[] == to_color(:orange)
    @test p.plots[2].linewidth[] == 7
    p.kwargs.linewidth[] = 3
    @test p.plots[2].linewidth[] == 3
end

Makie.@recipe PassthroughTest1 begin
    deeply = Attributes(
        nested = Attributes(
            attr = Attributes(
                color = :black,
                linewidth = 3
            )
        )
    )
    nested = Attributes(
        attr = Attributes(
            color = :white,
            linewidth = 3
        )
    )
end

function Makie.plot!(pl::PassthroughTest1)
    lines!(pl, pl.attributes.deeply.nested.attr, pl.converted_1, pl.converted_2)
    lines!(pl, pl.attributes.nested.attr, pl.converted_1, pl.converted_2)
    return pl
end


Makie.@recipe PassthroughTest2 begin
    deeply = Attributes(
        nested = Attributes(
            attr = Attributes(
                color = :red,
                linewidth = 5
            )
        )
    )
end

function Makie.plot!(pl::PassthroughTest2)
    passthroughtest1!(
        pl, pl.attributes, pl.converted_1, pl.converted_2,
        nested = Attributes(attr = Attributes(linewidth = 1))
    )
    passthroughtest1!(
        pl, pl.attributes.deeply, pl.converted_1, pl.converted_2,
        deeply = Attributes(nested = Attributes(attr = Attributes(linewidth = 1)))
    )
    passthroughtest1!(
        pl, pl.converted_1, pl.converted_2, deeply = pl.attributes.deeply,
        nested = Attributes(attr = Attributes(linewidth = 1))
    )
    return pl
end

@testset "Deeply Nested ComputeGraph passthrough" begin
    f, a, p = passthroughtest2(1:5, 1:5);

    # ComputeGraph passed
    @test haskey(p.plots[1].attributes, :deeply, :nested, :attr, :color)
    @test haskey(p.plots[1].attributes, :deeply, :nested, :attr, :linewidth)
    @test haskey(p.plots[1].attributes, :nested, :attr, :color)
    @test haskey(p.plots[1].attributes, :nested, :attr, :linewidth)
    @test p.plots[1].deeply.nested.attr.color[] == :red # passthrough
    @test p.plots[1].deeply.nested.attr.linewidth[] == 5 # passthrough
    @test p.plots[1].nested.attr.color[] == :white # default
    @test p.plots[1].nested.attr.linewidth[] == 1 # merge of explicit kwargs in recipe

    # ComputeGraphView passed
    @test haskey(p.plots[2].attributes, :deeply, :nested, :attr, :color)
    @test haskey(p.plots[2].attributes, :deeply, :nested, :attr, :linewidth)
    @test haskey(p.plots[2].attributes, :nested, :attr, :color)
    @test haskey(p.plots[2].attributes, :nested, :attr, :linewidth)
    @test p.plots[2].deeply.nested.attr.color[] == :black # default
    @test p.plots[2].deeply.nested.attr.linewidth[] == 1 # merge
    @test p.plots[2].nested.attr.color[] == :red # passthrough
    @test p.plots[2].nested.attr.linewidth[] == 5 # passthrough

    # ComputeGraphView passed through attributes
    @test haskey(p.plots[3].attributes, :deeply, :nested, :attr, :color)
    @test haskey(p.plots[3].attributes, :deeply, :nested, :attr, :linewidth)
    @test haskey(p.plots[3].attributes, :nested, :attr, :color)
    @test haskey(p.plots[3].attributes, :nested, :attr, :linewidth)
    @test p.plots[3].deeply.nested.attr.color[] == :red # kwarg set (full)
    @test p.plots[3].deeply.nested.attr.linewidth[] == 5 # kwarg set (full)
    @test p.plots[3].nested.attr.color[] == :white # default
    @test p.plots[3].nested.attr.linewidth[] == 1 # kwarg set (partial, merge)

    # attributes make it all the way
    @test p.plots[1].plots[1].color[] == to_color(:red) # passed :deeply which is connected to :deeply
    @test p.plots[1].plots[2].color[] == to_color(:white) # passed :nested which is defaulted
    @test p.plots[2].plots[1].color[] == to_color(:black) # passed :deeply which is defaulted
    @test p.plots[2].plots[2].color[] == to_color(:red) # passed :nested which is connected to :deeply.nested
    @test p.plots[3].plots[1].color[] == to_color(:red) # passed :deeply which is connected to :deeply
    @test p.plots[3].plots[2].color[] == to_color(:white) # passed :nested which is defaulted
    p.deeply.nested.attr.color[] = :cyan
    @test p.plots[1].plots[1].color[] == to_color(:cyan)
    @test p.plots[1].plots[2].color[] == to_color(:white)
    @test p.plots[2].plots[1].color[] == to_color(:black)
    @test p.plots[2].plots[2].color[] == to_color(:cyan)
    @test p.plots[3].plots[1].color[] == to_color(:cyan) # passed :deeply which is connected to :deeply
    @test p.plots[3].plots[2].color[] == to_color(:white) # passed :nested which is defaulted
end
