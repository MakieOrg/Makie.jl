
include("database.jl")
using Makie

@block SimonDanisch ["2d"] begin
    @cell "image" [image] begin
        image(Makie.logo(), scale_plot = false)
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
    @cell "colored triangle" [polygon] begin
        poly(
            [(0.0, 0.0), (0.5, 1.0), (1.0, 0.0)],
            color = [:red, :green, :blue],
            linecolor = :black, linewidth = 2
        )
    end
    # @cell "Subscenes" [image, scatter, subscene] begin
    #
    #     scene = Scene(@resolution)
    #     # # TODO: had to use Makie.loadasset
    #     # img = rand(RGBAf0, 100, 100)
    #     # scene = Scene(@resolution)
    #     # # TODO: fails here with ERROR: MethodError: no method matching isless(::ColorTypes.RGBA{FixedPointNumbers.Normed{UInt8,8}}, ::ColorTypes.RGBA{FixedPointNumbers.Normed{UInt8,8}})
    #     # is = image(img)
    #     # center!(scene)
    #     # # TODO: had to do Makie.Signal
    #     # subscene = Scene(scene, Node(Makie.SimpleRectangle(0, 0, 200, 200)))
    #     # scatter(subscene, rand(100) * 200, rand(100) * 200, markersize = 4)
    #     # center!(scene)
    #     # scene
    # end

    @cell "Polygons" [poly, polygon, linesegments] begin
        using GeometryTypes
        scene = Scene(@resolution)
        points = decompose(Point2f0, Circle(Point2f0(50), 50f0))
        pol = poly!(scene, points, color = :gray, linewidth = 10, linecolor = :red)
        # Optimized forms
        poly!(scene, [Circle(Point2f0(50+i, 50+i), 10f0) for i = 1:100:400])
        poly!(scene, [Rectangle{Float32}(50+i, 50+i, 20, 20) for i = 1:100:400], strokewidth = 10, strokecolor = :black)
        linesegments!(scene,
            [Point2f0(50+i, 50+i) => Point2f0(i + 80, i + 80) for i = 1:100:400], linewidth = 8, color = :purple
        )
    end

    @cell "Contour Function" [contour] begin
        r = linspace(-10, 10, 512)
        z = ((x, y)-> sin(x) + cos(y)).(r, r')
        contour(r, r, z, levels = 5, color = :RdYlBu)
    end


    @cell "contour" [contour] begin
        y = linspace(-0.997669, 0.997669, 23)
        contour(linspace(-0.99, 0.99, 23), y, rand(23, 23), levels = 10)
    end

    @cell "Heatmap" [heatmap] begin
        heatmap(rand(32, 32))
    end

    @cell "Animated Scatter" [animated, scatter, updating] begin
        scene = Scene(@resolution)
        N = 50
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
            font = "URW Chancery L"
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

    @cell "Sample 7" [scatter, similar] begin
        scene = Scene(@resolution)
        sv = scatter!(scene, rand(Point3f0, 100), markersize = 0.05)
        # TODO: ERROR: function similar does not accept keyword arguments
        # Simon says: maybe we won't keep similar
        # similar(sv, rand(10), rand(10), rand(10), color = :black, markersize = 0.4)
    end
    @cell "Axis + Surface" [axis, surface, interaction, manipulation] begin
        vx = -1:0.01:1
        vy = -1:0.01:1

        f(x, y) = (sin(x*10) + cos(y*10)) / 4

        # One way to style the axis is to pass a nested dictionary to it.
        scene = surface(vx, vy, f, axis = NT(framestyle = NT(linewidth = 2.0)))
        psurf = scene[end] # the surface we last plotted to scene
        # One can also directly get the axis object and manipulate it
        axis = scene[Axis] # get axis

        # You can access nested attributes likes this:
        axis[:titlestyle, :axisnames] = ("\\bf{ℜ}[u]", "\\bf{𝕴}[u]", " OK\n\\bf{δ}\n γ")
        tstyle = axis[:titlestyle] # or just get the nested attributes and work directly with them

        tstyle[:textsize] = 10
        tstyle[:textcolor] = (:red, :green, :black)
        tstyle[:font] = "Palatino"


        psurf[:colormap] = :RdYlBu
        wh = widths(scene)
        t = text!(
            campixel(scene),
            "Multipole Representation of first resonances of U-238",
            position = (wh[1] / 2.0, wh[2] - 20.0),
            align = (:center,  :center),
            textsize = 20,
            font = "Palatino",
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
        # TODO: Need Makie.HyperSphere to work
        large_sphere = HyperSphere(Point3f0(0), 1f0)
        # TODO: Makie.decompose
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
        scatter!(scene, positions, strokewidth = 0.02, strokecolor = :white, color = RGBAf0(0.9, 0.2, 0.4, 0.6))
        scene
    end
    @cell "image scatter" [image, scatter] begin
        scatter(
            1:10, 1:10, rand(10, 10) .* 10,
            rotations = normalize.(rand(Quaternionf0, 10*10)),
            markersize = 1,
            marker = Makie.logo() # can also be an array of images for each point
        )
    end
    @cell "Simple meshscatter" [meshscatter] begin
        large_sphere = Sphere(Point3f0(0), 1f0)
        positions = decompose(Point3f0, large_sphere)
        meshscatter(positions, color = RGBAf0(0.9, 0.2, 0.4, 1), markersize = 0.5)
    end

    @cell "Animated surface and wireframe" [wireframe, animated, surface, axis, video] begin
        scene = Scene(@resolution)
        function xy_data(x, y)
            r = sqrt(x^2 + y^2)
            r == 0.0 ? 1f0 : (sin(r)/r)
        end

        r = linspace(-2, 2, 50)
        surf_func(i) = [Float32(xy_data(x*i, y*i)) for x = r, y = r]
        # TODO: errors out here ERROR: DomainError:
        # Exponentiation yielding a complex result requires a complex argument.
        # Replace x^y with (x+0im)^y, Complex(x)^y, or similar.
        z = surf_func(20)
        surf = surface!(scene, r, r, z)[end]

        wf = wireframe!(scene, r, r, Makie.lift(x-> x .+ 1.0, surf[3]),
            linewidth = 2f0, color = Makie.lift(x-> to_colormap(x)[5], surf[:colormap])
        )
        record(scene, @outputfile(mp4), linspace(5, 40, 100)) do i
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

    @cell "Stars" [scatter, glow, update_cam!] begin
        stars = 100_000
        scene = Scene(@resolution)
        scene.theme[:backgroundcolor] = RGBAf0(0, 0, 0, 1)
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
        N = 25000
        t_audio = sin.(linspace(0, 10pi, N)) .+ (cos.(linspace(-3, 7pi, N)) .* 0.6) .+ (rand(Float32, N) .* 0.1) ./ 2f0
        start = time()
        t = (time() - start) * 100
        pos = calcpositions.((rings,), 1:N, t, (t_audio,))

        scene = lines(pos, color = RGBAf0.(to_colormap(:RdBu, N), 0.6), thickness = 0.6f0, show_axis = false)
        linesegments!(scene, FRect3D(Vec3f0(-1.5), Vec3f0(3)), raw = true, linewidth = 3, linestyle = :dot)
        eyepos = Vec3f0(5, 1.5, 0.5)
        lookat = Vec3f0(0)
        update_cam!(scene, eyepos, lookat)
        l = scene[1]
        record(scene, @outputfile(mp4), 1:300) do i
            t = (time() - start) * 700
            pos .= calcpositions.((rings,), 1:N, t, (t_audio,))
            l[1] = pos # update argument 1
            rotate_cam!(scene, 0.0, 0.01, 0.01)
        end

    end

    @cell "Line GIF" [lines, animated, gif, offset] begin
        us = linspace(0, 1, 100)
        scene = Scene()
        scene = linesegments!(scene, FRect3D(Vec3f0(0, -1, 0), Vec3f0(1, 2, 2)))
        p = lines!(scene, us, sin.(us .+ time()), zeros(100), linewidth = 3)[end]
        lineplots = [p]
        translate!(p, 0, 0, 0)
        colors = to_colormap(:RdYlBu)
        #display(scene) # would be needed without the record
        path = record(scene, @outputfile(gif), 1:200) do i
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


@block SimonDanisch [documentation] begin
    @group begin
        @cell "Axis 2D" [axis] begin
            scene = Scene(@resolution)
            scene.theme[:backgroundcolor] = RGBAf0(0.2, 0.4, 0.6, 1)
            aviz = axis2d!(scene, linspace(0, 2, 4), linspace(0, 2, 4))
            cam2d!(scene)
            center!(scene)
            scene
        end

        @cell "Axis 3D" [axis] begin
            aviz = Makie.axis3d!(scene, linspace(0, 2, 4), linspace(0, 2, 4), linspace(0, 2, 4))
            AbstractPlotting.center!(scene)
            # TODO: This kinda works, but only shows a 2D axis plane in 3D projection?
            cam3d!(scene)
            scene
        end

        @cell "Axis Custom" [axis] begin
            # always tuples of xyz for most attributes that are applied to each axis
            # TODO: aviz[:titlestyle] shows a Dict in a Dict, with :axisnames inside --> how to access this?
            # TODO: aviz[:showticks] works
            # aviz[:gridcolors] = (:gray, :gray, :gray)
            # aviz[:axiscolors] = (:red, :black, :black)
            # aviz[:showticks] = (true, true, false)

            scene = Scene(@resolution)
            println("placeholder")
        end
    end

    # @group begin
    #     @cell "overload to position" [axis] begin
    #         # scene = Scene(@resolution)
    #         # using GeometryTypes
    #         # # To simplify the example, we take the already existing GeometryTypes.Circle type, which
    #         # # can already be decomposed into positions
    #         # function AbstractPlotting.convert_arguments(P, x::Circle)
    #         #     # Convert to a type to_positions can handle.
    #         #     # Everything that usually works in e.g. scatter/lines should be allowed here.
    #         #     positions = Makie.decompose(Point2f0, x, 50)
    #         #     # Pass your position data to to_positions,
    #         #     # just in case the backend has some extra converts
    #         #     # that are not visible in the user facing API.
    #         #     Makie.to_positions(backend, positions)
    #         # end
    #         # # TODO: ERROR: MethodError: AbstractPlotting.convert_arguments(::Type{Lines{...}}, ::GeometryTypes.HyperSphere{2,Float32}) is ambiguous.
    #         # p1 = lines!(Makie.Circle(Point2f0(0), 5f0))
    #         # p2 = scatter!(Makie.Circle(Point2f0(0), 6f0))
    #         # AbstractPlotting.center!(scene)
    #
    #         scene = Scene(@resolution)
    #     end
    #
    #     @cell "change size" [axis] begin
    #         # # TODO: ERROR: MethodError: no method matching setindex!(::AbstractPlotting.Scene, ::GeometryTypes.HyperSphere{2,Float32}, ::Symbol)
    #         # p2[:positions] = Makie.Circle(Point2f0(0), 7f0)
    #         # AbstractPlotting.center!(scene)
    #
    #         scene = Scene(@resolution)
    #     end
    # end

    @cell "Volume Function" ["3d", volume] begin
        volume(rand(32, 32, 32), algorithm = :mip)
    end

    #TODO: document all of the algorithm types
    # :iso => IsoValue,
    # :absorption => Absorption,
    # :mip => MaximumIntensityProjection,
    # :absorptionrgba => AbsorptionRGBA,
    # :indexedabsorption => IndexedAbsorptionRGBA,


    @cell "Textured Mesh" ["3d", mesh, texture, cat] begin
        using FileIO
        scene = Scene(@resolution)
        catmesh = FileIO.load(Makie.assetpath("cat.obj"), GLNormalUVMesh)
        mesh(catmesh, color = Makie.loadasset("diffusemap.tga"))
    end
    @cell "Load Mesh" ["3d", mesh, cat] begin
        mesh(Makie.loadasset("cat.obj"))
    end
    @cell "Colored Mesh" ["3d", mesh, axis] begin
        x = [0, 1, 2, 0]
        y = [0, 0, 1, 2]
        z = [0, 2, 0, 1]
        color = [:red, :green, :blue, :yellow]
        i = [0, 0, 0, 1]
        j = [1, 2, 3, 2]
        k = [2, 3, 1, 3]
        # indices interpreted as triangles (every 3 sequential indices)
        indices = [1, 2, 3,   1, 3, 4,   1, 4, 2,   2, 3, 4]
        mesh(x, y, z, indices, color = color)
    end
    @cell "Wireframe of a Mesh" ["3d", mesh, wireframe, cat] begin
        wireframe(Makie.loadasset("cat.obj"))
    end
    @cell "Wireframe of Sphere" ["3d", wireframe] begin
        wireframe(Sphere(Point3f0(0), 1f0))
    end
    @cell "Wireframe of a Surface" ["3d", surface, wireframe] begin
        function xy_data(x, y)
            r = sqrt(x^2 + y^2)
            r == 0.0 ? 1f0 : (sin(r)/r)
        end
        N = 30
        lspace = linspace(-10, 10, N)
        z = Float32[xy_data(x, y) for x in lspace, y in lspace]
        range = linspace(0, 3, N)
        wireframe(range, range, z)
    end
    @cell "Surface" ["3d", surface] begin
        N = 30
        function xy_data(x, y)
            r = sqrt(x^2 + y^2)
            r == 0.0 ? 1f0 : (sin(r)/r)
        end
        lspace = linspace(-10, 10, N)
        z = Float32[xy_data(x, y) for x in lspace, y in lspace]
        range = linspace(0, 3, N)
        surface(
            range, range, z,
            colormap = :Spectral
        )
    end
    @cell "Surface with image" ["3d", surface, image] begin
        N = 30
        function xy_data(x, y)
            r = sqrt(x^2 + y^2)
            r == 0.0 ? 1f0 : (sin(r)/r)
        end
        r = linspace(-2, 2, N)
        surf_func(i) = [Float32(xy_data(x*i, y*i)) for x = r, y = r]
        surface(
            r, r, surf_func(10),
            image = rand(RGBAf0, 124, 124)
        )
    end
    @cell "Line Function" ["2d", lines] begin
        scene = Scene()
        x = linspace(0, 3pi)
        lines!(scene, x, sin.(x))
        lines!(scene, x, cos.(x), color = :blue)
    end

    @cell "Meshscatter Function" ["3d", meshscatter] begin
        using GeometryTypes
        large_sphere = Sphere(Point3f0(0), 1f0)
        positions = decompose(Point3f0, large_sphere)
        colS = [RGBAf0(rand(), rand(), rand(), 1.0) for i = 1:length(positions)]
        sizesS = [rand(Point3f0) .* 0.5f0 for i = 1:length(positions)]
        meshscatter(positions, color = colS, markersize = sizesS)
    end

    @cell "scatter" ["2d", scatter] begin
        scatter(rand(20), rand(20), markersize = 0.03)
    end

    @cell "Marker sizes" ["2d", scatter] begin
        scatter(rand(20), rand(20), markersize = rand(20)./20, color = to_colormap(:Spectral, 20))
    end

    @cell "Interaction" ["2d", scatter, linesegment, VideoStream] begin
        scene = Scene(@resolution)

        f(t, v, s) = (sin(v + t) * s, cos(v + t) * s)
        time = Node(0.0)
        p1 = scatter!(scene, lift(t-> f.(t, linspace(0, 2pi, 50), 1), time))[end]
        p2 = scatter!(scene, lift(t-> f.(t * 2.0, linspace(0, 2pi, 50), 1.5), time))[end]
        lines = lift(p1[1], p2[1]) do pos1, pos2
            map((a, b)-> (a, b), pos1, pos2)
        end
        linesegments!(scene, lines)
        record(scene, @outputfile(mp4), linspace(0, 10, 100)) do i
            push!(time, i)
        end
    end
    # @cell "Legend" ["3d", legend, lines, linestyle, scatter] begin
    #     # scene = Scene(@resolution)
    #     # # TODO: ERROR: UndefVarError: linesegment not defined
    #     # plots = map([:dot, :dash, :dashdot], [2, 3, 4]) do ls, lw
    #     #     linesegments!(linspace(1, 5, 100), rand(100), rand(100), linestyle = ls, linewidth = lw)
    #     # end
    #     #
    #     # # TODO: ERROR: MethodError: no method matching push!(::AbstractPlotting.#plots, ::AbstractPlotting.Scene)
    #     # push!(plots, scatter!(linspace(1, 5, 100), rand(100), rand(100)))
    #     #
    #     # AbstractPlotting.center!(scene)
    #     #
    #     # # plot a legend for the plots with an array of names
    #     # l = Makie.legend(plots, ["attribute $i" for i in 1:4])
    #     #
    #     # ann = VideoAnnotation(scene, @outputfile(mp4), "Themes")
    #     #
    #     # io = ann
    #     # # TODO: ERROR: UndefVarError: recordstep! not defined
    #     # recordstep!(io, "Interact with Legend:")
    #     # # Change some attributes interactively
    #     # l[:position] = (0.4, 0.7)
    #     # recordstep!(io, "Change Position")
    #     # l[:backgroundcolor] = RGBA(0.95, 0.95, 0.95)
    #     # recordstep!(io, "Change Background")
    #     # l[:strokecolor] = RGB(0.8, 0.8, 0.8)
    #     # recordstep!(io, "Change Stroke Color")
    #     # l[:gap] = 30
    #     # recordstep!(io, "Change Gaps")
    #     # l[:textsize] = 19
    #     # recordstep!(io, "Change Textsize")
    #     # l[:linepattern] = Point2f0[(0,-0.2), (0.5, 0.2), (0.5, 0.2), (1.0, -0.2)]
    #     # recordstep!(io, "Change Line Pattern")
    #     # l[:scatterpattern] = decompose(Point2f0, Circle(Point2f0(0.5, 0), 0.3f0), 9)
    #     # recordstep!(io, "Change Scatter Pattern")
    #     # l[:markersize] = 2f0
    #     # recordstep!(io, "Change Marker Size")
    #     # io
    #
    #     println("placeholder")
    # end

    # @cell "Color Legend" ["2d", colorlegend, legend] begin
    #     # scene = Scene(@resolution)
    #     # cmap = collect(linspace(to_color(:red), to_color(:blue), 20))
    #     # # TODO: ERROR: MethodError: no method matching (::AbstractPlotting.##384#385{AbstractPlotting.Scene})(::AbstractPlotting.Scene)
    #     # l = Makie.legend(cmap, 1:4)
    #     # ann = VideoAnnotation(scene, @outputfile(mp4), "Color Map Legend:")
    #     # recordstep!(io, "Color Map Legend:", 3)
    #     # l[:position] = (1.0, 1.0)
    #     # recordstep!(io, "Change Position")
    #     # l[:textcolor] = :blue
    #     # l[:strokecolor] = :black
    #     # recordstep!(io, "Change Colors")
    #     # l[:strokewidth] = 1
    #     # l[:textsize] = 15
    #     # l[:textgap] = 5
    #     # recordstep!(io, "Change everything!")
    #     # ann
    #
    #     println("placeholder")
    # end

    @cell "VideoStream" ["3d", VideoStream, meshscatter, linesegment] begin
        scene = Scene()

        f(t, v, s) = (sin(v + t) * s, cos(v + t) * s, (cos(v + t) + sin(v)) * s)
        # TODO: ERROR: UndefVarError: to_node not defined
        t = Node(Base.time()) # create a life signal
        limits = FRect3D(Vec3f0(-1.5, -1.5, -3), Vec3f0(3, 3, 6))
        p1 = meshscatter!(scene, lift(t-> f.(t, linspace(0, 2pi, 50), 1), t), markersize = 0.5)[end]
        p2 = meshscatter!(scene, lift(t-> f.(t * 2.0, linspace(0, 2pi, 50), 1.5), t), markersize = 0.5)[end]

        # you can now reference to life attributes from the above plots:
        # TODO: ERROR: UndefVarError: lift_node not defined
        lines = lift(p1[1], p2[1]) do pos1, pos2
            map((a, b)-> (a, b), pos1, pos2)
        end
        linesegments!(scene, lines, linestyle = :dot, limits = limits)
        # record a video
        record(scene, @outputfile(mp4), 1:300) do i
            push!(t, Base.time())
        end
    end


    @group begin
        @cell "Theming Step 1" ["3d", scatter, surface] begin

            scene = Scene(@resolution)
            vx = -1:0.05:1;
            vy = -1:0.05:1;
            f(x, y) = (sin(x*10) + cos(y*10)) / 4
            psurf = surface!(scene, vx, vy, f)[1]
            scene

            # TODO: ERROR: MethodError: no method matching getindex(::AbstractPlotting.Scene, ::Symbol)
            pos = lift(psurf[1], psurf[2], psurf[3]) do x, y, z
                vec(Point3f0.(x, y', z .+ 0.5))
            end
            pscat = scatter!(scene, pos)
            # TODO: the following errors out
            # ERROR: Not a valid index type: Reactive.Signal{StepRange{Int64,Int64}}. Please choose from Int, Vector{UnitRange{Int}}, Vector{Int} or a signal of either of them
            # plines = lines!(scene, lift(view, pos, lift(x->1:2:length(x), pos)))
        end

        @cell "Theming Step 2" ["3d", scatter, surface] begin
            # # TODO: didn't work
            # @theme theme = begin
            #     # TODO: ERROR: UndefVarError: to_markersize2d not defined
            #     markersize = to_markersize2d(0.01)
            #     strokecolor = to_color(:white)
            #     # TODO: ERROR: UndefVarError: to_float not defined
            #     strokewidth = to_float(0.01)
            # end
            # # this pushes all the values from theme to the plot
            # # TODO: ERROR: UndefVarError: theme not defined
            # # --> I guess it is from the above @theme block?
            # push!(pscat, theme)
            # # Update the entire surface node with this
            # scene[:scatter] = theme
            # # Or permananently (to be more precise: just for this session) change the theme for scatter
            # scene[:theme, :scatter] = theme
            # scatter(lift_node(x-> x .+ (Point3f0(0, 0, 1),), pos)) # will now use new theme
            # scene

            scene = Scene(@resolution)
            println("placeholder")
        end

        @cell "Theming Step 3" ["3d", scatter, surface] begin
            # TODO: didn't work
            # Make a completely new theme
            # function custom_theme(scene)
            #     @theme theme = begin
            #         linewidth = to_float(3)
            #         colormap = to_colormap(:RdPu)
            #         scatter = begin
            #             marker = to_spritemarker(Circle)
            #             markersize = to_float(0.03)
            #             strokecolor = to_color(:white)
            #             strokewidth = to_float(0.01)
            #             glowcolor = to_color(RGBA(0, 0, 0, 0.4))
            #             glowwidth = to_float(0.1)
            #         end
            #     end
            #     # update theme values
            #     scene[:theme] = theme
            # end
            #
            # # apply it to the scene
            # custom_theme(scene)
            #
            # # From now everything will be plotted with new theme
            # psurf = surface(vx, 1:0.1:2, psurf[:z])
            # AbstractPlotting.center!(scene)

            scene = Scene(@resolution)
            println("placeholder")
        end
    end
    # @cell "3D Volume Contour with slices" [volume, contour, heatmap, slices, "3d layout", layout] begin
    #     r = linspace(-2pi, 2pi, 100)
    #     volumeslices(r, r, r, (x, y, z)-> sin(x) + cos(y) + sin(z))
    # end
    @cell "3D Contour with 2D contour slices" [volume, contour, heatmap, "3d", transformation] begin
        function test(x, y, z)
            xy = [x, y, z]
            ((xy') * eye(3, 3) * xy) / 20
        end
        x = linspace(-2pi, 2pi, 100)
        scene = Scene()
        c = contour!(scene, x, x, x, test, levels = 10)[end]
        xm, ym, zm = minimum(scene.limits[])
        # c[4] == fourth argument of the above plotting command
        contour!(scene, x, x, map(v-> v[1, :, :], c[4]), transformation = (:xy, zm))
        heatmap!(scene, x, x, map(v-> v[:, 1, :], c[4]), transformation = (:xz, ym))
        contour!(scene, x, x, map(v-> v[:, :, 1], c[4]), fillrange = true, transformation = (:yz, xm))
    end

    @cell "Contour3d" begin [contour3d] begin
        function xy_data(x, y)
            r = sqrt(x*x + y*y)
            r == 0.0 ? 1f0 : (sin(r)/r)
        end
        r = linspace(-1, 1, 100)
        contour3d(r, r, (x,y)-> xy_data(10x, 10y), levels = 20, linewidth = 3)
    end
    # @cell "3d volume animation" [volume, animation, gui, slices, layout] begin
    #     # # TODO: is this example unfinished?
    #     # scene = Scene(@resolution)
    #     # r = linspace(-2pi, 2pi, 100)
    #     # psps = map(1:100) do i
    #     #     broadcast(r, reshape(r, (1, 100, 1)), reshape(r, (1, 1, 100))) do x, y, z
    #     #         j = (i/100)
    #     #         sin(x * j) + cos(y * j) + sin(z)
    #     #     end
    #     # end
    #
    #     println("placeholder")
    # end

    @cell "Arrows 3D" [arrows, "3d"] begin
        function SphericalToCartesian(r::T,θ::T,ϕ::T) where T<:AbstractArray
            x = @.r*sin(θ)*cos(ϕ)
            y = @.r*sin(θ)*sin(ϕ)
            z = @.r*cos(θ)
            Point3f0.(x, y, z)
        end
        n = 100^2 #number of points to generate
        r = ones(n);
        θ = acos.(1 .- 2 .* rand(n))
        φ = 2π * rand(n)
        pts = SphericalToCartesian(r,θ,φ)
        arrows(pts, (normalize.(pts) .* 0.1f0), arrowsize = 0.02, linecolor = :green)
    end

    @cell "Image on Surface Sphere" [surface, sphere, "3d", image] begin
        n = 20
        θ = [0;(0.5:n-0.5)/n;1]
        φ = [(0:2n-2)*2/(2n-1);2]
        x = [cospi(φ)*sinpi(θ) for θ in θ, φ in φ]
        y = [sinpi(φ)*sinpi(θ) for θ in θ, φ in φ]
        z = [cospi(θ) for θ in θ, φ in φ]
        rand([-1f0, 1f0], 3)
        pts = vec(Point3f0.(x, y, z))
        surface(x, y, z, image = Makie.logo())
    end
    @cell "Arrows on Sphere" [surface, sphere, arrows, "3d"] begin
        n = 20
        f   = (x,y,z) -> x*exp(cos(y)*z)
        ∇f  = (x,y,z) -> Point3f0(exp(cos(y)*z), -sin(y)*z*x*exp(cos(y)*z), x*cos(y)*exp(cos(y)*z))
        ∇ˢf = (x,y,z) -> ∇f(x,y,z) - Point3f0(x,y,z)*dot(Point3f0(x,y,z), ∇f(x,y,z))

        θ = [0;(0.5:n-0.5)/n;1]
        φ = [(0:2n-2)*2/(2n-1);2]
        x = [cospi(φ)*sinpi(θ) for θ in θ, φ in φ]
        y = [sinpi(φ)*sinpi(θ) for θ in θ, φ in φ]
        z = [cospi(θ) for θ in θ, φ in φ]

        pts = vec(Point3f0.(x, y, z))
        ∇ˢF = vec(∇ˢf.(x, y, z)) .* 0.1f0
        surface(x, y, z)
        # TODO arrows seem pretty wrong
        arrows!(
            pts, ∇ˢF,
            arrowsize = 0.03, linecolor = :white, linewidth = 3
        )
    end
    @cell "Test heatmap + image overlap" [image, heatmap, transparency, "2d"] begin
        heatmap(rand(32, 32))
        image!(map(x->RGBAf0(x,0.5, 0.5, 0.8), rand(32,32)))
    end
    @cell "Interaction with Mouse" [interactive, scatter, lines, marker] begin
        scene = Scene()
        r = linspace(0, 3, 4)
        cam2d!(scene)
        time = Node(0.0)
        pos = lift(scene.events.mouseposition, time) do mpos, t
            map(linspace(0, 2pi, 60)) do i
                circle = Point2f0(sin(i), cos(i))
                mouse = to_world(scene, Point2f0(mpos))
                secondary = (sin((i * 10f0) + t) * 0.09) * normalize(circle)
                (secondary .+ circle) .+ mouse
            end
        end
        scene = lines!(scene, pos, raw = true)
        p1 = scene[end]
        p2 = scatter!(
            scene,
            pos, markersize = 0.1f0,
            marker = :star5,
            color = p1[:color],
            raw = true
        )[end]

        display(scene)

        p1[:color] = RGBAf0(1, 0, 0, 0.1)
        p2[:marker] = 'π'
        p2[:markersize] = 0.2
        p2[:marker] = 'o'

        # push a reasonable mouse position in case this is executed as part
        # of the documentation
        push!(scene.events.mouseposition, (250.0, 250.0))
        record(scene, @outputfile(mp4), linspace(0.01, 0.4, 100)) do i
            push!(scene.events.mouseposition, (250.0, 250.0))
            p2[:markersize] = i
            push!(time, time[] + 0.1)
        end
    end
end

@block AnthonyWang [documentation] begin
    @cell "Marker sizes + Marker colors" ["2d", scatter, markersize, color] begin
        scene = Scene(@resolution)
        scatter!(
            scene,
            rand(20), rand(20),
            markersize = rand(20) ./20 + 0.02,
            color = rand(RGBf0, 20)
        )
    end
end

database
