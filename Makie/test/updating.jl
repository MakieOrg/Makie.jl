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
