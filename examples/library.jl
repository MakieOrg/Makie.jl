include("database.jl")

@globaly_shared begin
    using Makie, GLFW, GeometryTypes, Reactive, FileIO
    using GLVisualize, ColorBrewer, Colors
    using GLVisualize: loadasset, assetpath

    function xy_data(x, y)
        r = sqrt(x*x + y*y)
        r == 0.0 ? 1f0 : (sin(r)/r)
    end
    nothing
end


@block SimonDanisch ["2d"] begin

    @cell "Subscenes" [image, scatter, subscene] begin

        img = loadasset("doge.png")
        scene = Scene(resolution = (500, 500))

        is = image(img)
        center!(scene)
        subscene = Scene(scene, Signal(SimpleRectangle(0, 0, 200, 200)))
        scatter(subscene, rand(100) * 200, rand(100) * 200, markersize = 4)
        center!(scene)
        scene
    end


    @cell "Sample 4" [heatmap] begin
        scene = Scene(resolution = (500, 500))
        heatmap(rand(32, 32))
        center!(scene)
    end

    @cell "Sample 5" [contour] begin

        scene = Scene(resolution = (500, 500))
        r = linspace(-10, 10, 512)
        z = ((x, y)-> sin(x) + cos(y)).(r, r')
        Makie.contour(r, r, z, levels = 5, color = ColorBrewer.palette("RdYlBu", 5))
        center!(scene)
    end


    @cell "Sample 9" [contour] begin

        scene = Scene(resolution = (500, 500))
        y = linspace(-0.997669, 0.997669, 23)
        contour(linspace(-0.99, 0.99, 23), y, rand(23, 23), levels = 10)
        center!(scene)
    end


    @cell "Heatmap" [heatmap] begin
        scene = Scene(resolution = (500, 500))
        heatmap(rand(32, 32))
        center!(scene)
    end

    @cell "Sample 28" [animation, scatter, updating] begin
        r = [(rand(7, 2) .- 0.5) .* 25 for i = 1:200]
        scene = Scene(resolution = (600, 600))
        axis(linspace(-25, 25, 4), linspace(-25, 25, 4))
        scatter(r[1][:, 1], r[1][:, 2], markersize = 1)
        center!(scene)
        io = VideoStream(scene, path, "interaction")
        @inbounds for i in 2:length(r)
            scene[:scatter][:positions] = Point2f0.(view(r[i], :, 1), view(r[i], :, 2))
            recordframe!(io)
        end
        io
    end

    @cell "Text Annotation" [text, align] begin
        scene = Scene()
        text(
            ". This is an annotation!",
            position = (300, 200),
            align = (:center,  :center),
            textsize = 60,
            font = "URW Chancery L"
        )
        scene
    end
end

@block SimonDanisch ["3d"] begin

    @cell "Sample 2" [mesh, axis] begin

        scene = Scene(resolution = (500, 500));
        x = [0, 1, 2, 0]
        y = [0, 0, 1, 2]
        z = [0, 2, 0, 1]
        color = [:red, :green, :blue, :yellow]
        i = [0, 0, 0, 1]
        j = [1, 2, 3, 2]
        k = [2, 3, 1, 3]

        indices = [1, 2, 3, 1, 3, 4, 1, 4, 2, 2, 3, 4]
        mesh(x, y, z, indices, color = color)
        r = linspace(-0.5, 2.5, 4)
        axis(r, r, r)
        center!(scene)
    end

    @cell "Volume" [volume] begin

        scene = Scene(resolution = (500, 500))
        Makie.Makie.volume(rand(32, 32, 32), algorithm = :iso)
        center!(scene)

    end

    @cell "Theming" [scatter, surface, theming, lines] begin

        scene = Scene(resolution = (500, 500))

        function custom_theme(scene)
            @theme theme = begin
                linewidth = to_float(3)
                colormap = to_colormap(:RdYlGn)#to_colormap(:RdPu)
                scatter = begin
                    marker = to_spritemarker(Circle)
                    markersize = to_float(0.03)
                    strokecolor = to_color(:white)
                    strokewidth = to_float(0.01)
                    glowcolor = to_color(RGBA(0, 0, 0, 0.4))
                    glowwidth = to_float(0.1)
                end
            end
            # update theme values
            scene[:theme] = theme
        end

        vx = -1:0.1:1;
        vy = -1:0.1:1;

        f(x, y) = (sin(x*10) + cos(y*10)) / 4
        psurf = surface(vx, vy, f)

        pos = lift_node(psurf[:x], psurf[:y], psurf[:z]) do x, y, z
            vec(Point3f0.(x, y', z .+ 0.5))
        end
        pscat = scatter(pos)
        plines = lines(view(pos, 1:2:length(pos)))
        center!(scene)
        @theme theme = begin
            markersize = to_markersize2d(0.01)
            strokecolor = to_color(:white)
            strokewidth = to_float(0.01)
        end
        # this pushes all the values from theme to the plot
        push!(pscat, theme)
        pscat[:glow_color] = to_node(RGBA(0, 0, 0, 0.4), x->to_color((), x))
        # apply it to the scene
        custom_theme(scene)
        # From now everything will be plotted with new theme
        psurf = surface(vx, 1:0.1:2, psurf[:z])
        center!(scene)
    end


    @cell "Sample 7" [scatter, similar] begin
        scene = Scene(resolution = (500, 500))
        sv = scatter(rand(Point3f0, 100))
        similar(sv, rand(10), rand(10), rand(10), color = :black, markersize = 0.4)
        center!(scene)
    end

    @cell "Sample 8" [meshscatter] begin

        scene = Scene(resolution = (500, 500))
        large_sphere = HyperSphere(Point3f0(0), 1f0)
        positions = decompose(Point3f0, large_sphere)
        colS = [Colors.RGBA{Float32}(rand(), rand(), rand(), 1.) for i = 1:length(positions)]
        sizesS = [rand(Vec3f0) .* 0.5f0 for i = 1:length(positions)]
        meshscatter(positions, color = colS, markersize = sizesS)
        center!(scene)
    end

    @cell "Fluctuation 3D" [animated, mesh, meshscatter, axis] begin

        scene = Scene(resolution = (500, 500))
        # define points/edges
        perturbfactor = 4e1
        N = 3; nbfacese = 30; radius = 0.02
        large_sphere = HyperSphere(Point3f0(0), 1f0)
        positions = decompose(Point3f0, large_sphere, 30)
        np = length(positions)
        pts = [positions[k][l] for k = 1:length(positions), l = 1:3]
        pts = vcat(pts, 1.1 * pts + randn(size(pts)) / perturbfactor) # light position influence ?
        edges = hcat(collect(1:np), collect(1:np) + np)
        ne = size(edges, 1); np = size(pts, 1)
        # define markers meshes
        meshC = GLNormalMesh(
            Cylinder{3, Float32}(
                Point3f0(0., 0., 0.),
                Point3f0(0., 0, 1.),
                Float32(1)
            ), nbfacese
        )
        meshS = GLNormalMesh(large_sphere, 20)
        # define colors, markersizes and rotations
        pG = [Point3f0(pts[k, 1], pts[k, 2], pts[k, 3]) for k = 1:np]
        lengthsC = sqrt.(sum((pts[edges[:,1], :] .- pts[edges[:, 2], :]) .^ 2, 2))
        sizesC = [Vec3f0(radius, radius, lengthsC[i]) for i = 1:ne]
        sizesC = [Vec3f0(1., 1., 1.) for i = 1:ne]
        colorsp = [Colors.RGBA{Float32}(rand(), rand(), rand(), 1.) for i = 1:np]
        colorsC = [(colorsp[edges[i, 1]] + colorsp[edges[i, 2]]) / 2. for i = 1:ne]
        sizesC = [Vec3f0(radius, radius, lengthsC[i]) for i = 1:ne]
        Qlist = zeros(ne, 4)
        for k = 1:ne
            ct = Cylinder{3, Float32}(
                Point3f0(pts[edges[k, 1], 1], pts[edges[k, 1], 2], pts[edges[k, 1], 3]),
                Point3f0(pts[edges[k, 2], 1], pts[edges[k, 2], 2], pts[edges[k, 2], 3]),
                Float32(1)
            )
            Q = rotation(ct)
            r = 0.5 * sqrt(1 + Q[1, 1] + Q[2, 2] + Q[3, 3]); Qlist[k, 4] = r
            Qlist[k, 1] = (Q[3, 2] - Q[2, 3]) / (4 * r)
            Qlist[k, 2] = (Q[1, 3] - Q[3, 1]) / (4 * r)
            Qlist[k, 3] = (Q[2, 1] - Q[1, 2]) / (4 * r)
        end
        rotationsC = [Vec4f0(Qlist[i, 1], Qlist[i, 2], Qlist[i, 3], Qlist[i, 4]) for i = 1:ne]
        # plot
        hm = meshscatter(
            pG[edges[:, 1]], color = colorsC, marker = meshC,
            markersize = sizesC,  rotations = rotationsC
        )
        hp = meshscatter(pG, color = colorsp, marker = meshS, markersize = radius)

        r = linspace(-1.3, 1.3, 4); axis(r, r, r)
        center!(scene)
    end

    @cell "Connected Sphere" [lines, views, scatter, axis] begin

        scene = Scene(resolution = (500, 500))
        large_sphere = HyperSphere(Point3f0(0), 1f0)
        positions = decompose(Point3f0, large_sphere)
        linepos = view(positions, rand(1:length(positions), 1000))
        lines(linepos, linewidth = 0.1, color = :black)
        scatter(positions, strokewidth = 0.02, strokecolor = :white, color = RGBA(0.9, 0.2, 0.4, 0.6))
        r = linspace(-1.5, 1.5, 5)
        axis(r, r, r)
        scene
    end

    @cell "Sample 12" [meshscatter] begin

        scene = Scene(resolution = (500, 500))
        large_sphere = HyperSphere(Point3f0(0), 1f0)
        positions = decompose(Point3f0, large_sphere)
        meshscatter(positions, color = RGBA(0.9, 0.2, 0.4, 1))
        scene
    end

    @cell "Animated surface and wireframe" [wireframe, animated, surface, axis, video] begin

        scene = Scene(resolution = (500, 500))

        r = linspace(-2, 2, 40)
        surf_func(i) = [Float32(xy_data(x*i, y*i)) for x = r, y = r]
        z = surf_func(20)
        surf = surface(r, r, z)

        wf = wireframe(r, r, surf[:z] .+ 1.0,
            linewidth = 2f0, color = lift_node(x-> x[5], surf[:colormap])
        )
        xy = linspace(-2.1, 2.1, 4)
        axis(xy, xy, linspace(0, 2, 4))
        center!(scene)

        io = VideoStream(scene)
        for i in linspace(0, 60, 100)
            surf[:z] = surf_func(i)
            recordframe!(io)
        end
        scene
    end

    @cell "Surface with image" [surface, image] begin
        scene = Scene(resolution = (500, 500))

        N = 40
        r = linspace(-2, 2, 40)
        surf_func(i) = [Float32(xy_data(x*i, y*i)) for x = r, y = r]
        surface(
            r, r, surf_func(10),
            color = loadasset("doge.png")
        )
        center!(scene)
        scene
    end

    @cell "Normals of a Cat" [mesh, linesegment, cat] begin
        scene = Scene(resolution = (500, 500))
        x = loadasset("cat.obj")
        mesh(x.vertices, x.faces, color = :black)
        pos = map(x.vertices, x.normals) do p, n
            p => p .+ (normalize(n) .* 0.05f0)
        end
        linesegment(pos)
        scene
    end

    @cell "Simple Mesh" [mesh, cat] begin
        scene = Scene(resolution = (500, 500))
        mesh(loadasset("cat.obj"))
        r = linspace(-0.1, 1, 4)
        center!(scene)
        scene
    end

    @cell "Textured Mesh" [mesh, texture, cat] begin
        scene = Scene(resolution = (500, 500))
        cat = load(assetpath("cat.obj"), GLNormalUVMesh)
        mesh(cat, color = loadasset("diffusemap.tga"))
        center!(scene)
    end
    @cell "Sphere Mesh" [mesh] begin
        scene = Scene(resolution = (500, 500))
        mesh(Sphere(Point3f0(0), 1f0))
        center!(scene)
        scene
    end

    @cell "Wireframe of a Mesh" [mesh, wireframe, cat] begin
        scene = Scene(resolution = (500, 500))
        wireframe(GLVisualize.loadasset("cat.obj"))
        center!(scene)
    end

    @cell "Wireframe of Sphere" [mesh, wireframe] begin
        scene = Scene(resolution = (500, 500))
        wireframe(Sphere(Point3f0(0), 1f0))
        center!(scene)
    end

    @cell "Stars" [scatter, glow] begin

        scene = Scene(resolution = (500, 500), color = :black)
        stars = 100_000
        scatter((rand(Point3f0, stars) .- 0.5) .* 10,
            glowwidth = 0.005, glow_color = :white, color = RGBA(0.8, 0.9, 0.95, 0.4),
            markersize = rand(linspace(0.0001, 0.01, 100), stars)
        )
        scene
    end

    @cell "Unicode Marker" [scatter, axis, marker] begin
        scene = Scene(resolution = (500, 500))
        scatter(Point3f0[(1,0,0), (0,1,0), (0,0,1)], marker = [:x, :circle, :cross])
        axis(scene, linspace(0, 1, 4), linspace(0, 1, 4), linspace(0, 1, 4))
        center!(scene);
    end

    @cell "Legend" [legend, lines, linestyle, scatter] begin

        scene = Scene(resolution = (500, 500))

        x = map([:dot, :dash, :dashdot], [2, 3, 4]) do ls, lw
            linesegment(linspace(1, 5, 100), rand(100), rand(100), linestyle = ls, linewidth = lw)
        end
        push!(x, scatter(linspace(1, 5, 100), rand(100), rand(100)))
        center!(scene)
        l = Makie.legend(x, ["attribute $i" for i in 1:4])
        l[:position] = (0, 1)
        l[:backgroundcolor] = RGBA(0.95, 0.95, 0.95)
        l[:strokecolor] = RGB(0.8, 0.8, 0.8)
        l[:gap] = 30
        l[:textsize] = 19
        l[:linepattern] = Point2f0[(0,-0.2), (0.5, 0.2), (0.5, 0.2), (1.0, -0.2)]
        l[:scatterpattern] = decompose(Point2f0, Circle(Point2f0(0.5, 0), 0.3f0), 9)
        l[:markersize] = 2f0

        scene
    end

    @cell "Color Legend" [colorlegend, legend, ] begin
        scene = Scene(resolution = (500, 500))
        cmap = collect(linspace(to_color(:red), to_color(:blue), 20))
        l = legend(cmap, 1:4)
        l[:position] = (1.0,1.0)
        l[:textcolor] = :blue
        l[:strokecolor] = :black
        l[:strokewidth] = 1
        l[:textsize] = 15
        l[:textgap] = 5
        scene
    end

    @cell "Line Gif" [lines, animated, gif, offset] begin

        scene = Scene()
        lineplots = []
        axis(linspace(-0.1, 1.1, 4), linspace(-2, 2, 4), linspace(0, 2, 4))
        center!(scene)
        us = linspace(0, 1, 100)

        mktempdir() do path
            io = VideoStream(scene, path, "lines")
            for i = 1:100
                if length(lineplots) < 20
                    push!(lineplots, lines(us, sin.(us .+ time()), zeros(100)))
                else
                    lineplots = circshift(lineplots, 1)
                    lp = first(lineplots)
                    lp[:positions] = Point3f0.(us, sin.(us .+ time()), zeros(100))
                    lp[:offset] = Vec3f0(0)
                end
                for lp in lineplots
                    z = to_value(lp, :offset)[3]
                    lp[:offset] = Vec3f0(0, 0, z + 0.1)
                end
                sleep(1/30)
                recordframe!(io)
            end
            finish(io, "gif")
        end
    end

    @cell "Complex Axis" [surface, axis, text] begin

        scene = Scene()
        vx = -1:0.01:1;
        vy = -1:0.01:1;

        f(x, y) = (sin(x*10) + cos(y*10)) / 4
        psurf = surface(vx, vy, f)

        a = axis(linspace(extrema(vx)..., 4), linspace(extrema(vy)..., 4), linspace(-1, 1, 4))
        center!(scene, 0)

        a[:axisnames] = ("\\bf{ℜ}[u]", "\\bf{𝕴}[u]", " OK\n\\bf{δ}\n γ")
        a[:axisnames_size] = (0.15, 0.15, 0.15)
        a[:axisnames_color] = (:black, :black, :black)
        a[:axisnames_font] = "Palatino"

        # available_gradients() print gradients
        psurf[:colormap] = :RdYlBu
        wh = widths(scene)
        t = text(
            "Multipole Representation of first resonances of U-238",
            position = (wh[1] / 2.0, wh[2] - 20.0),
            align = (:center,  :center),
            textsize = 20,
            font = "Palatino",
            camera = :pixel
        )
        c = lines(Circle(Point2f0(0.1, 0.5), 0.1f0), color = :red, offset = Vec3f0(0, 0, 1))
        #update surface
        psurf[:z] = f.(vx .+ 0.5, (vy .+ 0.5)')
        scene
    end
end
