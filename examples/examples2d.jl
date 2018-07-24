
@block SimonDanisch ["2d"] begin

    @cell "Test heatmap + image overlap" [image, heatmap, transparency] begin
        heatmap(rand(32, 32))
        image!(map(x->RGBAf0(x,0.5, 0.5, 0.8), rand(32,32)))
    end

    @cell "Interaction" [scatter, linesegment, record] begin
        scene = Scene(@resolution)

        f(t, v, s) = (sin(v + t) * s, cos(v + t) * s)
        time = Node(0.0)
        p1 = scatter!(scene, lift(t-> f.(t, linspace(0, 2pi, 50), 1), time))[end]
        p2 = scatter!(scene, lift(t-> f.(t * 2.0, linspace(0, 2pi, 50), 1.5), time))[end]
        lines = lift(p1[1], p2[1]) do pos1, pos2
            map((a, b)-> (a, b), pos1, pos2)
        end
        linesegments!(scene, lines)
        N = 150
        record(scene, @outputfile(mp4), linspace(0, 10, N)) do i
            push!(time, i)
        end
    end

    @cell "quiver" [quiver, arrows, vectorfield, gradiend] begin
        using ImageFiltering
        x = linspace(-2, 2, 21)
        y = x
        z = x .* exp.(-x .^ 2 .- (y') .^ 2)
        scene = contour(x, y, z, levels = 10, linewidth = 3)
        u, v = ImageFiltering.imgradients(z)
        arrows!(x, y, u, v, arrowsize = 0.05)
    end
    @cell "image" [image] begin
        AbstractPlotting.vbox(
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
    @cell "heatmap interpolation" [heatmap, interpolate] begin
        p1 = heatmap(rand(100, 100), interpolate = true)
        p2 = heatmap(rand(100, 100), interpolate = false)
        scene = AbstractPlotting.vbox(p1, p2)
        text!(campixel(p1), "Interpolate = true", position = widths(p1) .* Vec(0.5, 1), align = (:center, :top), raw = true)
        text!(campixel(p2), "Interpolate = false", position = widths(p2) .* Vec(0.5, 1), align = (:center, :top), raw = true)
        scene
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
        r = linspace(-10, 10, 512)
        z = ((x, y)-> sin(x) + cos(y)).(r, r')
        contour(r, r, z, levels = 5, color = :viridis, linewidth = 10)
    end


    @cell "contour" [contour] begin
        y = linspace(-0.997669, 0.997669, 23)
        contour(linspace(-0.99, 0.99, 23), y, rand(23, 23), levels = 10)
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

    @cell "Text Annotation" [text, align] begin
        text(
            ". This is an annotation!",
            position = (300, 200),
            align = (:center,  :center),
            textsize = 60,
            font = "Blackchancery"
        )
    end

    @cell "Text rotation" [text, rotation] begin
        scene = Scene(@resolution)
        pos = (500, 500)
        posis = Point2f0[]
        for r in linspace(0, 2pi, 20)
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
end

@block SimonDanisch ["3d"] begin
    @cell "FEM mesh 3D" [mesh, fem] begin
        using GeometryTypes
        cat = Makie.loadasset("cat.obj")
        vertices = decompose(Point3f0, cat)
        faces = decompose(Face{3, Int}, cat)
        coordinates = [vertices[i][j] for i = 1:length(vertices), j = 1:3]
        connectivity = [faces[i][j] for i = 1:length(faces), j = 1:3]
        mesh(
            coordinates, connectivity,
            color = rand(length(vertices))
        )
    end


    @cell "Axis + Surface" [axis, surface, interaction, manipulation] begin
        vx = -1:0.01:1
        vy = -1:0.01:1

        f(x, y) = (sin(x*10) + cos(y*10)) / 4
        scene = Scene(resolution = (500, 500))
        # One way to style the axis is to pass a nested dictionary / named tuple to it.
        surface!(scene, vx, vy, f, axis = NT(frame = NT(linewidth = 2.0)))
        psurf = scene[end] # the surface we last plotted to scene
        # One can also directly get the axis object and manipulate it
        axis = scene[Axis] # get axis

        # You can access nested attributes likes this:
        axis[:names, :axisnames] = ("\\bf{ℜ}[u]", "\\bf{𝕴}[u]", " OK\n\\bf{δ}\n γ")
        tstyle = axis[:names] # or just get the nested attributes and work directly with them

        tstyle[:textsize] = 10
        tstyle[:textcolor] = (:red, :green, :black)
        tstyle[:font] = "helvetica"


        psurf[:colormap] = :RdYlBu
        wh = widths(scene)
        t = text!(
            campixel(scene),
            "Multipole Representation of first resonances of U-238",
            position = (wh[1] / 2.0, wh[2] - 20.0),
            align = (:center,  :center),
            textsize = 20,
            font = "helvetica",
            raw = :true
        )
        c = lines!(scene, Circle(Point2f0(0.1, 0.5), 0.1f0), color = :red, offset = Vec3f0(0, 0, 1))
        scene
        #update surface
        # TODO explain and improve the situation here
        psurf.converted[3][] = f.(vx .+ 0.5, (vy .+ 0.5)')
        scene
    end

    @cell "Fluctuation 3D" [animated, mesh, meshscatter, axis] begin
        using GeometryTypes, Colors
        scene = Scene()
        # define points/edges
        perturbfactor = 4e1
        N = 3; nbfacese = 30; radius = 0.02
        large_sphere = Sphere(Point3f0(0), 1f0)
        positions = decompose(Point3f0, large_sphere, 30)
        np = length(positions)
        pts = [positions[k][l] for k = 1:length(positions), l = 1:3]
        pts = vcat(pts, 1.1 * pts + randn(size(pts)) / perturbfactor) # light position influence ?
        edges = hcat(collect(1:np), collect(1:np) + np)
        ne = size(edges, 1); np = size(pts, 1)
        # define markers meshes
        meshC = GLNormalMesh(
            Makie.Cylinder{3, Float32}(
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
        colorsp = [RGBA{Float32}(rand(), rand(), rand(), 1.) for i = 1:np]
        colorsC = [(colorsp[edges[i, 1]] + colorsp[edges[i, 2]]) / 2. for i = 1:ne]
        sizesC = [Vec3f0(radius, radius, lengthsC[i]) for i = 1:ne]
        Qlist = zeros(ne, 4)
        for k = 1:ne
            ct = GeometryTypes.Cylinder{3, Float32}(
                Point3f0(pts[edges[k, 1], 1], pts[edges[k, 1], 2], pts[edges[k, 1], 3]),
                Point3f0(pts[edges[k, 2], 1], pts[edges[k, 2], 2], pts[edges[k, 2], 3]),
                Float32(1)
            )
            Q = GeometryTypes.rotation(ct)
            r = 0.5 * sqrt(1 + Q[1, 1] + Q[2, 2] + Q[3, 3]); Qlist[k, 4] = r
            Qlist[k, 1] = (Q[3, 2] - Q[2, 3]) / (4 * r)
            Qlist[k, 2] = (Q[1, 3] - Q[3, 1]) / (4 * r)
            Qlist[k, 3] = (Q[2, 1] - Q[1, 2]) / (4 * r)
        end
        rotationsC = [Makie.Vec4f0(Qlist[i, 1], Qlist[i, 2], Qlist[i, 3], Qlist[i, 4]) for i = 1:ne]
        # plot
        hm = meshscatter!(
            scene, pG[edges[:, 1]],
            color = colorsC, marker = meshC,
            markersize = sizesC,  rotations = rotationsC,
        )
        hp = meshscatter!(
            scene, pG,
            color = colorsp, marker = meshS, markersize = radius,
        )
    end

    @cell "Connected Sphere" [lines, views, scatter, axis] begin
        large_sphere = Sphere(Point3f0(0), 1f0)
        positions = decompose(Point3f0, large_sphere)
        linepos = view(positions, rand(1:length(positions), 1000))
        scene = lines(linepos, linewidth = 0.1, color = :black)
        scatter!(scene, positions, strokewidth = 10, strokecolor = :white, color = RGBAf0(0.9, 0.2, 0.4, 0.6))
        scene
    end
    @cell "image scatter" [image, scatter] begin
        scatter(
            1:10, 1:10, rand(10, 10) .* 10,
            rotations = normalize.(rand(Quaternionf0, 10*10)),
            markersize = 1,
            # can also be an array of images for each point
            # need to be the same size for best performance, though
            marker = Makie.logo()
        )
    end
    @cell "Simple meshscatter" [meshscatter] begin
        large_sphere = Sphere(Point3f0(0), 1f0)
        positions = decompose(Point3f0, large_sphere)
        meshscatter(positions, color = RGBAf0(0.9, 0.2, 0.4, 1), markersize = 0.05)
    end

    @cell "Animated surface and wireframe" [wireframe, animated, surface, axis, video, record] begin
        scene = Scene();
        function xy_data(x, y)
            r = sqrt(x^2 + y^2)
            r == 0.0 ? 1f0 : (sin(r)/r)
        end

        r = linspace(-2, 2, 50)
        surf_func(i) = [Float32(xy_data(x*i, y*i)) for x = r, y = r]
        z = surf_func(20)
        surf = surface!(scene, r, r, z)[end]

        wf = wireframe!(scene, r, r, Makie.lift(x-> x .+ 1.0, surf[3]),
            linewidth = 2f0, color = Makie.lift(x-> to_colormap(x)[5], surf[:colormap])
        )
        N = 150
        scene
        record(scene, @outputfile(mp4), linspace(5, 40, N)) do i
            surf[3] = surf_func(i)
        end
    end

    @cell "Normals of a Cat" [mesh, linesegment, cat] begin
        x = Makie.loadasset("cat.obj")
        mesh(x, color = :black)
        pos = map(x.vertices, x.normals) do p, n
            p => p .+ (normalize(n) .* 0.05f0)
        end
        linesegments!(pos, color = :blue)
    end

    @cell "Sphere Mesh" [mesh] begin
        mesh(Sphere(Point3f0(0), 1f0), color = :blue)
    end

    @cell "Stars" [scatter, glow, update_cam!, camera] begin
        stars = 100_000
        scene = Scene(backgroundcolor = :black)
        scatter!(
            scene,
            (rand(Point3f0, stars) .- 0.5) .* 10,
            glowwidth = 0.005, glowcolor = :white, color = RGBAf0(0.8, 0.9, 0.95, 0.4),
            markersize = rand(linspace(0.0001, 0.01, 100), stars),
            show_axis = false
        )
        update_cam!(scene, FRect3D(Vec3f0(-2), Vec3f0(4)))
        scene
    end

    @cell "Unicode Marker" [scatter, axis, marker] begin
        scene = Scene(@resolution)
        scatter!(scene, Point3f0[(1,0,0), (0,1,0), (0,0,1)], marker = [:x, :circle, :cross])
    end

    @cell "Merged color Mesh" [mesh, color] begin
        using GeometryTypes
        x = Vec3f0(0); baselen = 0.2f0; dirlen = 1f0
        # create an array of differently colored boxes in the direction of the 3 axes
        rectangles = [
            (HyperRectangle(Vec3f0(x), Vec3f0(dirlen, baselen, baselen)), RGBAf0(1,0,0,1)),
            (HyperRectangle(Vec3f0(x), Vec3f0(baselen, dirlen, baselen)), RGBAf0(0,1,0,1)),
            (HyperRectangle(Vec3f0(x), Vec3f0(baselen, baselen, dirlen)), RGBAf0(0,0,1,1))
        ]
        meshes = map(GLNormalMesh, rectangles)
        mesh(merge(meshes))
    end

    @cell "Moire" [lines, camera, update_cam!, rotate_cam!, linesegments, record, mp4] begin
        function cartesian(ll)
            return Point3f0(
                cos(ll[1]) * sin(ll[2]),
                sin(ll[1]) * sin(ll[2]),
                cos(ll[2])
            )
        end
        fract(x) = x - floor(x)
        function calcpositions(rings, index, time, audio)
            movement, radius, speed, spin = 1, 2, 3, 4;
            position = Point3f0(0.0)
            precision = 0.2f0
            for ring in rings
                position += ring[radius] * cartesian(
                    precision *
                    index *
                    Point2f0(ring[spin] + Point2f0(sin(time * ring[speed]), cos(time * ring[speed])) * ring[movement])
                )
            end
            amplitude = audio[round(Int, clamp(fract(position[1] * 0.1), 0, 1) * (25000-1)) + 1]; # index * 0.002
            position *= 1.0 + amplitude * 0.5;
            position
        end
        rings = [(0.1f0, 1.0f0, 0.00001f0, Point2f0(0.2, 0.1)), (0.1f0, 0.0f0, 0.0002f0, Point2f0(0.052, 0.05))]
        N2 = 25000
        t_audio = sin.(linspace(0, 10pi, N2)) .+ (cos.(linspace(-3, 7pi, N2)) .* 0.6) .+ (rand(Float32, N2) .* 0.1) ./ 2f0
        start = time()
        t = (time() - start) * 100
        pos = calcpositions.((rings,), 1:N2, t, (t_audio,))

        scene = lines(pos, color = RGBAf0.(to_colormap(:RdBu, N2), 0.6), thickness = 0.6f0, show_axis = false)
        linesegments!(scene, FRect3D(Vec3f0(-1.5), Vec3f0(3)), raw = true, linewidth = 3, linestyle = :dot)
        eyepos = Vec3f0(5, 1.5, 0.5)
        lookat = Vec3f0(0)
        update_cam!(scene, eyepos, lookat)
        l = scene[1]
        N = 150
        record(scene, @outputfile(mp4), 1:N) do i
            t = (time() - start) * 700
            pos .= calcpositions.((rings,), 1:N2, t, (t_audio,))
            l[1] = pos # update argument 1
            rotate_cam!(scene, 0.0, 0.01, 0.01)
        end

    end

    @cell "Line GIF" [lines, animated, gif, offset, record] begin
        us = linspace(0, 1, 100)
        scene = Scene()
        scene = linesegments!(scene, FRect3D(Vec3f0(0, -1, 0), Vec3f0(1, 2, 2)))
        p = lines!(scene, us, sin.(us .+ time()), zeros(100), linewidth = 3)[end]
        lineplots = [p]
        translate!(p, 0, 0, 0)
        colors = to_colormap(:RdYlBu)
        #display(scene) # would be needed without the record
        N = 150
        path = record(scene, @outputfile(gif), 1:N) do i
            global lineplots, scene
            if length(lineplots) < 20
                p = lines!(
                    scene,
                    us, sin.(us .+ time()), zeros(100),
                    color = colors[length(lineplots)],
                    linewidth = 3
                )[end]
                unshift!(lineplots, p)
                translate!(p, 0, 0, 0)
                #TODO automatically insert new plots
                insert!(Makie.global_gl_screen(), scene, p)
            else
                lineplots = circshift(lineplots, 1)
                lp = first(lineplots)
                lp[2] = sin.(us .+ time())
                translate!(lp, 0, 0, 0)
            end
            for lp in Iterators.drop(lineplots, 1)
                z = translation(lp)[][3]
                translate!(lp, 0, 0, z + 0.1)
            end
        end
        path
    end
end
