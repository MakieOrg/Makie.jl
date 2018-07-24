
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
        lspace = linspace(-10, 10, N)
        z = Float32[xy_data(x, y) for x in lspace, y in lspace]
        range = linspace(0, 3, N)
        wireframe(range, range, z)
    end
    @cell "Surface" [surface] begin
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
    @cell "Surface with image" [surface, image] begin
        N = 30
        function xy_data(x, y)
            r = sqrt(x^2 + y^2)
            r == 0.0 ? 1f0 : (sin(r)/r)
        end
        r = linspace(-2, 2, N)
        surf_func(i) = [Float32(xy_data(x*i, y*i)) for x = r, y = r]
        surface(
            r, r, surf_func(10),
            color = rand(RGBAf0, 124, 124)
        )
    end
    @cell "Line Function" ["2d", lines] begin
        scene = Scene()
        x = linspace(0, 3pi)
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
        p1 = meshscatter!(scene, lift(t-> f.(t, linspace(0, 2pi, 50), 1), t), markersize = 0.05)[end]
        p2 = meshscatter!(scene, lift(t-> f.(t * 2.0, linspace(0, 2pi, 50), 1.5), t), markersize = 0.05)[end]

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
        function test(x, y, z)
            xy = [x, y, z]
            ((xy') * eye(3, 3) * xy) / 20
        end
        x = linspace(-2pi, 2pi, 100)
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

end
