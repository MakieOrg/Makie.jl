function verify_colorbar_defaults(fig::Figure, plot; kwargs...)
    cb = Colorbar(fig[1, 2], plot)
    return verify_colorbar_defaults(cb, plot; kwargs...)
end

function verify_colorbar_defaults(
        cb::Colorbar, plot;
        color = plot.color, colorrange = plot.colorrange,
        colormap = plot.colormap, colorscale = plot.colorscale,
        lowclip = plot.lowclip, highclip = plot.highclip,
        color_mapping_type = Makie.colormapping_type(colormap[])
    )
    @testset "$(Makie.plotsym(typeof(plot)))" begin
        # @test cb.values.parent.inputs[1] == color
        @test cb.values.parent.inputs[1] == color
        @test cb.colorrange.parent.inputs[1] == colorrange
        @test cb.colormap.parent.inputs[1] == colormap
        @test cb.scale.parent.inputs[1] == colorscale
        @test cb.lowclip.parent.inputs[1] == lowclip
        @test cb.highclip.parent.inputs[1] == highclip
        @test cb.color_mapping_type[] == color_mapping_type
    end
    return
end

@testset "Colorbar from plots" begin
    @testset "Basic recipes" begin
        f, a, p = ablines([1, 2, 3], [1, 1.0, 2], color = 1:3)
        verify_colorbar_defaults(f, p)

        # no colormapping
        # f,a,p = annotation(rand(Point2f, 3), text = string.(1:3), color = 1:3)
        # verify_colorbar_defaults(f, p)

        # arc - single element

        f, a, p = arrows2d(rand(Point2f, 3), rand(Vec2f, 3), color = 1:3)
        cb = Colorbar(f[1, 2], p)
        verify_colorbar_defaults(cb, p, color = p.raw_merged_color)

        f, a, p = arrows3d(rand(Point2f, 3), rand(Vec2f, 3), color = 1:3)
        verify_colorbar_defaults(f, p)

        f, a, p = band(1:3, 0:2, 1:3, color = 1:3)
        verify_colorbar_defaults(f, p)

        f, a, p = barplot(1:3, 1:3, color = 1:3)
        verify_colorbar_defaults(f, p)

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
        verify_colorbar_defaults(f, p.plots[1], color = p.plots[1].raw_color)

        f, a, p = errorbars(1:3, 0:2, ones(3), color = 1:3)
        verify_colorbar_defaults(f, p)

        f, a, p = rangebars(1:3, 0:2, 1:3, color = 1:3)
        verify_colorbar_defaults(f, p)

        f, a, p = hlines(1:3, color = 1:3)
        verify_colorbar_defaults(f, p)

        f, a, p = vlines(1:3, color = 1:3)
        verify_colorbar_defaults(f, p)

        f, a, p = hspan(0:2, 1:3, color = 1:3)
        verify_colorbar_defaults(f, p)

        f, a, p = vspan(0:2, 1:3, color = 1:3)
        verify_colorbar_defaults(f, p)

        # one color for the whole string, so the range has to be given
        f, a, p = pathtext(1:3, [1, 2, 1], text = "123", color = 2, colorrange = (1, 3))
        verify_colorbar_defaults(f, p)

        f, a, p = pie(1:3, color = 1:3)
        verify_colorbar_defaults(f, p.plots[1])

        f, a, p = poly([Rect2f(0, 0, 1, 1), Rect2f(1, 1, 1, 1)], color = 1:2)
        verify_colorbar_defaults(f, p.plots[1])

        # not colormapped
        # f,a,p = rainclouds(rand(1:2, 100), rand(100), color = 1:2)

        f, a, p = scatterlines(1:3, color = 1:3)
        verify_colorbar_defaults(f, p)

        # not colormapped
        # f,a,p = series(rand(5, 3))

        f, a, p = spy([1 2; 3 4])
        verify_colorbar_defaults(f, p.plots[1])

        # 3 args, 5 colors...?
        f, a, p = stairs(1:3, color = 1:5)
        verify_colorbar_defaults(f, p.plots[1])

        # stem has multiple independent colormaps (and no lowclip/highclip) so it's
        # not clear how this should interact with Colorbar
        # f,a,p = stem(1:3, color = 1:3)

        f, a, p = streamplot(xy -> Vec2f(xy[2], -xy[1]), Rect2f(-1, -1, 2, 2))
        verify_colorbar_defaults(f, p.plots[1])

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
        verify_colorbar_defaults(f, p.plots[1], color = p.plots[1].raw_color)

        f, a, p = voronoiplot([1 2; 3 4])
        verify_colorbar_defaults(f, p.plots[1])

        f, a, p = waterfall(1:3, color = 1:3)
        verify_colorbar_defaults(f, p)

        # may support, but doesn't make much sense?
        # wireframe
    end

    @testset "Stats Plots" begin
        cats = rand(1:3, 100)
        vals = rand(100)
        f, a, p = boxplot(cats, vals, color = cats)
        verify_colorbar_defaults(f, p)

        f, a, p = crossbar(1:3, 1:3, 0:2, 2:4, color = 1:3)
        verify_colorbar_defaults(f, p)

        f, a, p = dendrogram(Point2f.(1:4, 0), [(1, 2), (3, 4), (5, 6)], groups = [1, 1, 2, 2])
        verify_colorbar_defaults(f, p.plots[1])

        # colormapping not implemented?
        # qqplot, qqnorm

        f, a, p = density(vals, color = :x)
        verify_colorbar_defaults(f, p.plots[1])

        # not really supported
        # f,a,p = ecdfplot(vals, color = 1:201)
        # verify_colorbar_defaults(f, p.plots[1])

        f, a, p = hexbin(rand(Point2f, 100))
        verify_colorbar_defaults(f, p.plots[1])

        f, a, p = hist(vals, color = 1:15)
        verify_colorbar_defaults(f, p.plots[1])

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
