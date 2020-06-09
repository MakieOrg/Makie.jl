@block KimFung ["attributes"] begin

    @cell "algorithm" [vbox, volume, algorithm] begin
        sc = vbox(
            volume(rand(32, 32, 32), algorithm = :mip), #with mip algorithm
            volume(rand(32, 32, 32), algorithm = :absorptionrgba), #with AbsorptionRGBA algorithm
        )
    end

    @cell "align" [scatter, text, align, "2d"] begin
        scene = Scene()
        scatter!(scene, rand(10), color=:red)
        text!(scene,"adding text",textsize = 0.6, align = (:center, :center))
    end

    @cell "color" [lines, color, "2d"] begin
        vbox(
            lines(rand(10), linewidth = 20, color = :blue),
            lines(rand(10), linewidth = 20, color = to_colormap(:viridis, 10)) #mapping from a colormap to colors with 10 color points
        )
    end

    @cell "colormap" [lines, colormap, "2d"] begin
        t = range(0, stop=1, length=300)
        θ = (6π) .* t
        x = t .* cos.(θ)
        y = t .* sin.(θ)
        lines(x, y, color = t, colormap = :colorwheel, linewidth = 8, scale_plot = false)
    end

    @cell "colorrange" [lines, colormap, colorrange, "2d"] begin
        lines(randn(10),color=LinRange(-1, 1, 10),colormap=:colorwheel,linewidth=8, colorrange = (-1.0,1.0))
    end

    @cell "fillrange" [contour, fillrange, "2d"] begin
        x = LinRange(-1, 1, 20)
        y = LinRange(-1, 1, 20)
        z = x .* y'
        contour(x, y, z, levels = 0, linewidth = 0, fillrange = true)
    end

    @cell "font" [text, scatter, font, "2d"] begin
        scene = Scene()
        scatter!(scene, rand(10), color=:red)
        text!(scene,"adding text",textsize = 0.6, align = (:center, :center), font = "Blackchancery")
    end

    @cell "glowcolor, glowwidth" [scatter, glowcolor, glowwidth, "2d"] begin
        scatter(randn(10),color=:blue, glowcolor = :orange, glowwidth = 10)
    end

    @cell "image" [image, "2d"] begin
        using FileIO
        img = load(joinpath(dirname(pathof(MakieGallery)), "..", "docs", "src", "assets", "logo.png"))
        image(img, scale_plot = false)
    end

    @cell "interpolate" [heatmap, colormap, interpolate, "2d"] begin
        scene = heatmap(rand(50, 50), colormap = :colorwheel, interpolate = true)
    end

    @cell "isorange, isovalue" [volume, algorithm, isorange, isovalue] begin
        r = range(-1, stop = 1, length = 100)
        matr = [(x.^2 + y.^2 + z.^2) for x = r, y = r, z = r]
        volume(matr .* (matr .> 1.4), algorithm = :iso, isorange = 0.05, isovalue = 1.7)
    end

    @cell "levels" [contour, colormap, levels, "2d"] begin
        x = LinRange(-1, 1, 20)
        y = LinRange(-1, 1, 20)
        z = x .* y'
        contour(x, y, z, linewidth = 3, colormap = :colorwheel, levels = 50)
    end

    @cell "linestyle" [lines, linestyle, "2d"] begin
        lines(rand(10), linewidth = 6, linestyle = :dashdotdot)
    end

    @cell "linewidth" [lines, linewidth, "2d"] begin
        scene = Scene()
        lines!(scene, randn(20), linewidth = 8)
        lines!(scene, rand(20), linewidth = 4)
    end

    @cell "markersize" [scatter, markersize, "2d"] begin
        scatter(rand(50), color = :orange, markersize = 2)
    end

    @cell "position" [scatter, text, position, "2d"] begin
        scene = Scene()
        scatter!(scene, rand(10), color=:red)
        text!(scene,"adding text",textsize = 0.6, position = (5.0, 1.1))
    end

    @cell "rotation" [text, rotation, "2d"] begin
        text("Hello World", rotation = 1.1)
    end

    @cell "shading" [mesh, sphere, shading, "2d"] begin
        mesh(Sphere(Point3f0(0), 1f0), color = :orange, shading = true)
    end

    @cell "strokecolor, strokewidth" [poly, stokecolor, strokewidth, "2d"] begin
        x = LinRange(0, 2pi, 100)
        poly(Point2f0.(zip(sin.(x), sin.(2x))), color = :white, strokecolor = :blue, strokewidth = 10)
    end

    @cell "strokecolor, strokewidth" [poly, stokecolor, strokewidth, "2d"] begin
        x = LinRange(0, 2pi, 100)
        poly(Point2f0.(zip(sin.(x), sin.(2x))), color = :white, strokecolor = :blue, strokewidth = 10)
    end

    @cell "textsize" [text, scatter, textsize, "2d"] begin
        scene = Scene()
        scatter!(scene, rand(10), color = to_colormap(:colorwheel, 10))
        text!(scene, "hello world", textsize = 2)
    end

    @cell "visible" [scatter, visible, "2d"] begin
        vbox(
            scatter(randn(20), color = to_colormap(:deep, 20), markersize = 1, visible = true),
            scatter(randn(20), color = to_colormap(:deep, 20), markersize = 1, visible = false)
        )
    end
end
