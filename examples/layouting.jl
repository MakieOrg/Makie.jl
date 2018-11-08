@block SimonDanisch [layout] begin

    @cell "Layouting" [scatter, lines, surface, heatmap, vbox] begin
        p1 = scatter(rand(10), markersize = 1)
        p2 = lines(rand(10), rand(10))
        p3 = surface(0..1, 0..1, rand(100, 100))
        p4 = heatmap(rand(100, 100))
        x = 0:0.1:10
        p5 = lines(0:0.1:10, sin.(x))
        pscene = vbox(
            hbox(p1, p2),
            p3,
            hbox(p4, p5, sizes = [0.7, 0.3]),
            sizes = [0.2, 0.6, 0.2]
        )
    end

    @cell "Comparing contours, image, surfaces and heatmaps" [image, contour, surface, heatmap, vbox] begin
        N = 20
        x = LinRange(-0.3, 1, N)
        y = LinRange(-1, 0.5, N)
        z = x .* y'
        hbox(
            vbox(
                contour(x, y, z, levels = 20, linewidth =3),
                contour(x, y, z, levels = 0, linewidth = 0, fillrange = true),
                heatmap(x, y, z),
            ),
            vbox(
                image(x, y, z, colormap = :viridis),
                surface(x, y, fill(0f0, N, N), color = z, shading = false),
                image(-0.3..1, -1..0.5, Makie.logo())
            )
        )
    end
end
