
function test_updates(obs)
    updates = Ref(0)
    on(obs) do _
        return updates[] += 1
    end
    return updates
end

points = Point2f.(1:4, 1:4)

plot_types = [(f=scatter, args=(points,), new_kw=(; color=2:5), kw=(; color=1:4)),
              (f=lines, args=(points,), new_kw=(; color=2:5), kw=(; color=1:4)),
              (f=linesegments, args=(points,), new_kw=(; color=2:5), kw=(; color=1:4)),
              (f=meshscatter, args=(points,), new_kw=(; color=2:5), kw=(; color=1:4)),
              (f=text, args=(points,), new_kw=(; color=2:5), kw=(; text=fill("aa", 4), color=1:4)),
              (f=mesh, args=(Rect2f(0, 0, 1, 1),), new_kw=(; color=2:5), kw=(; color=1:4)),
              (f=heatmap, args=(rand(4, 4),), new_args=(rand(4, 4),)),
              (f=image, args=(rand(4, 4),), new_args=(rand(4, 4),)),
              (f=surface, args=(rand(4, 4),), new_args=(rand(4, 4),)),
              (f=volume, args=(rand(4, 4, 4),), new_args=(rand(4, 4, 4),))]

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
    f, a, p = text(fill("aa", 10); position=rand(Point2f, 10), color=1:10)
    tgl = p.plots[1].plots[1]
    glyph_collection_obs = tgl[1]
    updates = test_updates(glyph_collection_obs)
    p.colormap = :blues
    @test updates[] == 1
    colors = to_colormap(:blues)
    @test glyph_collection_obs[][1].colors[1] == colors[1]
    @test glyph_collection_obs[][end].colors[1] == colors[2]
end
