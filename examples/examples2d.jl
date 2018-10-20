
@block SimonDanisch ["2d"] begin

    @cell "Test heatmap + image overlap" [image, heatmap, transparency] begin
        heatmap(rand(32, 32))
        image!(map(x->RGBAf0(x,0.5, 0.5, 0.8), rand(32,32)))
    end

    @cell "Interaction" [scatter, linesegment, record] begin
        scene = Scene()
        f(t, v, s) = (sin(v + t) * s, cos(v + t) * s)
        time_node = Node(0.0)
        p1 = scatter!(scene, lift(t-> f.(t, range(0, stop = 2pi, length = 50), 1), time_node))[end]
        p2 = scatter!(scene, lift(t-> f.(t * 2.0, range(0, stop = 2pi, length = 50), 1.5), time_node))[end]
        points = lift(p1[1], p2[1]) do pos1, pos2
            map((a, b)-> (a, b), pos1, pos2)
        end
        linesegments!(scene, points)
        N = 150
        record(scene, @outputfile(mp4), range(0, stop = 10, length = N)) do i
            push!(time_node, i)
        end
    end
    @cell "barplot" [barplot] begin
        # barplot(1:10, rand(10))
        # barplot(rand(10))
        barplot(rand(10), color = rand(10))
        # barplot(rand(3), color = [:red, :blue, :green])
    end
    @cell "quiver" [quiver, arrows, vectorfield, gradient] begin
        using ImageFiltering
        x = range(-2, stop = 2, length = 21)
        y = x
        z = x .* exp.(-x .^ 2 .- (y') .^ 2)
        scene = contour(x, y, z, levels = 10, linewidth = 3)
        u, v = ImageFiltering.imgradients(z, KernelFactors.ando3)
        arrows!(x, y, u, v, arrowsize = 0.05)
    end
    @cell "image" [image] begin
        AbstractPlotting.hbox(
            image(Makie.logo(), scale_plot = false),
            image(rand(100, 500), scale_plot = false),
        )
    end
    @cell "scatter colormap" [scatter, colormap] begin
        scatter(rand(10), rand(10), color = rand(10))
    end
    @cell "FEM polygon 2D" [fem, poly] begin
        coordinates = [
            0.0 0.0;
            0.5 0.0;
            1.0 0.0;
            0.0 0.5;
            0.5 0.5;
            1.0 0.5;
            0.0 1.0;
            0.5 1.0;
            1.0 1.0;
        ]
        connectivity = [
            1 2 5;
            1 4 5;
            2 3 6;
            2 5 6;
            4 5 8;
            4 7 8;
            5 6 9;
            5 8 9;
        ]
        color = [0.0, 0.0, 0.0, 0.0, -0.375, 0.0, 0.0, 0.0, 0.0]
        poly(coordinates, connectivity, color = color, strokecolor = (:black, 0.6), strokewidth = 4)
    end
    @cell "FEM mesh 2D" [fem, mesh] begin
        coordinates = [
            0.0 0.0;
            0.5 0.0;
            1.0 0.0;
            0.0 0.5;
            0.5 0.5;
            1.0 0.5;
            0.0 1.0;
            0.5 1.0;
            1.0 1.0;
        ]
        connectivity = [
            1 2 5;
            1 4 5;
            2 3 6;
            2 5 6;
            4 5 8;
            4 7 8;
            5 6 9;
            5 8 9;
        ]
        color = [0.0, 0.0, 0.0, 0.0, -0.375, 0.0, 0.0, 0.0, 0.0]
        scene = mesh(coordinates, connectivity, color = color, shading = false)
        wireframe!(scene[end][1], color = (:black, 0.6), linewidth = 3)
    end
    @cell "colored triangle" [mesh, polygon] begin
        mesh(
            [(0.0, 0.0), (0.5, 1.0), (1.0, 0.0)], color = [:red, :green, :blue],
            shading = false
        )
    end
    @cell "heatmap interpolation" [heatmap, interpolate, subscene, theme] begin
        using AbstractPlotting: hbox, vbox
        data = rand(100, 50)
        p1 = heatmap(data, interpolate = true)
        p2 = heatmap(data, interpolate = false)
        t = Theme(align = (:left, :bottom), raw = true, camera = campixel!)
        title1 = text(t, "Interpolate = true")
        title2 = text(t, "Interpolate = false")
        s = vbox(
            hbox(p1, title1),
            hbox(p2, title2),
        )
    end
    @cell "colored triangle" [polygon] begin
        poly(
            [(0.0, 0.0), (0.5, 1.0), (1.0, 0.0)],
            color = [:red, :green, :blue],
            strokecolor = :black, strokewidth = 2
        )
    end
    @cell "Subscenes" [image, scatter, subscene] begin
        img = rand(RGBAf0, 100, 100)
        scene = image(img, show_axis = false)
        subscene = Scene(scene, IRect(100, 100, 300, 300))
        scatter!(subscene, rand(100) * 200, rand(100) * 200, markersize = 4)
        scene
    end

    @cell "Polygons" [poly, polygon, linesegments] begin
        using GeometryTypes
        scene = Scene(resolution = (500, 500))
        points = decompose(Point2f0, Circle(Point2f0(50), 50f0))
        pol = poly!(scene, points, color = :gray, strokewidth = 10, strokecolor = :red)
        # Optimized forms
        poly!(scene, [Circle(Point2f0(50+300), 50f0)], color = :gray, strokewidth = 10, strokecolor = :red)
        poly!(scene, [Circle(Point2f0(50+i, 50+i), 10f0) for i = 1:100:400], color = :red)
        poly!(scene, [Rectangle{Float32}(50+i, 50+i, 20, 20) for i = 1:100:400], strokewidth = 2, strokecolor = :green)
        linesegments!(scene,
            [Point2f0(50 + i, 50 + i) => Point2f0(i + 70, i + 70) for i = 1:100:400], linewidth = 8, color = :purple
        )
    end

    @cell "Contour Function" [contour] begin
        r = range(-10, stop = 10, length = 512)
        z = ((x, y)-> sin(x) + cos(y)).(r, r')
        contour(r, r, z, levels = 5, color = :viridis, linewidth = 3)
    end


    @cell "contour" [contour] begin
        y = range(-0.997669, stop = 0.997669, length = 23)
        contour(range(-0.99, stop = 0.99, length = 23), y, rand(23, 23), levels = 10)
    end

    @cell "Heatmap" [heatmap] begin
        heatmap(rand(32, 32))
    end

    @cell "Animated Scatter" [animated, scatter, updating, record] begin
        N = 10
        r = [(rand(7, 2) .- 0.5) .* 25 for i = 1:N]
        scene = scatter(r[1][:, 1], r[1][:, 2], markersize = 1, limits = FRect(-25/2, -25/2, 25, 25))
        s = scene[end] # last plot in scene
        record(scene, @outputfile(mp4), r) do m
            s[1] = m[:, 1]
            s[2] = m[:, 2]
        end
    end

    @cell "Text Annotation" [text, align, annotation] begin
        text(
            ". This is an annotation!",
            position = (300, 200),
            align = (:center,  :center),
            textsize = 60,
            font = "Blackchancery"
        )
    end

    @cell "Text rotation" [text, rotation] begin
        scene = Scene()
        pos = (500, 500)
        posis = Point2f0[]
        for r in range(0, stop = 2pi, length = 20)
            global pos, posis
            p = pos .+ (sin(r)*100.0, cos(r) * 100)
            push!(posis, p)
            t = text!(
                scene, "test",
                position = p,
                textsize = 50,
                rotation = 1.5pi - r,
                align = (:center, :center)
            )
        end
        scatter!(scene, posis, markersize = 10)
    end

    @cell "The famous iris example" [RDatasets, DataFrames, scatter, axis] begin
        using DataFrames, RDatasets # do Pkg.add.(["DataFrames", "RDatasets"]) if you don't have these packages installed
        iris = dataset("datasets", "iris")

        x = iris[:SepalWidth]
        y = iris[:SepalLength]

        scene = Scene()
        colors = [:red, :green, :blue]
        i = 1 #color incrementer
        for sp in unique(iris[:Species])
            idx = iris[:Species] .== sp
            sel = iris[idx, [:SepalWidth, :SepalLength]]
            scatter!(scene, sel[:,1], sel[:,2], color = colors[i], limits = FRect(1.5, 4.0, 3.0, 4.0))
            global i = i+1
        end
        scene
        axis = scene[Axis] # get axis
        axis[:names][:axisnames] = ("Sepal width", "Sepal length")
        scene
    end
end
