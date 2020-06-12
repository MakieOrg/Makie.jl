@block KimFung ["attributes"] begin


    @cell "align" [scatter, text, align, "2d"] begin
        scene = scatter(rand(10), color=:red)
        text!(scene,"adding text",textsize = 0.6, align = (:center, :center))
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


    @cell "position" [scatter, text, position, "2d"] begin
        scene = Scene()
        scatter!(scene, rand(10), color=:red)
        text!(scene,"adding text",textsize = 0.6, position = (5.0, 1.1))
    end

    @cell "rotation" [text, rotation, "2d"] begin
        text("Hello World", rotation = 1.1)
    end

    @cell "shading" [mesh, sphere, shading, "2d"] begin
        mesh(Sphere(Point3f0(0), 1f0), color = :orange, shading = false)
    end


    @cell "visible" [scatter, visible, "2d"] begin
        vbox(
            scatter(randn(20), color = to_colormap(:deep, 20), markersize = 1, visible = true),
            scatter(randn(20), color = to_colormap(:deep, 20), markersize = 1, visible = false)
        )
    end
end
