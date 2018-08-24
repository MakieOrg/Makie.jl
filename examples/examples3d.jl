
@block SimonDanisch ["3d"] begin

    @cell "Volume Function" [volume] begin
        volume(rand(32, 32, 32), algorithm = :mip)
    end
    @cell "Textured Mesh" [mesh, texture, cat] begin
        using FileIO
        scene = Scene(@resolution)
        catmesh = FileIO.load(Makie.assetpath("cat.obj"), GLNormalUVMesh)
        mesh(catmesh, color = Makie.loadasset("diffusemap.tga"))
    end
    @cell "Load Mesh" [mesh, cat] begin
        mesh(Makie.loadasset("cat.obj"))
    end
    @cell "Colored Mesh" [mesh, axis] begin
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
    @cell "Wireframe of a Mesh" [mesh, wireframe, cat] begin
        wireframe(Makie.loadasset("cat.obj"))
    end
    @cell "Wireframe of Sphere" [wireframe] begin
        wireframe(Sphere(Point3f0(0), 1f0))
    end
    @cell "Wireframe of a Surface" [surface, wireframe] begin
        function xy_data(x, y)
            r = sqrt(x^2 + y^2)
            r == 0.0 ? 1f0 : (sin(r)/r)
        end
        N = 30
        lspace = range(-10, stop = 10, length = N)
        z = Float32[xy_data(x, y) for x in lspace, y in lspace]
        r = range(0, stop = 3, length = N)
        wireframe(r, r, z)
    end
    @cell "Surface" [surface] begin
        N = 30
        function xy_data(x, y)
            r = sqrt(x^2 + y^2)
            r == 0.0 ? 1f0 : (sin(r)/r)
        end
        lspace = range(-10, stop = 10, length = N)
        z = Float32[xy_data(x, y) for x in lspace, y in lspace]
        r = range(0, stop = 3, length = N)
        surface(
            r, r, z,
            colormap = :Spectral
        )
    end
    @cell "Surface with image" [surface, image] begin
        N = 30
        function xy_data(x, y)
            r = sqrt(x^2 + y^2)
            r == 0.0 ? 1f0 : (sin(r)/r)
        end
        r = range(-2, stop = 2, length = N)
        surf_func(i) = [Float32(xy_data(x*i, y*i)) for x = r, y = r]
        surface(
            r, r, surf_func(10),
            color = rand(RGBAf0, 124, 124)
        )
    end
    @cell "Line Function" ["2d", lines] begin
        scene = Scene()
        x = range(0, stop = 3pi)
        lines!(scene, x, sin.(x))
        lines!(scene, x, cos.(x), color = :blue)
    end

    @cell "Meshscatter Function" [meshscatter] begin
        using GeometryTypes
        large_sphere = Sphere(Point3f0(0), 1f0)
        positions = decompose(Point3f0, large_sphere)
        colS = [RGBAf0(rand(), rand(), rand(), 1.0) for i = 1:length(positions)]
        sizesS = [rand(Point3f0) .* 0.05f0 for i = 1:length(positions)]
        meshscatter(positions, color = colS, markersize = sizesS)
    end

    @cell "scatter" ["2d", scatter] begin
        scatter(rand(20), rand(20), markersize = 0.03)
    end

    @cell "Marker sizes" ["2d", scatter] begin
        scatter(rand(20), rand(20), markersize = rand(20)./20, color = to_colormap(:Spectral, 20))
    end



    @cell "Record Video" [record, meshscatter, linesegment] begin
        scene = Scene()

        f(t, v, s) = (sin(v + t) * s, cos(v + t) * s, (cos(v + t) + sin(v)) * s)
        t = Node(Base.time()) # create a life signal
        limits = FRect3D(Vec3f0(-1.5, -1.5, -3), Vec3f0(3, 3, 6))
        p1 = meshscatter!(scene, lift(t-> f.(t, range(0, stop = 2pi, length = 50), 1), t), markersize = 0.05)[end]
        p2 = meshscatter!(scene, lift(t-> f.(t * 2.0, range(0, stop = 2pi, length = 50), 1.5), t), markersize = 0.05)[end]

        lines = lift(p1[1], p2[1]) do pos1, pos2
            map((a, b)-> (a, b), pos1, pos2)
        end
        linesegments!(scene, lines, linestyle = :dot, limits = limits)
        # record a video
        N = 150
        record(scene, @outputfile(mp4), 1:N) do i
            push!(t, Base.time())
        end
    end

    @cell "3D Contour with 2D contour slices" [volume, contour, heatmap, transformation] begin
        using LinearAlgebra
        function test(x, y, z)
            xy = [x, y, z]
            ((xy') * Matrix(I, 3, 3) * xy) / 20
        end
        x = range(-2pi, stop = 2pi, length = 100)
        scene = Scene()
        c = contour!(scene, x, x, x, test, levels = 6, alpha = 0.3)[end]
        xm, ym, zm = minimum(scene.limits[])
        # c[4] == fourth argument of the above plotting command
        contour!(scene, x, x, map(v-> v[1, :, :], c[4]), transformation = (:xy, zm), linewidth = 10)
        heatmap!(scene, x, x, map(v-> v[:, 1, :], c[4]), transformation = (:xz, ym))
        contour!(scene, x, x, map(v-> v[:, :, 1], c[4]), fillrange = true, transformation = (:yz, xm))
    end

    @cell "Contour3d" [contour3d] begin
        function xy_data(x, y)
            r = sqrt(x*x + y*y)
            r == 0.0 ? 1f0 : (sin(r)/r)
        end
        r = range(-1, stop = 1, length = 100)
        contour3d(r, r, (x,y)-> xy_data(10x, 10y), levels = 20, linewidth = 3)
    end

    # @cell "3d volume animation" [volume, animation, gui, slices, layout] begin
    #     # # TODO: is this example unfinished?
    #     # scene = Scene(@resolution)
    #     # r = range(-2pi, stop = 2pi, length = 100)
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
        using LinearAlgebra
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
        arrows(pts, (normalize.(pts) .* 0.1f0), arrowsize = 0.02, linecolor = :green, arrowcolor = :darkblue)
    end

    @cell "Image on Surface Sphere" [surface, sphere, image] begin
        n = 20
        θ = [0;(0.5:n-0.5)/n;1]
        φ = [(0:2n-2)*2/(2n-1);2]
        x = [cospi(φ)*sinpi(θ) for θ in θ, φ in φ]
        y = [sinpi(φ)*sinpi(θ) for θ in θ, φ in φ]
        z = [cospi(θ) for θ in θ, φ in φ]
        rand([-1f0, 1f0], 3)
        pts = vec(Point3f0.(x, y, z))
        surface(x, y, z, color = Makie.logo())
    end

    @cell "Arrows on Sphere" [surface, sphere, arrows, "3d"] begin
        using LinearAlgebra
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
        arrows!(
            pts, ∇ˢF,
            arrowsize = 0.03, linecolor = (:white, 0.6), linewidth = 3
        )
    end

    @cell "surface + contour3d" [surface, contour3d, subscene] begin
        vx = -1:0.01:1
        vy = -1:0.01:1

        f(x, y) = (sin(x*10) + cos(y*10)) / 4

        p1 = surface(vx, vy, f)
        p2 = contour3d(vx, vy, (x, y) -> f(x,y), levels = 15, linewidth = 3)

        scene = AbstractPlotting.vbox(p1, p2)
        text!(campixel(p1), "surface", position = widths(p1) .* Vec(0.5, 1), align = (:center, :top), raw = true)
        text!(campixel(p2), "contour3d", position = widths(p2) .* Vec(0.5, 1), align = (:center, :top), raw = true)
        scene
    end

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
        lengthsC = sqrt.(sum((pts[edges[:,1], :] .- pts[edges[:, 2], :]) .^ 2, dims = 2))
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
        using LinearAlgebra
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

        r = range(-2, stop = 2, length = 50)
        surf_func(i) = [Float32(xy_data(x*i, y*i)) for x = r, y = r]
        z = surf_func(20)
        surf = surface!(scene, r, r, z)[end]

        wf = wireframe!(scene, r, r, Makie.lift(x-> x .+ 1.0, surf[3]),
            linewidth = 2f0, color = Makie.lift(x-> to_colormap(x)[5], surf[:colormap])
        )
        N = 150
        scene
        record(scene, @outputfile(mp4), range(5, stop = 40, length = N)) do i
            surf[3] = surf_func(i)
        end
    end

    @cell "Normals of a Cat" [mesh, linesegment, cat] begin
        using LinearAlgebra
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
            markersize = rand(range(0.0001, stop = 0.01, length = 100), stars),
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
        t_audio = sin.(range(0, stop = 10pi, length = N2)) .+ (cos.(range(-3, stop = 7pi, length = N2)) .* 0.6) .+ (rand(Float32, N2) .* 0.1) ./ 2f0
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
        us = range(0, stop = 1, length = 100)
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

    @cell "Surface + wireframe + contour" [surface, wireframe, contour, transformation] begin
        N = 51
        x = range(-2, stop = 2, length = N)
        y = x
        z = (-x .* exp.(-x .^ 2 .- (y') .^ 2)) .* 4

        scene = wireframe(x, y, z)
        xm, ym, zm = minimum(scene.limits[])
        scene = surface!(scene, x, y, z)
        contour!(scene, x, y, z, levels = 15, linewidth = 2, transformation = (:xy, zm))
        scene
    end

end
