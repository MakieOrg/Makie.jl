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
            color = pl.calculated_colors[].color_scaled
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
    tgl = p.plots[1].plots[1]
    glyph_collection_obs = tgl[1]
    updates = test_updates(glyph_collection_obs)
    p.colormap = :blues
    @test updates[] == 1
    colors = to_colormap(:blues)
    @test glyph_collection_obs[][1].colors[1] == colors[1]
    @test glyph_collection_obs[][end].colors[1] == colors[2]
end

@testset "updating heatmap with mutated array that is A === B" begin
    n = 5
    # Float32 is important, to not have a conversion inbetween, which circumvents A === B
    data = Observable(fill(1.0f0, n, n))
    s = Scene(; size = (200, 200))
    # TODO heatmap!(s, data) triggers 3 times :(
    hm = heatmap!(s, data)
    color_triggered = Observable(0)
    on(hm.calculated_colors[].color_scaled) do x
        color_triggered[] += 1
    end
    colorrange_triggered = Observable(0)
    on(hm.calculated_colors[].colorrange_scaled) do x
        colorrange_triggered[] += 1
    end
    @test color_triggered[] == 0
    notify(data)
    @test color_triggered[] == 1
    # If updating with a new array, that contains the same values, we don't want to trigger an updat
    data[] = copy(data[])
    @test color_triggered[] == 1
    # Colorrange should never update if it stays the same
    @test colorrange_triggered[] == 0
end

@testset "updating volume with mutated array that is A === B" begin
    n = 5
    # Float32 is important, to not have a conversion inbetween, which circumvents A === B
    data = Observable(fill(1.0f0, n, n, n))
    s = Scene(; size = (200, 200))
    # TODO heatmap!(s, data) triggers 3 times :(
    hm = volume!(s, data)
    color_triggered = Observable(0)
    on(hm.calculated_colors[].color_scaled) do x
        color_triggered[] += 1
    end
    colorrange_triggered = Observable(0)
    on(hm.calculated_colors[].colorrange_scaled) do x
        colorrange_triggered[] += 1
    end
    @test color_triggered[] == 0
    notify(data)
    @test color_triggered[] == 1
    # If updating with a new array, that contains the same values, we don't want to trigger an updat
    data[] = copy(data[])
    @test color_triggered[] == 1
    # Colorrange should never update if it stays the same
    @test colorrange_triggered[] == 0
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
