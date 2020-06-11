using MakieGallery: @substep

@block SimonDanisch ["tests"] begin
    ## Scatter
    @cell begin
        using GeometryBasics
        ## Some helpers
        data_2d = AbstractPlotting.peaks()
        args_2d = (-10..10, -10..10, data_2d)
        function n_times(f, n=10, interval=0.05)
            obs = Observable(f(1))
            @async for i in 2:n
                try
                    obs[] = f(i)
                    sleep(interval)
                catch e
                    @warn "Error!" exception=CapturedException(e, Base.catch_backtrace())
                end
            end
            return obs
        end
        cmap = cgrad(:RdYlBu; categorical=true);
        line_positions = Point2f0.([1:4; NaN; 1:4], [1:4; NaN; 2:5])
        cat = MakieGallery.loadasset("cat.obj")
        tex = MakieGallery.loadasset("diffusemap.png")
        meshes = GeometryBasics.normal_mesh.([Sphere(Point3f0(0.5), 1), Rect(Vec3f0(1, 0, 0), Vec3f0(1))])
        positions = Point2f0[(1, 1), (2, 2), (3, 2), (4, 4)]
        positions_connected = connect(positions, LineFace{Int}[(1, 2), (2, 3), (3, 4)])

        scatter(1:4; color=:red, markersize=0.3)
        @substep
        scatter(1:4; color=:red, markersize=10px)
        @substep
        scatter(1:4; color=:red, markersize=10, markerspace=Pixel)
        @substep
        scatter(1:4; color=:red, markersize=(1:4).*8, markerspace=Pixel)

        @substep
        scatter(1:4; marker='☼')
        @substep
        scatter(1:4; marker=['☼', '◒', '◑', '◐'])
        @substep
        scatter(1:4; marker="☼◒◑◐")
        @substep
        scatter(1:4; marker=rand(RGBf0, 10, 10), markersize=20px)
        # TODO rotation with markersize=px
        @substep
        scatter(1:4; marker='▲', markersize=0.3, rotations=LinRange(0, pi, 4))

        ## Meshscatter
        @substep
        meshscatter(1:4; color=1:4)

        @substep
        meshscatter(1:4; color=rand(RGBAf0, 4))
        @substep
        meshscatter(1:4; color=rand(RGBf0, 4))
        @substep
        meshscatter(1:4; color=:red)
        @substep
        meshscatter(rand(Point3f0, 10); color=rand(RGBf0, 10))
        @substep
        meshscatter(rand(Point3f0, 10); marker=Pyramid(Point3f0(0), 1f0, 1f0))

        ## Barplot
        barplot(sort(rand(10)); color=rand(10))
        @substep
        barplot(1:3; color=[:red, :green, :blue])
        @substep

        ## Lines
        @substep
        lines(line_positions)
        @substep
        lines(line_positions; linestyle=:dot)
        @substep
        lines(line_positions; linestyle=[0.0, 1.0, 2.0, 3.0, 4.0])
        @substep
        lines(line_positions; color=1:9)
        @substep
        lines(line_positions; color=rand(RGBf0, 9), linewidth=4)

        ## Linesegments
        @substep
        linesegments(1:4)
        @substep
        linesegments(1:4; linestyle=:dot)
        @substep
        linesegments(1:4; linestyle=[0.0, 1.0, 2.0, 3.0, 4.0])
        @substep
        linesegments(1:4; color=1:4)
        @substep
        linesegments(1:4; color=rand(RGBf0, 4), linewidth=4)

        ## Surface
        @substep
        surface(args_2d...)
        @substep
        surface(args_2d...; color=rand(size(data_2d)...))
        @substep
        surface(args_2d...; color=rand(RGBf0, size(data_2d)...))
        @substep
        surface(args_2d...; colormap=:magma, colorrange=(-3.0, 4.0))
        @substep
        surface(args_2d...; shading=false); wireframe!(args_2d..., linewidth=0.5)
        @substep
        surface(1:30, 1:31, rand(30, 31))
        @substep
        n = 20
        θ = [0;(0.5:n-0.5)/n;1]
        φ = [(0:2n-2)*2/(2n-1);2]
        x = [cospi(φ)*sinpi(θ) for θ in θ, φ in φ]
        y = [sinpi(φ)*sinpi(θ) for θ in θ, φ in φ]
        z = [cospi(θ) for θ in θ, φ in φ]
        surface(x, y, z)
        ## Polygons
        @substep
        poly(decompose(Point2f0, Circle(Point2f0(0), 1f0)))

        ## Image like!
        @substep
        image(rand(10, 10))
        @substep
        heatmap(rand(10, 10))

        ## Volumes
        @substep
        volume(rand(4, 4, 4), isovalue=0.5, isorange=0.01, algorithm=:iso)
        @substep
        volume(rand(4, 4, 4), algorithm=:mip)
        @substep
        volume(rand(4, 4, 4), algorithm=:absorption)
        @substep
        volume(rand(4, 4, 4), algorithm=Int32(5))

        @substep
        volume(rand(RGBAf0, 4, 4, 4), algorithm=:absorptionrgba)
        @substep
        contour(rand(4, 4, 4))

        ## Meshes

        @substep
        mesh(cat, color=tex)
        @substep
        mesh([(0.0, 0.0), (0.5, 1.0), (1.0, 0.0)], color = [:red, :green, :blue],
             shading = false)
        @substep
        mesh(meshes, color=[1, 2])
        @substep

        ## Axis
        scene = lines(IRect(Vec2f0(0), Vec2f0(1)))
        axis = scene[Axis]
        axis.ticks.ranges = ([0.1, 0.2, 0.9], [0.1, 0.2, 0.9])
        axis.ticks.labels = (["😸", "♡", "𝕴"], ["β ÷ δ", "22", "≙"])
        scene
        @substep
        ## Text
        text("heyllo")
        @substep
        ## Colormaps
        heatmap(args_2d...; colormap=cgrad(:RdYlBu; categorical=true), interpolate=true)
        @substep
        image(args_2d...; colormap=cgrad(:RdYlBu; categorical=true), interpolate=true)
        @substep
        heatmap(args_2d...; colorrange=(-4.0, 3.0), colormap=cmap, highclip=:green,
                      lowclip=:pink, interpolate=true)
        @substep
        surface(args_2d...; colorrange=(-4.0, 3.0), highclip=:green, lowclip=:pink)
        @substep

        ## Animations
        annotations(n_times(i-> map(j-> ("$j", Point2f0(j*30, 0)), 1:i)), textsize=20,
                          limits=FRect2D(30, 0, 320, 50))
        @substep
        scatter(n_times(i-> Point2f0.((1:i).*30, 0)), markersize=20px,
                      limits=FRect2D(30, 0, 320, 50))
        @substep
        linesegments(n_times(i-> Point2f0.((2:2:2i).*30, 0)), limits=FRect2D(30, 0, 620, 50))
        @substep
        lines(n_times(i-> Point2f0.((2:2:2i).*30, 0)), limits=FRect2D(30, 0, 620, 50))
        @substep
        # Scaling
        scene = Scene(transform_func=(identity, log10))
        linesegments!(1:4, color=:black, linewidth=20, transparency=true)
        scatter!(1:4, color=rand(RGBf0, 4), markersize=20px)
        lines!(1:4, color=rand(RGBf0, 4))
        @substep

        # Views
        linesegments(positions)
        @substep
        scatter(positions_connected)
        @substep

        # Interpolation
        heatmap(data_2d, interpolate=true)
        @substep
        image(data_2d, interpolate=false)
        @substep

        # Categorical
        barplot(["hi", "ima", "string"], rand(3))
        @substep
        heatmap(["a", "b", "c"], ["α", "β", "γ"], rand(3, 3))
    end
end
