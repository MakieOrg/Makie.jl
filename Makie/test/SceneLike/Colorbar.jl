function verify_colorbar_defaults(fig::Figure, cb_plot, source = cb_plot; kwargs...)
    cb = Colorbar(fig[1, 2], cb_plot)
    return verify_colorbar_defaults(cb, source; kwargs...)
end

function verify_colorbar_defaults(
        cb::Colorbar, plot;
        color = plot.color, colorrange = plot.colorrange,
        colormap = plot.colormap, colorscale = plot.colorscale,
        lowclip = plot.lowclip, highclip = plot.highclip,
        color_mapping_type = Makie.colormapping_type(colormap[])
    )
    @testset "$(Makie.plotsym(typeof(plot)))" begin
        @test cb.values.parent.inputs[1] == color
        @test cb.colorrange.parent.inputs[1] == colorrange
        @test cb.colormap.parent.inputs[1] == colormap
        @test cb.scale.parent.inputs[1] == colorscale
        @test cb.lowclip.parent.inputs[1] == lowclip
        @test cb.highclip.parent.inputs[1] == highclip
        @test cb.color_mapping_type[] == color_mapping_type
        # TODO: check color_dim_convert?
    end
    return
end

@testset "Colorbar from plots" begin
    @testset "Basic recipes" begin
        f, a, p = ablines([1, 2, 3], [1, 1.0, 2], color = 1:3)
        verify_colorbar_defaults(f, p.plots[1])

        # no colormapping
        # f,a,p = annotation(rand(Point2f, 3), text = string.(1:3), color = 1:3)
        # verify_colorbar_defaults(f, p)

        # arc - single element

        f, a, p = arrows2d(rand(Point2f, 3), rand(Vec2f, 3), color = 1:3)
        cb = Colorbar(f[1, 2], p)
        verify_colorbar_defaults(cb, p, color = p.raw_merged_color)

        f, a, p = arrows3d(rand(Point2f, 3), rand(Vec2f, 3), color = 1:3)
        verify_colorbar_defaults(f, p.plots[1])

        f, a, p = band(1:3, 0:2, 1:3, color = 1:3)
        verify_colorbar_defaults(f, p, p.plots[1])

        # This doesn't render because mesh can't deal with color values per mesh?
        f, a, p = barplot(1:3, 1:3, color = 1:3)
        verify_colorbar_defaults(f, p, p.plots[1].plots[1])

        # no colormapping
        # f,a,p = bracket(1:3, 0:2, 1:3, 1:3, color = 1:3)
        # verify_colorbar_defaults(f, p)

        f, a, p = contourf([1 2; 3 4])
        cb = Colorbar(f[1, 2], p)
        verify_colorbar_defaults(
            cb, p, color = p.computed_levels, colormap = p.computed_colormap,
            colorrange = p.computed_colorrange, lowclip = p.cb_lowclip, highclip = p.cb_highclip
        )

        f, a, p = contour([1 2; 3 4])
        cb = Colorbar(f[1, 2], p)
        verify_colorbar_defaults(cb, p, color = p.zlevels, colorrange = p.computed_colorrange)

        f, a, p = contour3d([1 2; 3 4])
        cb = Colorbar(f[1, 2], p)
        verify_colorbar_defaults(cb, p, color = p.zlevels, colorrange = p.computed_colorrange)

        f, a, p = contour(collect(reshape(1:8, 2, 2, 2)))
        cb = Colorbar(f[1, 2], p)
        verify_colorbar_defaults(
            cb, p, color = p.value_levels, colorrange = p.padded_colorrange,
            colormap = p.opaque_colormap
        )

        f, a, p = datashader(rand(Point2f, 100))
        cb = Colorbar(f[1, 2], p)
        @testset "DataShader" begin
            @test cb.values[] == p.canvas[].pixelbuffer
            @test cb.colorrange[] == p.raw_colorrange[]
            @test cb.colormap[] == Makie.to_colormap(p.colormap[])
            @test cb.scale[] == p.colorscale[]
            @test cb.lowclip[] == p.lowclip[]
            @test cb.highclip[] == p.highclip[]
            @test cb.color_mapping_type[] == Makie.continuous
        end

        f, a, p = heatmap(Resampler([1 2; 3 4]))
        verify_colorbar_defaults(f, p, p.plots[1], color = p.plots[1].raw_color)

        f, a, p = errorbars(1:3, 0:2, ones(3), color = 1:3)
        verify_colorbar_defaults(f, p, p.plots[1])

        f, a, p = rangebars(1:3, 0:2, 1:3, color = 1:3)
        verify_colorbar_defaults(f, p, p.plots[1])

        f, a, p = hlines(1:3, color = 1:3)
        verify_colorbar_defaults(f, p, p.plots[1])

        f, a, p = vlines(1:3, color = 1:3)
        verify_colorbar_defaults(f, p, p.plots[1])

        f, a, p = hspan(0:2, 1:3, color = 1:3)
        verify_colorbar_defaults(f, p, p.plots[1].plots[1])

        f, a, p = vspan(0:2, 1:3, color = 1:3)
        verify_colorbar_defaults(f, p, p.plots[1].plots[1])

        f, a, p = pathtext(1:3, [1, 2, 1], text = "123", color = 1:3)
        verify_colorbar_defaults(f, p, p.plots[1])

        f, a, p = pie(1:3, color = 1:3)
        verify_colorbar_defaults(f, p, p.plots[1].plots[1])

        f, a, p = poly([Rect2f(0, 0, 1, 1), Rect2f(1, 1, 1, 1)], color = 1:2)
        verify_colorbar_defaults(f, p, p.plots[1])

        # not colormapped
        # f,a,p = rainclouds(rand(1:2, 100), rand(100), color = 1:2)

        f, a, p = scatterlines(1:3, color = 1:3)
        verify_colorbar_defaults(f, p, p.plots[1])

        # not colormapped
        # f,a,p = series(rand(5, 3))

        f, a, p = spy([1 2; 3 4])
        verify_colorbar_defaults(f, p, p.plots[1])

        # 3 args, 5 colors...?
        f, a, p = stairs(1:3, color = 1:5)
        verify_colorbar_defaults(f, p, p.plots[1])

        # stem has multiple independent colormaps (and no lowclip/highclip) so it's
        # not clear how this should interact with Colorbar
        # f,a,p = stem(1:3, color = 1:3)

        f, a, p = streamplot(xy -> Vec2f(xy[2], -xy[1]), Rect2f(-1, -1, 2, 2))
        verify_colorbar_defaults(f, p, p.plots[1])

        # also unclear
        # f,a,p = textlabel(1:3, text = ["A", "B", "C"], text_color = 1:3)

        # not compatible with per-element attributes
        # f,a,p = timeseries(1)

        # also unclear
        # f,a,p = tooltip(1:3, 1:3, text = ["A", "B", "C"], textcolor = 1:3)

        f, a, p = tricontourf(rand(10), rand(10), 1:10)
        cb = Colorbar(f[1, 2], p)
        verify_colorbar_defaults(
            cb, p, color = p.computed_levels, colormap = p.computed_colormap,
            colorrange = p.computed_colorrange, lowclip = p.cb_lowclip, highclip = p.cb_highclip
        )

        # also unclear
        # f,a,p = triplot(rand(Point2f, 10), triangle_color = 1:10)

        # TODO: This should probably use p.volume instead of stepping down
        f, a, p = volumeslices(1:2, 1:2, 1:2, reshape(1:8, 2, 2, 2))
        verify_colorbar_defaults(f, p, p.plots[1], color = p[4])

        f, a, p = voronoiplot([1 2; 3 4])
        verify_colorbar_defaults(f, p, p.plots[1])

        f, a, p = waterfall(1:3, color = 1:3)
        verify_colorbar_defaults(f, p, p.plots[1].plots[1].plots[1])

        # may support, but doesn't make much sense?
        # wireframe
    end

    @testset "Stats Plots" begin
        cats = rand(1:3, 100)
        vals = rand(100)
        f, a, p = boxplot(cats, vals, color = cats)
        verify_colorbar_defaults(f, p, p.plots[3].plots[1].plots[1])

        f, a, p = crossbar(1:3, 1:3, 0:2, 2:4, color = 1:3)
        verify_colorbar_defaults(f, p, p.plots[1].plots[1])

        f, a, p = dendrogram(Point2f.(1:4, 0), [(1, 2), (3, 4), (5, 6)], groups = [1, 1, 2, 2])
        verify_colorbar_defaults(f, p, p.plots[1])

        # colormapping not implemented?
        # qqplot, qqnorm

        f, a, p = density(vals, color = :x)
        verify_colorbar_defaults(f, p, p.plots[1].plots[1])

        # not really supported
        # f,a,p = ecdfplot(vals, color = 1:201)
        # verify_colorbar_defaults(f, p.plots[1])

        f, a, p = hexbin(rand(Point2f, 100))
        verify_colorbar_defaults(f, p, p.plots[1])

        f, a, p = hist(vals, color = 1:15)
        verify_colorbar_defaults(f, p.plots[1].plots[1].plots[1])

        # not really supported
        # f,a,p = stephist(vals, color = 1:33)
        # verify_colorbar_defaults(f, p.plots[1])

        # doesn't support colormap
        # violin
    end

    @testset "Primitives" begin
        f, a, p = text(1:3, text = ["A", "B", "C"], color = 1:3)
        verify_colorbar_defaults(f, p)

        f, a, p = scatter(1:3, color = 1:3)
        verify_colorbar_defaults(f, p)

        f, a, p = lines(1:4, color = 1:4)
        verify_colorbar_defaults(f, p)

        f, a, p = linesegments(1:4, color = 1:4)
        verify_colorbar_defaults(f, p)

        f, a, p = mesh(Rect2f(0, 0, 1, 1), color = 1:4)
        verify_colorbar_defaults(f, p)

        f, a, p = meshscatter(1:3, color = 1:3)
        verify_colorbar_defaults(f, p)

        f, a, p = image([1 2; 3 4])
        verify_colorbar_defaults(f, p, color = p.raw_color)

        f, a, p = heatmap([1 2; 3 4])
        verify_colorbar_defaults(f, p, color = p.raw_color)

        f, a, p = surface([1 2; 3 4])
        verify_colorbar_defaults(f, p, color = p.raw_color)

        f, a, p = volume(collect(reshape(1:8, 2, 2, 2)))
        verify_colorbar_defaults(f, p, color = p.raw_color)

        f, a, p = voxels(collect(reshape(1:8, 2, 2, 2)))
        verify_colorbar_defaults(f, p, color = p.chunk, colorrange = p.value_limits)
    end
end

@recipe CDCTest begin
    color = :red
end
function Makie.plot!(p::CDCTest)
    scatter!(p, p.attributes, p[1])
    scatter!(p, p[1]; p.color)
    return
end

@testset "color dim converts" begin
    @testset "Unitful" begin
        f, a, p = scatter(rand(10), color = (1:10) .* u"m")
        @test p.resolved_cdc[] isa Makie.UnitfulConversion
        @test p.dc_color[] == 1:10 # something needs to activate the dc before we can check unit
        @test p.resolved_cdc[].unit[] == u"m"
        @test p.scaled_colorrange[] == Vec2f(1, 10)

        cb = Colorbar(f[1, 2], p)
        @test cb.resolved_cdc[] === p.resolved_cdc[]
        @test cb.color_mapping_type[] == Makie.continuous
        @test cb.merged_color_mapping_type[] == Makie.continuous
        @test cb.cb_colors[] ≈ collect(range(1.0, 10.0, cb.nsteps[]))
        @test cb.attributes.axis.tickvalues[] == Float64.(collect(1:10))
        @test cb.attributes.axis.tickstrings[] == string.(1:10)
        @test cb.attributes.axis.label_with_suffix[] == rich("[", rich("m"), "]")

        p2 = scatter!(rand(10), color = (1:10) .* u"mm"; p.color_dim_convert)
        @test p2.resolved_cdc[] === p.resolved_cdc[]
        @test p2.resolved_cdc[].unit[] == u"m"
        @test p2.dc_color[] == collect((1:10) .* 1.0f-3)
        # Would be nice if the colorrange was shared but we need to figure out how
        # to do that first (and also: colormap, colorscale, lowclip, highclip, nan_color)
        @test p2.scaled_colorrange[] == Vec2f(0.001, 0.01)

        # Sanity check - if this fails we should pick another unit above to verify
        # that u"m" persists
        f, a, p = scatter(rand(10), color = (1:10) .* u"mm")
        p.dc_color[]
        @test p.resolved_cdc[].unit[] == u"mm"
    end

    @testset "Categorical" begin
        f, a, p = scatter(rand(3), color = Categorical(["A", "A", "B"]))
        @test p.resolved_cdc[] isa Makie.CategoricalConversion
        @test p.dc_color[] == [1.0, 1.0, 2.0]
        @test only(p.resolved_cdc[].sets)[2] == ["A", "B"]
        @test p.scaled_colorrange[] == Vec2f(1, 2)
        key = only(p.resolved_cdc[].sets)[1]

        cb = Colorbar(f[1, 2], p)
        @test cb.resolved_cdc[] === p.resolved_cdc[]
        @test cb.color_mapping_type[] == Makie.continuous
        @test cb.merged_color_mapping_type[] == Makie.categorical
        @test cb.cb_colors[] ≈ [1.0, 2.0]
        @test cb.attributes.axis.tickvalues[] == [1.0, 2.0]
        @test cb.attributes.axis.tickstrings[] == ["A", "B"]
        @test cb.attributes.axis.label_with_suffix[] == ""

        p2 = scatter!(1:3, color = Categorical(["B", "C", "C"]); p.color_dim_convert)
        @test p2.resolved_cdc[] === p.resolved_cdc[]
        @test p2.dc_color[] == [2.0, 3.0, 3.0]
        @test length(p2.resolved_cdc[].sets) == 2
        for (k, set) in p2.resolved_cdc[].sets
            if k == key
                @test set == ["A", "B"]
            else
                @test set == ["B", "C"]
            end
        end
        @test p2.scaled_colorrange[] == Vec2f(1.0, 3.0)

        # This one synchronizes automatic colorranges, so it'll update p and cb
        @test p.scaled_colorrange[] == Vec2f(1.0, 3.0)
        @test cb.cb_colors[] ≈ [1.0, 2.0, 3.0]
        @test cb.attributes.axis.tickvalues[] == [1.0, 2.0, 3.0]
        @test cb.attributes.axis.tickstrings[] == ["A", "B", "C"]
    end

    @testset "recipe passthrough" begin
        f, a, p = scatter(rand(10), color = (1:10) .* u"m")
        cdc = p.resolved_cdc[]
        p2 = cdctest!(rand(10), color = (1:10) .* u"m"; p.color_dim_convert)
        @test p2.resolved_cdc[] === cdc
        @test p2.plots[1].resolved_cdc[] === cdc
        @test p2.plots[2].resolved_cdc[] === cdc

        # don't pass compute node
        f, a, p = scatter(rand(10), color = (1:10) .* u"m")
        p2 = cdctest!(rand(10), color = (1:10) .* u"m"; color_dim_convert = p.color_dim_convert[])
        cdc = p.resolved_cdc[]
        @test p2.resolved_cdc[] === cdc
        @test p2.plots[1].resolved_cdc[] === cdc
        @test p2.plots[2].resolved_cdc[] === cdc
    end
end

@testset "ticks" begin
    fig, ax, pl = barplot(1:3; color=1:3, colormap=Makie.Categorical(:viridis))
    cb = Colorbar(fig[1, 2], pl)
    @test cb.attributes.axis.tickvalues[] == [1, 2, 3]
    @test cb.attributes.axis.tickstrings[] == ["1.0", "2.0", "3.0"]
    cb.ticks = (1:3, ["a", "b", "c"])
    @test cb.attributes.axis.tickvalues[] == [1, 2, 3]
    @test cb.attributes.axis.tickstrings[] == ["a", "b", "c"]
end
